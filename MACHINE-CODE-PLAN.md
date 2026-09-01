# Polymer Picker — Machine-Code Conversion Plan

A plan for converting the per-frame game loop of Polymer Picker from BBC BASIC to
6502 machine code, to increase speed.

**Decisions locked in (2026-08-20):**

| Decision | Choice |
|---|---|
| Target hardware | BBC Model B / B+ (32K), no shadow RAM |
| Scope | Main game loop only — menus, instructions, redefine-keys and hall-of-fame stay in BASIC |
| Approach | Big-bang rewrite of the loop (write the asm engine, then switch over) |

---

## 1. Where the time actually goes

The game is already a hybrid. The pieces that people *usually* have to hand-code
in assembler — the sprite blitter and the collision test — you already wrote:

- `plotshape` (EOR sprite plotter, assembled to `&900`) — called as `CALL W%`.
- `check` / `FNc` (collision-in-box, assembled just after it) — called as `CALL Q%`.

Everything slow that remains is the **per-frame logic in POLY3**, still interpreted:

| Proc | Job | Cost |
|---|---|---|
| `PROCv` | Read player keys, move diver, oxygen-tank pickup, pause/sound keys | Every frame |
| `PROCm` | Fish AI: move each of 8 fish, wrap/steer, bite the diver | Every frame, ×8 |
| `PROCE` | Shark AI: home in on diver, bite | Every frame |
| `PROCcj` | Jellyfish drift + diver collision | Every frame |
| `PROCD` | Deplete air, spawn spare tank, low-air alarm | Every frame (time-gated) |
| `PROCl` | Scroll the boat | Every frame |
| `PROCd` | Thin wrapper: `CALL W%` (plot a shape) | Called many times/frame |
| `FNf`,`FNu`,`FNc` | Collision predicates | Called many times/frame |

**The conversion is: turn those procedures into one 6502 game-tick routine, keep
`plotshape`/`check` (lightly adapted), and leave the one-shot BASIC alone.**

---

## 2. The fact that makes big-bang realistic

Big-bang is risky when the state lives in the interpreter's variable heap. Here it
largely doesn't — POLY4 already pins the game arrays to fixed addresses:

```
k%=&AB8   fish X positions      (8 bytes)
n%=&AC0   fish Y positions      (8 bytes)
q%=&AC8   fish state/dir        (8 bytes)
t%=&AD0   fish vertical delta   (8 bytes)
F%=&AD8   fish sprite/frame     (8 bytes)
G%=&AE0   junk-item X (also collision box X array)  (8 bytes)
J%=&AE8   junk-item Y (also collision box Y array)  (8 bytes)
U%=&AF0   jellyfish X           (4 bytes)
zz%=&AF4  jellyfish Y           (4 bytes)
jv%=&AF8  jellyfish velocity    (4 bytes)
```

Plus: redefinable keys at `&100–&104`, sprite row-table at `&D01–&D5F`, collision
scratch at `&AB0–&AB2`. So a big fraction of the model is **already in a flat,
byte-addressable layout the asm can use as-is.**

What is *not* yet externalised — the scalars the asm loop will need homes for:

```
D%   diver X            e%   diver Y            f%   diver facing
O%   oxygen (air)       M%   tick interval      g%   speed (1 or 2)
P%   items left         L%   fish left          l%   level
S%   score              V%   shark vert speed    E%   fish cursor index
e    jellyfish cursor   pl%  item sprite id      SD%/SX%/SY% shark state
cx%/co%/cr% boat        H%/K%/ST% air-alarm flags
```

These become a small block of named zero-page / low-RAM variables in the asm build.

---

## 3. Memory map — the central constraint

The gameplay screen is **MODE 2** (`VDU22,2` in POLY3): 160×256, 8 colours
doubled to 16 with the flashing set, occupying **&3000–&7FFF (20K)**. (The title
screen is MODE 1 and the hall-of-fame is MODE 7, but those are off-loop BASIC.)
Everything else lives below &3000.

### 3.1 Current layout (BASIC build)

```
&0000–&008F  BASIC zero page (game uses &70–&7B for plotshape pointers)
&0100–&0104  redefinable key numbers      (overlaps 6502 stack low end — works today)
&0100–&01FF  6502 hardware stack
&0900–&0AAF  plotshape + check code + shape tables
&0AB0–&0AFF  collision scratch + fish/jelly/junk state arrays
&0D00–&0D5F  screen row high-byte table
&0E00 / &1100  PAGE (juggled; DFS workspace reclaimed after load)
&1100–~&2AFF  tokenised BASIC (POLY2/POLY3/POLY4) + BASIC variable heap
&2B00–&2FFF  SPRITES (loaded)                (~1.25K)
&3000–&7FFF  MODE 2 screen                   (20K)
```

### 3.2 Target layout (asm loop build)

Dropping the interpreter from the loop is a **net memory win**: you reclaim almost
all of zero page and the entire BASIC variable heap while the loop runs.

```
&0000–&008F  Engine zero page — free for you while BASIC is dormant (144 bytes).
             Reuse &70–&7B for plotshape as today; put the hot game
             variables (D%,e%,O%,pointers,loop indices) in &00–&6F.
&0090–&009F  spare
&00A0–&00FF  OS zero page — DO NOT TOUCH
&0100–&0104  key table (leave as-is; the loop reads it)
&0105–&01FF  6502 stack
&0200–&02FF  OS vectors / workspace — leave
&0900–&0AAF  plotshape + check + shape tables  (keep; called by the loop)
&0AB0–&0AFF  collision scratch + fish/jelly/junk arrays  (keep — reused verbatim)
&0B00–&0CFF  NEW: engine code and/or non-ZP variables (free real estate)
&0D00–&0D5F  row table (keep)
&0D60–&0DFF  spare
&0E00–&2AFF  NEW: main asm game-loop engine  (~7.4K budget for code + data)
&2B00–&2FFF  SPRITES  (unchanged, MODE 2 format)
&3000–&7FFF  MODE 2 screen  (unchanged)
```

**Budget headline: ~7.4K (`&0E00–&2B00`) for the whole asm engine, plus the
`&0900–&0CFF` scraps.** Hand 6502 for this much game logic is typically 3–6K, so it
should fit with room to spare — but this table is the thing to keep honest as code
is written, not to assume. Track the assembled size after every milestone.

### 3.3 Zero-page allocation (draft)

| Range | Use |
|---|---|
| `&00–&0F` | Diver: `D% e% f% g%` + old-position temps for erase/redraw |
| `&10–&1F` | Shark: `SD% SX% SY% V%` + temps |
| `&20–&2F` | Air/oxygen: `O% M% H% K% ST%` + tank spawn state |
| `&30–&3F` | Loop cursors: `E%` (fish), `e` (jelly), level `l%`, `P% L%` |
| `&40–&5F` | General 16-bit scratch for multiply / address maths |
| `&60–&6F` | Score `S%` (BCD or binary), boat `cx% co% cr%` |
| `&70–&7B` | **plotshape pointers — reserved, unchanged** |
| `&7C–&8F` | spare |

(Exact assignments finalised in the memory-map milestone, step 6.1.)

---

## 4. Frame timing — the part that will bite

Today the loop is paced by the centisecond clock: `M%` is an interval (200, then
100 when swimming fast), and `PROCD`/movement fire when `TIME` exceeds it. Remove
the interpreter and the loop runs **orders of magnitude faster** — without a new
timebase the game is unplayable. Two faithful options:

1. **Keep the centisecond throttle (identical feel).** At the top of each tick,
   read the system clock (OSWORD `&01`) or an interval timer and only advance game
   state when the elapsed time crosses the same `M%` thresholds. The extra CPU just
   idles. Lowest-risk; behaviour matches the current game exactly.
2. **Re-base to vsync (true 50 Hz), retune speeds.** Lock each tick to the frame
   with OSBYTE `&13` (wait-for-vertical-sync) and re-tune the movement/air constants
   so the game plays at the intended pace at 50 Hz. Smoother, but every speed
   constant (`g%`, `V%`, air-drain rate, spawn timing) must be re-balanced by hand.

**Recommendation:** build the engine loop with a `wait_frame` at the top from day
one (option 2's plumbing), but drive game-state advancement off the *existing*
`M%`/centisecond thresholds (option 1's semantics). That keeps timing behaviour
identical while giving you a clean vsync anchor to re-tune later if you want.

---

## 5. The BASIC ↔ ASM boundary

Menus, instructions, redefine-keys and hall-of-fame stay in BASIC (POLY1 mostly,
plus the score-entry procs in POLY3). Define a narrow, deliberate ABI:

- **Entry:** BASIC finishes setup exactly as now (character defs, envelopes, key
  table into `&100`, sprites loaded, arrays initialised), then `CALL <engine>`
  once. This replaces the body of `PROCstart`/the POLY3 `REPEAT…UNTIL0` loop.
- **During play:** the engine owns the machine. It calls OS routines directly for
  keys (OSBYTE `&81` — the negative-INKEY scan the loop already relies on), sound
  (OSWORD `7`), and screen writes (OSWRCH / direct screen pokes via `plotshape`).
- **Exit:** on game-over / new-high-score the engine `RTS`es back to BASIC with the
  final `S%`, `l%` etc. in known addresses, and BASIC runs the existing
  `PROCN/PROCO/PROCP` hall-of-fame + name entry, then loops back to the title.
- **Contract:** enumerate every byte the engine reads on entry and writes on exit.
  Because state is already at fixed addresses (§2), this list is short and mostly
  already exists.

Design implication: the BASIC side keeps building the game world; the engine is a
drop-in replacement for one `CALL`. That is what makes a "big-bang" of the *loop*
safe — the risky whole-program rewrite is explicitly **not** what we're doing.

---

## 6. Work breakdown (big-bang, but staged so each stage builds & runs)

Big-bang on the loop, yes — but stage the construction so there's always a
buildable `.ssd` and a way to A/B against the current game.

### 6.1 Foundation — memory map & data model  ✅ DONE (M0)
- Frozen as [`src/memorymap.asm`](src/memorymap.asm) — a BeebAsm include of named
  labels for every fixed address, verified to assemble clean. Every later stage
  references these names, never raw addresses.
- Fixed-address arrays (§2) adopted unchanged as `arr_*` symbols.
- Score representation (binary vs BCD) left as an open question; 4 bytes reserved
  at `var_score` either way.
- Recorded the entry/exit ABI rule in the include header: engine saves/restores
  reclaimed ZP `&00–&6F` around the `CALL` so BASIC survives the return.

### 6.2 Skeleton engine  ✅ DONE (M1)
- [`src/engine.asm`](src/engine.asm): `engine_start` saves ZP `&00–&6F`, then
  `main_loop` = OSBYTE 19 frame-lock + OSWORD 1 centisecond gate; `game_tick` is an
  empty placeholder (bumps a counter, prints a heartbeat marker); a tick-count limit
  stands in for "game over" and drives `restore_zp` + `RTS` back to BASIC.
- Assembles clean; loads at `&0E00`; **260 bytes, 7164 bytes headroom** to the
  `&2B00` sprite boundary.
- Verified by a throwaway BASIC harness (`MODE 2`, `*LOAD ENGINE`, time the `CALL`,
  assert elapsed ≈ ticks × interval → `TIMING: PASS`). Runtime is visual in b2.
- The real per-level intervals (200/100/50 cs) replace the M1 placeholders at M3–M4.

### 6.3 Port the procedures (one 6502 subroutine each)
Suggested order — cheapest/most-isolated first, so each can be tested against the
BASIC version by swapping one `JSR` in:

1. **`PROCl` sea-bed critter scroll** (crab/shrimp — *not* the boat, which is
   static level furniture drawn once at setup) — trivial; good ABI shakedown.
2. **`PROCd`/`FNf`/`FNu`/`FNc` wrappers** — these are already `CALL`s; in asm they
   become plain `JSR plotshape` / `JSR check`. Removes the interpreter tax on the
   most-called operations immediately.
3. **`PROCv` player movement** — key reads (OSBYTE `&81`), bounds, erase-then-draw
   diver, oxygen-tank grab, pause/sound toggles.
4. **`PROCcj` jellyfish** — 4-entry drift + collision, uses `U%/zz%/jv%`.
5. **`PROCm` fish AI** — the big one: 8-entry loop, steering, wrap, bite. Port the
   `q%`/`t%`/`F%` state machine faithfully.
6. **`PROCE` shark AI** — homing + bite.
7. **`PROCD` air model** — time-gated drain, spare-tank spawn, low-air alarm sound.
8. **Level flow** — end-of-level bonus (`PROCF`/`PROCM`/`PROCp`), advance `l%`.

### 6.4 Integration & cutover
- Replace the POLY3 `REPEAT…UNTIL0` body with the single `CALL <engine>`.
- Keep the BASIC procs only for the off-loop screens.
- Remove now-dead BASIC (fish/shark/jelly procs) once the asm equivalents are in.

### 6.5 Retune & polish
- If going true-50 Hz (§4 option 2), rebalance speed/air constants.
- Reclaim freed RAM; confirm the size budget (§3.2).

---

## 7. Data-structure conversion notes

- **Parallel byte arrays** (`k% n% q% t% F%` …): index with `X`/`Y`; `LDA k%,X`.
  This is *why* the current design pre-flattened them — it was built for this.
- **Signed deltas**: `t%?E%-6` and `q%?E%-2` (BASIC) are bias-encoded signed steps.
  Preserve the bias in asm (add/subtract the constant) rather than reworking the
  encoding, to keep behaviour bit-identical.
- **`FNc`/collision boxes** already store box arrays at `&AE0/&AE8` and answer via
  `&AB2`; the asm loop calls `check` and reads `&AB2` exactly as `FNc` does.
- **Screen addressing & pixel format**: gameplay is **MODE 2** (2 pixels/byte,
  interleaved 4-bits-per-pixel). `plotshape` already encodes this layout and derives
  screen addresses from the `&D01` row table, and the sprite `.bin` files are already
  in MODE 2 format — reuse both verbatim; do not reinvent the address/pixel maths or
  assume a MODE 1 (4-pixels/byte) layout.
- **Score display** (`PROCe`, 6 digits): needs a binary/BCD → digits routine; the
  one non-trivial new piece of pure arithmetic.

---

## 8. Risks & gotchas

- **THE DFS RULES (learned the hard way at M2 — mandatory).** Violating any of
  these produced sprite tearing, garbage draws, CPU jams and phantom BASIC
  errors, with symptoms that shape-shifted between builds:
  1. `&0E00–&18FF` is live DFS workspace. Never `*LOAD` or execute engine code
     there while DFS is the active filing system — the DFS corrupts it (verified
     byte-level: opcodes rewritten, table entries zeroed). Development builds
     load at `&1F00`. The shipping build may occupy `&0E00+` only after the
     POLY1-style `*TAPE` + relocate dance — that code is load-bearing.
  2. Launch protocol before `CALL`: wait ~2.5 s for disc-motor spin-down, then
     `CLOSE#0` and `*TAPE`.
  3. Row table (`&D00–&D20`) built only after all disc access, with the `&40`
     (RTI) guard at `&D00` (NMI entry).
  4. Set `HIMEM=&2B00` in the hosting BASIC (as the real game does) or BASIC's
     stack, which grows down from HIMEM, nibbles the JELLY sprite at `&2F80`.
  Debug workflow note: b2 Debug's HTTP API (port 48075: `peek/b2/BEGIN/END`)
  reads emulated RAM directly; screen text is decodable by matching cells
  against the OS 1.20 ROM font (first &300 bytes of `OS12.ROM` in the b2
  bundle). This turns emulator verification into a closed loop with no
  screenshots — used to prove the residue-0 result.

- **`&100–&104` vs the stack.** The key table lives in the bottom of the 6502 stack
  page and works today because the stack never descends that far. The asm loop must
  keep stack use shallow (it will — no deep recursion) so this stays true. Noted so
  it's a conscious constraint, not an accident.
- **Size creep.** 7.4K is comfortable but not infinite. Measure after each stage
  (§6). If it ever tightens: the menu/instruction text is the first thing to move
  or compress, not the engine.
- **OS zero page.** Anything the loop calls (sound, keys, clock) uses `&A0–&FF`.
  Keep engine ZP in `&00–&8F` and never assume ZP survives across an OS call unless
  it's in your reserved range.
- **Timing regressions.** The single most likely "it feels wrong" bug. Lock the
  timebase (§4) *before* porting AI, so every ported proc is judged at correct pace.
- **Sound/envelope parity.** Envelopes are set up once in BASIC (`PROCenv`); the asm
  loop only needs to fire `SOUND` (OSWORD 7) with the same parameters the BASIC
  `SOUND` calls use. Copy the parameter blocks exactly.

---

## 9. Build & test workflow

- Toolchain stays **BeebAsm** — you already assemble asm into the `.ssd` this way.
  Add the engine as another `ORG &0E00 … SAVE "ENGINE"` block loaded like `SPRITES`.
- The README's `basictool` compression pain **goes away** for everything ported —
  another reason to move the loop out of BASIC.
- Test in **b2** (you already have `testinb2.sh`). Keep the current released `.ssd`
  as the reference build; A/B each ported proc against it.
- Regression checks per stage: level 1 playthrough, fast-swim air drain, spare-tank
  spawn at ~50% air, shark bite, jellyfish sting, end-of-level bonus, game-over →
  high-score entry → back to title.

---

## 10. Milestones

1. **M0 — Memory map frozen.** ✅ `src/memorymap.asm`, assembles clean. No behaviour change.
2. **M1 — Skeleton engine runs.** ✅ `src/engine.asm`, 260 bytes; timed loop + ABI + RTS to BASIC.
3. **M2 — Draw/collision on asm.** ✅ `src/gfx.asm` (plotshape/check, verbatim from
   POLY2); engine draws + moves diver and scrolls the sea-bed critter. 922 bytes at
   `&1F00`. Verified under sustained real key input: 750-frame runs, screen-residue
   count = 0 (every EOR draw perfectly cancelled). See §8 for the DFS rules this
   bring-up uncovered — they are mandatory for all future milestones.
4. **M3 — Enemies on asm.** ✅ Items (PROCg + pickup via `check`), fish
   (PROCf/PROCm/PROCL: swim, bounds, eat, die, sink-and-settle at n=48), shark
   (PROCs/PROCE homing + facing + bite), jellyfish (PROCj/PROCcj bounce + sting),
   PROCu-lite (hurt counter + bleed splash; sound/air are M4), seeded PRNG.
   Engine 2.3K at `&1F00`, build-time ASSERT guards the debug page (&0B00)
   against overlap with the image. Verified via HTTP-driven autopilot: all 8
   items vacuumed by a scripted diver; 45s all-systems soak crash-free with
   invariant checks (positions/states/shapes in bounds, 0 violations).
   Known M6 item: full load runs at ~25 fps (2 vsyncs/tick) — tune later.
   Documented divergence: dead fish can no longer "eat" (latent shape-table
   overrun in the BASIC original).
   **Author-approved tuning (interactive session, 2026-09-01):**
   - Game pace: tick divider = 4 (12.5 game-ticks/s, vsync-locked) judged
     "just right" vs the BASIC original — this is the M6 baseline.
   - Jellyfish: serviced every frame at quarter-steps (same net speed classes
     ±4/8/12/16, 4× finer motion) — deliberate machine-code-era enhancement,
     author-requested and approved.
   - Occasional sprite flicker (raster vs draw timing) noted and deferred to
     M6 (draw ordering / vsync phase), explicitly not a priority now.
5. **M4 — Air & level flow on asm.** ✅ Air drain (PROCD) with the M% fast-swim
   coupling, spare tank spawn/grab (PROCJ), full PROCu (air cost + sound), sound
   via OSWORD 7 with the original envelopes installed by the engine (OSWORD 8),
   BCD score + PROCe/PROCB HUD, air bar with warning-colour switch, end-of-level
   bonuses (PROCM hearts, PROCp air-to-score), level advance, and both game-over
   conditions with a result code for BASIC. gfx.asm moved to its production
   &900; engine at &1C00 (dev), 3.8K.
   **Bug found in play by the author and fixed:** `play_snd_ptr` (OSWORD)
   clobbered Y while `du_pickup` held the item index there — the item never
   erased and re-collected every tick, completing the level instantly. Sound
   helpers now preserve X/Y; state mutation happens before effects. Verified:
   8 collections, each one step, boxes consistent.
   **Shark facing improved on author feedback:** the original compares sprite
   LEFT EDGES (`D%-8 < SX% < D%+8`), but the front-on sprite (FSHK, 8 units) is
   half the width of the side sprites (16 units), so front-on engaged with the
   shark's centre up to 18px left / 10px right of the diver's. The port now
   compares sprite CENTRES (side `SX+8`, front `SX+4`, diver `D%+6`) with a
   tunable half-window `dbg_sharkwin` (&0B08, default 4 units = 8px), shifts SX
   by 4 units on a state change to preserve the visible centre (the original
   shifted 8, i.e. double, causing a visible jump), and uses mouth offset 4 for
   FSHK so it comes to rest exactly centred. Measured: engages at +/-8px,
   settles at 0px, flips back to the correct side sprite when the diver
   outruns it.
   **'Ouch' feedback rate-limited (author feedback):** with the shark now
   resting centred, `FNf` hits every tick, so `hurt` queued ~12 notes/sec into
   the OS sound buffer and the bite sound droned on after contact ended. The
   sound and blood splash are now gated by `var_hurtcd` (reload from
   `dbg_hurtcd`, &0B09, default 10 ticks ~ 0.8s); the AIR COST is deliberately
   left per-tick so sustained contact still punishes. Measured: 251 contact
   ticks produced 29 sounded events (8.7x fewer).
   Two hazards fixed alongside: the dev harness set `HIMEM=&2B00`, putting
   BASIC's downward-growing stack on top of the engine's last bytes (now
   `HIMEM=&1C00`, below the engine); and `bar_full` was rewritten as a
   table-driven `vdu_seq` call, saving ~90 bytes.
   **BCD score carry bug (author feedback: "air-left bonus does not increase
   the score"):** `score_add`'s ripple did `CPX #3 : BCS ... : ADC #0`, but CPX
   clobbers the carry, so every hundreds carry was silently dropped - the score
   oscillated (001650 -> 001600 -> 001650) instead of climbing, and this hit
   the heart bonuses and any pickup crossing a hundred boundary too. The ripple
   now uses an explicit `CLC : ADC #1` after the bounds check. Verified: the
   air bonus scores exactly 50/step (30 steps = 1500), and carries across both
   009950->010150 and 099900->100100.
6. **M5 — Cutover.** ✅ DONE.
   **Done — the architecture works end to end:**
   - Engine relocated to its production home `&0E00`, BASIC moved up to
     `PAGE=&2000`. Because `&0E00` is live DFS workspace, BASIC stages the
     engine in screen RAM (`&5000`), waits for spin-down, `CLOSE#0`, `*TAPE`,
     then block-copies it down with a 33-byte page copier at `&0A00`.
     Verified byte-perfect after relocation (only runtime data differs).
   - BASIC↔engine ABI (documented in engine.asm header): IN `dbg_level`,
     `dbg_newgame`, `key_table`; OUT `dbg_result` (0 abort / 1 out of air /
     2 fish gone / 3 level complete) and `var_score`. The score moved OUT of
     zero page to `&0B0C` so it survives the engine's ZP save/restore and can
     be read by the hall-of-fame.
   - **Scenery stays in BASIC** (author's decision): the engine returns on
     level completion and BASIC paints the next level — palette, sky circles
     (PROCc), hills (PROCH), seagrass, coral, seabed, boat — then re-CALLs.
     The engine's own level re-init block was removed (~1.5K freed).
   - UDGs moved from 21 `VDU23` statements into a binary blob loaded straight
     to the `&0C00` UDG page.
   - Verified: levels 1→2→3→4 with fresh scenery each time and the score
     accumulating across them (0 → 1850 → 4250 → 7100).
   **Fidelity fixes from author side-by-side comparison with the original:**
   - `PROCo` blacks all 16 logical colours before painting scenery and restores
     them via `G$`, which contains a **`VDU 20`** (restore default palette)
     before its specific overrides. Without it every sprite drawn in logical
     1-7 rendered black.
   - The seabed needed all of `B$;I$`, not just `I$`: `B$` fills rows 27-31
     with logical 15 then overpaints 27-28 with logical 4, giving the sand its
     backing and the HUD its black strip.
   - Texture chars 242-247 are generated randomly at RUN TIME in POLY1, not
     fixed art, and the strip uses a specific 40-character sequence.
   - `PROCB` prints `D$` first, which selects background logical 15 for the HUD
     row and prints the "Air" label - both were missing.
   - **Spawn rule restored:** POLY3 line 1 gives `l%>6` fish AND shark, odd
     levels fish only, even levels shark only (which is why PROCB's fish
     counter is conditional). The engine spawned both on every level. Now
     `var_active` = `dbg_features` masked by the level rule, and every
     subsystem gate consults it.
   **Chain wired (M5 complete):** POLYSCR (title) → POLY1 (menu, instructions,
   redefine-keys) → POLY3 (scenery, level flow, hall of fame) ↔ ENGINE.
   POLY2 and POLY4 are retired: plotshape is now the GFX binary and the
   variable setup moved into the engine and POLY3.
   Final memory map below the MODE 2 screen:
     `&0900` GFX · `&0A00` COPY · `&0C00` UDG · `&0E00-&1CD1` ENGINE
     · `&1D00-&2888` POLY3 (632 bytes for variables) · `&2B00` SPRITES
   The engine image carries the level tables at fixed addresses (`&0E03`
   levels, `&0EAB` seabed, `&0ED3` tunes, `&0EE8` game-over tune) because
   BASIC `DATA` text costs roughly three times the binary, and BASIC is the
   scarcer space - moving them freed ~460 bytes.
   Hall of fame ported verbatim (PROCh/PROCN/PROCO/PROCP) reading the score
   from `var_score`; one new bug found and fixed - the score had to be zeroed
   at startup or the first hall of fame read cold RAM and demanded a name.
7. **M6 — Retune & reclaim.** Timebase finalised, constants rebalanced, size booked.

---

## Open questions to settle at M0

- Timebase: keep centisecond throttle, or move to true 50 Hz and retune? (§4)
- Score storage: binary or BCD? (affects §7 display routine)
- Do we keep the `*TAPE`/`CALL&50` relocation trampoline from `PROCstart`, or load
  the engine as a plain file like `SPRITES`? (Cleaner to do the latter.)
