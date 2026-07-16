# Living Word Lutheran VBS — Check-In App (v2)

A phone-friendly check-in / check-out app for the Rainforest Falls VBS team.
Grades K4–5, August 3–6, 2026, Jackson WI.

## What it does
- **Roles & permissions** — each person signs in and sees only what their role needs
  (director, assistant, check-in, snack, CDC teacher, pastor, station lead, crew assistant,
  volunteer). In the demo you can preview any role with the "Viewing as" switcher.
- **Check in / check out** with guardian-confirmed pickup, live "who's here" counts,
  add-a-pickup-person at the door, undo a mistaken check-in, and check-in **locked to today**
  during the event so nobody uses the wrong date. Name-tag dots show on each child:
  🔴 no-photo · 🟡 allergy · 🔵 community.
- **Filters everywhere** — by crew and by CDC room on check-in, check-out, roster, allergies.
  Check-out has a "community kids only" toggle.
- **Snack Team** view — all crews for the single Treetop Treats block, counts + allergy roster,
  printable for the kitchen.
- **Allergy / medical list** with crew filter and a printable report.
- **Daily schedule** with station locations (director/asst/pastor can edit them).
- **Event calendar**, **announcements** board (post daily notes + picture of the day),
  and an **activity log** (who did what, when).
- **Reports & export** — the five leadership numbers (registered, attended ≥1 day, highest &
  average daily attendance, community kids) computed live, downloadable as a spreadsheet,
  plus print rosters: today's check-in sheet, by crew, entire A–Z, per day, and a full-detail
  (parents/emergency/pickup) tech-outage backup — all showing CDC room + community indicator.
- **Import** children + parents straight from the Google Form responses sheet (paste rows;
  siblings group under one parent by shared email).
- **Data model:** parent/photo/emergency/pickup info is entered **once per family** and applies
  to all their kids.

## Try it now (demo mode)
Open `index.html` in any phone or laptop browser. It loads with sample kids, saves nothing to
the cloud, and needs no login. Use **⋯ Info → Preview a role** to see each volunteer's view.
Reset anytime under **⋯ Info → Reset demo**.

## Going live (real sync across every phone)
1. In Supabase, open the **SQL editor** and run `schema.sql`.
2. In **Authentication → Users**, add an account for each team member (email + password).
3. In **Table editor → volunteers**, set each person's `role_key` and matching `email`
   (that's how their role is resolved at sign-in).
4. In `index.html`, fill in `CONFIG.supabaseUrl` and `CONFIG.supabaseAnonKey`
   (Supabase → Project Settings → API).
5. Host the file (GitHub Pages is already set up) and share the link.

> With live keys the app requires a Supabase login before showing any data. The anon key is
> safe in the page: Row Level Security means nothing is readable until a volunteer signs in.
> Preview the sign-in screen anytime with `index.html?preview=login`.

## Security & privacy
- **Login-gated in live mode** — never public. **Role-gated** — people see only their part.
- **Nothing stored on phones** — data lives in Supabase only while the page is open.
- **Least data** — only what the event needs.
- **Audit log** — every check-in/out, edit, consent, and sign-in is recorded with the person.
- **Purge after the event** — run the delete block at the bottom of `schema.sql`.

## Files
- `index.html` — the whole app (open this)
- `schema.sql` — Supabase tables + security + purge block
- `docs/` — Todd's requirements doc + build notes
- `README.md` — this file
