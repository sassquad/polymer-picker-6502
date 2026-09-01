; ============================================================================
; Polymer Picker - machine-code engine memory map   (Milestone M0)
; ----------------------------------------------------------------------------
; The single source of truth for every fixed address the asm engine uses.
; INCLUDE this first in the engine build; reference the NAMES below, never the
; raw addresses, so the map can be re-tuned in one place.
;
; Target: BBC Model B / B+ (32K), gameplay screen MODE 2 (&3000-&7FFF, 20K).
;
; Addresses fall into three groups:
;   (A) INHERITED - already used by the current game (POLY2 asm / POLY4 setup).
;       These are fixed by existing code and reused verbatim.
;   (B) NEW       - homes for the POLY3 scalars that today live in BASIC's heap.
;       These we are free to place; grouped in reclaimed ZP &00-&6F.
;   (C) OS / hardware - standard entry points and screen constants.
;
; ABI NOTE (implemented at M1, stated here because it governs the map):
;   The engine is CALLed from BASIC and RTSes back for the hall-of-fame. It
;   reclaims BASIC's zero page &00-&6F for engine variables, so on entry it
;   must SAVE &00-&6F to a buffer and RESTORE it before RTS. &70-&7B (the
;   plotshape pointers) are already understood to be volatile across a CALL.
;
; DFS HAZARD RULES (hard-won; violating these caused sprite tearing, CPU
; jams and phantom BASIC errors during M2 bring-up):
;   1. &0E00-&18FF is LIVE DFS workspace. NEVER *LOAD or run engine code
;      there while the DFS is the current filing system - the DFS scribbles
;      on it (verified byte-level corruption of engine code). The shipping
;      game may only occupy &0E00+ after the POLY1-style *TAPE + relocate
;      dance. Development builds load at &1F00+.
;   2. &D00-&D5F (row_table home) is DFS/NMI workspace: build the row table
;      only AFTER every disc access, and install the &40 (RTI) guard at &D00.
;   3. Before CALLing the engine: wait ~2.5s for disc motor spin-down, then
;      CLOSE#0 and *TAPE. The original game's PROCstart does exactly this -
;      it is load-bearing, not legacy cruft.
;   4. BASIC's stack grows DOWN from HIMEM: set HIMEM=&2B00 (as the real
;      game does) or BASIC will nibble the top sprite (JELLY at &2F80).
; ============================================================================


; ============================================================================
; (C) OS entry points
; ============================================================================
osrdch          = &FFE0
osasci          = &FFE3
osnewl          = &FFE7
oswrch          = &FFEE
osword          = &FFF1
osbyte          = &FFF4
oscli           = &FFF7


; ============================================================================
; (C) Screen / hardware constants
; ============================================================================
screen_base     = &3000     ; MODE 2 screen start
screen_size     = &5000     ; 20K
screen_top      = &8000
mode_gameplay   = 2         ; VDU22,2
bytes_per_row   = 640       ; one character row (8 lines x 80 bytes) in MODE 2
sprite_base     = &2B00     ; SPRITES load address (MODE 2 format)


; ============================================================================
; (A) INHERITED zero page - plotshape pointers (from POLY2 .plotshape block)
;     Reserved and volatile; do not repurpose.
; ============================================================================
zp_addr         = &70       ; EQUW  working screen address
                            ; &71 high byte
zp_top          = &72       ; EQUW  = &3000
                            ; &73 high byte
;               = &74       ; notrowcounter (declared unused in POLY2)
zp_counter      = &75       ; EQUB  shape column counter
zp_temp         = &76       ; EQUB
zp_temp1        = &77       ; EQUB
zp_depth        = &78       ; EQUB  shape depth (bytes per column)
;               = &79       ; notshape EQUW (declared unused in POLY2)
;               = &7A
zp_offset       = &7B       ; EQUB
;   &7C-&8F  spare zero page (still language space, free while BASIC dormant)


; ============================================================================
; (B) NEW engine variables - reclaimed zero page &00-&6F
;     These replace POLY3's BASIC scalars. Grouped by subsystem. 16-bit values
;     are noted; everything else is a single byte.
; ============================================================================

; --- Diver (player) --------------------------------------------------- &00-&07
var_dx          = &00       ; D%   diver X   (1..67)
var_dy          = &01       ; e%   diver Y   (54..212)
var_facing      = &02       ; f%   0=left 1=right
var_speed       = &03       ; g%   1 normal, 2 fast
var_dx_old      = &04       ; erase/redraw previous X
var_dy_old      = &05       ; previous Y
var_facing_old  = &06       ; previous facing
;               = &07       ; diver scratch

; --- Shark ------------------------------------------------------------ &08-&0F
var_shk_dir     = &08       ; SD%  facing/frame (4/5/8)
var_shk_x       = &09       ; SX%
var_shk_y       = &0A       ; SY%  (60..195)
var_shk_vspeed  = &0B       ; V%   vertical closing speed
var_shk_dir_old = &0C       ; OA%
var_shk_x_old   = &0D       ; N%
var_shk_y_old   = &0E       ; j%
;               = &0F       ; shark scratch

; --- Air / oxygen ----------------------------------------------------- &10-&1F
var_air         = &10       ; O%   16-BIT  (~912..1224)   &10 lo / &11 hi
var_interval    = &12       ; M%   tick interval, centiseconds (50..200)
var_alarm_h     = &13       ; H%   low-air / bleed flag
var_alarm_k     = &14       ; K%   low-air alarm sounded flag
var_alarm_st    = &15       ; ST%  spare-tank state flag
;   &16-&1F  spare air/tank state

; --- Loop cursors & level counters ------------------------------------ &20-&2F
var_fish_cursor = &20       ; E%   which fish this tick (0..7)
var_jelly_cursor = &21      ; e    which jellyfish this tick (0..3)
var_level       = &22       ; l%   current level
var_items_left  = &23       ; P%   junk items remaining (0..8)
var_fish_left   = &24       ; L%   fish remaining alive (0..8)
var_item_sprite = &25       ; pl%  junk sprite id for this level
var_hurt        = &26       ; M3: bite/sting counter (PROCu-lite; observability)
var_rng         = &27       ; M3: 16-bit PRNG state  &27/&28
var_gameover    = &29       ; M4: 0 = playing, 1 = out of air, 2 = fish gone
var_hurtcd      = &2A       ; M4: ticks until the next 'ouch' may sound again
;   &2B-&2F  spare

; --- Sea-bed critter (PROCl: crab char 228 / shrimp char 229) ---------- &30-&37
; NOTE: this is NOT the boat. The boat is static level furniture drawn once at
; setup (POLY4 C$ VDU string, waterline) and never touched by the loop.
var_crit_x      = &30       ; cx%  16-BIT  (0..1260)      &30 lo / &31 hi
var_crit_x_old  = &32       ; oc%  16-BIT                 &32 lo / &33 hi
var_crit_col    = &34       ; co%  colour
var_crit_sprite = &35       ; cr%  sprite id
;               = &36
;               = &37

; --- Score ------------------------------------------------------------ &38-&3B
; NOTE: representation (binary-24 vs 4-byte BCD) is an OPEN M0 QUESTION.
; 4 bytes reserved either way; the display routine (PROCe, 6 digits) is decided
; alongside it. Reference as var_score regardless of the encoding chosen.
var_score       = &38       ; 4 bytes &38-&3B  (S%)

; --- General scratch -------------------------------------------------- &40-&5F
var_tmpA        = &40
var_tmpB        = &41
var_tmpC        = &42
var_tmpD        = &43
;   &44-&47  byte scratch
zp_ptr0         = &48       ; EQUW general 16-bit pointer   &48/&49
zp_ptr1         = &4A       ; EQUW                          &4A/&4B
zp_ptr2         = &4C       ; EQUW                          &4C/&4D
;   &4E-&4F  pointer scratch
;   &50-&5F  multiply / coordinate maths scratch

;   &60-&6F  spare (upper end of the reclaimed ZP block)


; ============================================================================
; (A) INHERITED fixed-address game arrays (from POLY4 setup)
;     Parallel byte arrays, index with X or Y:  LDA arr_fish_x,X
; ============================================================================
arr_fish_x      = &AB8      ; k%   fish X            (8)
arr_fish_y      = &AC0      ; n%   fish Y            (8)
arr_fish_state  = &AC8      ; q%   state/direction   (8)
arr_fish_vdelta = &AD0      ; t%   vertical delta     (8)
arr_fish_frame  = &AD8      ; F%   sprite/frame       (8)
arr_item_x      = &AE0      ; G%   junk X  == collision box X array  (8)
arr_item_y      = &AE8      ; J%   junk Y  == collision box Y array  (8)
arr_jelly_x     = &AF0      ; U%   jellyfish X        (4)
arr_jelly_y     = &AF4      ; zz%  jellyfish Y        (4)
arr_jelly_vel   = &AF8      ; jv%  jellyfish velocity (4)


; ============================================================================
; (A) INHERITED collision interface (from POLY2 .check / FNc)
;     check reads the box arrays arr_item_x/arr_item_y (&AE0/&AE8).
; ============================================================================
collide_x       = &AB0      ; input  X to test (STX &AB0)
collide_y       = &AB1      ; input  Y to test (STY &AB1)
collide_result  = &AB2      ; output box index hit, or negative if none


; ============================================================================
; (A) INHERITED tables and I/O addresses
; ============================================================================
key_table       = &100      ; redefinable keys, 5 bytes &100-&104
                            ; loop reads INKEY(-(key_table+n+1))
row_table_guard  = &D00     ; POLY4 sets this = 64
row_table       = &D01      ; screen-row high-byte table, 32 entries &D01-&D20
                            ; row_table[r] = (screen_base + r*bytes_per_row) DIV 256


; ============================================================================
; Engine debug interface (main RAM; poked by test harnesses or via the b2
; Debug HTTP API before/while the engine runs; survives save/restore_zp).
; Lives in the function-key buffer page &0B00 - NEVER inside the engine's own
; address range (an earlier &2500 placement collided with the grown engine
; image and the frame counter rewrote engine opcodes - hard-won lesson).
; ============================================================================
dbg_features    = &0B00     ; bit0 items, bit1 fish, bit2 shark, bit3 jelly
                            ; 0 is treated as &FF (all on) so a cold boot works
dbg_forcekeys   = &0B01     ; bit7 set: test_key ignores hardware; bits 0-4 =
                            ; pressed MASK (1=left 2=right 4=up 8=down 16=fast,
                            ; combinable). 0 = real keyboard
dbg_go          = &0B02     ; harness GO/abort handshake: harness zeroes it and
                            ; waits nonzero before CALL; engine exits when &FF
frame_count     = &0B03     ; EQUW frames run this session (peekable liveness)
dbg_divider     = &0B05     ; game ticks every N vsync frames (0 -> 1 = 50Hz);
                            ; live-pokeable pacing control until M6 retunes
dbg_divcnt      = &0B06     ; internal divider counter
dbg_result      = &0B07     ; why the engine exited: 0 = space/abort/safety,
                            ; 1 = out of air, 2 = all fish dead
dbg_hurtcd      = &0B09     ; game ticks between 'ouch' sound/blood events while
                            ; contact is sustained (0 -> default 10). The air
                            ; cost is NOT gated by this. Live-tunable.
dbg_sharkwin    = &0B08     ; shark front-on half-window, in D%-units (1 unit =
                            ; 2 pixels): front-on engages while the shark's
                            ; sprite centre is within this of the diver's.
                            ; 0 -> sanitized to the default 4. Live-tunable.
zp_savebuf      = &0B10     ; 112-byte hold for BASIC's ZP &00-&6F (to &0B7F)


; ============================================================================
; (A) INHERITED routine entry points
;     plotshape assembles at its load base; check follows it. In the engine
;     build these are provided as real labels by the routine module (the ported
;     POLY2 code), so downstream code should JSR plotshape / JSR check by name.
;     plotshape_base documents the historical load address for reference.
; ============================================================================
plotshape_base  = &900      ; historical .plotshape ORG (see POLY2)
