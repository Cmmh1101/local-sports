alter table public.inning_halves
  add column if not exists batting_team_id uuid
    references public.teams(id),

  add column if not exists runs_scored integer not null default 0;

alter table public.inning_halves
  add constraint inning_halves_inning_chk
    check (inning >= 1);

alter table public.inning_halves
  add constraint inning_halves_half_chk
    check (half in ('top', 'bottom'));

create unique index if not exists
  inning_halves_game_inning_half_uniq
  on public.inning_halves (game_id, inning, half);