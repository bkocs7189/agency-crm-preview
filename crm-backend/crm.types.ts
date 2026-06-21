// Curated TypeScript types for the Internal CRM backend (OMN-59).
// Canonical tables: contacts, deals, pipelines, pipeline_stages, activities, notes.
// Regenerate the full project type with:
//   supabase gen types typescript --project-id krthbgtykwamxqvapxnx
// (The crm_* tables are a deprecated prototype — do not use.)

export type ContactKind = 'company' | 'person';
export type DealStatus = 'open' | 'won' | 'lost';
export type ActivityType = 'call' | 'email' | 'meeting' | 'note' | 'task' | 'other';

export interface Pipeline {
  id: string;
  key: string;
  name: string;
  description: string | null;
  is_default: boolean;
  created_at: string;
  updated_at: string;
}

export interface PipelineStage {
  id: string;
  pipeline_id: string;
  name: string;
  position: number;
  default_probability: number; // 0..1
  is_won: boolean;
  is_lost: boolean;
  created_at: string;
  updated_at: string;
}

export interface Contact {
  id: string;
  kind: ContactKind;
  name: string;
  first_name: string | null;
  last_name: string | null;
  email: string | null;
  phone: string | null;
  title: string | null;
  company_id: string | null; // -> contacts.id (a person's company)
  website: string | null;
  address: string | null;
  tags: string[];
  owner_id: string | null; // auth.users.id
  created_at: string;
  updated_at: string;
  deleted_at?: string | null; // soft-delete (added by OMN-57)
}

export interface Deal {
  id: string;
  name: string;
  pipeline_id: string;
  stage_id: string | null;
  contact_id: string | null;
  value: number;
  currency: string;
  probability: number | null; // 0..1; defaults from stage when null
  weighted_value: number | null; // computed: value * probability (read-only)
  owner_id: string | null;
  status: DealStatus;
  expected_close_date: string | null; // date
  closed_at: string | null;
  created_at: string;
  updated_at: string;
  deleted_at?: string | null;
}

export interface Activity {
  id: string;
  type: ActivityType;
  subject: string | null;
  notes: string | null;
  activity_date: string;
  contact_id: string | null;
  deal_id: string | null;
  owner_id: string | null;
  created_at: string;
  updated_at: string;
  deleted_at?: string | null;
}

export interface Note {
  id: string;
  body: string;
  contact_id: string | null;
  deal_id: string | null;
  author_id: string | null;
  created_at: string;
  updated_at: string;
  deleted_at?: string | null;
}

export interface DealPipelineSummaryRow {
  pipeline_id: string;
  pipeline_name: string;
  stage_id: string;
  stage_name: string;
  stage_position: number;
  deal_count: number;
  total_value: number;
  weighted_value: number;
}
