# Agency CRM (OMN-56)

A simple, fully custom internal CRM web app — replaces any third-party CRM SaaS
(HubSpot integration cancelled). Same stack and board-access pattern as the EOS
Tracker.

**Live preview:** GitHub Pages (see deployment)
**Board access code:** `ADF4-B41B`

## Modules
- **Contacts** — companies + people, custom fields, tags, notes
- **Pipeline** — deals/opportunities with stage tracking (Kanban + list, drag to move stage)
- **Deals** — value, close date, owner, probability, notes
- **Activities** — calls, emails, meetings, notes logged against contacts/deals
- **Dashboard** — pipeline summary by stage, weighted forecast, activity feed, team leaderboard

## Stack
- Single-file static SPA (`index.html`), no build step — deploys to GitHub Pages
- Shared backend: Supabase Postgres (project `Convergence`), tables `crm_companies`,
  `crm_people`, `crm_deals`, `crm_activities`
- Optimistic in-memory writes with background sync; localStorage offline fallback
- Board entry behind a shared SHA-256 access-code gate (same pattern as EOS Tracker)

## Security posture
This is a board preview tool. Entry is gated by the shared access code; the
Supabase **publishable** key only identifies the project. Data is non-sensitive
seeded demo data. RLS is enabled on all tables. If this graduates to holding real
customer data, migrate to per-user Supabase Auth + authenticated-only RLS — the
same hardening applied to EOS Tracker in OMN-55.

## Local dev
Open `index.html` in a browser, or `python3 -m http.server` and visit the page.
