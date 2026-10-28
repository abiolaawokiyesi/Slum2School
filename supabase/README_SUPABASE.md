# Bringing the S2S People Portal live — quick guide (v6.11.0)

**From v6.9.2 nobody has to enter anything.** Your Supabase project details are built into
`index.html`, so the portal connects itself the first time each person opens it. Staff just open the
link and sign in. There is no key to circulate, no setup step for the 40+ people on the team, and
nothing for you to talk anyone through over the phone.

Your project:

| | |
|---|---|
| Project URL | `https://ndtipdjcohxfyqtfesrr.supabase.co` |
| Key baked into the app | the **anon public** key (verified — role `anon`, valid to July 2036) |

What is left for you is three things: build the database, turn on email sign-in, and put the file
somewhere staff can reach it. About fifteen minutes, once.

---

## Step 1 — Build the database  ⚠ do not skip this

Open your project at <https://supabase.com>, go to **SQL Editor → New query**, then paste and
**Run** each file **in this order**. Wait for each to finish before starting the next.

| # | File | What it creates |
|---|------|-----------------|
| 1 | `01_schema.sql` | All 13 tables, **the security rules that decide who sees what**, and the trigger that builds a staff profile automatically when someone registers |
| 2 | `02_seed.sql` | The 51-person roster with roles, departments, salaries and bank details |
| 3 | `03_views.sql` | The HR and ED dashboard views (attendance boards, payroll register, requisition spend) |
| 4 | `04_accounts.sql` | Pre-creates the HR, Executive Director and Finance Manager logins |
| 5 | `05_attendance_punches.sql` | Multiple clock-ins per day, plus the session / daily / monthly attendance views |
| 6 | `06_verify.sql` | Optional — checks everything landed, and gives HR and the ED 20 ready-made activity queries |
| 7 | `07_v610_login_visibility_proration.sql` | **v6.10.** Sign-in from any device, who counts as HR / ED / Finance (`access_roles`), the profile guard, automatic email confirmation for company addresses, and the salary proration columns. Run it last, and again whenever you re-run `01` |
| 8 | `08_v611_compliance.sql` | **v6.11.** Cloud columns for the salary breakdown, date of birth and the working-day / statutory settings |

Every file is safe to run more than once, so if you lose your place you can start that file again.
Green "Success" with no rows returned is the normal result for files 1 to 5.

**Why `01_schema.sql` matters more than ever.** Now that the anon key ships inside the app, the
Row-Level Security rules in that file are what stand between your data and anyone who opens the
page. That is exactly how Supabase is designed to work — the anon key is meant to be public, and
the database, not the app, decides who may read what. But it only holds if `01_schema.sql` has
run. Do not create tables by hand and skip it, and do not turn RLS off on any table.

## Step 2 — Turn on email sign-in

Go to **Authentication → Sign In / Providers → Email** and make sure it is **enabled**.

For the smoothest launch, switch **"Confirm email" OFF**. Staff are then signed in the moment they
register. If you leave it on, all 40+ people must find a confirmation link in their inbox before
their first login, which in practice is where most rollouts stall.

## Step 3 — Put the app where staff can reach it

Upload `index.html`, `sw.js`, `icon-192.png` and `icon-512.png` to any web host, keeping them in
the same folder. Netlify Drop, GitHub Pages, Cloudflare Pages and Vercel all work and are free;
so does your own domain. It must be served over **HTTPS**, because GPS clock-in and install-to-home-
screen both require it.

Then send staff the one link. That is the whole rollout — the portal is already connected when it
opens.

## Step 4 — Sign in and check it worked

Three accounts already exist from `04_accounts.sql`:

| Role | Email | Temporary password |
|------|-------|--------------------|
| HR (Super Admin) | abiola.awokiyesi@slum2school.org | `S2S-HR-2026` |
| Executive Director | otto.orondaam@slum2school.org | `S2S-ED-2026` |
| Finance Manager | hammed.balogun@slum2school.org | `S2S-Finance-2026` |

**Change all three passwords straight after the first login** — Supabase → Authentication → Users,
or the portal's "Forgot password?" once email is configured.

Everyone else simply clicks **Register** with their work email. Their profile is created
automatically as an ordinary employee, and their attendance and requisitions link to their record
by email address.

To confirm the whole chain: sign in as any staff member and clock in, then sign in as HR on a
different device. The clock-in should already be on the HR dashboard, without a refresh.

You can tell at a glance that a device is live — the round button at the bottom-right of the screen
is **green** with a tick. Click it and it will say *"✓ Connected to the S2S project automatically —
data is saving live. Nothing to enter."*

---

## What HR and the ED can see once it is live

This is enforced by the database itself, not just by the app, so it holds even if someone tries to
go around the interface.

**HR (Super Admin), the Executive Director and the Finance Manager can see, for every staff member:**
every clock-in and clock-out including the full punch list for the day, hours worked, which office
they clocked in from and the GPS accuracy of the fix; every requisition raised, its amount, its
status and its line items; the full staff directory and every salary, payslip and payroll run; and
every notice posted, whoever the audience was. HR additionally sees all leave requests and the
complete audit log of who changed what and when.

**An ordinary staff member sees only their own record** — their own attendance, their own
requisitions, their own leave and payslip, the staff directory, and notices addressed to them.
Payroll is hidden from them in the app and refused by the database.

The dashboards read from views built for exactly this: `v_admin_dashboard` for HR,
`v_ed_dashboard` for the Executive Director, plus `v_attendance_today`, `attendance_daily`,
`attendance_monthly`, `v_department_attendance_today`, `v_org_attendance_daily` and
`v_requisitions_pending`. Attendance, requisitions, payslips, notices and office records are all
published for realtime, so a new clock-in appears on the HR and ED screens as it happens.

## If something does not work

**The cloud button is navy instead of green.** Either that device has no internet on first open —
the portal needs one online visit to fetch the Supabase library, after which it works offline — or
someone clicked **Work offline** on it. Click the button and choose **Use the S2S project**.

**"Invalid login credentials" for HR, ED or Finance.** `04_accounts.sql` did not run, or your
Supabase version refused the direct account insert. The fallback is at the bottom of that file:
have each person Register in the portal with the same email and job title, then run the one-line
promote for HR.

**A staff member registered but sees nothing.** They registered with a personal email that does not
match their roster record. Correct the email in Supabase → Authentication → Users, or add it to
their row in `public.staff`.

**HR can see attendance but the hours look wrong.** `05_attendance_punches.sql` has not been run.
Until it is, the database only stores first-in and last-out, so the extra punches during the day
are not counted. Run it — it backfills the existing rows.

**Nothing is syncing and a small banner mentions pending changes.** That is the offline queue doing
its job. The portal saved everything on the device and will push it up by itself when the
connection returns; no re-typing is needed.

## Notes worth knowing

**Staff can install the portal on their phones** once it is hosted over HTTPS — Android offers an
install prompt, and on iPhone it is Share → Add to Home Screen.

**Losing internet does not break anything.** Clock-ins and requisitions made offline are saved on
the device and pushed up automatically when the connection returns.

**Changing the key later.** If you ever rotate the anon key or move to a different Supabase
project, you have two options. Either send out a rebuilt `index.html` with the new details, or —
for one device at a time — click the cloud button, paste the new Project URL and anon key, and
click **Save & connect**. A device with its own saved details ignores the built-in ones until you
click **Use the S2S project** to put it back.

**The `service_role` key must never go into the portal**, be pasted into the cloud modal, or be
shared. It bypasses every security rule. Only the anon key belongs in a browser, and it is already
there.
