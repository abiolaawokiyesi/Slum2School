-- SUPABASE · 02 · SEED  (roster + salaries + bank details; total ₦8,315,000). Runs as owner, bypasses RLS.

insert into public.staff(staff_id,full_name,role,category,department,status,start_date,email,account_no,bank_name) values
 ('S26001','Otto Orondaam Harmony','Executive Director','Full-Time','Full-Time','Active','Jun 2026','otto.harmony@slum2school.org','0039409354','GTBANK'),
 ('S26002','Ifeanyichukwu Lois','Senior Growth and Sustainability Manager','Full-Time','Full-Time','Active','Jun 2026','ifeanyichukwu.lois@slum2school.org','0043609458','GTBANK'),
 ('S26003','Abiola Awokiyesi','Human Resource Manager','Full-Time','Full-Time','Active','Jun 2026','abiola.awokiyesi@slum2school.org','0108365501','GTBANK'),
 ('S26004','Yahaya Hauwa Iloba','Partnership Manager','Full-Time','Full-Time','Active','Jun 2026','yahaya.iloba@slum2school.org','0109934106','GTBANK'),
 ('S26005','Patience Osinaike','Chief of Staff','Full-Time','Full-Time','Active','Jun 2026','patience.osinaike@slum2school.org','2401649147','ZENITH'),
 ('S26006','Adekunle Idowu Olukayode','Senior Project Manager','Full-Time','Full-Time','Active','Jun 2026','adekunle.olukayode@slum2school.org','3089293869','POLARIS'),
 ('S26007','Ekene Chukwuma','Administration & Logistics Manager','Full-Time','Full-Time','Active','Jun 2026','ekene.chukwuma@slum2school.org','2011571032','OPAY'),
 ('S26008','Balogun Hammed Olanrewaju','Finance Manager','Full-Time','Full-Time','Active','Jun 2026','balogun.olanrewaju@slum2school.org','3024317647','POLARIS'),
 ('S26009','Oluyemi Ajike Alugo','Education & Innovation Manager','Full-Time','Full-Time','Active','Jun 2026','oluyemi.alugo@slum2school.org','0026301308','STANBIC'),
 ('S26010','Reuben Micheal','Project Coordinator','Full-Time','Full-Time','Active','Jun 2026','reuben.micheal@slum2school.org','0250112920','WEMA'),
 ('S26011','Akodoye Henry Sewanu','Programs Coordinator','Full-Time','Full-Time','Active','Jun 2026','akodoye.sewanu@slum2school.org','8051633581','OPAY'),
 ('S26012','Mojetoluwa Adedeji','Partnership & Fundraising Officer','Full-Time','Full-Time','Active','Jun 2026','mojetoluwa.adedeji@slum2school.org','8140400422','OPAY'),
 ('S26013','Favour Oluwatunbi','Creative Media and Content Coordinator','Full-Time','Full-Time','Active','Jun 2026','favour.oluwatunbi@slum2school.org','8090680368','OPAY'),
 ('S26014','Joshua Samson','Program Manager (Abj)','Contract','Contract','Active','Jun 2026','joshua.samson@slum2school.org','0735239861','OPAY'),
 ('S26015','Emmanuella Iduot','Program Manager (PH)','Contract','Contract','Active','Jun 2026','emmanuella.iduot@slum2school.org','0170931462','GTB'),
 ('S26016','Praise Ntui','Creative Media Executive','Contract','Contract','Active','Jun 2026','praise.ntui@slum2school.org','7071421920','Moniepoint'),
 ('S26017','Grace Udeh','Cleaning Officer','Auxiliary','Auxiliary','Active','Jun 2026','grace.udeh@slum2school.org','0105429989','ACCESS'),
 ('S26018','Christopher Epigha','Community Officer','Auxiliary','Auxiliary','Active','Jun 2026','christopher.epigha@slum2school.org','8076183364','OPAY'),
 ('S26019','Moshood Adewale Ayeola','Security Personnel (Saga)','Auxiliary','Auxiliary','Active','Jun 2026','moshood.ayeola@slum2school.org','8158175936','OPAY'),
 ('S26020','Moibi Taofeek','Security Personnel (Saga)','Auxiliary','Auxiliary','Active','Jun 2026','moibi.taofeek@slum2school.org','9032270359','Opay'),
 ('S26021','Glory Semidara','Cleaning Officer - Saga','Auxiliary','Auxiliary','Active','Jun 2026','glory.semidara@slum2school.org','1806025679','ACCESS'),
 ('S26022','Ebimobowei Jimma Ugeh','Cleaning Officer - Saga','Auxiliary','Auxiliary','Active','Jun 2026','ebimobowei.ugeh@slum2school.org','7052660561','OPAY'),
 ('S26023','Amala Security','Security Personnel (Hub)','Auxiliary','Auxiliary','Active','Jun 2026','amala.security@slum2school.org','1012601289','ZENITH'),
 ('S26024','NFSS Security','Security Personnel','Auxiliary','Auxiliary','Active','Jun 2026','nfss.security@slum2school.org','',''),
 ('S26025','Wada James Jesutin','Adekunle Teacher','School','School','Active','Jun 2026','wada.jesutin@slum2school.org','3070470018','FIRST'),
 ('S26026','Idowu Joshua','Adekunle Teacher','School','School','Active','Jun 2026','idowu.joshua@slum2school.org','0044667483','ACCESS'),
 ('S26027','Chinaza Joy Agudozie','Adekunle Teacher','School','School','Active','Jun 2026','chinaza.agudozie@slum2school.org','0040825410','ACCESS'),
 ('S26028','Israel Afolarin Idowu','Adekunle Teacher','School','School','Active','Jun 2026','israel.idowu@slum2school.org','1239246285','ACCESS'),
 ('S26029','Anifat Jimoh','Aiyetoro Teacher','School','School','Active','Jun 2026','anifat.jimoh@slum2school.org','2107496443','UBA'),
 ('S26030','Jonathan Deborah','Aiyetoro Teacher','School','School','Active','Jun 2026','jonathan.deborah@slum2school.org','3090360562','FIRST'),
 ('S26031','Odjenu Ruth Adeola','Aiyetoro Teacher','School','School','Active','Jun 2026','odjenu.adeola@slum2school.org','0466211502','GTBANK'),
 ('S26032','Zaccheaus Oluwaseun Tosse','Aiyetoro Teacher','School','School','Active','Jun 2026','zaccheaus.tosse@slum2school.org','2069359343','UBA'),
 ('S26033','Iroko Temitope Barthlemy','Makoko Community Engagement Officer','School','School','Active','Jun 2026','iroko.barthlemy@slum2school.org','0091953583','OPAY'),
 ('S26034','Agoyon Amandine Abiodun','Makoko Teacher','School','School','Active','Jun 2026','agoyon.abiodun@slum2school.org','3120656687','FIRST'),
 ('S26035','Okpoe Florentin Mihode','Makoko Teacher','School','School','Active','Jun 2026','okpoe.mihode@slum2school.org','2893003211','ECO'),
 ('S26036','Ige Mary Olubimpe','Makoko Children/School Support','School','School','Active','Jun 2026','ige.olubimpe@slum2school.org','3214261801','FIRST'),
 ('S26037','Zeblon Doris Flora','Epiphany Teacher & Independent Community Officer','School','School','Active','Jun 2026','zeblon.flora@slum2school.org','2125954697','UBA'),
 ('S26038','Happiness Anadozie','Epiphany Teacher','School','School','Active','Jun 2026','happiness.anadozie@slum2school.org','4201880191','ZENITH'),
 ('S26039','Omosuwa Emiloju','School Officer / Support','School','School','Active','Jun 2026','omosuwa.emiloju@slum2school.org','5692010686','ECOBANK'),
 ('S26040','Modinat Idowu Kamilu','Green Academy','School','School','Active','Jun 2026','modinat.kamilu@slum2school.org','2282415028','UBA'),
 ('S26041','Giwa Opeyemi','Green Academy','School','School','Active','Jun 2026','giwa.opeyemi@slum2school.org','6018548679','KEYSTONE'),
 ('S26042','Gbatomine Queen','Green Academy','School','School','Active','Jun 2026','gbatomine.queen@slum2school.org','0814637825','ACCESS'),
 ('S26043','Aisha Firdausi Zakari','Field Officer','School','School','Active','Jun 2026','aisha.zakari@slum2school.org','1490814630','ACCESS'),
 ('S26044','Michelle Omon Ijeojealero','Green Academy','School','School','Active','Jun 2026','michelle.ijeojealero@slum2school.org','8117440670','OPay'),
 ('S26045','Dereoyanimugh Paibi','Green Academy','School','School','Active','Jun 2026','dereoyanimugh.paibi@slum2school.org','2159067745','ECOBANK'),
 ('S26046','Toluwalase Stola','Green Academy','School','School','Active','Jun 2026','toluwalase.stola@slum2school.org','0014687359','STANBIC'),
 ('S26047','Aminat Idris','Green Academy','School','School','Active','Jun 2026','aminat.idris@slum2school.org','8053716494','OPAY'),
 ('S26048','Okwandu Atuoma','Green Academy','School','School','Active','Jun 2026','okwandu.atuoma@slum2school.org','9032518893','OPAY'),
 ('S26049','Sunday Posu','Badagry Community Officer','School','School','Active','Jun 2026','sunday.posu@slum2school.org','1760997734','POLARIS'),
 ('S26050','Ashiegbu Salem Chinemerem','Green Academy','School','School','Active','Jun 2026','ashiegbu.chinemerem@slum2school.org','3136893407','Firstbank'),
 ('S26051','Oluwafisayo Olaoye Peace','Green Academy','School','School','Active','Jun 2026','oluwafisayo.peace@slum2school.org','7031812018','Opay')
on conflict (staff_id) do update set full_name=excluded.full_name, role=excluded.role, department=excluded.department, email=excluded.email, account_no=excluded.account_no, bank_name=excluded.bank_name;

insert into public.salaries(staff_id,gross,other_fixed) values
 ('S26001',600000,0),
 ('S26002',550000,0),
 ('S26003',300000,0),
 ('S26004',350000,0),
 ('S26005',300000,0),
 ('S26006',350000,0),
 ('S26007',250000,0),
 ('S26008',300000,0),
 ('S26009',250000,0),
 ('S26010',220000,0),
 ('S26011',220000,0),
 ('S26012',200000,0),
 ('S26013',200000,0),
 ('S26014',250000,0),
 ('S26015',300000,0),
 ('S26016',100000,0),
 ('S26017',100000,0),
 ('S26018',75000,0),
 ('S26019',40000,0),
 ('S26020',40000,0),
 ('S26021',70000,0),
 ('S26022',70000,0),
 ('S26023',235000,0),
 ('S26024',80000,0),
 ('S26025',100000,0),
 ('S26026',100000,0),
 ('S26027',100000,0),
 ('S26028',100000,0),
 ('S26029',100000,0),
 ('S26030',100000,0),
 ('S26031',100000,0),
 ('S26032',100000,0),
 ('S26033',150000,0),
 ('S26034',100000,0),
 ('S26035',100000,0),
 ('S26036',70000,0),
 ('S26037',150000,0),
 ('S26038',100000,0),
 ('S26039',200000,0),
 ('S26040',75000,0),
 ('S26041',75000,0),
 ('S26042',75000,0),
 ('S26043',150000,0),
 ('S26044',120000,0),
 ('S26045',100000,0),
 ('S26046',100000,0),
 ('S26047',100000,0),
 ('S26048',100000,0),
 ('S26049',100000,0),
 ('S26050',100000,0),
 ('S26051',100000,0)
on conflict (staff_id) do update set gross=excluded.gross;

insert into public.pay_rates(id,paye,pension,nhf,other) values (1,0,0,0,0) on conflict (id) do nothing;

-- Office locations (200m geofence). HQ = Babatope Bejide Crescent, Lekki Phase 1
-- (best-estimate coordinate — pin it exactly on-site via "Pin this office to where I am").
insert into public.offices(id,name,address,lat,lng,radius,calibrated) values
 ('hq','Slum2School Headquarters','13 Babatope Bejide Crescent, off Fola Osibo Rd, Lekki Phase 1, Lagos 105102',6.443385,3.476079,200,true),
 ('ecd','S2S Early Childhood Development Ctr','Early Childhood Development Center, Lagos',6.4312,3.4116,200,true)
on conflict (id) do update set name=excluded.name, address=excluded.address,
     lat=excluded.lat, lng=excluded.lng, radius=excluded.radius, calibrated=excluded.calibrated;

insert into public.attendance(staff_id,email,name,department,work_date,clock_in,clock_out,lat,lng,verified_id) values
 ('S26001','otto.harmony@slum2school.org','Otto Orondaam Harmony','Full-Time','2026-07-22','2026-07-22 08:49:00+01','2026-07-22 17:28:00+01',6.4413,3.4712,true),
 ('S26001','otto.harmony@slum2school.org','Otto Orondaam Harmony','Full-Time','2026-07-21','2026-07-21 08:11:00+01','2026-07-21 18:30:00+01',6.4413,3.4712,true),
 ('S26001','otto.harmony@slum2school.org','Otto Orondaam Harmony','Full-Time','2026-07-20','2026-07-20 09:06:00+01','2026-07-20 17:19:00+01',6.4413,3.4712,true),
 ('S26001','otto.harmony@slum2school.org','Otto Orondaam Harmony','Full-Time','2026-07-17','2026-07-17 08:44:00+01','2026-07-17 18:02:00+01',6.4413,3.4712,true),
 ('S26001','otto.harmony@slum2school.org','Otto Orondaam Harmony','Full-Time','2026-07-16','2026-07-16 08:28:00+01','2026-07-16 18:47:00+01',6.4413,3.4712,true),
 ('S26002','ifeanyichukwu.lois@slum2school.org','Ifeanyichukwu Lois','Full-Time','2026-07-22','2026-07-22 08:00:00+01','2026-07-22 18:04:00+01',6.4413,3.4712,true),
 ('S26002','ifeanyichukwu.lois@slum2school.org','Ifeanyichukwu Lois','Full-Time','2026-07-20','2026-07-20 08:01:00+01','2026-07-20 17:20:00+01',6.4413,3.4712,true),
 ('S26002','ifeanyichukwu.lois@slum2school.org','Ifeanyichukwu Lois','Full-Time','2026-07-17','2026-07-17 09:33:00+01','2026-07-17 16:40:00+01',6.4413,3.4712,true),
 ('S26002','ifeanyichukwu.lois@slum2school.org','Ifeanyichukwu Lois','Full-Time','2026-07-16','2026-07-16 08:05:00+01','2026-07-16 17:41:00+01',6.4413,3.4712,true),
 ('S26003','abiola.awokiyesi@slum2school.org','Abiola Awokiyesi','Full-Time','2026-07-22','2026-07-22 09:53:00+01','2026-07-22 16:45:00+01',6.4413,3.4712,true),
 ('S26003','abiola.awokiyesi@slum2school.org','Abiola Awokiyesi','Full-Time','2026-07-21','2026-07-21 09:32:00+01','2026-07-21 17:01:00+01',6.4413,3.4712,true),
 ('S26003','abiola.awokiyesi@slum2school.org','Abiola Awokiyesi','Full-Time','2026-07-17','2026-07-17 08:54:00+01','2026-07-17 17:24:00+01',6.4413,3.4712,true),
 ('S26004','yahaya.iloba@slum2school.org','Yahaya Hauwa Iloba','Full-Time','2026-07-21','2026-07-21 08:03:00+01','2026-07-21 17:24:00+01',6.4413,3.4712,true),
 ('S26004','yahaya.iloba@slum2school.org','Yahaya Hauwa Iloba','Full-Time','2026-07-20','2026-07-20 08:04:00+01','2026-07-20 18:40:00+01',6.4413,3.4712,true),
 ('S26004','yahaya.iloba@slum2school.org','Yahaya Hauwa Iloba','Full-Time','2026-07-17','2026-07-17 08:21:00+01','2026-07-17 16:19:00+01',6.4413,3.4712,true),
 ('S26004','yahaya.iloba@slum2school.org','Yahaya Hauwa Iloba','Full-Time','2026-07-16','2026-07-16 09:48:00+01','2026-07-16 16:08:00+01',6.4413,3.4712,true),
 ('S26005','patience.osinaike@slum2school.org','Patience Osinaike','Full-Time','2026-07-22','2026-07-22 08:03:00+01','2026-07-22 17:51:00+01',6.4413,3.4712,true),
 ('S26005','patience.osinaike@slum2school.org','Patience Osinaike','Full-Time','2026-07-21','2026-07-21 08:12:00+01','2026-07-21 17:32:00+01',6.4413,3.4712,true),
 ('S26005','patience.osinaike@slum2school.org','Patience Osinaike','Full-Time','2026-07-20','2026-07-20 09:08:00+01','2026-07-20 17:41:00+01',6.4413,3.4712,true),
 ('S26005','patience.osinaike@slum2school.org','Patience Osinaike','Full-Time','2026-07-17','2026-07-17 08:13:00+01','2026-07-17 16:17:00+01',6.4413,3.4712,true),
 ('S26005','patience.osinaike@slum2school.org','Patience Osinaike','Full-Time','2026-07-16','2026-07-16 09:37:00+01','2026-07-16 17:01:00+01',6.4413,3.4712,true),
 ('S26006','adekunle.olukayode@slum2school.org','Adekunle Idowu Olukayode','Full-Time','2026-07-22','2026-07-22 08:54:00+01','2026-07-22 18:41:00+01',6.4413,3.4712,true),
 ('S26006','adekunle.olukayode@slum2school.org','Adekunle Idowu Olukayode','Full-Time','2026-07-21','2026-07-21 08:09:00+01','2026-07-21 16:28:00+01',6.4413,3.4712,true),
 ('S26006','adekunle.olukayode@slum2school.org','Adekunle Idowu Olukayode','Full-Time','2026-07-20','2026-07-20 09:21:00+01','2026-07-20 17:24:00+01',6.4413,3.4712,true)
on conflict (email,work_date) do nothing;

-- sample requisition
insert into public.requisitions(id,doc_date,subject,addressed_to,through,background,purpose,method,method_detail,amount,amount_words,requester_email,requester_name,designation,status) values
 ('REQ1000000000001','22nd July, 2026','Payment for CCTV repairs','Hammed Balogun','The Executive Director',
  'This memo is written to request approval for the payment of the CCTV repairs.','CCTV Repairs','Fund Transfer',
  'Opay — Nwachuku Kingsley 8053731857',190000,'One hundred and ninety thousand naira only',
  'abiola.awokiyesi@slum2school.org','Abiola Awokiyesi','Human Resource Manager','Pending')
on conflict (id) do nothing;
insert into public.requisition_items(requisition_id,sn,description,amount,account_details) values
 ('REQ1000000000001',1,'CCTV Power box',30000,'Nwachuku Kingsley · 8053731857 · Opay'),
 ('REQ1000000000001',2,'RG59 Cable Power and video',70000,'Nwachuku Kingsley · 8053731857 · Opay'),
 ('REQ1000000000001',3,'Service Charge',60000,'Nwachuku Kingsley · 8053731857 · Opay'),
 ('REQ1000000000001',4,'Arrears',30000,'Nwachuku Kingsley · 8053731857 · Opay')
on conflict do nothing;

-- sample notice (visible to everyone)
insert into public.announcements(id,title,message,audience_type,urgency,theme,responsibilities,poster_email,poster_name) values
 ('ANN1000000000001','Welcome to the S2S Notice Board','Post announcements and urgent tasks here. Choose who sees each notice and tag who is responsible.',
  'everyone','Important','sunset',
  '[{"who":"HR","task":"Onboarding & staff records"},{"who":"Finance","task":"Payroll & requisitions"}]'::jsonb,
  'abiola.awokiyesi@slum2school.org','Abiola Awokiyesi')
on conflict (id) do nothing;
