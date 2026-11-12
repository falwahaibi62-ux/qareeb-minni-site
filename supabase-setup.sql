-- قريب مني: جدول طلبات العملاء
-- يُنفَّذ مرة واحدة في مشروع Supabase الجديد الخاص بقريب مني (وليس مشروع واثق)
-- من لوحة Supabase: SQL Editor ثم الصق هذا الملف واضغط Run

create table if not exists public.requests (
  id              uuid primary key default gen_random_uuid(),
  created_at      timestamptz not null default now(),
  name            text not null check (char_length(name) between 2 and 80),
  phone           text not null check (phone ~ '^\+968[79][0-9]{7}$'),
  service         text not null check (service in ('move','storage','both')),
  wilayat         text not null,
  address         text check (address is null or char_length(address) <= 200),
  lat             double precision,
  lng             double precision,
  preferred_date  date,
  notes           text check (notes is null or char_length(notes) <= 600),
  consent         boolean not null,
  -- حقول الإدارة: لا يستطيع الزائر تعبئتها
  status          text not null default 'new'
                  check (status in ('new','contacted','confirmed','assigned','done','cancelled')),
  assigned_driver text,
  admin_notes     text
);

-- تفعيل صلاحيات الصفوف (إلزامي لحماية بيانات العملاء)
alter table public.requests enable row level security;

-- الزائر (anon) يستطيع إضافة طلب جديد فقط، بموافقة، وبحالة "جديد" ودون سائق
create policy "visitors can submit requests"
  on public.requests for insert
  to anon
  with check (consent = true and status = 'new' and assigned_driver is null and admin_notes is null);

-- لا توجد سياسة قراءة للزائر: لا يستطيع أحد من الموقع رؤية الطلبات

-- المستخدمون المسجّلون (إدارة قريب مني) يقرؤون ويعدّلون
create policy "staff can read requests"
  on public.requests for select
  to authenticated
  using (true);

create policy "staff can update requests"
  on public.requests for update
  to authenticated
  using (true) with check (true);

-- منع الزائر من تعديل الحقول الإدارية عبر صلاحيات الأعمدة
revoke insert on public.requests from anon;
grant insert (name, phone, service, wilayat, address, lat, lng, preferred_date, notes, consent)
  on public.requests to anon;
