# Email Hub — How to Make It Real

The Email Hub page is now live in the portal, running in **preview mode** with sample
messages. This guide explains, in plain terms, what it takes to connect it to real
mailboxes — and walks a developer through building the backend.

Read the first two sections even if you're not technical. They affect budget and timeline.

---

## 1. The honest summary (read this first)

The portal is a single HTML file with no server. A web page in the browser **cannot**
read Gmail, Yahoo, or IMAP mail directly — the mail providers block it, and browsers
can't open mail connections. So a small **backend server** has to sit between each
staff member and their own mailboxes. It holds *their* access token (which they consent
to) and fetches *their* mail.

This is true even though each person only ever sees their own email. "Their own mail
only" makes it safer and simpler — it does **not** remove the need for a server.

What that means in practice:

- You need a backend service running somewhere (a small always-on server).
- You need a database to store which accounts each person connected.
- For Gmail/Workspace, you must register an app with Google and pass their review.
- You take on a real duty of care: you're holding keys to staff inboxes, which is
  personal data under NDPR. Encryption and access control are not optional.

**Before building anything, consider the free alternative.** The Gmail app and Outlook
both already let one person add multiple accounts (Gmail, Workspace, Yahoo, IMAP) and
read them in one unified inbox, on phone and desktop, with zero build and zero security
burden. For many people that solves the exact "stop juggling tabs" problem in an
afternoon. Build the custom backend only if you specifically need email *inside the
portal* for all staff and have decided it's worth the ongoing commitment.

---

## 2. What's already done (the front end)

The Email Hub page is complete and waiting:

- A 3-pane inbox: accounts on the left, a merged message feed in the middle, a
  reading-and-reply pane on the right.
- A "Connect account" flow for Gmail, Yahoo, and IMAP.
- Everything scoped to the logged-in user only.
- A clean **backend seam**: every email action goes through one object called
  `EmailAPI` in the code. When there's no backend, it serves sample data. When a backend
  exists, it calls it. You flip between them by setting one value.

**To go live, a developer sets this near the top of the email module in `index.html`:**

```js
const EMAIL_BACKEND = 'https://email-api.slum2school.org';  // empty = demo mode
```

Once that points at a real server, the page stops showing sample data and starts showing
real mail. No other front-end changes needed.

The backend must expose these endpoints (the front end already calls them):

| Method | Path | Purpose |
|--------|------|---------|
| `GET`  | `/api/email/accounts` | List the logged-in user's connected accounts |
| `GET`  | `/api/email/unified-inbox` | Return all their mail, merged and normalised |
| `POST` | `/api/email/accounts/connect-imap` | Save Yahoo/IMAP credentials |
| `GET`  | `/api/email/oauth/google/start` | Begin Google sign-in |
| `POST` | `/api/email/send` | Send a reply |
| `DELETE`| `/api/email/accounts/:id` | Disconnect an account |

Every message the backend returns must match this shape (the UI depends on it):

```ts
interface NormalizedEmail {
  id: string;
  accountId: string;
  accountEmail: string;
  provider: 'GMAIL' | 'YAHOO' | 'IMAP';
  sender: { name: string; address: string };
  subject: string;
  snippet: string;
  bodyHtml: string;
  date: string;     // ISO format
  isRead: boolean;
}
```

---

## 3. The build, stage by stage

A competent Node developer can stand up a first working version in a few days. Plan for
2–4 weeks end-to-end once Google's review and security hardening are included.

### Stage 0 — Decide hosting and budget

- **Server:** a small Node host (Render, Railway, Fly.io, or a cheap VPS). ~$7–25/month.
- **Database:** managed PostgreSQL (Neon, Supabase, Railway). Free tier is fine to start.
- **Domain:** a subdomain like `email-api.slum2school.org` with HTTPS.

### Stage 1 — Database

Store *which* accounts each user connected and their tokens. Use this Prisma schema:

```prisma
// prisma/schema.prisma
generator client { provider = "prisma-client-js" }
datasource db { provider = "postgresql"; url = env("DATABASE_URL") }

model User {
  id        String         @id @default(cuid())
  email     String         @unique
  accounts  EmailAccount[]
  createdAt DateTime       @default(now())
}

enum Provider { GMAIL  YAHOO  IMAP }
enum SyncStatus { ACTIVE  ERROR  PENDING }

model EmailAccount {
  id           String     @id @default(cuid())
  user         User       @relation(fields: [userId], references: [id], onDelete: Cascade)
  userId       String
  emailAddress String
  provider     Provider
  syncStatus   SyncStatus @default(PENDING)

  // ⚠️ ENCRYPT THESE AT THE APPLICATION LAYER BEFORE SAVING.
  // Never store them as plain text. See Stage 5.
  accessToken  String?    // Gmail OAuth
  refreshToken String?    // Gmail OAuth
  imapPassword String?    // Yahoo / IMAP app password

  imapHost     String?
  imapPort     Int?
  smtpHost     String?
  smtpPort     Int?

  createdAt    DateTime   @default(now())
  @@unique([userId, emailAddress])
}
```

Run `npx prisma migrate dev` to create the tables.

### Stage 2 — Project setup

```bash
mkdir s2s-email-backend && cd s2s-email-backend
npm init -y
npm i express cors googleapis imapflow nodemailer @prisma/client jsonwebtoken
npm i -D typescript @types/express @types/node ts-node prisma
npx tsc --init
npx prisma init
```

### Stage 3 — Gmail (Google OAuth)

This is the part with the most setup, because Google guards Gmail access carefully.

1. Go to **Google Cloud Console** → create a project.
2. Enable the **Gmail API**.
3. Create **OAuth consent screen** (External), add the scope
   `https://www.googleapis.com/auth/gmail.modify` (read + send).
4. Create **OAuth client credentials** (Web application). Set the redirect URI to
   `https://email-api.slum2school.org/api/email/oauth/google/callback`.
5. **Submit for verification.** Because Gmail is a "restricted scope", Google requires a
   review and, for organisations, often a security assessment. This is the step that adds
   weeks — start it early. Until verified, only test users you list can connect.

The flow in code: the front end sends the user to `/oauth/google/start`, you redirect to
Google, the user consents, Google calls your `/callback` with a code, you exchange it for
tokens, **encrypt** them, and save an `EmailAccount` row.

### Stage 4 — The aggregation service

One class with two methods, both returning the exact `NormalizedEmail` shape:

```ts
// src/services/emailSync.service.ts
import { google } from 'googleapis';
import { ImapFlow } from 'imapflow';
import { decrypt } from '../crypto';          // see Stage 5
import type { EmailAccount } from '@prisma/client';

export interface NormalizedEmail {
  id: string; accountId: string; accountEmail: string;
  provider: 'GMAIL' | 'YAHOO' | 'IMAP';
  sender: { name: string; address: string };
  subject: string; snippet: string; bodyHtml: string;
  date: string; isRead: boolean;
}

export class EmailSyncService {
  async fetchGmailInbox(account: EmailAccount): Promise<NormalizedEmail[]> {
    const auth = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_SECRET,
      process.env.GOOGLE_REDIRECT_URI
    );
    auth.setCredentials({ refresh_token: decrypt(account.refreshToken!) });
    const gmail = google.gmail({ version: 'v1', auth });

    const list = await gmail.users.messages.list({ userId: 'me', maxResults: 25, q: 'in:inbox' });
    const out: NormalizedEmail[] = [];
    for (const m of list.data.messages ?? []) {
      const full = await gmail.users.messages.get({ userId: 'me', id: m.id!, format: 'full' });
      const headers = full.data.payload?.headers ?? [];
      const h = (n: string) => headers.find(x => x.name?.toLowerCase() === n)?.value ?? '';
      const fromRaw = h('from');
      const match = fromRaw.match(/(.*)<(.*)>/);
      out.push({
        id: m.id!, accountId: account.id, accountEmail: account.emailAddress,
        provider: 'GMAIL',
        sender: { name: (match?.[1] ?? fromRaw).trim().replace(/"/g, ''), address: (match?.[2] ?? fromRaw).trim() },
        subject: h('subject'),
        snippet: full.data.snippet ?? '',
        bodyHtml: extractHtml(full.data.payload),   // walk parts for text/html
        date: new Date(Number(full.data.internalDate)).toISOString(),
        isRead: !(full.data.labelIds ?? []).includes('UNREAD'),
      });
    }
    return out;
  }

  async fetchImapInbox(account: EmailAccount): Promise<NormalizedEmail[]> {
    const client = new ImapFlow({
      host: account.imapHost!, port: account.imapPort ?? 993, secure: true,
      auth: { user: account.emailAddress, pass: decrypt(account.imapPassword!) },
      logger: false,
    });
    await client.connect();
    const out: NormalizedEmail[] = [];
    const lock = await client.getMailboxLock('INBOX');
    try {
      const total = client.mailbox.exists;
      const from = Math.max(1, total - 24);
      for await (const msg of client.fetch(`${from}:*`, { envelope: true, source: true, flags: true })) {
        const env = msg.envelope;
        const sender = env.from?.[0];
        out.push({
          id: String(msg.uid), accountId: account.id, accountEmail: account.emailAddress,
          provider: account.provider === 'YAHOO' ? 'YAHOO' : 'IMAP',
          sender: { name: sender?.name ?? sender?.address ?? '', address: sender?.address ?? '' },
          subject: env.subject ?? '(no subject)',
          snippet: '',                       // parse body with mailparser if you want snippets
          bodyHtml: msg.source?.toString() ?? '',
          date: (env.date ?? new Date()).toISOString(),
          isRead: msg.flags?.has('\\Seen') ?? false,
        });
      }
    } finally {
      lock.release();
      await client.logout();
    }
    return out.reverse();
  }
}
```

The unified-inbox endpoint then fetches every account **in parallel** and merges:

```ts
const results = await Promise.allSettled(
  accounts.map(a => a.provider === 'GMAIL'
    ? svc.fetchGmailInbox(a)
    : svc.fetchImapInbox(a))
);
const merged = results.flatMap(r => r.status === 'fulfilled' ? r.value : []);
merged.sort((a, b) => +new Date(b.date) - +new Date(a.date));
res.json(merged);
```

### Stage 5 — Encryption (do not skip)

Tokens and IMAP passwords must be encrypted before they touch the database. A minimal,
correct approach using Node's built-in crypto:

```ts
// src/crypto.ts
import crypto from 'crypto';
const KEY = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex'); // 32 random bytes, kept secret

export function encrypt(text: string): string {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', KEY, iv);
  const enc = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return [iv.toString('hex'), tag.toString('hex'), enc.toString('hex')].join(':');
}
export function decrypt(payload: string): string {
  const [iv, tag, data] = payload.split(':').map(h => Buffer.from(h, 'hex'));
  const d = crypto.createDecipheriv('aes-256-gcm', KEY, iv);
  d.setAuthTag(tag);
  return Buffer.concat([d.update(data), d.final()]).toString('utf8');
}
```

Generate the key once with `openssl rand -hex 32` and store it as an environment secret —
never in the code or the repo.

### Stage 6 — Sending mail

- **Gmail:** send via the Gmail API using the same OAuth client.
- **Yahoo/IMAP:** send via `nodemailer` over the account's SMTP server.

The `/api/email/send` endpoint looks at the chosen "from" account and picks the right
transport.

### Stage 7 — Connect the front end

1. Deploy the backend to your host.
2. Point the portal at it: set `EMAIL_BACKEND` in `index.html`, commit, push (Vercel
   redeploys).
3. Make sure the backend allows requests from your portal's domain (CORS) and shares the
   logged-in user's identity (a token or session cookie).

---

## 4. Security checklist before real staff use

- [ ] Tokens and passwords encrypted at rest (Stage 5).
- [ ] Encryption key stored as a secret, not in code.
- [ ] HTTPS everywhere.
- [ ] Each request authenticated — a user can only ever reach their own accounts.
- [ ] Google OAuth app verified for the Gmail scope.
- [ ] A "disconnect" action that fully deletes stored tokens.
- [ ] An NDPR data-protection note covering what you store and why.
- [ ] Logging that never records token values or message contents.

---

## 5. A sensible rollout

1. **Now:** show the preview Email Hub to the ED and a few staff. Confirm the layout and
   workflow are what people actually want.
2. **If yes:** build the backend with **one or two pilot users** (yourself + the ED) while
   Google verification is in progress.
3. **Pilot:** run it for a few weeks with real accounts. Watch for sync errors and load.
4. **Roll out** to more staff in small groups, not all at once.

If at any stage the free Gmail/Outlook multi-account route turns out to be enough, you can
stop — the preview page can simply stay as a "set up unified mail" helper that links staff
to those apps.

---

Slum2School Africa · HR & Talent
