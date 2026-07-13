# Living Word Lutheran VBS — Check-In App

A simple, phone-friendly check-in / check-out app for the VBS admin team.
Grades K–5, August 3–6, 2026, Jackson WI.

## What it does
- **Check in / check out** kids each day, with a live "who's here now" count
- **Guardian-at-the-door pickup**: only people listed on a child's record can take them, and every check-out records who picked up and when
- **Allergy & medical list** the snack and crew teams can pull up in one tap
- **Roster** with search, walk-up add, and a **printable paper backup**
- **Volunteer list** that also powers the "helper on duty" tag on each check-in

## Try it now (demo mode)
Open `index.html` in any phone or laptop browser. It loads with sample kids,
saves nothing to the cloud, and needs no login. Play with the whole flow.
Reset the sample data anytime under **⋯ Info → Reset demo**.

## Going live (real sync across every volunteer's phone)
1. In Supabase, create a project (or reuse one) and open the **SQL editor**.
2. Paste and run `schema.sql`.
3. In Supabase **Authentication → Users**, add an account for each admin-team
   member (email + password), or one shared church account.
4. In `index.html`, fill in `CONFIG.supabaseUrl` and `CONFIG.supabaseAnonKey`
   (Supabase → Project Settings → API).
5. Host the file for free (Netlify drop, Cloudflare Pages, or Supabase hosting)
   and share the link with the team.

> The sign-in screen is built in — with live keys, the app requires a Supabase
> login before showing any data. The anon key is safe in the page: Row Level
> Security means nothing is readable until a volunteer signs in.
> Preview the sign-in screen anytime by opening `index.html?preview=login`.

## Security & privacy
- **Login-gated in live mode** — the app is never public.
- **Nothing stored on volunteers' phones** — data lives only in Supabase and
  only while the page is open.
- **Least data** — only what the event needs (name, grade, guardians, allergies).
- **Purge after the event** — run the delete block at the bottom of `schema.sql`
  once follow-up is done so kids' info doesn't linger.

## Easy for older volunteers
Big buttons, search-a-name-and-tap, almost no typing, plain words. Set the
"helper on duty" once and it tags every check-in. Print a paper roster each
morning as a backup if wifi drops.

## Files
- `index.html` — the whole app (open this)
- `schema.sql` — Supabase tables + security + purge block
- `README.md` — this file
