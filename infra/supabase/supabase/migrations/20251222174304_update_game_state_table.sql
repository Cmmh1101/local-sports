-- 1) Add live status
alter table public.game_state
add column if not exists is_live boolean not null default false;

-- 2) Track last update timestamp (for sync + UI refresh)
alter table public.game_state
add column if not exists last_event_at timestamptz;

-- 3) updated_at auto-updates
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_game_state_updated_at on public.game_state;

create trigger trg_game_state_updated_at
before update on public.game_state
for each row
execute function public.set_updated_at();

-- 4) basic sanity constraints
alter table public.game_state
add constraint game_state_balls_chk check (balls between 0 and 3);

alter table public.game_state
add constraint game_state_strikes_chk check (strikes between 0 and 2);

alter table public.game_state
add constraint game_state_outs_chk check (outs between 0 and 2);

alter table public.game_state
add constraint game_state_half_chk check (half in ('top', 'bottom'));