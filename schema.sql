-- ============================================================
-- Living Word Lutheran VBS Check-In — Supabase schema (v2)
-- Run once in your Supabase project's SQL editor to go LIVE.
-- v2 adds: parent/family fields, CDC room, days attending,
-- gender/DOB/comments, announcements, per-volunteer roles,
-- and an app_settings table for editable station locations.
-- ============================================================

-- Children roster. Parent/photo/emergency/pickup live in the `parent`
-- JSON block (entered ONCE per family) so they apply to all a family's kids.
create table if not exists public.children (
  id            text primary key,
  family_id     text,                  -- groups siblings; parent block is shared per family
  first_name    text not null,
  last_name     text not null,
  grade         text,                  -- 'K4','K5','1'..'5'
  gender        text,
  dob           date,
  crew          text,
  attends_cdc   boolean default false, -- true = CDC child (has a room); false = community child
  cdc_room      text,                  -- CDC room number (CDC kids)
  community     boolean default false, -- community kid (not CDC) — signed pickup
  days          jsonb default '["Mon","Tue","Wed","Thu"]',  -- days attending
  allergies     text default '',
  medical_notes text default '',
  comments      text default '',
  parent        jsonb,                 -- {first,last,email,phone,altPhone,street,city,state,zip,photoConsent,emergency:{name,relationship,phone},altPickup:{name,phone}}
  extra_pickups jsonb default '[]',    -- [{name,phone,relationship}] added at check-in
  consent       jsonb,                 -- {name, signature(dataURL), signedAt} — held for a future year
  created_at    timestamptz default now()
);

-- Volunteers (also feeds the "helper on duty" picker + drives role-based access)
create table if not exists public.volunteers (
  id       text primary key,
  name     text not null,
  role_key text default 'volunteer',   -- director|asst|checkin|snack|cdc|pastor|station|crew|volunteer
  role     text default '',            -- display label
  email    text default '',            -- matched to the signed-in account to resolve the role
  phone    text default '',
  days     jsonb default '[]'
);

-- Append-only audit trail: who did what, and when
create table if not exists public.activity_log (
  id         bigint generated always as identity primary key,
  user_email text,
  action     text not null,
  child_id   text,
  at         timestamptz default now()
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

-- Team announcements (daily Bible point, reminders, picture of the day)
create table if not exists public.announcements (
  id        bigint generated always as identity primary key,
  by_name   text,
  text      text not null,
  image_url text,
  at        timestamptz default now()
);

-- Small key/value store (editable station locations, etc.)
create table if not exists public.app_settings (
  key   text primary key,
  value jsonb
);

-- ============================================================
-- Row Level Security: only signed-in team accounts can read/write.
-- The public anon key alone can see nothing. (Role-based *view*
-- gating happens in the app; harden per-table here later if wanted.)
-- ============================================================
alter table public.children      enable row level security;
alter table public.volunteers    enable row level security;
alter table public.attendance    enable row level security;
alter table public.activity_log  enable row level security;
alter table public.announcements enable row level security;
alter table public.app_settings  enable row level security;

create policy "team reads children"  on public.children   for select to authenticated using (true);
create policy "team writes children" on public.children   for all    to authenticated using (true) with check (true);
create policy "team reads vols"      on public.volunteers for select to authenticated using (true);
create policy "team writes vols"     on public.volunteers for all    to authenticated using (true) with check (true);
create policy "team reads att"       on public.attendance for select to authenticated using (true);
create policy "team writes att"      on public.attendance for all    to authenticated using (true) with check (true);
create policy "team reads ann"       on public.announcements for select to authenticated using (true);
create policy "team writes ann"      on public.announcements for all    to authenticated using (true) with check (true);
create policy "team reads settings"  on public.app_settings for select to authenticated using (true);
create policy "team writes settings" on public.app_settings for all    to authenticated using (true) with check (true);
-- Audit log: signed-in team can read + append, but NOT edit/delete (keeps the trail honest)
create policy "team reads log"       on public.activity_log for select to authenticated using (true);
create policy "team appends log"     on public.activity_log for insert to authenticated with check (true);

-- ============================================================
-- AFTER THE EVENT — data purge (run when follow-up is done):
--   truncate table public.attendance;
--   truncate table public.activity_log;
--   truncate table public.announcements;
--   delete from public.children;
-- Keeps volunteers if you want them for next year; otherwise:
--   delete from public.volunteers;
-- ============================================================
