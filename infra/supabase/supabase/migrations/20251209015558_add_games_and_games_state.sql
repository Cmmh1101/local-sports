-- 1) Enum types (roles + game status)

do $$
begin
  if not exists (
    select 1 from pg_type where typname = 'member_role'
  ) then
    create type public.member_role as enum ('admin', 'parent', 'fan');
  end if;
end $$;

;

do $$
begin
  if not exists (
    select 1 from pg_type where typname = 'game_status'
  ) then
    create type public.game_status as enum ('scheduled', 'live', 'final');
  end if;
end $$;

-- 2) Make sure team_members has role + is_approved
-- (idempotent: will only add if missing)

do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name   = 'team_members'
      and column_name  = 'role'
  ) then
    alter table public.team_members
      add column role public.member_role not null default 'parent';
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name   = 'team_members'
      and column_name  = 'is_approved'
  ) then
    alter table public.team_members
      add column is_approved boolean not null default false;
  end if;
end $$;

-- 3) Helper function: is_team_admin(team_id)

create or replace function public.is_team_admin(p_team uuid)
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1
    from public.team_members tm
    where tm.team_id = p_team
      and tm.user_id = auth.uid()
      and tm.role    = 'admin'
      and tm.is_approved = true
  );
$$;

-- 4) Games table

create table if not exists public.games (
  id              uuid primary key default gen_random_uuid(),
  home_team_id    uuid not null references public.teams(id) on delete restrict,
  away_team_id    uuid not null references public.teams(id) on delete restrict,
  scheduled_at    timestamptz not null,
  location        text,
  status          public.game_status not null default 'scheduled',
  final_home_score int,
  final_away_score int,
  created_at      timestamptz not null default now()
);

-- 5) Live game_state table (one row per game)

create table if not exists public.game_state (
  id           uuid primary key default gen_random_uuid(),
  game_id      uuid not null references public.games(id) on delete cascade,
  inning       int not null default 1,
  half         text not null default 'top' check (half in ('top','bottom')),
  balls        int not null default 0,
  strikes      int not null default 0,
  outs         int not null default 0,
  bases        jsonb not null default '{"first":false,"second":false,"third":false}'::jsonb,
  home_score   int not null default 0,
  away_score   int not null default 0,
  updated_at   timestamptz not null default now(),
  unique (game_id)
);


-- 6) Enable RLS

alter table public.games      enable row level security;
alter table public.game_state enable row level security;


-- 7) RLS policies for games
--    - everyone can read
--    - only team admins can insert/update

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'games'
      and policyname = 'Games are readable by everyone'
  ) then
    create policy "Games are readable by everyone"
      on public.games
      for select
      using (true);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'games'
      and policyname = 'Team admins can insert games'
  ) then
    create policy "Team admins can insert games"
      on public.games
      for insert
      with check (
        public.is_team_admin(home_team_id)
        or public.is_team_admin(away_team_id)
      );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'games'
      and policyname = 'Team admins can update games'
  ) then
    create policy "Team admins can update games"
      on public.games
      for update
      using (
        public.is_team_admin(home_team_id)
        or public.is_team_admin(away_team_id)
      );
  end if;
end $$;

-- 8) RLS policies for game_state
--    - anyone can read
--    - only team admins can insert/update

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'game_state'
      and policyname = 'Game state is readable by everyone'
  ) then
    create policy "Game state is readable by everyone"
      on public.game_state
      for select
      using (true);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'game_state'
      and policyname = 'Team admins can insert game_state'
  ) then
    create policy "Team admins can insert game_state"
      on public.game_state
      for insert
      with check (
        public.is_team_admin(
          (select g.home_team_id from public.games g where g.id = game_id)
        )
        or
        public.is_team_admin(
          (select g.away_team_id from public.games g where g.id = game_id)
        )
      );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'game_state'
      and policyname = 'Team admins can update game_state'
  ) then
    create policy "Team admins can update game_state"
      on public.game_state
      for update
      using (
        public.is_team_admin(
          (select g.home_team_id from public.games g where g.id = game_id)
        )
        or
        public.is_team_admin(
          (select g.away_team_id from public.games g where g.id = game_id)
        )
      );
  end if;
end $$;