-- Add season_year and region to teams

alter table public.teams
  add column if not exists season_year int,
  add column if not exists region text;