# Twilio SMS — sign-in codes + pickup texts

Two features use Twilio. Set up the account once, then wire each feature. The app
already ships both; they just need Twilio switched on to go live.

- **Sign-in by text** — a volunteer enters their mobile number, gets a 6-digit
  code, taps it in, and they're in. Handled by Supabase Auth (phone provider).
- **Pickup text** — on check-out the parent gets a confirmation ("Emma was signed
  out at 11:32 AM to Sarah Bauer") from the church's number. Handled by the
  `send-sms` Edge Function.

Until Twilio is on, everything still works: email magic-link sign-in, and the
manual **📱 Text the parent** button on a checked-out child's page (opens your own
Messages app pre-filled — no Twilio needed).

---

## 1. Twilio account (once, ~10 min)

1. Sign up at twilio.com. A trial gives a small credit and can only text
   **verified** numbers — fine for testing. To text any parent, upgrade (pay-as-
   you-go; a text is well under a cent, plus the number is ~$1.15/mo).
2. Buy a phone number with SMS (Console → Phone Numbers → Buy a number, US, SMS).
3. From the Console dashboard copy:
   - **Account SID** (`AC…`)
   - **Auth Token**
   - your **Twilio number** (`+1…`)
4. **A2P 10DLC (required for US texting):** register the number for
   Application-to-Person messaging (Console → Messaging → Regulatory Compliance).
   Without it, US carriers filter or block the texts — T-Mobile drops unregistered
   traffic outright, so it will appear to work in your own testing and then fail
   for volunteers on other networks.

   > ⏱️ **Budget weeks, not days.** Checked 2026-07-31: Twilio quotes 5–7 business
   > days for a standard use case, campaign review is currently running **10–15
   > days**, and anything AT&T pulls into manual review takes **3–6 weeks** end to
   > end. Toll-free verification is faster than 10DLC but is still a review queue,
   > and from early 2026 a Business Registration Number is mandatory for new
   > toll-free verifications. (This section previously said "a day or two." That
   > was wrong, and it is why SMS sign-in was scoped for the Aug 2026 event and
   > then cut three days out.)

---

## 2. Sign-in by text (Supabase phone provider)

Supabase Dashboard → **Authentication → Providers → Phone**:

1. Enable **Phone**.
2. SMS provider = **Twilio**. Paste Account SID, Auth Token, and the Twilio
   number (Message Service SID optional).
3. Save.
4. **Set `CONFIG.phoneSignIn: true` in `index.html`** and redeploy. The tab is
   hidden by default (index.html:365) precisely so nobody is handed a button that
   returns `phone_provider_disabled` at the check-in table. Everything behind it
   — the OTP screens, `verifyOtp`, phone→volunteer matching — is already built and
   was verified working with the flag on; the flag is the only switch.

Then give each volunteer's **mobile number** to their login so only authorized
phones can get a code:

```
cd private
# supabase.env must hold the NEW secret key (SUPABASE_SERVICE_KEY=sb_secret_…)
python provision_users.py --dry-run    # preview: shows email + phone per user
python provision_users.py              # create/update auth users with phones
```

`provision_users.py` sets each eligible volunteer's phone on their auth account
(and confirms it). Numbers come straight from Todd's roster. A volunteer can then
sign in with **either** their email link **or** a texted code — both resolve to
the same person and role.

> Note: Supabase phone OTP and email OTP share one hourly rate limit. The email
> limit is already bumped to 100/hour; raise the SMS limit too if a lot of people
> sign in at once (Authentication → Rate Limits).

---

## 3. Pickup text (send-sms Edge Function)

This sends the check-out confirmation from the church's Twilio number. Needs the
Supabase CLI once.

```
# from the repo root (C:\Users\cryst\projects\vbs-checkin)
npm i -g supabase                      # or: scoop install supabase
supabase login
supabase link --project-ref uvmptaurflsohnhnazuv

# store the Twilio secrets (server-side only — never in the app)
supabase secrets set TWILIO_ACCOUNT_SID=AC...   TWILIO_AUTH_TOKEN=...   TWILIO_FROM=+1XXXXXXXXXX
# TWILIO_FROM can be a Twilio number (+1…) OR a Messaging Service SID (MG…)

supabase functions deploy send-sms
```

`SUPABASE_URL` and `SUPABASE_ANON_KEY` are injected automatically — don't set them.

The function requires a signed-in user, so only logged-in volunteers can trigger a
text, and the Twilio token stays on the server.

### How the app uses it
- On the check-out screen there's a checkbox **"📱 Text [parent] that [child] was
  picked up"** (default on when a mobile is on file). On confirm, the app calls
  `send-sms`.
- If the function isn't deployed yet, check-out still completes — the toast just
  says "open [child] to text parent," and the child's page has the manual
  **📱 Text the parent** button (your own Messages app).

### Test it
1. Sign in to the live app.
2. Check a child out with the box checked. The parent number on file gets the text.
3. If nothing arrives: confirm A2P registration is approved, the number has SMS,
   and the parent number is real. Trial accounts only text **verified** numbers.

---

## Cost, roughly
- Number: ~$1.15/mo. Each SMS: ~$0.008. A whole week of VBS is a couple dollars.
- A2P 10DLC low-volume: a small one-time + tiny monthly carrier fee.
