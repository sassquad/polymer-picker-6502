# Polymer Picker — Next Features Plan (post-v2.00)

This plan covers the four enhancements floated after the v2.00 machine-code
conversion merged to `main`. It follows the same iterative,
verify-then-playtest rhythm as [MACHINE-CODE-PLAN.md](MACHINE-CODE-PLAN.md), and
milestone numbering continues from there (M0–M6 were the conversion; features
start at M7).

---

## The governing constraint — read this first

The engine assembles to **3837 bytes, `ORG &0E00` … ending at &1CFD**. BASIC's
`PAGE` for POLY3 sits at **&1D00**, so there are **3 free bytes** below it. The
engine cannot grow:

- **up** — it hits BASIC at &1D00;
- **down** — it hits the row table at &0D00 and the UDGs at &0C00.

Every feature below needs code, and there is effectively **no inline headroom**.
So this is not "add four features" — it is "reclaim a code budget, then spend it
deliberately." That is why **M7 is a space-reclamation milestone** and nothing
else starts until it reports a real byte budget.

Three structural facts from the current code shape the features:

1. **Junk items are static.** `arr_item_x/arr_item_y` (&AE0/&AE8) are written
   once at level setup and only erased/redrawn on collection (`item_draw`,
   which preserves Y). There is **no per-tick item motion today** — the sea
   current is genuinely new movement code, but `item_draw` is a ready-made
   erase/redraw primitive to build on.
2. **All input funnels through `test_key`** (with the `dbg_forcekeys` puppet
   path). That is the single seam for a joystick, and the puppet path is
   dev-only scaffolding that can part-fund the joystick's code.
3. **Between-level flow already returns to BASIC** (`dbg_result=3` → `do_exit`
   → BASIC paints the next level). The bonus round slots in as a
   BASIC-orchestrated phase, not a bolt-on inside the play loop.

**The DFS hazard still rules everything** (see the rules in
[memorymap.asm](src/memorymap.asm)): while the engine occupies &0E00 and the
game is running under `*TAPE`, **you cannot do disc I/O** — DFS scribbles
&0E00–&18FF and would shred the engine. Any feature that wants to *load*
something mid-game (notably the bonus-round graphic) must do so while DFS is
safe, i.e. during a BASIC phase before the relocate, not from inside the loop.

---

## Milestone sequence

| #  | Milestone | Rationale for position | Test approach |
|----|-----------|------------------------|---------------|
| **M7** | Reclaim & measure | Nothing lands without headroom; no behaviour change | Byte-identical checks on unaffected segments; report free-byte count |
| **M8** | Sea current | Most self-contained, highest visible payoff, cheapest | Poke current strength, observe |
| **M9** | Joystick | Independent of the others; input seam already exists | b2 gamepad *if supported*, else poke ADC over HTTP |
| **M10** | Sprite flipping | Enabler for the bonus graphic, **not** an end in itself; only if M11 needs the sprite RAM | Visual + pixel-address verification |
| **M11** | Bonus round | Largest, depends on freed space, needs the design sketch | Poke into bonus state directly |

Each milestone stays small, is verified in the emulator, and is then playtested
by Stephen — the division of labour that found every gameplay bug in M4–M6.

---

## M7 — Reclaim & measure  *(enabler, no behaviour change)*

**Goal:** turn 3 free bytes into a known, usable budget, and decide whether the
feature set fits inline or needs an overlay scheme.

**Reclaim candidates (dev-only scaffolding):**
- The `dbg_forcekeys` puppet path in `test_key` — keep the *hook point* for the
  joystick (M9), but the "puppet the diver from a poked mask" branch is a test
  aid, not shipping behaviour.
- Any remaining M1-era safety/abort remnants and unused debug knobs.
- Dead data / duplicated table bytes surfaced by the audit.

**Keep:** the live-tunable *gameplay* knobs Stephen uses (`dbg_tankdepth`,
`dbg_sharkwin`, `dbg_hurtcd`) and `dbg_features` (used at init). These are
tuning tools, not scaffolding.

**Deliverable:** a measured free-byte count (same `PRINT engine_end` method used
here) and a go/no-go on whether M8–M10 fit inline. If they don't, M7 also
proposes the overlay/bank approach (feature code staged and relocated like the
engine itself, only ever loaded while DFS is safe).

**Verification:** the byte-identical segment method — build to scratchpad, md5
every disc segment against the current baseline; only the engine should change.

---

## M8 — Sea current  *(first feature)*

**Behaviour:** the 8 junk items drift with a per-level current; "still" to
"quite rough". Recommended model: **water-tank bounce**, not wrap — a per-item
signed velocity that flips sign at the tank walls. Bounce is a cheap sign-flip,
avoids EOR half-sprite artefacts at the screen edge, and matches the tank
metaphor. The diver gets a lighter coupled drift once the current variable
exists.

**Cost:** ~150–250 bytes: a per-tick pass (erase via `item_draw` → add signed
current → clamp/bounce → redraw) plus a current-strength byte, set per level and
live-tunable via the debug page.

**Open choices to settle in-milestone:** does the current also nudge fish, or
only junk + diver? Per-item independent velocity vs. one global drift?

**Test:** poke current strength and watch items move — no play needed.

---

## M9 — Joystick  *(Xbox controller)*

**Approach:** read the BBC analogue joystick (`ADVAL` / OSBYTE 128, ADC
channels) inside `test_key`, deriving the same left/right/up/down/fast/fire the
key path derives, with a centre deadzone. Selection between keys and stick via a
config/debug flag.

**Cost:** ~100–200 bytes, partly offset by the puppet-path reclaim in M7.

**Research spike (do before committing the milestone):** confirm whether **b2
maps a host Xbox pad to the BBC analogue port**. If yes, Stephen can test on the
pad directly. If no, we test by poking ADC readings over the HTTP API (the
established "poke state, don't simulate play" workflow) — the feature is still
fully verifiable.

---

## M10 — Sprite flipping  *(only if M11 needs the room)*

**The counter-intuitive part:** flipping saves *sprite* RAM (the &2B00–&2FFF
right-facing copies of diver/fish/shark, ~500 bytes) but **costs engine RAM**
(the flip routine + per-plot CPU). Engine RAM is the bottleneck, so flipping for
its own sake makes the tight problem *worse*. Its real justification is freeing
sprite space **for the bonus-round graphic** — hence its position after the
current and joystick, and gated on M11 actually needing it.

**MODE 2 wrinkle:** a horizontal flip must reverse column order **and** swap the
two pixels packed in each byte (a fixed bit-permutation, cheapest as a 256-byte
lookup — which itself costs space). This is why it is not a free "just flip it"
and is scheduled deliberately, not early.

**Test:** visual, plus pixel-address verification that a flipped sprite lands
where its mirror should.

---

## M11 — Bonus round  *(design spike first, build last)*

**Concept:** a large sea animal (e.g. a whale shark) draped in nets; the diver
must touch each net piece to free it. The rubbish-collection mechanic extends
directly — net pieces are collision boxes in `arr_item_x/arr_item_y`, tested by
`check`, up to 8 at a time.

**The memory answer:** the animal graphic is a **MODE 2 screen loaded into the
middle third of the gameplay screen as a single-colour image** (Stephen to
produce). It therefore does **not** need separate storage — it *is* the visible
screen. Net pieces are sprites/UDGs plotted on top; freeing them is EOR-erase
plus a `check` hit, exactly like junk.

**The load-timing problem to design around:** loading that MODE 2 image into
screen memory is disc I/O, and disc I/O is forbidden while the engine is live at
&0E00 under `*TAPE` (DFS hazard). So the bonus graphic must be brought in during
a **BASIC phase with DFS safe** — either loaded once at boot and kept resident,
or loaded as part of a between-level transition before the `*TAPE` relocate, or
the bonus round runs as its own relocated code phase orchestrated from BASIC.
Resolving *when* the image loads is the core of the design spike.

**Dependencies:** needs Stephen's sketch (framing + the actual MODE 2 image),
and may need M10's freed sprite space depending on how many net pieces and how
large.

**Test:** poke directly into bonus state (nets remaining, diver position)
rather than playing through a level to reach it.

---

## What is still needed from Stephen

1. **Bonus-round sketch + the MODE 2 image** (middle-third, single colour) — for
   M11 only; no rush.
2. Nothing else to start — M7 can begin now.

Deferred/decided:
- Fresh branch off `main`: **done** (`claude/next-features-plan`).
- Milestone order: **approved**.
- b2 Xbox-pad support: to be confirmed as the M9 spike, not a blocker for M7/M8.
