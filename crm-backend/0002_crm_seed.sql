-- ============================================================================
-- CRM seed data (demo / preview) — OMN-59
-- Safe to re-run: only seeds when no pipeline exists yet. No hardcoded UUIDs.
-- ============================================================================
do $$
declare
  v_pipeline uuid;
  s_lead uuid; s_qual uuid; s_prop uuid; s_neg uuid; s_won uuid; s_lost uuid;
  c_acme uuid; c_globex uuid; c_initech uuid;
  p_jane uuid; p_john uuid; p_mary uuid; p_sam uuid;
  d1 uuid; d2 uuid; d3 uuid; d4 uuid;
begin
  if exists (select 1 from public.pipelines) then
    raise notice 'CRM already seeded; skipping.';
    return;
  end if;

  insert into public.pipelines (key, name, description, is_default)
    values ('sales', 'Sales Pipeline', 'Default sales pipeline', true)
    returning id into v_pipeline;

  insert into public.pipeline_stages (pipeline_id, name, position, default_probability, is_won, is_lost) values
    (v_pipeline, 'Lead',        1, 0.10, false, false) returning id into s_lead;
  insert into public.pipeline_stages (pipeline_id, name, position, default_probability, is_won, is_lost) values
    (v_pipeline, 'Qualified',   2, 0.25, false, false) returning id into s_qual;
  insert into public.pipeline_stages (pipeline_id, name, position, default_probability, is_won, is_lost) values
    (v_pipeline, 'Proposal',    3, 0.50, false, false) returning id into s_prop;
  insert into public.pipeline_stages (pipeline_id, name, position, default_probability, is_won, is_lost) values
    (v_pipeline, 'Negotiation', 4, 0.75, false, false) returning id into s_neg;
  insert into public.pipeline_stages (pipeline_id, name, position, default_probability, is_won, is_lost) values
    (v_pipeline, 'Closed Won',  5, 1.00, true,  false) returning id into s_won;
  insert into public.pipeline_stages (pipeline_id, name, position, default_probability, is_won, is_lost) values
    (v_pipeline, 'Closed Lost', 6, 0.00, false, true ) returning id into s_lost;

  insert into public.contacts (kind, name, website, address, tags) values
    ('company','Acme Corp','https://acme.example','100 Market St, SF','{enterprise}') returning id into c_acme;
  insert into public.contacts (kind, name, website, address, tags) values
    ('company','Globex Inc','https://globex.example','42 Industrial Way, Austin','{midmarket}') returning id into c_globex;
  insert into public.contacts (kind, name, website, address, tags) values
    ('company','Initech LLC','https://initech.example','9 Office Park, Dallas','{smb}') returning id into c_initech;

  insert into public.contacts (kind, name, first_name, last_name, email, phone, title, company_id) values
    ('person','Jane Doe','Jane','Doe','jane@acme.example','+1-555-0101','VP Operations', c_acme) returning id into p_jane;
  insert into public.contacts (kind, name, first_name, last_name, email, phone, title, company_id) values
    ('person','John Smith','John','Smith','john@globex.example','+1-555-0102','CTO', c_globex) returning id into p_john;
  insert into public.contacts (kind, name, first_name, last_name, email, phone, title, company_id) values
    ('person','Mary Lee','Mary','Lee','mary@initech.example','+1-555-0103','Office Manager', c_initech) returning id into p_mary;
  insert into public.contacts (kind, name, first_name, last_name, email, phone, title, company_id) values
    ('person','Sam Park','Sam','Park','sam@acme.example','+1-555-0104','Procurement Lead', c_acme) returning id into p_sam;

  insert into public.deals (name, pipeline_id, stage_id, contact_id, value, expected_close_date) values
    ('Acme — Platform License', v_pipeline, s_prop, c_acme, 120000, current_date + 30) returning id into d1;
  insert into public.deals (name, pipeline_id, stage_id, contact_id, value, expected_close_date) values
    ('Globex — Pilot Rollout', v_pipeline, s_qual, c_globex, 45000, current_date + 60) returning id into d2;
  insert into public.deals (name, pipeline_id, stage_id, contact_id, value, expected_close_date) values
    ('Initech — Annual Renewal', v_pipeline, s_neg, c_initech, 28000, current_date + 14) returning id into d3;
  insert into public.deals (name, pipeline_id, stage_id, contact_id, value, expected_close_date) values
    ('Acme — Add-on Modules', v_pipeline, s_won, c_acme, 36000, current_date - 5) returning id into d4;

  insert into public.activities (type, subject, notes, contact_id, deal_id, activity_date) values
    ('call','Discovery call','Discussed requirements and budget.', p_jane, d1, now() - interval '6 days'),
    ('email','Sent proposal','Proposal v1 emailed to Jane.', p_jane, d1, now() - interval '2 days'),
    ('meeting','Pilot kickoff','Scoped 30-day pilot with John.', p_john, d2, now() - interval '4 days'),
    ('task','Send renewal quote','Prepare and send renewal pricing.', p_mary, d3, now() - interval '1 day'),
    ('note','Deal closed','Add-on modules signed off.', p_sam, d4, now() - interval '5 days');

  insert into public.notes (body, contact_id, deal_id) values
    ('Acme is consolidating vendors this quarter — strong fit.', c_acme, d1),
    ('John prefers async updates over calls.', p_john, null),
    ('Initech renewal at risk if pricing increases >10%.', null, d3);

  raise notice 'CRM seed complete.';
end;
$$;
