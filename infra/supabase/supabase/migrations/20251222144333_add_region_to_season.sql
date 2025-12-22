alter table public.seasons
    add column if not exists season_year int,
    add column if not exists region text;

update public.seasons
set season_year = extract(year from start_date)
where season_year is null
  and start_date is not null;

-- Constraint (safe range)
-- NOTE: added AFTER backfill to avoid violations
alter table public.seasons
  add constraint seasons_season_year_chk
  check (season_year between 1900 and 2100);