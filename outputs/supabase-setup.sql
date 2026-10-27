-- Quiz Battle shared backend for Supabase/Postgres.
-- Run the complete script once in Supabase Dashboard > SQL Editor.
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.quiz_question_bank (
  id bigint generated always as identity primary key,
  category text not null,
  prompt text not null,
  options jsonb not null check (jsonb_typeof(options) = 'array' and jsonb_array_length(options) = 4),
  correct_index integer not null check (correct_index between 0 and 3)
);

create table if not exists public.quiz_rooms (
  code text primary key,
  state jsonb not null,
  revision bigint not null default 1,
  updated_at timestamptz not null default now()
);
alter table public.quiz_rooms add column if not exists revision bigint not null default 1;
alter table public.quiz_rooms drop constraint if exists quiz_rooms_code_check;
alter table public.quiz_rooms drop constraint if exists quiz_rooms_code_format_check;
alter table public.quiz_rooms add constraint quiz_rooms_code_format_check
  check (code ~ '^([A-F0-9]{6}|[A-F0-9]{8})$');

-- The previous version exposed room codes through an RLS policy on this table.
-- Realtime invalidations now use Broadcast, so remove that table if it exists.
drop table if exists public.quiz_signals;

alter table public.quiz_rooms enable row level security;
alter table public.quiz_question_bank enable row level security;
revoke all on table public.quiz_rooms, public.quiz_question_bank from public, anon, authenticated;
grant usage on schema public to anon, authenticated;

create unique index if not exists quiz_question_prompt_unique
  on public.quiz_question_bank(prompt);

insert into public.quiz_question_bank(category,prompt,options,correct_index) values
('Science','Which planet is known as the Red Planet?','["Venus","Mars","Jupiter","Mercury"]',1),
('Science','What gas do plants absorb from the air?','["Oxygen","Nitrogen","Carbon dioxide","Helium"]',2),
('Science','What is the chemical symbol for gold?','["Ag","Au","Gd","Go"]',1),
('Science','How many bones are in the typical adult human body?','["106","206","306","406"]',1),
('Science','Which part of a cell contains most of its genetic material?','["Nucleus","Membrane","Ribosome","Cytoplasm"]',0),
('Science','What force keeps planets in orbit around the Sun?','["Magnetism","Friction","Gravity","Buoyancy"]',2),
('Science','At sea level, water boils at what temperature in Celsius?','["50°","75°","100°","125°"]',2),
('History','Which ancient civilization built Machu Picchu?','["Maya","Inca","Aztec","Olmec"]',1),
('History','The Great Wall is located in which country?','["India","Japan","China","Mongolia"]',2),
('History','Who was the first person to walk on the Moon?','["Buzz Aldrin","Yuri Gagarin","Neil Armstrong","John Glenn"]',2),
('History','Which ship carried the Pilgrims to North America in 1620?','["Endeavour","Mayflower","Santa Maria","Beagle"]',1),
('History','The Renaissance began in which present-day country?','["France","Italy","Greece","Spain"]',1),
('History','What was the name of the trade route connecting East Asia and Europe?','["Spice Road","Amber Route","Silk Road","Royal Road"]',2),
('Geography','What is the capital city of Australia?','["Sydney","Melbourne","Canberra","Perth"]',2),
('Geography','Which is the largest ocean on Earth?','["Atlantic","Indian","Arctic","Pacific"]',3),
('Geography','On which continent is the Sahara Desert?','["Asia","Africa","South America","Australia"]',1),
('Geography','Which country has a maple leaf on its national flag?','["Canada","Austria","Denmark","Finland"]',0),
('Geography','What is the longest river in South America?','["Nile","Amazon","Orinoco","Paraná"]',1),
('Geography','Which mountain is the tallest above sea level?','["K2","Kilimanjaro","Everest","Denali"]',2),
('Sports','How many players from one soccer team are on the field at a time?','["9","10","11","12"]',2),
('Sports','In tennis, what word means a score of zero?','["Nil","Love","Blank","Duck"]',1),
('Sports','Which sport uses a shuttlecock?','["Squash","Badminton","Table tennis","Lacrosse"]',1),
('Sports','How many rings appear on the Olympic symbol?','["Four","Five","Six","Seven"]',1),
('Sports','In basketball, how many points is a free throw worth?','["1","2","3","4"]',0),
('Sports','The Tour de France is primarily a competition in which sport?','["Running","Cycling","Skiing","Rowing"]',1),
('Technology','What does the “www” in a website address stand for?','["World Wide Web","Web World Window","Wide Web World","World Web Wire"]',0),
('Technology','Which company created the iPhone?','["Google","Apple","Microsoft","Samsung"]',1),
('Technology','What does a computer’s CPU mainly do?','["Stores files permanently","Processes instructions","Displays images","Connects to Wi-Fi"]',1),
('Technology','Which of these is a programming language?','["Python","Kangaroo","Lizard","Gecko"]',0),
('Technology','What does GPS help you determine?','["Your location","The weather","Time zones only","Internet speed"]',0),
('Technology','What kind of energy powers a typical solar panel?','["Wind","Sunlight","Tides","Geothermal heat"]',1),
('Entertainment','Which fictional school does Harry Potter attend?','["Narnia Academy","Hogwarts","Nevermore","Starfleet Academy"]',1),
('Entertainment','What is the name of the cowboy in Toy Story?','["Buzz","Woody","Rex","Andy"]',1),
('Entertainment','Which instrument has 88 keys on a standard model?','["Violin","Piano","Flute","Harp"]',1),
('Entertainment','In the Mario games, what color is Luigi’s outfit usually?','["Red","Blue","Green","Yellow"]',2),
('Entertainment','Which movie features the song “Let It Go”?','["Moana","Frozen","Encanto","Tangled"]',1),
('Entertainment','What is the name of the fictional city Batman protects?','["Metropolis","Gotham City","Star City","Central City"]',1),
('Nature','What is the largest animal on Earth?','["African elephant","Blue whale","Giraffe","Whale shark"]',1),
('Nature','What do caterpillars become after metamorphosis?','["Beetles","Butterflies or moths","Dragonflies","Ants"]',1),
('Nature','Which tree produces acorns?','["Maple","Oak","Pine","Birch"]',1),
('Nature','What is a group of lions called?','["Pack","Pride","Herd","Colony"]',1),
('Nature','Which natural process lets plants make food using sunlight?','["Fermentation","Photosynthesis","Respiration","Pollination"]',1),
('Nature','How many legs does a spider have?','["Six","Eight","Ten","Twelve"]',1),
('Nature','What is the fastest land animal?','["Lion","Cheetah","Pronghorn","Ostrich"]',1),
('Science','Which vitamin can the human body make when skin is exposed to sunlight?','["Vitamin A","Vitamin C","Vitamin D","Vitamin K"]',2),
('History','Which city was famously buried by the eruption of Mount Vesuvius in AD 79?','["Athens","Pompeii","Carthage","Sparta"]',1),
('Geography','What is the smallest independent country by area?','["Monaco","San Marino","Vatican City","Liechtenstein"]',2),
('Sports','In baseball, how many strikes make an out?','["Two","Three","Four","Five"]',1),
('Technology','What does “URL” identify?','["A web address","A computer chip","A wireless signal","A file type"]',0),
('Entertainment','Which band released the album Abbey Road?','["The Rolling Stones","The Beatles","Queen","ABBA"]',1),
('Nature','What is the name for liquid water changing to vapor at its surface?','["Condensation","Evaporation","Freezing","Precipitation"]',1)
on conflict do nothing;


-- This helper applies the same whitespace normalization on the server as the browser.
create or replace function public.quiz_clean_name(p_name text)
returns text
language sql
immutable
set search_path = ''
as $$
  select pg_catalog.regexp_replace(pg_catalog.btrim(p_name), '[[:space:]]+', ' ', 'g');
$$;

create or replace function public.quiz_pick_questions(p_exclude jsonb default '[]'::jsonb)
returns jsonb
language sql
volatile
security definer
set search_path = ''
as $$
  with random_offset as materialized (
    select floor(random() * 7)::integer as n
  ), categories as (
    select category, row_number() over (order by random()) as n
    from (
      select distinct b.category
      from public.quiz_question_bank as b
      where not exists (
        select 1
        from jsonb_array_elements(coalesce(p_exclude, '[]'::jsonb)) as old(value)
        where old.value->>'prompt' = b.prompt
      )
    ) as available_categories
  ), slots as (
    select generate_series(0, 14) as slot
  ), assignment_base as (
    select sl.slot, c.category
    from slots as sl
    cross join random_offset as o
    join categories as c on c.n = ((sl.slot + o.n) % 7) + 1
  ), assignment as (
    select slot, category,
           row_number() over (partition by category order by slot) as category_n
    from assignment_base
  ), eligible as (
    select b.category, b.prompt, b.options, b.correct_index,
           row_number() over (partition by b.category order by random()) as category_n
    from public.quiz_question_bank as b
    where not exists (
      select 1
      from jsonb_array_elements(coalesce(p_exclude, '[]'::jsonb)) as old(value)
      where old.value->>'prompt' = b.prompt
    )
  )
  select jsonb_agg(
    jsonb_build_object('category', e.category, 'prompt', e.prompt,
                       'options', e.options, 'correct_index', e.correct_index)
    order by a.slot
  )
  from assignment as a
  join eligible as e on e.category = a.category and e.category_n = a.category_n;
$$;

-- Touch the private room revision and send only a change notice (never game data).
create or replace function public.quiz_touch(p_code text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_revision bigint;
begin
  update public.quiz_rooms
     set revision = revision + 1
   where code = p_code
   returning revision into v_revision;

  if v_revision is not null then
    perform realtime.send(
      payload => pg_catalog.jsonb_build_object('revision', v_revision),
      event => 'room_changed',
      topic => 'quiz-room-' || p_code,
      private => false
    );
  end if;
end;
$$;

create or replace function public.get_room_state(
  p_code text, p_display_name text, p_token text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s jsonb;
  pl jsonb;
  me_player jsonb;
  q jsonb;
  qidx integer;
  revno bigint;
  hostid text;
  hname text;
  phase_name text;
  ptoken text;
begin
  select r.state, r.revision into s, revno
  from public.quiz_rooms as r
  where r.code = upper(p_code);
  if s is null then
    return jsonb_build_object('error', 'Room not found.');
  end if;
  ptoken := public.quiz_token_hash(p_token);
  if ptoken is null then
    return jsonb_build_object('error', 'Invalid player session.');
  end if;
  select x.value into me_player
  from pg_catalog.jsonb_array_elements(s->'players') as x(value)
  where pg_catalog.lower(x.value->>'name') = pg_catalog.lower(public.quiz_clean_name(p_display_name))
    and x.value->>'token_hash' = ptoken
  limit 1;
  if me_player is null then
    return jsonb_build_object('error', 'You are not in this room. Join again with your original name.');
  end if;

  select x.value->>'id', x.value->>'name' into hostid, hname
  from pg_catalog.jsonb_array_elements(s->'players') as x(value)
  where x.value->>'id' = s->>'host_id'
  limit 1;

  phase_name := s->>'phase';
  qidx := coalesce((s->>'q_index')::integer, 0);
  if phase_name in ('question', 'reveal') then
    q := s->'questions'->qidx;
    if phase_name = 'question' then
      q := q - 'correct_index';
    end if;
    q := q || jsonb_build_object('number', qidx + 1);
  else
    q := null;
  end if;

  select jsonb_agg(
    jsonb_build_object(
      'id', e.value->>'id', 'name', e.value->>'name',
      'score', coalesce((e.value->>'score')::integer, 0),
      'connected', coalesce((e.value->>'connected')::boolean, false),
      'answered', e.value->'answer' is not null and e.value->'answer' <> 'null'::jsonb
    ) order by (e.value->>'joined_order')::integer
  ) into pl
  from pg_catalog.jsonb_array_elements(s->'players') as e(value);

  return jsonb_build_object(
    'server_now', clock_timestamp(), 'code', upper(p_code), 'phase', phase_name,
    'revision', coalesce(revno, 0), 'players', coalesce(pl, '[]'::jsonb),
    'me', me_player->>'id', 'host_id', hostid, 'host_name', hname,
    'round', floor(qidx / 5.0)::integer + 1, 'question_in_round', qidx % 5 + 1,
    'question', q,
    'deadline', case when s->>'deadline' is null or s->>'deadline' = 'null'
                     then null else to_timestamp((s->>'deadline')::double precision) end,
    'progress', round(qidx * 100.0 / 15),
    'connected_count', (select count(*) from pg_catalog.jsonb_array_elements(s->'players') as e(value)
                        where coalesce((e.value->>'connected')::boolean, false)),
    'answered_count', (select count(*) from pg_catalog.jsonb_array_elements(s->'players') as e(value)
                       where coalesce((e.value->>'connected')::boolean, false)
                         and e.value->'answer' is not null and e.value->'answer' <> 'null'::jsonb),
    'my_answer', case when me_player->'answer' is null or me_player->'answer' = 'null'::jsonb
                      then null else (me_player->>'answer')::integer end,
    'my_points_earned', coalesce((me_player->>'points_earned')::integer, 0)
  );
end;
$$;

create or replace function public.quiz_token_hash(p_token text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_token ~* '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    then pg_catalog.encode(extensions.digest(pg_catalog.convert_to(pg_catalog.lower(p_token), 'UTF8'), 'sha256'), 'hex')
    else null
  end;
$$;

create or replace function public.create_room(p_display_name text, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := public.quiz_clean_name(p_display_name);
  v_code text;
  v_id uuid := extensions.gen_random_uuid();
  v_hash text := public.quiz_token_hash(p_token);
  s jsonb;
  tries integer := 0;
begin
  if v_name is null or pg_catalog.char_length(v_name) < 2 or pg_catalog.char_length(v_name) > 16 then
    return jsonb_build_object('error', 'Names must be 2–16 characters.');
  end if;
  if v_hash is null then
    return jsonb_build_object('error', 'Invalid player session. Refresh and try again.');
  end if;

  delete from public.quiz_rooms where updated_at < pg_catalog.now() - interval '24 hours';
  s := jsonb_build_object(
    'phase', 'lobby', 'host_id', v_id::text, 'q_index', 0,
    'deadline', null, 'reveal_at', null, 'next_joined', 2,
    'host_lost_at', null, 'questions', public.quiz_pick_questions('[]'::jsonb),
    'players', jsonb_build_array(jsonb_build_object(
      'id', v_id::text, 'name', v_name, 'score', 0, 'token_hash', v_hash,
      'connected', true, 'last_seen', extract(epoch from clock_timestamp()),
      'joined_order', 1, 'answer', null, 'points_earned', 0
    ))
  );

  loop
    v_code := pg_catalog.upper(pg_catalog.substr(pg_catalog.encode(extensions.gen_random_bytes(4), 'hex'), 1, 8));
    begin
      insert into public.quiz_rooms(code, state, revision, updated_at)
      values (v_code, s, 1, pg_catalog.now());
      exit;
    exception when unique_violation then
      tries := tries + 1;
      if tries >= 20 then
        return jsonb_build_object('error', 'Could not create a room. Try again.');
      end if;
    end;
  end loop;

  return public.get_room_state(v_code, v_name, p_token);
end;
$$;

create or replace function public.join_room(p_code text, p_display_name text, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code text := pg_catalog.upper(p_code);
  v_name text := public.quiz_clean_name(p_display_name);
  v_hash text := public.quiz_token_hash(p_token);
  s jsonb;
  arr jsonb;
  p jsonb;
  hostp jsonb;
  candidate jsonb;
  pos integer := -1;
  i integer := 0;
  tries integer;
  now_epoch double precision := extract(epoch from clock_timestamp());
  same_token boolean := false;
  host_expired boolean := false;
  host_deadline double precision;
begin
  if v_name is null or pg_catalog.char_length(v_name) < 2 or pg_catalog.char_length(v_name) > 16 then
    return jsonb_build_object('error', 'Names must be 2–16 characters.');
  end if;
  if v_hash is null then
    return jsonb_build_object('error', 'Invalid player session. Refresh and try again.');
  end if;

  select r.state into s from public.quiz_rooms as r where r.code = v_code for update;
  if s is null then
    return jsonb_build_object('error', 'Room not found. Check the code and try again.');
  end if;
  arr := s->'players';

  -- Preserve an expired host reservation even if no other client ticked at the exact deadline.
  select x.value into hostp
  from pg_catalog.jsonb_array_elements(arr) as x(value)
  where x.value->>'id' = s->>'host_id'
  limit 1;
  if hostp is not null then
    if s->>'host_lost_at' is not null and s->>'host_lost_at' <> 'null' then
      host_deadline := (s->>'host_lost_at')::double precision;
    elsif now_epoch - coalesce((hostp->>'last_seen')::double precision, now_epoch) > 15 then
      host_deadline := coalesce((hostp->>'last_seen')::double precision, now_epoch) + 60;
      s := jsonb_set(s, '{host_lost_at}', to_jsonb(host_deadline));
    end if;
    host_expired := host_deadline is not null and now_epoch >= host_deadline;
  end if;

  for p in select x.value from pg_catalog.jsonb_array_elements(arr) as x(value) loop
    if pg_catalog.lower(p->>'name') = pg_catalog.lower(v_name) then
      pos := i;
      same_token := p->>'token_hash' = v_hash;
      exit;
    end if;
    i := i + 1;
  end loop;

  if pos >= 0 then
    p := arr->pos;
    if not coalesce(same_token, false) then
      return jsonb_build_object(
        'error', 'That name belongs to an existing player. Enter its reconnect key to restore it, or choose another name.'
      );
    end if;
    -- The stored token is never replaced by a join request. This preserves the player's
    -- identity, score, host role, and reconnect credential across disconnects.
    p := jsonb_set(p, '{connected}', 'true'::jsonb);
    p := jsonb_set(p, '{last_seen}', to_jsonb(now_epoch));
    arr := jsonb_set(arr, array[pos::text], p);
  else
    if exists (
      select 1 from pg_catalog.jsonb_array_elements(arr) as x(value)
      where x.value->>'token_hash' = v_hash
    ) then
      return jsonb_build_object('error', 'That reconnect key is already linked to another player in this room.');
    end if;
    if jsonb_array_length(arr) >= 8 then
      return jsonb_build_object('error', 'This room is full (8 players maximum).');
    end if;
    if s->>'phase' not in ('lobby', 'waiting_rematch') then
      return jsonb_build_object('error', 'This game has already started.');
    end if;
    p := jsonb_build_object(
      'id', extensions.gen_random_uuid()::text, 'name', v_name, 'score', 0,
      'token_hash', v_hash, 'connected', true, 'last_seen', now_epoch,
      'joined_order', (s->>'next_joined')::integer, 'answer', null, 'points_earned', 0
    );
    arr := arr || jsonb_build_array(p);
    s := jsonb_set(s, '{next_joined}', to_jsonb((s->>'next_joined')::integer + 1));
  end if;

  s := jsonb_set(s, '{players}', arr);
  if host_expired then
    select x.value into candidate
    from pg_catalog.jsonb_array_elements(arr) as x(value)
    where x.value->>'id' <> s->>'host_id'
      and coalesce((x.value->>'connected')::boolean, false)
      and now_epoch - coalesce((x.value->>'last_seen')::double precision, 0) <= 15
    order by (x.value->>'joined_order')::integer
    limit 1;
    if candidate is not null then
      s := jsonb_set(s, '{host_id}', to_jsonb(candidate->>'id'));
      s := jsonb_set(s, '{host_lost_at}', 'null'::jsonb);
    end if;
  elsif s->>'host_id' = p->>'id' then
    s := jsonb_set(s, '{host_lost_at}', 'null'::jsonb);
  end if;

  update public.quiz_rooms set state = s, updated_at = pg_catalog.now() where code = v_code;
  perform public.quiz_touch(v_code);
  return public.get_room_state(v_code, v_name, p_token);
end;
$$;

create or replace function public.player_heartbeat(p_code text, p_display_name text, p_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  s jsonb;
  arr jsonb;
  p jsonb;
  pos integer := -1;
  i integer := 0;
  v_hash text := public.quiz_token_hash(p_token);
  v_name text := public.quiz_clean_name(p_display_name);
  now_epoch double precision := extract(epoch from clock_timestamp());
  woke boolean := false;
  host_deadline double precision;
begin
  if v_hash is null or v_name is null then
    return;
  end if;

  -- Reconcile deadlines before refreshing last_seen. A host arriving after the 60-second
  -- reservation cannot win a race against the next room tick.
  perform public.tick_room(upper(p_code), v_name, p_token);
  select r.state into s from public.quiz_rooms as r where r.code = upper(p_code) for update;
  if s is null then
    return;
  end if;
  arr := s->'players';
  for p in select x.value from pg_catalog.jsonb_array_elements(arr) as x(value) loop
    if pg_catalog.lower(p->>'name') = pg_catalog.lower(v_name) and p->>'token_hash' = v_hash then
      pos := i;
      exit;
    end if;
    i := i + 1;
  end loop;
  if pos < 0 then
    return;
  end if;

  p := arr->pos;
  woke := not coalesce((p->>'connected')::boolean, false);
  p := jsonb_set(p, '{connected}', 'true'::jsonb);
  p := jsonb_set(p, '{last_seen}', to_jsonb(now_epoch));
  arr := jsonb_set(arr, array[pos::text], p);
  s := jsonb_set(s, '{players}', arr);

  if s->>'host_id' = p->>'id' then
    if s->>'host_lost_at' is not null and s->>'host_lost_at' <> 'null' then
      host_deadline := (s->>'host_lost_at')::double precision;
    end if;
    if host_deadline is null or now_epoch < host_deadline then
      s := jsonb_set(s, '{host_lost_at}', 'null'::jsonb);
    end if;
  end if;

  update public.quiz_rooms set state = s, updated_at = pg_catalog.now() where code = upper(p_code);
  if woke then
    perform public.quiz_touch(upper(p_code));
  end if;
end;
$$;

create or replace function public.start_game(p_code text, p_display_name text, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s jsonb;
  p jsonb;
  v_hash text := public.quiz_token_hash(p_token);
  v_name text := public.quiz_clean_name(p_display_name);
begin
  if v_hash is null or v_name is null then
    return jsonb_build_object('error', 'Invalid player session. Refresh and try again.');
  end if;
  select r.state into s from public.quiz_rooms as r where r.code = upper(p_code) for update;
  if s is null then
    return jsonb_build_object('error', 'Room not found.');
  end if;
  select x.value into p
  from pg_catalog.jsonb_array_elements(s->'players') as x(value)
  where x.value->>'id' = s->>'host_id'
  limit 1;
  if p is null or not coalesce((p->>'connected')::boolean, false)
     or p->>'token_hash' <> v_hash
     or pg_catalog.lower(p->>'name') <> pg_catalog.lower(v_name) then
    return jsonb_build_object('error', 'Only the connected host can start the game.');
  end if;
  if s->>'phase' <> 'lobby' then
    return jsonb_build_object('error', 'The game has already started.');
  end if;
  if jsonb_array_length(s->'players') < 2 then
    return jsonb_build_object('error', 'At least two players must have joined.');
  end if;

  s := jsonb_set(s, '{phase}', '"question"'::jsonb);
  s := jsonb_set(s, '{q_index}', '0'::jsonb);
  s := jsonb_set(s, '{deadline}', to_jsonb(extract(epoch from clock_timestamp()) + 15));
  s := jsonb_set(s, '{host_lost_at}', 'null'::jsonb);
  update public.quiz_rooms set state = s, updated_at = pg_catalog.now() where code = upper(p_code);
  perform public.quiz_touch(upper(p_code));
  return public.get_room_state(upper(p_code), v_name, p_token);
end;
$$;

create or replace function public.submit_answer(
  p_code text, p_display_name text, p_token text, p_answer integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s jsonb;
  arr jsonb;
  p jsonb;
  pos integer := -1;
  i integer := 0;
  v_hash text := public.quiz_token_hash(p_token);
  v_name text := public.quiz_clean_name(p_display_name);
  now_epoch double precision := extract(epoch from clock_timestamp());
  q jsonb;
  pts integer;
  deadline double precision;
  all_done boolean;
begin
  if v_hash is null or v_name is null then
    return jsonb_build_object('error', 'Invalid player session. Refresh and try again.');
  end if;
  if p_answer is null or p_answer not between 0 and 3 then
    return jsonb_build_object('error', 'Choose one of the four answers.');
  end if;
  select r.state into s from public.quiz_rooms as r where r.code = upper(p_code) for update;
  if s is null then
    return jsonb_build_object('error', 'Room not found.');
  end if;
  if s->>'phase' <> 'question' then
    return jsonb_build_object('error', 'This question is already closed.');
  end if;
  deadline := (s->>'deadline')::double precision;
  if now_epoch >= deadline then
    return jsonb_build_object('error', 'Time is up.');
  end if;

  arr := s->'players';
  for p in select x.value from pg_catalog.jsonb_array_elements(arr) as x(value) loop
    if pg_catalog.lower(p->>'name') = pg_catalog.lower(v_name) and p->>'token_hash' = v_hash then
      pos := i;
      exit;
    end if;
    i := i + 1;
  end loop;
  if pos < 0 then
    return jsonb_build_object('error', 'You are not in this room.');
  end if;
  p := arr->pos;
  if not coalesce((p->>'connected')::boolean, false) then
    return jsonb_build_object('error', 'Reconnect before answering.');
  end if;
  if p->'answer' is not null and p->'answer' <> 'null'::jsonb then
    return jsonb_build_object('error', 'Your answer is already locked.');
  end if;

  q := s->'questions'->((s->>'q_index')::integer);
  pts := case
    when p_answer = (q->>'correct_index')::integer
      then 100 + round(50 * greatest(0, least(1, (deadline - now_epoch) / 15)))::integer
    else 0
  end;
  p := jsonb_set(p, '{answer}', to_jsonb(p_answer));
  p := jsonb_set(p, '{points_earned}', to_jsonb(pts));
  p := jsonb_set(p, '{score}', to_jsonb(coalesce((p->>'score')::integer, 0) + pts));
  arr := jsonb_set(arr, array[pos::text], p);
  s := jsonb_set(s, '{players}', arr);

  select not exists (
    select 1 from pg_catalog.jsonb_array_elements(arr) as x(value)
    where coalesce((x.value->>'connected')::boolean, false)
      and (x.value->'answer' is null or x.value->'answer' = 'null'::jsonb)
  ) into all_done;
  if all_done then
    s := jsonb_set(s, '{phase}', '"reveal"'::jsonb);
    s := jsonb_set(s, '{reveal_at}', to_jsonb(now_epoch));
  end if;

  update public.quiz_rooms set state = s, updated_at = pg_catalog.now() where code = upper(p_code);
  perform public.quiz_touch(upper(p_code));
  return public.get_room_state(upper(p_code), v_name, p_token);
end;
$$;

create or replace function public.tick_room(p_code text, p_display_name text, p_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  s jsonb;
  arr jsonb;
  p jsonb;
  hostp jsonb;
  candidate jsonb;
  pos integer := 0;
  now_epoch double precision := extract(epoch from clock_timestamp());
  v_hash text := public.quiz_token_hash(p_token);
  v_name text := public.quiz_clean_name(p_display_name);
  qidx integer;
  all_done boolean;
  changed boolean := false;
  host_deadline double precision;
begin
  if v_hash is null or v_name is null then
    return;
  end if;
  select r.state into s from public.quiz_rooms as r where r.code = upper(p_code) for update;
  if s is null then
    return;
  end if;
  if not exists (
    select 1 from pg_catalog.jsonb_array_elements(s->'players') as x(value)
    where pg_catalog.lower(x.value->>'name') = pg_catalog.lower(v_name)
      and x.value->>'token_hash' = v_hash
  ) then
    return;
  end if;

  arr := s->'players';
  pos := 0;
  for p in select x.value from pg_catalog.jsonb_array_elements(arr) as x(value) loop
    if coalesce((p->>'connected')::boolean, false)
       and now_epoch - coalesce((p->>'last_seen')::double precision, 0) > 15 then
      p := jsonb_set(p, '{connected}', 'false'::jsonb);
      arr := jsonb_set(arr, array[pos::text], p);
      changed := true;
    end if;
    pos := pos + 1;
  end loop;
  s := jsonb_set(s, '{players}', arr);

  select x.value into hostp
  from pg_catalog.jsonb_array_elements(arr) as x(value)
  where x.value->>'id' = s->>'host_id'
  limit 1;
  if hostp is not null then
    if s->>'host_lost_at' is not null and s->>'host_lost_at' <> 'null' then
      host_deadline := (s->>'host_lost_at')::double precision;
    elsif not coalesce((hostp->>'connected')::boolean, false) then
      host_deadline := coalesce((hostp->>'last_seen')::double precision, now_epoch) + 60;
      s := jsonb_set(s, '{host_lost_at}', to_jsonb(host_deadline));
      changed := true;
    end if;

    if host_deadline is not null and now_epoch >= host_deadline then
      select x.value into candidate
      from pg_catalog.jsonb_array_elements(arr) as x(value)
      where x.value->>'id' <> s->>'host_id'
        and coalesce((x.value->>'connected')::boolean, false)
      order by (x.value->>'joined_order')::integer
      limit 1;
      if candidate is not null then
        s := jsonb_set(s, '{host_id}', to_jsonb(candidate->>'id'));
        s := jsonb_set(s, '{host_lost_at}', 'null'::jsonb);
        changed := true;
      end if;
    elsif host_deadline is not null and coalesce((hostp->>'connected')::boolean, false) then
      s := jsonb_set(s, '{host_lost_at}', 'null'::jsonb);
      changed := true;
    end if;
  end if;

  if s->>'phase' = 'question' then
    select count(*) > 0 and not exists (
      select 1 from pg_catalog.jsonb_array_elements(s->'players') as x(value)
      where coalesce((x.value->>'connected')::boolean, false)
        and (x.value->'answer' is null or x.value->'answer' = 'null'::jsonb)
    ) into all_done;
    if all_done or now_epoch >= (s->>'deadline')::double precision then
      s := jsonb_set(s, '{phase}', '"reveal"'::jsonb);
      s := jsonb_set(s, '{reveal_at}', to_jsonb(now_epoch));
      changed := true;
    end if;
  elsif s->>'phase' = 'reveal'
        and now_epoch - (s->>'reveal_at')::double precision >= 3 then
    qidx := (s->>'q_index')::integer;
    if qidx >= 14 then
      s := jsonb_set(s, '{phase}', '"final"'::jsonb);
      s := jsonb_set(s, '{deadline}', 'null'::jsonb);
    else
      qidx := qidx + 1;
      s := jsonb_set(s, '{q_index}', to_jsonb(qidx));
      s := jsonb_set(s, '{phase}', '"question"'::jsonb);
      s := jsonb_set(s, '{deadline}', to_jsonb(now_epoch + 15));
      s := jsonb_set(s, '{reveal_at}', 'null'::jsonb);
      arr := s->'players';
      pos := 0;
      for p in select x.value from pg_catalog.jsonb_array_elements(arr) as x(value) loop
        p := jsonb_set(p, '{answer}', 'null'::jsonb);
        p := jsonb_set(p, '{points_earned}', '0'::jsonb);
        arr := jsonb_set(arr, array[pos::text], p);
        pos := pos + 1;
      end loop;
      s := jsonb_set(s, '{players}', arr);
    end if;
    changed := true;
  end if;

  if changed then
    update public.quiz_rooms set state = s, updated_at = pg_catalog.now() where code = upper(p_code);
    perform public.quiz_touch(upper(p_code));
  end if;
end;
$$;

create or replace function public.request_rematch(p_code text, p_display_name text, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s jsonb;
  p jsonb;
  v_hash text := public.quiz_token_hash(p_token);
  v_name text := public.quiz_clean_name(p_display_name);
begin
  if v_hash is null or v_name is null then
    return jsonb_build_object('error', 'Invalid player session. Refresh and try again.');
  end if;
  select r.state into s from public.quiz_rooms as r where r.code = upper(p_code) for update;
  if s is null then
    return jsonb_build_object('error', 'Room not found.');
  end if;
  select x.value into p
  from pg_catalog.jsonb_array_elements(s->'players') as x(value)
  where x.value->>'id' = s->>'host_id'
  limit 1;
  if p is null or not coalesce((p->>'connected')::boolean, false)
     or p->>'token_hash' <> v_hash
     or pg_catalog.lower(p->>'name') <> pg_catalog.lower(v_name) then
    return jsonb_build_object('error', 'Only the connected host can request a rematch.');
  end if;
  if s->>'phase' <> 'final' then
    return jsonb_build_object('error', 'The current game is not finished.');
  end if;

  s := jsonb_set(s, '{phase}', '"waiting_rematch"'::jsonb);
  s := jsonb_set(s, '{deadline}', 'null'::jsonb);
  update public.quiz_rooms set state = s, updated_at = pg_catalog.now() where code = upper(p_code);
  perform public.quiz_touch(upper(p_code));
  return public.get_room_state(upper(p_code), v_name, p_token);
end;
$$;

create or replace function public.confirm_rematch(p_code text, p_display_name text, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s jsonb;
  arr jsonb;
  p jsonb;
  pos integer := 0;
  v_hash text := public.quiz_token_hash(p_token);
  v_name text := public.quiz_clean_name(p_display_name);
  now_epoch double precision := extract(epoch from clock_timestamp());
begin
  if v_hash is null or v_name is null then
    return jsonb_build_object('error', 'Invalid player session. Refresh and try again.');
  end if;
  select r.state into s from public.quiz_rooms as r where r.code = upper(p_code) for update;
  if s is null then
    return jsonb_build_object('error', 'Room not found.');
  end if;
  select x.value into p
  from pg_catalog.jsonb_array_elements(s->'players') as x(value)
  where x.value->>'id' = s->>'host_id'
  limit 1;
  if p is null or not coalesce((p->>'connected')::boolean, false)
     or p->>'token_hash' <> v_hash
     or pg_catalog.lower(p->>'name') <> pg_catalog.lower(v_name) then
    return jsonb_build_object('error', 'Only the connected host can start the rematch.');
  end if;
  if s->>'phase' <> 'waiting_rematch' then
    return jsonb_build_object('error', 'The room is not waiting for a rematch.');
  end if;
  if (select count(*) from pg_catalog.jsonb_array_elements(s->'players') as x(value)
      where coalesce((x.value->>'connected')::boolean, false)) < 2 then
    return jsonb_build_object('error', 'At least two players must be connected.');
  end if;

  arr := s->'players';
  for p in select x.value from pg_catalog.jsonb_array_elements(arr) as x(value) loop
    p := jsonb_set(p, '{score}', '0'::jsonb);
    p := jsonb_set(p, '{answer}', 'null'::jsonb);
    p := jsonb_set(p, '{points_earned}', '0'::jsonb);
    arr := jsonb_set(arr, array[pos::text], p);
    pos := pos + 1;
  end loop;
  s := jsonb_set(s, '{players}', arr);
  s := jsonb_set(s, '{questions}', public.quiz_pick_questions(s->'questions'));
  s := jsonb_set(s, '{q_index}', '0'::jsonb);
  s := jsonb_set(s, '{phase}', '"question"'::jsonb);
  s := jsonb_set(s, '{deadline}', to_jsonb(now_epoch + 15));
  s := jsonb_set(s, '{reveal_at}', 'null'::jsonb);
  update public.quiz_rooms set state = s, updated_at = pg_catalog.now() where code = upper(p_code);
  perform public.quiz_touch(upper(p_code));
  return public.get_room_state(upper(p_code), v_name, p_token);
end;
$$;

-- Helpers stay private. Only the client-facing, token-checked RPCs are executable by players.
revoke all on function public.quiz_clean_name(text) from public, anon, authenticated;
revoke all on function public.quiz_token_hash(text) from public, anon, authenticated;
revoke all on function public.quiz_pick_questions(jsonb) from public, anon, authenticated;
revoke all on function public.quiz_touch(text) from public, anon, authenticated;
revoke all on function public.get_room_state(text, text, text) from public, anon, authenticated;
revoke all on function public.create_room(text, text) from public, anon, authenticated;
revoke all on function public.join_room(text, text, text) from public, anon, authenticated;
revoke all on function public.player_heartbeat(text, text, text) from public, anon, authenticated;
revoke all on function public.start_game(text, text, text) from public, anon, authenticated;
revoke all on function public.submit_answer(text, text, text, integer) from public, anon, authenticated;
revoke all on function public.tick_room(text, text, text) from public, anon, authenticated;
revoke all on function public.request_rematch(text, text, text) from public, anon, authenticated;
revoke all on function public.confirm_rematch(text, text, text) from public, anon, authenticated;

grant execute on function public.get_room_state(text, text, text) to anon, authenticated;
grant execute on function public.create_room(text, text) to anon, authenticated;
grant execute on function public.join_room(text, text, text) to anon, authenticated;
grant execute on function public.player_heartbeat(text, text, text) to anon, authenticated;
grant execute on function public.start_game(text, text, text) to anon, authenticated;
grant execute on function public.submit_answer(text, text, text, integer) to anon, authenticated;
grant execute on function public.request_rematch(text, text, text) to anon, authenticated;
grant execute on function public.confirm_rematch(text, text, text) to anon, authenticated;


