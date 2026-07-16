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

## Going live (real sync across every phone, passwordless magic-link login)
1. **Create a Supabase project** (or reuse one) and run `schema.sql` in the SQL editor.
2. **Seed the data**: run `private/seed-real.sql` (children + all 34 volunteers).
3. **Create login accounts** (operational roles only — leaders, check-in/out, station/snack
   leaders, pastor, CDC admin; ~19). Set your project keys and run the provisioner:
   ```
   SUPABASE_URL=https://<proj>.supabase.co SUPABASE_SERVICE_KEY=<service_role> \
     python private/provision_users.py        # --dry-run first to preview
   ```
   It creates email-confirmed, passwordless users. Crew/assistant volunteers are skipped
   (they still show in the roster; they just don't sign in).
4. **Custom email sender** (Authentication → Email → SMTP): point it at a real sender so
   ~19 people can request links the same morning without hitting Supabase's built-in send
   limit. (The default sender is fine for a few test logins.) Add the app URL under
   Authentication → URL Configuration → Redirect URLs.
5. **Flip it on**: fill `CONFIG.supabaseUrl` + `CONFIG.supabaseAnonKey` in `index.html`
   (Project Settings → API) and re-deploy.

> **How sign-in works:** a volunteer opens the app, types their email, taps **Send my login
> link**, and clicks the one-tap link in their inbox — no password ever. `shouldCreateUser`
> is off, so only people the provisioner added can get in. Sessions persist, so one link at
> the start covers the whole event.
> RLS means the anon key in the page is safe: nothing is readable until a volunteer signs in.
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
