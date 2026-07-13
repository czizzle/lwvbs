-- ============================================================
-- Living Word Lutheran VBS Check-In — Supabase schema
-- Run once in your Supabase project's SQL editor to go LIVE.
-- ============================================================

-- Children roster (guardians + emergency contact stored inline as JSON)
create table if not exists public.children (
  id            text primary key,
  first_name    text not null,
  last_name     text not null,
  grade         text,                 -- 'K','1'..'5'
  crew          text,
  allergies     text default '',
  medical_notes text default '',
  photo_consent boolean default true,
  guardians     jsonb default '[]',   -- [{name,phone,relationship,canPickup}]
  emergency     jsonb,                -- {name,phone,relationship}
  consent       jsonb,                -- {name, signature(dataURL), signedAt} e-signature
  created_at    timestamptz default now()
);

-- Volunteers (also feeds the "helper on duty" picker)
create table if not exists public.volunteers (
  id    text primary key,
  name  text not null,
  role  text default '',
  phone text default ''
);

-- One row per child per event day
create table if not exists public.attendance (
  child_id       text not null references public.children(id) on delete cascade,
  event_date     date not null,
  checked_in_at  timestamptz,
  checked_in_by  text,
  checked_out_at timestamptz,
  checked_out_by text,
  released_to    text,
  primary key (child_id, event_date)
);

-- ============================================================
-- Row Level Security: only signed-in admin-team accounts can
-- read or write. The public anon key alone can see nothing.
-- ============================================================
alter table public.children   enable row level security;
alter table public.volunteers enable row level security;
alter table public.attendance enable row level security;

create policy "team reads children"  on public.children   for select to authenticated using (true);
create policy "team writes children" on public.children   for all    to authenticated using (true) with check (true);
create policy "team reads vols"      on public.volunteers for select to authenticated using (true);
create policy "team writes vols"     on public.volunteers for all    to authenticated using (true) with check (true);
create policy "team reads att"       on public.attendance for select to authenticated using (true);
create policy "team writes att"      on public.attendance for all    to authenticated using (true) with check (true);

-- ============================================================
-- AFTER THE EVENT — data purge (run when follow-up is done):
--   truncate table public.attendance;
--   delete from public.children;
-- Keeps volunteers if you want them for next year; otherwise:
--   delete from public.volunteers;
-- ============================================================
