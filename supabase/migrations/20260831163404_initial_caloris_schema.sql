-- Caloris initial schema. All client-facing records are private to auth.uid().

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = pg_catalog.now();
  return new;
end;
$$;

revoke all on function public.set_updated_at() from public, anon, authenticated;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 2 and 80),
  gender text not null check (
    gender in ('female', 'male', 'other', 'prefer_not_to_say')
  ),
  birth_date date not null check (
    birth_date between (current_date - interval '100 years')::date
      and (current_date - interval '13 years')::date
  ),
  height_cm numeric(5,2) not null check (height_cm between 100 and 250),
  current_weight_kg numeric(6,2) not null check (
    current_weight_kg between 25 and 400
  ),
  target_weight_kg numeric(6,2) not null check (
    target_weight_kg between 25 and 400
  ),
  activity_level text not null check (
    activity_level in (
      'sedentary', 'lightly_active', 'moderately_active', 'very_active'
    )
  ),
  goal text not null check (
    goal in ('lose_weight', 'maintain_weight', 'gain_weight')
  ),
  water_target_ml integer not null default 2000 check (
    water_target_ml between 250 and 10000
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.food_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_type text not null check (
    meal_type in ('breakfast', 'lunch', 'dinner', 'snack')
  ),
  food_name text not null check (char_length(btrim(food_name)) between 1 and 160),
  amount numeric(10,2) not null check (amount > 0 and amount <= 100000),
  unit text not null check (
    unit in (
      'gram', 'kilogram', 'milliliter', 'tablespoon', 'teaspoon', 'piece',
      'bowl', 'glass', 'plate', 'fruit', 'half_portion', 'portion'
    )
  ),
  calories numeric(10,2) not null check (calories between 0 and 10000),
  protein numeric(10,2) not null default 0 check (protein between 0 and 2000),
  carbohydrate numeric(10,2) not null default 0 check (
    carbohydrate between 0 and 2000
  ),
  fat numeric(10,2) not null default 0 check (fat between 0 and 2000),
  fiber numeric(10,2) not null default 0 check (fiber between 0 and 1000),
  cooking_method text check (
    cooking_method is null or cooking_method in (
      'boiled', 'steamed', 'grilled', 'baked', 'stir_fried', 'fried',
      'battered_fried', 'other'
    )
  ),
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.weight_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  weight_kg numeric(6,2) not null check (weight_kg between 25 and 400),
  note text check (note is null or char_length(note) <= 500),
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.water_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount_ml integer not null check (amount_ml between 1 and 10000),
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  activity_type text not null check (
    char_length(btrim(activity_type)) between 1 and 80
  ),
  duration_minutes integer not null check (duration_minutes between 1 and 1440),
  distance_km numeric(8,2) check (distance_km is null or distance_km between 0 and 1000),
  estimated_calories numeric(10,2) check (
    estimated_calories is null or estimated_calories between 0 and 10000
  ),
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 1 and 7),
  activity_name text not null check (
    char_length(btrim(activity_name)) between 1 and 120
  ),
  start_time time not null,
  end_time time not null,
  category text not null check (
    category in ('study', 'work', 'travel', 'rest', 'exercise', 'other')
  ),
  busyness_level smallint not null default 2 check (busyness_level between 1 and 3),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint schedules_time_order check (start_time < end_time)
);

create table public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reminder_type text not null check (
    reminder_type in (
      'breakfast', 'lunch', 'dinner', 'water', 'walk', 'activity',
      'weigh_in', 'sleep', 'food_log'
    )
  ),
  reminder_time time not null,
  enabled boolean not null default true,
  repeat_days smallint[] not null default '{1,2,3,4,5,6,7}'::smallint[] check (
    cardinality(repeat_days) between 1 and 7
    and repeat_days <@ '{1,2,3,4,5,6,7}'::smallint[]
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.scan_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  estimated_calories numeric(10,2) not null check (
    estimated_calories between 0 and 10000
  ),
  scan_result jsonb not null check (jsonb_typeof(scan_result) = 'object'),
  image_path text check (
    image_path is null or (
      char_length(image_path) <= 500
      and image_path !~ '(^|/)\.\.(/|$)'
    )
  ),
  scanned_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.favorite_meals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  meal_data jsonb not null check (jsonb_typeof(meal_data) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index food_logs_user_logged_at_idx
  on public.food_logs (user_id, logged_at desc);
create index food_logs_user_meal_logged_at_idx
  on public.food_logs (user_id, meal_type, logged_at desc);
create index weight_logs_user_logged_at_idx
  on public.weight_logs (user_id, logged_at desc);
create index water_logs_user_logged_at_idx
  on public.water_logs (user_id, logged_at desc);
create index activities_user_logged_at_idx
  on public.activities (user_id, logged_at desc);
create index schedules_user_day_time_idx
  on public.schedules (user_id, day_of_week, start_time);
create index reminders_user_enabled_time_idx
  on public.reminders (user_id, enabled, reminder_time);
create index scan_history_user_scanned_at_idx
  on public.scan_history (user_id, scanned_at desc);
create index favorite_meals_user_name_idx
  on public.favorite_meals (user_id, lower(name));

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger food_logs_set_updated_at before update on public.food_logs
for each row execute function public.set_updated_at();
create trigger schedules_set_updated_at before update on public.schedules
for each row execute function public.set_updated_at();
create trigger reminders_set_updated_at before update on public.reminders
for each row execute function public.set_updated_at();
create trigger favorite_meals_set_updated_at before update on public.favorite_meals
for each row execute function public.set_updated_at();

revoke all on table
  public.profiles,
  public.food_logs,
  public.weight_logs,
  public.water_logs,
  public.activities,
  public.schedules,
  public.reminders,
  public.scan_history,
  public.favorite_meals
from anon, authenticated;

grant select, insert, update, delete on table
  public.profiles,
  public.food_logs,
  public.weight_logs,
  public.water_logs,
  public.activities,
  public.schedules,
  public.reminders,
  public.scan_history,
  public.favorite_meals
to authenticated;

alter table public.profiles enable row level security;
alter table public.food_logs enable row level security;
alter table public.weight_logs enable row level security;
alter table public.water_logs enable row level security;
alter table public.activities enable row level security;
alter table public.schedules enable row level security;
alter table public.reminders enable row level security;
alter table public.scan_history enable row level security;
alter table public.favorite_meals enable row level security;

create policy "profiles_select_own" on public.profiles for select to authenticated
using ((select auth.uid()) = id);
create policy "profiles_insert_own" on public.profiles for insert to authenticated
with check ((select auth.uid()) = id);
create policy "profiles_update_own" on public.profiles for update to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "profiles_delete_own" on public.profiles for delete to authenticated
using ((select auth.uid()) = id);

create policy "food_logs_select_own" on public.food_logs for select to authenticated
using ((select auth.uid()) = user_id);
create policy "food_logs_insert_own" on public.food_logs for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy "food_logs_update_own" on public.food_logs for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "food_logs_delete_own" on public.food_logs for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "weight_logs_select_own" on public.weight_logs for select to authenticated
using ((select auth.uid()) = user_id);
create policy "weight_logs_insert_own" on public.weight_logs for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy "weight_logs_update_own" on public.weight_logs for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "weight_logs_delete_own" on public.weight_logs for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "water_logs_select_own" on public.water_logs for select to authenticated
using ((select auth.uid()) = user_id);
create policy "water_logs_insert_own" on public.water_logs for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy "water_logs_update_own" on public.water_logs for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "water_logs_delete_own" on public.water_logs for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "activities_select_own" on public.activities for select to authenticated
using ((select auth.uid()) = user_id);
create policy "activities_insert_own" on public.activities for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy "activities_update_own" on public.activities for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "activities_delete_own" on public.activities for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "schedules_select_own" on public.schedules for select to authenticated
using ((select auth.uid()) = user_id);
create policy "schedules_insert_own" on public.schedules for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy "schedules_update_own" on public.schedules for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "schedules_delete_own" on public.schedules for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "reminders_select_own" on public.reminders for select to authenticated
using ((select auth.uid()) = user_id);
create policy "reminders_insert_own" on public.reminders for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy "reminders_update_own" on public.reminders for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "reminders_delete_own" on public.reminders for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "scan_history_select_own" on public.scan_history for select to authenticated
using ((select auth.uid()) = user_id);
create policy "scan_history_insert_own" on public.scan_history for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy "scan_history_update_own" on public.scan_history for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "scan_history_delete_own" on public.scan_history for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "favorite_meals_select_own" on public.favorite_meals for select to authenticated
using ((select auth.uid()) = user_id);
create policy "favorite_meals_insert_own" on public.favorite_meals for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy "favorite_meals_update_own" on public.favorite_meals for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "favorite_meals_delete_own" on public.favorite_meals for delete to authenticated
using ((select auth.uid()) = user_id);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'food-scans',
  'food-scans',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "food_scans_select_own" on storage.objects for select to authenticated
using (
  bucket_id = 'food-scans'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
create policy "food_scans_insert_own" on storage.objects for insert to authenticated
with check (
  bucket_id = 'food-scans'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
create policy "food_scans_update_own" on storage.objects for update to authenticated
using (
  bucket_id = 'food-scans'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'food-scans'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
create policy "food_scans_delete_own" on storage.objects for delete to authenticated
using (
  bucket_id = 'food-scans'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
