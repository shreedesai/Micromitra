# MICROMITRA — Deployment Guide

This turns the original single-file HTML artifact into a standalone app you fully own:
- Your own Anthropic API key (kept secret on a small server, never in the browser)
- Supabase for real accounts (email + password) and a real database
- Hosted on Render, so it runs with no Claude.ai dependency at all

Total setup time: ~20–30 minutes, no coding required beyond copy/paste.

---

## 1. Create your Supabase project

1. Go to https://supabase.com → sign up (free tier is fine) → **New project**.
2. Pick a name (e.g. `micromitra`), a database password (save it somewhere safe), and a region close to your students.
3. Once the project finishes provisioning, go to **SQL Editor** (left sidebar) → **New query**.
4. Open `supabase/schema.sql` from this project, paste its entire contents in, and click **Run**.
   This creates the `profiles` and `stats` tables with the correct access rules (students see only their own data; faculty can see everyone's).
5. Go to **Project Settings → API**. Copy two values, you'll need them shortly:
   - **Project URL** (looks like `https://xxxxx.supabase.co`)
   - **anon public** key (a long string) — this one is *safe* to put in browser code; it's designed for that, and access is enforced by the database rules you just created, not by keeping it secret.
6. Go to **Authentication → Providers** and confirm **Email** is enabled (it is by default).
   - Optional: under **Authentication → Settings**, you can turn OFF "Confirm email" if you want students to log in immediately after signup without clicking a confirmation email — convenient for classroom use, but less secure. Your call.

## 2. Add your Supabase credentials to the app

Open `public/index.html`, find this block near the top (inside `<head>`):

```js
const SUPABASE_URL = 'YOUR_SUPABASE_PROJECT_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_PUBLIC_KEY';
```

Replace both placeholder strings with the values you copied in step 1.5.

## 3. Get your own Anthropic API key

1. Go to https://console.anthropic.com → sign up / log in.
2. Go to **API Keys** → **Create Key**. Copy it — you'll paste it into Render, never into the HTML file.
3. Add billing (Anthropic's API is pay-as-you-go; it's separate from any Claude.ai subscription).

## 4. Put this project on GitHub

Render deploys from a GitHub repo.

1. Create a new repository on https://github.com (e.g. `micromitra`).
2. Upload all the files in this project folder (`server.js`, `package.json`, `public/`, `supabase/`) to that repo — either via GitHub's web "upload files" button, or `git push` if you're comfortable with git.

## 5. Deploy on Render

1. Go to https://render.com → sign up (free tier works) → **New +** → **Web Service**.
2. Connect your GitHub account and select the repo you just created.
3. Configure:
   - **Runtime**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Instance type**: Free is fine to start
4. Under **Environment**, add one environment variable:
   - Key: `ANTHROPIC_API_KEY`
   - Value: (paste the key from step 3)
5. Click **Create Web Service**. Render will build and deploy — takes a couple of minutes.
6. Once live, Render gives you a URL like `https://micromitra.onrender.com` — that's your app, running independently of Claude.ai.

Note: Render's free tier spins down after inactivity and takes ~30–50 seconds to wake up on the next visit. Fine for classroom use; upgrade to a paid instance if you want it always-on.

## 6. Try it

1. Open your Render URL.
2. Sign up as **Faculty** with your own email — this becomes your admin account.
3. Have a student (or yourself, in a private/incognito window) sign up as **Student**.
4. Use the AI Tutor as the student a few times, then log in as faculty and check **Class Dashboard** / **Admin Panel** — you should see the real student's data appear (it may take a page refresh).

---

## What changed from the original file, and why

| Area | Before | Now |
|---|---|---|
| AI calls | Browser called `api.anthropic.com` directly, relying on Claude.ai's built-in credential proxy — only works inside a Claude.ai artifact | Browser calls your own `/api/claude` endpoint; the server attaches your Anthropic key server-side |
| Model | `claude-sonnet-4-20250514` (a retiring dated snapshot) | `claude-sonnet-4-6` (current) |
| Login | Name-only, no accounts | Real Supabase Auth (email + password) |
| Storage | `window.storage` — only works inside a Claude.ai artifact | Supabase Postgres tables (`profiles`, `stats`), with row-level security |
| Class Dashboard / Admin Panel roster | Hardcoded fictional students (Ananya Nair, Rohit Verma, etc.) | Live query of real signed-up students |

## Known limitations to be aware of

- **Trend charts are still illustrative.** The line chart (SDL over 4 weeks), the Miller's-pyramid radar, and the per-subject bar chart in Class Dashboard / Admin Panel use static example numbers — the schema doesn't yet track weekly history or per-subject breakdowns per student. Real values would need extra tables (e.g. a `weekly_snapshots` table) and periodic recording.
- **Activity feed is empty** until you add an `activity` table and log events (quiz submitted, roadmap milestone, etc.) — the code checks for this and shows a friendly "no activity yet" message instead of fake entries.
- **At-risk student cards** in the Admin Panel (Rohit Verma / Karan Patel) are still static HTML placeholders, not wired to real data — the AI-generated class insight *is* now computed from real students, but that specific card UI would need similar templating work to become fully dynamic.
- Email confirmation: if you leave Supabase's "Confirm email" setting on, new users must click a link in their inbox before they can log in — worth testing this flow before rolling it out to a class.
