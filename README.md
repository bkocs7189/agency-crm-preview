# Agency CRM (OMN-56)

A fully custom internal sales CRM web app — replaces third-party CRM SaaS
(HubSpot integration cancelled). Single-file static SPA, same stack as the EOS
Tracker, bound to the canonical CRM backend (OMN-59).

**Live preview:** GitHub Pages — `bkocs7189/agency-crm-preview`
**Sign-in:** Supabase Auth (email/password). A demo board login is provisioned
for preview/QA — see *Access* below.

## Modules
- **Dashboard** — open pipeline, weighted forecast (server-computed), won total, pipeline-by-stage, top open deals, activity feed
- **Contacts** — people + companies (polymorphic `contacts.kind`), search, tags
- **Pipeline** — Kanban (drag-to-move stage) + list view; live column totals; weighted column
- **Activities** — calls / emails / meetings / notes / tasks logged against contacts & deals

## Stack
- Single-file static SPA (`index.html`), no build step — deploys to GitHub Pages
- Shared backend: Supabase Postgres (project **Convergence** `krthbgtykwamxqvapxnx`),
  schema `public`, canonical tables from OMN-59:
  `pipelines`, `pipeline_stages`, `contacts`, `deals`, `activities`, `notes`
- **Computed server-side:** `deals.weighted_value` is a generated column
  (`value × probability`); a trigger inherits the stage default probability and
  syncs `status`/`closed_at` on won/lost stages. The SPA never computes or writes
  these — it reads them back after each write.
- Writes are **per-row** (insert / update / delete) and re-select the affected row
  so generated + trigger-set fields round-trip into the UI immediately.

## Access & security posture
- Entry is gated by **Supabase Auth** (email/password sign-in). This replaces the
  earlier SHA-256 access-code gate.
- RLS grants CRUD only to the `authenticated` role; the `anon` (publishable) key
  alone returns **nothing**. The publishable key in `index.html` only identifies
  the project and is safe to ship.
- Demo board login for preview/QA: `crm-demo@agency.local` / `CrmDemo2026!`
  (a confirmed Supabase Auth user; rotate or remove before any real customer data).
- This closes the anon-CRUD exposure of the previous `crm56_*` prototype tables,
  which the backend (OMN-59) and security review (OMN-62) are dropping.

## Schema deltas (tracked on OMN-67)
The canonical schema is leaner than the earlier prototype. Fields with no column
in OMN-59 were dropped from the UI rather than faked: per-row text `owner`
(canonical uses `owner_id` → `auth.users`, auto-set to the signed-in user),
company `industry`, person `custom_fields`, activity `done`/task-checkbox, and
freeform per-entity `notes` text (a dedicated `notes` table exists and can back a
notes panel later). Restoring these is a schema decision for Backend on OMN-67.

## Local dev
Open `index.html` in a browser, or `python3 -m http.server` and visit the page.
Sign in with the demo login above.
