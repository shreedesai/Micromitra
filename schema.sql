-- ═══════════════════════════════════════════════════════════
-- MICROMITRA — Supabase schema
-- Run this once in Supabase → SQL Editor → New query → Run
-- ═══════════════════════════════════════════════════════════

-- Student / faculty profile (1 row per authenticated user)
create table public.profiles (
  id         uuid references auth.users(id) on delete cascade primary key,
  email      text,
  name       text,
  roll       text,
  year       text,
  college    text,
  dept       text,
  goal       text,
  role       text default 'student' check (role in ('student','faculty')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Progress stats / competency mastery (1 row per user)
create table public.stats (
  id           uuid references auth.users(id) on delete cascade primary key,
  interactions int default 0,
  gaps_found   int default 0,
  k int default 0, s int default 0, a int default 0, com int default 0,
  kc int default 0, sc int default 0, ac int default 0, cc int default 0,
  score_total  int default 0,
  score_count  int default 0,
  quiz_count   int default 0,
  streak       int default 1,
  comp_mastery jsonb default '{}'::jsonb,
  updated_at   timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.stats    enable row level security;

-- Helper: is the current logged-in user a faculty member?
-- SECURITY DEFINER lets this bypass RLS internally so it doesn't recurse.
create or replace function public.is_faculty()
returns boolean
language sql security definer
set search_path = public
as $$
  select exists(
    select 1 from public.profiles where id = auth.uid() and role = 'faculty'
  );
$$;

-- Everyone can manage their own row; faculty can additionally READ everyone's.
create policy "own profile or faculty read" on public.profiles
  for select using (auth.uid() = id or public.is_faculty());
create policy "insert own profile" on public.profiles
  for insert with check (auth.uid() = id);
create policy "update own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "own stats or faculty read" on public.stats
  for select using (auth.uid() = id or public.is_faculty());
create policy "insert own stats" on public.stats
  for insert with check (auth.uid() = id);
create policy "update own stats" on public.stats
  for update using (auth.uid() = id);
