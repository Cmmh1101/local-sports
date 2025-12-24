-- ==============================================================
-- 02_rls_policies.sql
-- RLS, helper predicates, and access rules
-- ==============================================================

-- 1) Enable RLS on all app tables
alter table public.user_profiles    enable row level security;
alter table public.regions          enable row level security;
alter table public.leagues          enable row level security;
alter table public.seasons          enable row level security;
alter table public.teams            enable row level security;
alter table public.team_members     enable row level security;
alter table public.players          enable row level security;
alter table public.league_teams     enable row level security;
alter table public.games            enable row level security;
alter table public.game_state       enable row level security;
alter table public.inning_halves    enable row level security;
alter table public.follow_requests  enable row level security;
alter table public.messages         enable row level security;
alter table public.standings        enable row level security;

-- 2) Helper functions (predicates)

-- Is the current user an approved admin of a team?
create or replace function public.is_team_admin(p_team uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.team_members tm
    where tm.team_id = p_team
      and tm.user_id = auth.uid()
      and tm.role = 'admin'
      and tm.is_approved = true
  );
$$;

-- Is the current user an approved parent of a team?
create or replace function public.is_member_parent(p_team uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.team_members tm
    where tm.team_id = p_team
      and tm.user_id = auth.uid()
      and tm.role = 'parent'
      and tm.is_approved = true
  );
$$;

-- 3) Policies

-- Profiles: owner can read/update own profile; everyone authenticated can insert self on first sign-in if desired.
drop policy if exists "profiles owner read" on public.user_profiles;
create policy "profiles owner read"
  on public.user_profiles
  for select
  using (user_id = auth.uid());

drop policy if exists "profiles owner update" on public.user_profiles;
create policy "profiles owner update"
  on public.user_profiles
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "profiles self insert" on public.user_profiles;
create policy "profiles self insert"
  on public.user_profiles
  for insert
  with check (user_id = auth.uid());

-- Reference data (readable to signed-in users)
drop policy if exists "regions read" on public.regions;
create policy "regions read"
  on public.regions
  for select
  using (auth.role() = 'authenticated');

drop policy if exists "leagues read" on public.leagues;
create policy "leagues read"
  on public.leagues
  for select
  using (auth.role() = 'authenticated');

drop policy if exists "seasons read" on public.seasons;
create policy "seasons read"
  on public.seasons
  for select
  using (auth.role() = 'authenticated');

-- Teams: public readable; admins can write
drop policy if exists "teams read" on public.teams;
create policy "teams read"
  on public.teams
  for select
  using (true);

drop policy if exists "teams admin write" on public.teams;
create policy "teams admin write"
  on public.teams
  for all
  using (public.is_team_admin(id))
  with check (public.is_team_admin(id));

-- Team members: read your own row or admins can read team; self-insert; admin update (e.g., approve)
drop policy if exists "tm read self or admin" on public.team_members;
create policy "tm read self or admin"
  on public.team_members
  for select
  using (
    user_id = auth.uid()
    or public.is_team_admin(team_id)
  );

drop policy if exists "tm self insert" on public.team_members;
create policy "tm self insert"
  on public.team_members
  for insert
  with check (user_id = auth.uid());

drop policy if exists "tm admin update" on public.team_members;
create policy "tm admin update"
  on public.team_members
  for update
  using (public.is_team_admin(team_id))
  with check (public.is_team_admin(team_id));

-- Players: public read; admins write
drop policy if exists "players read" on public.players;
create policy "players read"
  on public.players
  for select
  using (true);

drop policy if exists "players admin write" on public.players;
create policy "players admin write"
  on public.players
  for all
  using (public.is_team_admin(team_id))
  with check (public.is_team_admin(team_id));

-- League entries (season admission): public read; admins write for their team
drop policy if exists "league_teams read" on public.league_teams;
create policy "league_teams read"
  on public.league_teams
  for select
  using (true);

drop policy if exists "league_teams admin write" on public.league_teams;
create policy "league_teams admin write"
  on public.league_teams
  for all
  using (
    exists (
      select 1 from public.team_members tm
      where tm.team_id = league_teams.team_id
        and public.is_team_admin(tm.team_id)
    )
  )
  with check (
    exists (
      select 1 from public.team_members tm
      where tm.team_id = league_teams.team_id
        and public.is_team_admin(tm.team_id)
    )
  );

-- Games: public read; admins of either team write
drop policy if exists "games read" on public.games;
create policy "games read"
  on public.games
  for select
  using (true);

drop policy if exists "games write by admin" on public.games;
create policy "games write by admin"
  on public.games
  for all
  using (
    public.is_team_admin(home_team_id)
    or public.is_team_admin(away_team_id)
  )
  with check (
    public.is_team_admin(home_team_id)
    or public.is_team_admin(away_team_id)
  );

-- Game state: public read; admins write
drop policy if exists "state read" on public.game_state;
create policy "state read"
  on public.game_state
  for select
  using (true);

drop policy if exists "state admin write" on public.game_state;
create policy "state admin write"
  on public.game_state
  for all
  using (
    exists (
      select 1
      from public.games g
      where g.id = game_state.game_id
        and (public.is_team_admin(g.home_team_id) or public.is_team_admin(g.away_team_id))
    )
  )
  with check (
    exists (
      select 1
      from public.games g
      where g.id = game_state.game_id
        and (public.is_team_admin(g.home_team_id) or public.is_team_admin(g.away_team_id))
    )
  );

-- Inning halves: public read; admins write
drop policy if exists "ih read" on public.inning_halves;
create policy "ih read"
  on public.inning_halves
  for select
  using (true);

drop policy if exists "ih admin write" on public.inning_halves;
create policy "ih admin write"
  on public.inning_halves
  for all
  using (
    public.is_team_admin(
      (select home_team_id from public.games where id = inning_halves.game_id)
    )
    or public.is_team_admin(
      (select away_team_id from public.games where id = inning_halves.game_id)
    )
  )
  with check (true);

-- Follow requests: requester read; team admins read/update; requester can create
drop policy if exists "follow read requester or admin" on public.follow_requests;
create policy "follow read requester or admin"
  on public.follow_requests
  for select
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.team_members tm
      where tm.team_id = follow_requests.team_id
        and public.is_team_admin(tm.team_id)
    )
  );

drop policy if exists "follow create self" on public.follow_requests;
create policy "follow create self"
  on public.follow_requests
  for insert
  with check (user_id = auth.uid());

drop policy if exists "follow admin update" on public.follow_requests;
create policy "follow admin update"
  on public.follow_requests
  for update
  using (
    exists (
      select 1 from public.team_members tm
      where tm.team_id = follow_requests.team_id
        and public.is_team_admin(tm.team_id)
    )
  );

-- Messages: room visible to admins+parents; DMs visible to sender/recipient
drop policy if exists "messages read visibility" on public.messages;
create policy "messages read visibility"
  on public.messages
  for select
  using (
    (type = 'room' and (public.is_team_admin(team_id) or public.is_member_parent(team_id)))
    or
    (type = 'dm' and (from_user_id = auth.uid() or to_user_id = auth.uid()))
  );

drop policy if exists "messages write allowed" on public.messages;
create policy "messages write allowed"
  on public.messages
  for insert
  with check (
    (type = 'room' and (public.is_team_admin(team_id) or public.is_member_parent(team_id)))
    or
    (type = 'dm' and from_user_id = auth.uid())
  );

-- Standings: public read only
drop policy if exists "standings read" on public.standings;
create policy "standings read"
  on public.standings
  for select
  using (true);