-- ============================================================================
-- CRM Backend (OMN-59) — migration 0001: schema, computed fields, triggers, RLS
-- Project: Convergence (Supabase ref krthbgtykwamxqvapxnx), schema: public
-- Single-team model: any authenticated board user can read/write all CRM data.
-- anon role gets NO access (closes the anon-CRUD gap seen on the EOS tables).
-- ============================================================================

create extension if not exists pgcrypto;

-- Shared helper: keep updated_at fresh on UPDATE -----------------------------
create or replace function public.crm_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- pipelines ------------------------------------------------------------------
create table public.pipelines (
  id          uuid primary key default gen_random_uuid(),
  key         text not null unique,
  name        text not null,
  description text,
  is_default  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- pipeline_stages — configurable, ordered stages per pipeline ----------------
create table public.pipeline_stages (
  id                  uuid primary key default gen_random_uuid(),
  pipeline_id         uuid not null references public.pipelines(id) on delete cascade,
  name                text not null,
  position            integer not null,
  default_probability numeric(5,4) not null default 0
                        check (default_probability >= 0 and default_probability <= 1),
  is_won              boolean not null default false,
  is_lost             boolean not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (pipeline_id, position),
  unique (pipeline_id, name)
);
create index idx_pipeline_stages_pipeline on public.pipeline_stages(pipeline_id);

-- contacts — polymorphic companies + people (kind discriminator) -------------
create table public.contacts (
  id          uuid primary key default gen_random_uuid(),
  kind        text not null check (kind in ('company','person')),
  name        text not null,
  first_name  text,
  last_name   text,
  email       text,
  phone       text,
  title       text,
  company_id  uuid references public.contacts(id) on delete set null,
  website     text,
  address     text,
  tags        text[] not null default '{}',
  owner_id    uuid default auth.uid() references auth.users(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  check (company_id is null or kind = 'person')
);
create index idx_contacts_kind    on public.contacts(kind);
create index idx_contacts_company on public.contacts(company_id);
create index idx_contacts_owner   on public.contacts(owner_id);
create index idx_contacts_email   on public.contacts(lower(email));

-- deals — pipeline opportunities with computed weighted value ----------------
create table public.deals (
  id                   uuid primary key default gen_random_uuid(),
  name                 text not null,
  pipeline_id          uuid not null references public.pipelines(id),
  stage_id             uuid references public.pipeline_stages(id) on delete set null,
  contact_id           uuid references public.contacts(id) on delete set null,
  value                numeric(14,2) not null default 0,
  currency             text not null default 'USD',
  probability          numeric(5,4) check (probability >= 0 and probability <= 1),
  weighted_value       numeric(16,2) generated always as
                         (round(value * coalesce(probability, 0), 2)) stored,
  owner_id             uuid default auth.uid() references auth.users(id) on delete set null,
  status               text not null default 'open' check (status in ('open','won','lost')),
  expected_close_date  date,
  closed_at            timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);
create index idx_deals_pipeline on public.deals(pipeline_id);
create index idx_deals_stage    on public.deals(stage_id);
create index idx_deals_contact  on public.deals(contact_id);
create index idx_deals_owner    on public.deals(owner_id);
create index idx_deals_status   on public.deals(status);

-- Inherit stage default probability when null; sync status with terminal stage
create or replace function public.deals_apply_stage_defaults()
returns trigger language plpgsql as $$
declare
  s public.pipeline_stages%rowtype;
begin
  if new.stage_id is not null then
    select * into s from public.pipeline_stages where id = new.stage_id;
    if found then
      if new.probability is null then
        new.probability := s.default_probability;
      end if;
      if s.is_won then
        new.status := 'won';  new.closed_at := coalesce(new.closed_at, now());
      elsif s.is_lost then
        new.status := 'lost'; new.closed_at := coalesce(new.closed_at, now());
      else
        new.status := 'open'; new.closed_at := null;
      end if;
    end if;
  end if;
  return new;
end;
$$;
create trigger trg_deals_stage_defaults
  before insert or update of stage_id, probability on public.deals
  for each row execute function public.deals_apply_stage_defaults();

-- activities — timeline events linked to a contact and/or deal ---------------
create table public.activities (
  id            uuid primary key default gen_random_uuid(),
  type          text not null default 'note'
                  check (type in ('call','email','meeting','note','task','other')),
  subject       text,
  notes         text,
  activity_date timestamptz not null default now(),
  contact_id    uuid references public.contacts(id) on delete cascade,
  deal_id       uuid references public.deals(id) on delete cascade,
  owner_id      uuid default auth.uid() references auth.users(id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  check (contact_id is not null or deal_id is not null)
);
create index idx_activities_contact on public.activities(contact_id);
create index idx_activities_deal    on public.activities(deal_id);
create index idx_activities_date    on public.activities(activity_date desc);

-- notes — freeform notes linked to a contact and/or deal ---------------------
create table public.notes (
  id          uuid primary key default gen_random_uuid(),
  body        text not null,
  contact_id  uuid references public.contacts(id) on delete cascade,
  deal_id     uuid references public.deals(id) on delete cascade,
  author_id   uuid default auth.uid() references auth.users(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  check (contact_id is not null or deal_id is not null)
);
create index idx_notes_contact on public.notes(contact_id);
create index idx_notes_deal    on public.notes(deal_id);

-- updated_at triggers --------------------------------------------------------
create trigger trg_pipelines_updated       before update on public.pipelines       for each row execute function public.crm_set_updated_at();
create trigger trg_pipeline_stages_updated before update on public.pipeline_stages for each row execute function public.crm_set_updated_at();
create trigger trg_contacts_updated        before update on public.contacts        for each row execute function public.crm_set_updated_at();
create trigger trg_deals_updated           before update on public.deals           for each row execute function public.crm_set_updated_at();
create trigger trg_activities_updated      before update on public.activities      for each row execute function public.crm_set_updated_at();
create trigger trg_notes_updated           before update on public.notes           for each row execute function public.crm_set_updated_at();

-- Convenience view: weighted pipeline forecast rollup (computed field) -------
create or replace view public.deal_pipeline_summary
with (security_invoker = true) as
select
  p.id as pipeline_id, p.name as pipeline_name,
  st.id as stage_id, st.name as stage_name, st.position as stage_position,
  count(d.id) as deal_count,
  coalesce(sum(d.value), 0) as total_value,
  coalesce(sum(d.weighted_value), 0) as weighted_value
from public.pipelines p
join public.pipeline_stages st on st.pipeline_id = p.id
left join public.deals d on d.stage_id = st.id and d.status = 'open'
group by p.id, p.name, st.id, st.name, st.position
order by p.name, st.position;

-- Row Level Security — single-team: authenticated full access, anon none -----
alter table public.pipelines       enable row level security;
alter table public.pipeline_stages enable row level security;
alter table public.contacts        enable row level security;
alter table public.deals           enable row level security;
alter table public.activities      enable row level security;
alter table public.notes           enable row level security;

create policy crm_pipelines_authenticated       on public.pipelines       for all to authenticated using (true) with check (true);
create policy crm_pipeline_stages_authenticated on public.pipeline_stages for all to authenticated using (true) with check (true);
create policy crm_contacts_authenticated        on public.contacts        for all to authenticated using (true) with check (true);
create policy crm_deals_authenticated           on public.deals           for all to authenticated using (true) with check (true);
create policy crm_activities_authenticated      on public.activities      for all to authenticated using (true) with check (true);
create policy crm_notes_authenticated           on public.notes           for all to authenticated using (true) with check (true);

-- ----------------------------------------------------------------------------
-- OPTIONAL: per-user (private) ownership model instead of single-team.
-- Swap the policies above for these if board users must only see their own data:
--
--   create policy crm_deals_owner on public.deals for all to authenticated
--     using (owner_id = auth.uid()) with check (owner_id = auth.uid());
--   (repeat per table using owner_id / author_id)
-- ----------------------------------------------------------------------------
