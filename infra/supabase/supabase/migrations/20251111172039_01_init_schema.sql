-- ==============================================================
-- 01_init_schema.sql
-- Base schema for GameApp MVP (Supabase Cloud)
-- ==============================================================

-- === ENUM TYPES (safe idempotent creation) ====================

-- member_role
do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'member_role' and n.nspname = 'public'
  ) then
    create type public.member_role as enum ('admin','parent','fan');
  end if;
end $$;

-- game_status
do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'game_status' and n.nspname = 'public'
  ) then
    create type public.game_status as enum ('scheduled','live','final');
  end if;
end $$;

-- follow_role
do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'follow_role' and n.nspname = 'public'
  ) then
    create type public.follow_role as enum ('fan','family');
  end if;
end $$;

-- follow_status
do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'follow_status' and n.nspname = 'public'
  ) then
    create type public.follow_status as enum ('pending','approved','declined');
  end if;
end $$;

-- chat_type
do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'chat_type' and n.nspname = 'public'
  ) then
    create type public.chat_type as enum ('room','dm');
  end if;
end $$;

-- ==============================================================
-- USERS & REGIONS
-- ==============================================================

create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.regions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  country_code text default 'VE',
  created_at timestamptz not null default now()
);

create table if not exists public.leagues (
  id uuid primary key default gen_random_uuid(),
  region_id uuid not null references public.regions(id) on delete cascade,
  name text not null,
  level text,
  long_format boolean default true,
  created_at timestamptz not null default now()
);

create table if not exists public.seasons (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues(id) on delete cascade,
  name text not null,
  start_date date,
  end_date date,
  created_at timestamptz not null default now()
);

-- ==============================================================
-- TEAMS & MEMBERS
-- ==============================================================

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text,
  org text,
  created_at timestamptz not null default now()
);

create table if not exists public.team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.member_role not null,
  is_approved boolean not null default false,
  player_id uuid null,
  created_at timestamptz not null default now()
);

-- ==============================================================
-- PLAYERS / ROSTER
-- ==============================================================

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  first_name text not null,
  last_name text not null,
  jersey text,
  position text,
  dob date,
  photo_url text,
  created_at timestamptz not null default now()
);

-- ==============================================================
-- LEAGUE TEAMS (season entries)
-- ==============================================================

create table if not exists public.league_teams (
  season_id uuid not null references public.seasons(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  approved boolean not null default false,
  added_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  primary key (season_id, team_id)
);

-- ==============================================================
-- GAMES
-- ==============================================================

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete restrict,
  home_team_id uuid not null references public.teams(id) on delete restrict,
  away_team_id uuid not null references public.teams(id) on delete restrict,
  starts_at timestamptz,
  location text,
  notes text,
  status public.game_status not null default 'scheduled',
  actual_start_at timestamptz,
  actual_end_at timestamptz,
  score_home int default 0,
  score_away int default 0,
  created_at timestamptz not null default now()
);

-- ==============================================================
-- GAME STATE + INNING HISTORY
-- ==============================================================

create table if not exists public.game_state (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null unique references public.games(id) on delete cascade,
  inning int not null default 1,
  half text not null check (half in ('top','bottom')),
  balls int not null default 0,
  strikes int not null default 0,
  outs int not null default 0,
  bases jsonb not null default '{"first":false,"second":false,"third":false}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.inning_halves (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  inning int not null check (inning >= 1),
  half text not null check (half in ('top','bottom')),
  start_at timestamptz,
  end_at timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (game_id, inning, half)
);

-- ==============================================================
-- FOLLOW REQUESTS
-- ==============================================================

create table if not exists public.follow_requests (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.follow_role not null,
  player_id uuid null references public.players(id) on delete set null,
  status public.follow_status not null default 'pending',
  decided_by uuid null references auth.users(id) on delete set null,
  decided_at timestamptz null,
  created_at timestamptz not null default now()
);

-- ==============================================================
-- CHAT
-- ==============================================================

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  type public.chat_type not null,
  to_user_id uuid null references auth.users(id),
  from_user_id uuid not null references auth.users(id),
  body text not null,
  created_at timestamptz not null default now()
);

-- ==============================================================
-- STANDINGS
-- ==============================================================

create table if not exists public.standings (
  season_id uuid not null references public.seasons(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  wins int not null default 0,
  losses int not null default 0,
  ties int not null default 0,
  runs_for int not null default 0,
  runs_against int not null default 0,
  last_updated timestamptz not null default now(),
  primary key (season_id, team_id)
);