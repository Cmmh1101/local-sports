do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'teams_season_year_chk'
  ) then
    alter table public.teams
      add constraint teams_season_year_chk
      check (
        season_year is null or season_year between 2000 and 2100
      );
  end if;
end $$;