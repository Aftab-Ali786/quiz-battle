# Quiz Battle

A colorful, phone-friendly multiplayer trivia game. Players join a shared room from a browser, choose a name, and compete in three rounds. The game uses Supabase Postgres and Realtime; room state, timing, answers, scoring, and progression are controlled by database functions.

## Complete game rules

- A room supports 2–8 player entries. The room creator is host. An eight-character room code and invite link let other people join without accounts or installation.
- Each player uses a trimmed 2–16 character display name, unique inside that room. Names can be reused in other rooms. A duplicate name gets a clear error unless the player proves ownership with their private reconnect key. A returning player on the same device uses the key saved in that browser; for another device, they must enter the key copied from their original session. Room code and name alone never grant access to a stored score.
- The host can start after at least two players have joined. Each game contains 3 rounds of 5 questions, 15 total.
- Each question has four labeled choices (A–D) and one correct answer. Question topics are mixed across science, history, geography, sports, technology, entertainment, and nature. The included bank has a selection of clear general-knowledge questions. Questions are selected without repeats within a game; rematches exclude the previous game's questions.
- The shared database clock sets a 15-second deadline. The browser displays the remaining time using the server clock offset. A player can submit once; the server rejects a second or late answer.
- A correct answer earns 100 points plus a speed bonus calculated by rounding `50 × remaining_seconds ÷ 15` to the nearest whole point (0–50). Incorrect, late, or unanswered questions earn 0.
- A question ends when every connected player answers, or when 15 seconds elapse. Disconnected players do not block the group. The correct answer and leaderboard are then shown for 3 seconds before the next question starts automatically.
- After all 15 questions, the final leaderboard shows the winner. All players tied for the highest score are co-winners; no tiebreaker is added.
- On the final screen, only the host can request a rematch. Everyone sees a waiting state. The host must separately confirm; that action resets scores, selects 15 new questions, and starts the game in the same room. At least two players must be connected to confirm.
- A player who loses connection remains in the room. Their unanswered question scores zero. Rejoining with the same room code, display name, and private reconnect key restores their entry and score. The key is saved in the browser and can be copied using the in-game “Copy reconnect key” button. A player can answer a current question only while its original deadline is still open and if they have not submitted already. If the key is lost, the existing identity cannot be recovered securely from only a public room code and name.
- A disconnected host keeps their role reserved for 60 seconds from their last server heartbeat. If they return in time, they resume hosting. Otherwise, hosting passes to the longest-tenured connected player. The same rule applies to a replacement host. Host changes are announced in the room. Disconnects do not pause or reset game progress.

## Technical plan

- `index.html`, `styles.css`, and `app.js` make a static site that works in current desktop and mobile browsers.
- `supabase-setup.sql` creates the question bank, private room-state table, Supabase Realtime Broadcast invalidations, and server-authoritative Postgres functions. Room state (including correct answers and player tokens) is not directly readable by browser clients. Each client RPC checks a per-player secret token; no room-state table is readable by browser clients. Reconnect keys are random UUID v4 values, stored only as SHA-256 hashes in the database, and must be kept private.
- Browsers receive a room-scoped Broadcast invalidation containing only a revision number, then call the authorized `get_room_state` RPC for a filtered view. The correct answer is omitted until the reveal phase.
- Database row locks serialize room changes. Server timestamps decide answer deadlines and scores. Repeated submissions, conflicting starts, and competing transitions are rejected or serialized.
- A heartbeat marks a device online. The database timer advances the game and handles host transfer even if the host leaves.
- The Supabase URL and public publishable/anon key go in `app-config.js`. Do not put a service-role key in browser code.
- `README.md`, this SQL file, and the three site files form the deployable static site. Hosting options include Cloudflare Pages, Netlify, or Vercel.

## Set up the real shared backend

1. Create a Supabase project at [supabase.com](https://supabase.com). Choose a database password and region, then wait until the project is ready.
2. In Supabase, open **SQL Editor → New query**. Open `supabase-setup.sql` from this folder, copy the full contents into the query, and click **Run**. The script is safe to rerun; question prompts are unique.
3. In **Project Settings → API**, copy the **Project URL** and the **publishable key** (older projects may call it the `anon` key).
4. Edit `app-config.js` and paste those two values into `supabaseUrl` and `supabaseAnonKey`. Save the file. The key is public and the SQL functions restrict game access by room and player token. Never paste the `service_role` key.
5. Serve the `outputs` folder locally or publish its contents to a static host. Open the site in two separate browser sessions, create a room in one, join it from the other, and play through 15 questions. Use separate names.

## Publish a public URL

The static site can be hosted by Cloudflare Pages, Netlify, or Vercel. Create a site from the `outputs` folder (or a repository containing its files), set the publish/output directory to `outputs` if the repository includes the whole project, and deploy. The host supplies a public HTTPS URL; share that URL with `?room=CODE` to invite players.

A real public deployment needs a Supabase project URL/key and access to a hosting account. Those credentials are intentionally not checked into this folder. Deployment and live multi-device play have not been verified until the project is configured and the deployed site has been exercised in separate browser sessions.

## Local static preview

From this folder run:

```powershell
python -m http.server 8000 --directory outputs
```

Then open `http://localhost:8000`. Without Supabase settings the page explains that backend setup is required; the game does not pretend to be multiplayer without its shared server.




