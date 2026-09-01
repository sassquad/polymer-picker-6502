; ============================================================================
; Polymer Picker - machine-code game engine
; ----------------------------------------------------------------------------
; The per-frame game loop, ported from POLY3. BASIC keeps the title screen,
; instructions, redefine-keys, hall-of-fame AND the per-level scenery; this
; engine owns everything that runs every frame.
;
; ---- M5 ABI (BASIC <-> engine) ---------------------------------------------
; BASIC paints the scenery for the level, then sets and CALLs:
;   IN   dbg_level    (&0B0A) level number to play
;        dbg_newgame  (&0B0B) 1 = new game (zero the score), 0 = continue
;        key_table    (&0100) 5 redefinable key numbers
;   OUT  dbg_result   (&0B07) 0 = aborted (SPACE/safety), 1 = out of air,
;                             2 = all fish dead, 3 = level complete
;        var_score    (&0B0C) 3-byte BCD score, persists between CALLs
; The engine returns on level completion so BASIC can paint the next level;
; it never draws scenery itself.
;
; Contents (ported procedure in brackets):
;   * junk items placed into the collision boxes and drawn (PROCg)
;   * diver item pickup via the machine 'check' routine (PROCv pickup + PROCK)
;   * fish AI: init, swim, bounds, eat items, die and sink (PROCf/PROCm/PROCL)
;   * shark AI: homing, facing, bite (PROCs/PROCE)
;   * jellyfish: bounce, sting (PROCj/PROCcj)
;   * PROCu-lite: bites/stings bump var_hurt and splash a bleed char
;     (sound + air drain arrive with M4)
;   * seeded 16-bit PRNG replacing BASIC's RND
;
; Debug interface (see memorymap.asm): dbg_features gates each subsystem,
; dbg_forcekeys puppets the diver - both pokeable live over b2 Debug HTTP.
;
; Timing model (confirmed from POLY3): PROCv/enemies/PROCl run every loop
; iteration; only air (PROCD) is throttled by M% - that gate arrives at M4.
; Fish advance ONE per frame (E% cursor), jellies ONE of four per frame,
; shark every frame - exactly like the BASIC loop.
;
; DELIBERATE MICRO-DIVERGENCE (documented): POLY3 lets a DEAD fish (q%=2) run
; the eat-items check; a second "eat" would push F% past the shape table
; (latent bug, masked by luck in BASIC). Here the eat check is gated to live
; fish (q%=1 or 3).
;
; LOAD ADDRESS &0E00 - which is live DFS workspace until the disc is finished
; with (see memorymap.asm DFS HAZARD RULES). It therefore CANNOT be *LOADed
; straight there. BASIC must: load it somewhere safe (screen RAM works), wait
; for the drive to stop, CLOSE#0, *TAPE, then block-copy it down to &0E00.
; BASIC itself runs at PAGE=&2000, above the engine.
; ============================================================================

INCLUDE "src/memorymap.asm"

; --- graphics module at its production address &900 (proven home in the
;     shipping game; cassette buffers, untouched since we do no tape I/O) ---
ORG &900
.gfx_start
INCLUDE "src/gfx.asm"
.gfx_end
SAVE "GFX", gfx_start, gfx_end

SPACE_INKEY     = &9D       ; OSBYTE &81 X-operand for negative-INKEY SPACE (-99)
SAFETY_HI       = 48        ; exit after frame_count high byte reaches this (~60 s)
BLEED_CHAR      = 239       ; PROCu blood particle UDG
ITEM_COL        = 7         ; items drawn GCOL3 (EOR) white
TANK_CHAR       = 237       ; spare oxygen tank UDG
HEART_CHAR      = 238       ; end-of-level fish bonus heart UDG
P_INKEY         = &C8       ; negative-INKEY operands: P (pause)
U_INKEY         = &CA       ; U (unpause)
Q_INKEY         = &EF       ; Q (sound off)
S_INKEY         = &AE       ; S (sound on)

ORG &0E00
.engine_base

; ---------------------------------------------------------------------------
; Entry is a JMP so the level tables can sit at fixed, BASIC-readable
; addresses. Held here rather than in BASIC DATA statements because DATA text
; costs roughly three times what the binary does, and BASIC is the scarcer
; space. Addresses are contractual - POLY3 hardcodes them:
;   &0E03  level records: 4 x 21 x 16-bit  (v,ci,m, 2 circles, 2 hills, o,p)
;   &0EAB  seabed character sequence, 40 bytes
;   &0ED3  level tunes, 3 x 7 notes
;   &0EE8  game-over tune, 8 x (pitch,duration)
; ---------------------------------------------------------------------------
    JMP engine_start

.game_data
.gd_levels
    EQUW 131,1,2,  40,860,40,5,   0,0,0,0,      864,120,32,1,  980,200,64,1,  1,7
    EQUW 134,1,2,  40,980,40,3,   0,0,0,0,      864,200,64,2,  980,200,64,2,  6,7
    EQUW 133,1,2,  40,860,40,1,   0,0,0,0,      864,180,32,15, 980,200,64,15, 5,3
    EQUW 143,2,2, 100,920,40,7, 120,920,40,15,  864,180,32,7,  980,200,64,7,  0,7
.gd_seabed
    EQUB 242,243,244,245,246,247,246,245,244,243
    EQUB 242,243,244,245,246,247,246,245,244,243
    EQUB 247,246,245,244,243,242,243,244,245,246
    EQUB 247,246,245,244,243,242,243,244,245,246
.gd_tunes
    EQUB 129,125,109,101,89,81,77
    EQUB 77,81,89,101,109,125,129
    EQUB 129,125,129,125,129,125,81
.gd_over
    EQUB 53,5,41,10,53,10,73,15,41,5,33,10,53,10,69,20

.engine_start
    JSR save_zp             ; ABI: preserve BASIC's zero page &00-&6F

    JSR build_row_table     ; populate row_table (&D01) for plotshape

    ; --- seed the PRNG from the system clock (harness may re-poke var_rng) ---
    JSR read_clock
    LDA clock_buf   : STA var_rng
    LDA clock_buf+1 : STA var_rng+1
    ORA var_rng
    BNE seed_ok
    LDA #&34 : STA var_rng
    LDA #&12 : STA var_rng+1
.seed_ok

    ; --- feature mask: 0 (cold RAM) means everything on ---
    LDA dbg_features
    BNE feat_ok
    LDA #&FF : STA dbg_features
.feat_ok
    ; --- pacing divider: sanitize cold RAM to default 4 (=12.5 ticks/s) ---
    LDA dbg_divider
    BEQ div_default
    CMP #11
    BCC div_ok
.div_default
    LDA #4 : STA dbg_divider
.div_ok
    LDA #0 : STA dbg_divcnt
    ; --- shark front-on half-window: clamp cold RAM to the default 4 ---
    LDA dbg_sharkwin
    BEQ swin_default
    CMP #13
    BCC swin_ok
.swin_default
    LDA #4 : STA dbg_sharkwin
.swin_ok
    ; --- 'ouch' feedback cooldown: clamp cold RAM to the default 10 ticks ---
    LDA dbg_hurtcd
    BEQ hcd_default
    CMP #61
    BCC hcd_ok
.hcd_default
    LDA #10 : STA dbg_hurtcd
.hcd_ok
    LDA #0 : STA var_hurtcd

    ; --- initial game state (normally set by PROCo) ---
    LDA #32  : STA var_dx           ; diver start X
    LDA #214 : STA var_dy           ; diver start Y (near the surface)
    LDA #1   : STA var_facing       ; facing right (RDIVER)
    LDA #1   : STA var_speed        ; g% = 1
    LDA dbg_level                   ; l% comes from BASIC (0 -> default 1)
    BNE lvl_ok
    LDA #1 : STA dbg_level
.lvl_ok
    STA var_level
    ; effective subsystem mask = debug features AND the level's spawn rule
    ; (POLY3 line 1: l%>6 -> fish AND shark, l% odd -> fish, l% even -> shark)
    LDA dbg_features : STA var_active
    LDA var_level : CMP #7 : BCS lr_done
    LDA var_level : AND #1 : BEQ lr_even
    LDA var_active : AND #&FB : STA var_active   ; odd level: no shark
    JMP lr_done
.lr_even
    LDA var_active : AND #&FD : STA var_active   ; even level: no fish
.lr_done
    LDA #8   : STA var_items_left   ; P%
    LDA #8   : STA var_fish_left    ; L%
    LDA #0   : STA var_hurt
    LDA #0   : STA var_fish_cursor  ; E%
    LDA #3   : STA var_jelly_cursor ; e (first tick wraps to 0)
    LDA #248 : STA var_item_sprite  ; pl% = 248 + (l%-1) MOD 4 -> 250 for l%=7
    LDA var_level : SEC : SBC #1
.pl_mod4
    CMP #4 : BCC pl_done
    SBC #4 : JMP pl_mod4
.pl_done
    CLC : ADC #248 : STA var_item_sprite
    LDA #<100 : STA var_crit_x      ; critter (crab/shrimp) start X = 100
    LDA #>100 : STA var_crit_x+1
    LDA #1   : STA var_crit_col     ; co%
    LDA #228 : STA var_crit_sprite  ; cr% (crab UDG)
    LDA #0 : STA frame_count : STA frame_count+1

    ; --- M4: air / score / flags ---
    LDA #<1224 : STA var_air        ; O% = 1224 (full)
    LDA #>1224 : STA var_air+1
    LDA #255 : STA var_interval     ; M% ~ PROCo's 300cs initial grace
    LDA #0
    STA var_alarm_h                 ; H%
    STA var_alarm_k                 ; K% (tank icon not shown)
    STA var_gameover
    STA dbg_result
    ; the score persists across levels; only a NEW GAME clears it
    LDA dbg_newgame
    BEQ score_kept
    LDA #0
    STA var_score : STA var_score+1 : STA var_score+2   ; BCD 000000
    STA dbg_newgame                                     ; consume the flag
.score_kept
    JSR read_clock                  ; air-tick baseline = now
    LDA clock_buf   : STA air_base
    LDA clock_buf+1 : STA air_base+1

    ; --- M4: sound envelopes (PROCenv, via OSWORD 8) ---
    LDX #<env1 : LDY #>env1 : LDA #8 : JSR osword
    LDX #<env2 : LDY #>env2 : LDA #8 : JSR osword
    LDX #<env3 : LDY #>env3 : LDA #8 : JSR osword
    LDX #<env4 : LDY #>env4 : LDA #8 : JSR osword

    ; --- M4: HUD ---
    JSR bar_full                    ; full air bar
    JSR print_score
    JSR print_counts

    ; --- per-subsystem init (feature-gated) ---
    ; always zero the item boxes first so 'check' can never match cold RAM
    LDY #7
    LDA #0
.clr_boxes
    STA arr_item_x,Y
    STA arr_item_y,Y
    DEY
    BPL clr_boxes
    LDA var_active : AND #1 : BEQ no_items_init
    JSR items_init
.no_items_init
    LDA var_active : AND #2 : BEQ no_fish_init
    JSR fish_init
.no_fish_init
    LDA var_active : AND #4 : BEQ no_shark_init
    JSR shark_init
.no_shark_init
    LDA var_active : AND #8 : BEQ no_jelly_init
    JSR jelly_init
.no_jelly_init

    ; draw the diver once; game_tick maintains it thereafter
    LDX var_dx
    LDY var_dy
    LDA var_facing
    JSR plotshape

    ; draw the critter once so critter_tick's first EOR erase cancels it
    LDA var_crit_x   : STA zp_ptr1
    LDA var_crit_x+1 : STA zp_ptr1+1
    LDA #192 : STA zp_ptr2
    LDA #0   : STA zp_ptr2+1
    LDA var_crit_col : STA var_tmpD
    LDA var_crit_sprite
    JSR vdu_char

.main_loop
    LDA #19                 ; frame lock: wait for vertical sync (50 Hz)
    JSR osbyte

    JSR check_exit          ; SPACE?  Z=1 if pressed
    BNE not_space
    JMP do_exit
.not_space

    INC frame_count         ; safety limit
    BNE fc_nohi
    INC frame_count+1
.fc_nohi
    LDA frame_count+1
    CMP #SAFETY_HI
    BCC fc_ok
    JMP do_exit
.fc_ok
    LDA dbg_go              ; remote abort: poke &FF to end the run cleanly
    CMP #&FF
    BNE go_ok
    JMP do_exit
.go_ok

    ; jellies run EVERY frame (50Hz) with quarter-steps: same net speeds as
    ; the BASIC original's chunky jumps, but 4x smoother (author-requested)
    LDA var_active : AND #8 : BEQ ml_nojelly
    JSR jelly_tick
.ml_nojelly

    ; pacing: advance game state only every dbg_divider-th frame
    INC dbg_divcnt
    LDA dbg_divider
    BNE div_set
    LDA #1                  ; 0 means run every frame
.div_set
    CMP dbg_divcnt
    BCC div_tick
    BEQ div_tick
    JMP main_loop           ; not yet - just keep frame-locked
.div_tick
    LDA #0 : STA dbg_divcnt

    LDA var_hurtcd          ; run down the 'ouch' feedback cooldown
    BEQ ml_nocd
    DEC var_hurtcd
.ml_nocd

    JSR diver_update
    JSR air_check                   ; PROCD: time-gated air drain + tank spawn
    LDA var_active : AND #2 : BEQ ml_nofish
    JSR fish_tick
.ml_nofish
    LDA var_active : AND #4 : BEQ ml_noshark
    JSR shark_tick
.ml_noshark
    JSR critter_tick

    ; game over? (air ran out, or every fish is dead)
    LDA var_gameover
    BEQ ml_alive
    STA dbg_result
    JMP do_exit
.ml_alive
    ; level clear when all items gone (collected or eaten): pay the bonuses,
    ; then hand back to BASIC so it can paint the next level's scenery
    LDA var_active : AND #1 : BEQ ml_loop
    LDA var_items_left
    BNE ml_loop
    JSR level_clear
    LDA #3 : STA dbg_result
    JMP do_exit
.ml_loop
    JMP main_loop

.do_exit
    JSR restore_zp          ; ABI: hand BASIC its zero page back
    RTS


; ============================================================================
; diver_update - PROCv: keys, move within bounds, erase+redraw, item pickup.
; ============================================================================
.diver_update
    LDA var_dx     : STA var_dx_old
    LDA var_dy     : STA var_dy_old
    LDA var_facing : STA var_facing_old

    ; left (key 0): if D% > 1 then D% -= g%, face left
    LDA #0 : JSR test_key : BNE du_noleft
    LDA var_dx : CMP #2 : BCC du_noleft
    LDA var_dx : SEC : SBC var_speed : STA var_dx
    LDA #0 : STA var_facing
.du_noleft
    ; right (key 1): if D% < 67 then D% += g%, face right
    LDA #1 : JSR test_key : BNE du_noright
    LDA var_dx : CMP #67 : BCS du_noright
    LDA var_dx : CLC : ADC var_speed : STA var_dx
    LDA #1 : STA var_facing
.du_noright
    ; up (key 2): if e% < 212 then e% += g%*2
    LDA #2 : JSR test_key : BNE du_noup
    LDA var_dy : CMP #212 : BCS du_noup
    LDA var_speed : ASL A : CLC : ADC var_dy : STA var_dy
.du_noup
    ; down (key 3): if e% > 54 then e% -= g%*2
    LDA #3 : JSR test_key : BNE du_nodown
    LDA var_dy : CMP #55 : BCC du_nodown
    LDA var_speed : ASL A : STA var_tmpA
    LDA var_dy : SEC : SBC var_tmpA : STA var_dy
.du_nodown
    ; faster (key 4): PROCv line 49 - fast AND moved: g=2, M%=100, immediate
    ; air check; otherwise g=1, M%=200
    LDA #4 : JSR test_key : BNE du_slow
    LDA var_dx : CMP var_dx_old : BNE du_fast
    LDA var_dy : CMP var_dy_old : BNE du_fast
    JMP du_slow                     ; fast key held but not moving
.du_fast
    LDA #2   : STA var_speed
    LDA #100 : STA var_interval
    JSR air_check
    JMP du_speeddone
.du_slow
    LDA #1   : STA var_speed
    LDA #200 : STA var_interval
.du_speeddone

    ; redraw only if the diver actually changed
    LDA var_dx     : CMP var_dx_old     : BNE du_redraw
    LDA var_dy     : CMP var_dy_old     : BNE du_redraw
    LDA var_facing : CMP var_facing_old : BNE du_redraw
    JMP du_pickup
.du_redraw
    LDX var_dx_old : LDY var_dy_old : LDA var_facing_old : JSR plotshape ; erase old
    LDX var_dx     : LDY var_dy     : LDA var_facing     : JSR plotshape ; draw new

.du_pickup
    ; PROCv pickup: C% = FNc((D%+6)*2, e%-14); hit -> sound + PROCK
    LDA var_active : AND #1 : BEQ du_tank
    LDA var_dx : CLC : ADC #6 : ASL A : TAX
    LDA var_dy : SEC : SBC #14 : TAY
    JSR check
    LDA collide_result
    BMI du_tank
    TAY                     ; Y = item index hit
    JSR item_draw           ; EOR erase the item char (preserves Y)
    LDA #0                  ; clear the box BEFORE anything else can touch Y,
    STA arr_item_x,Y        ; or the diver re-collects it every tick
    STA arr_item_y,Y
    DEC var_items_left
    LDX #<snd_pickup : STX snd_ptr
    LDX #>snd_pickup : STX snd_ptr+1
    JSR play_snd_ptr
    LDX #1 : LDA #&02 : JSR score_add    ; S% += 200
    JSR print_score
    JSR print_counts
.du_tank
    ; PROCv line 52 tank grab: D%>30 AND D%<40 AND e%>210 AND O%<1068 AND H%=0
    LDA var_dx : CMP #31 : BCC du_keys
    CMP #40 : BCS du_keys
    LDA var_dy : CMP #211 : BCC du_keys
    SEC                              ; O% < 1068 ?
    LDA var_air   : SBC #<1068
    LDA var_air+1 : SBC #>1068
    BCS du_keys
    LDA var_alarm_h : BNE du_keys
    JSR refill                       ; PROCJ
.du_keys
    ; P pauses until U; Q sound off; S sound on (PROCv lines 53-55)
    LDA #P_INKEY : JSR scan_key : BNE du_nopause
.du_pauseloop
    LDA #19 : JSR osbyte
    LDA #U_INKEY : JSR scan_key : BNE du_pauseloop
.du_nopause
    LDA #Q_INKEY : JSR scan_key : BNE du_noqoff
    LDA #&D2 : LDX #1 : LDY #0 : JSR osbyte     ; *FX210,1 sound off
.du_noqoff
    LDA #S_INKEY : JSR scan_key : BNE du_done
    LDA #&D2 : LDX #0 : LDY #0 : JSR osbyte     ; *FX210,0 sound on
.du_done
    RTS

; scan_key - A = negative-INKEY operand; Z=1 if that key is held
.scan_key
    TAX
    LDY #&FF
    LDA #&81
    JSR osbyte
    CPX #&FF
    RTS


; ============================================================================
; items_init - PROCg: place 8 junk items into the collision boxes and draw.
;   G%?A = (A+1)*16 ; J%?A = 63 + RND(135)  (i.e. 64..198)
; ============================================================================
.items_init
    LDY #0
.ii_loop
    TYA : CLC : ADC #1
    ASL A : ASL A : ASL A : ASL A          ; (A+1)*16
    STA arr_item_x,Y
    LDA #135 : JSR rnd_mod                 ; 0..134
    CLC : ADC #64                          ; 64..198
    STA arr_item_y,Y
    JSR item_draw                          ; preserves Y
    INY
    CPY #8
    BNE ii_loop
    RTS

; ----------------------------------------------------------------------------
; item_draw - EOR-draw (or erase) item Y's char at graphics (G%*8, J%*4).
;   Preserves Y.
; ----------------------------------------------------------------------------
.item_draw
    STY item_saveY
    LDA arr_item_x,Y : STA zp_ptr1
    LDA #0 : STA zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1            ; x16 = G% * 8
    LDA arr_item_y,Y : STA zp_ptr2
    LDA #0 : STA zp_ptr2+1
    ASL zp_ptr2 : ROL zp_ptr2+1
    ASL zp_ptr2 : ROL zp_ptr2+1            ; y16 = J% * 4
    LDA #ITEM_COL : STA var_tmpD
    LDA var_item_sprite
    JSR vdu_char
    LDY item_saveY
    RTS


; ============================================================================
; fish_init - PROCf: 8 fish; 0-3 swim right (q=3,F=RFISH), 4-7 left (q=1,LFISH)
;   t%=8 ; k%=RND(73)-1 ; n%=47+RND(152)
; ============================================================================
.fish_init
    LDY #0
.fi_loop
    LDA #8 : STA arr_fish_vdelta,Y
    LDA #73 : JSR rnd_mod : STA arr_fish_x,Y       ; 0..72
    LDA #152 : JSR rnd_mod : CLC : ADC #48         ; 48..199
    STA arr_fish_y,Y
    CPY #4
    BCS fi_left
    LDA #3 : STA arr_fish_state,Y : STA arr_fish_frame,Y   ; right, RFISH
    JMP fi_draw
.fi_left
    LDA #1 : STA arr_fish_state,Y                          ; left
    LDA #2 : STA arr_fish_frame,Y                          ; LFISH
.fi_draw
    STY item_saveY
    LDX arr_fish_x,Y
    LDA arr_fish_y,Y
    STA var_tmpA
    LDA arr_fish_frame,Y
    LDY var_tmpA
    JSR plotshape
    LDY item_saveY
    INY
    CPY #8
    BNE fi_loop
    RTS

; ============================================================================
; fish_tick - PROCm: advance ONE fish (cursor E%).
; ============================================================================
.fish_tick
    LDX var_fish_cursor
    LDA arr_fish_state,X
    CMP #2
    BNE ft_alivebranch
    LDA arr_fish_y,X
    BNE ft_elsebranch
    JMP ft_advance                          ; dead & settled: just advance cursor
.ft_alivebranch
.ft_elsebranch
    ; if q<>0 and l%>2: FNf(k,n) -> PROCu   (POLY3 ELSE branch)
    LDA arr_fish_state,X
    BEQ ft_move
    LDA var_level : CMP #3 : BCC ft_move
    LDA arr_fish_x,X : STA var_tmpA
    LDA arr_fish_y,X : STA var_tmpB
    JSR fnf
    BCC ft_move
    JSR hurt
.ft_move
    ; erase at old position with old shape
    LDA arr_fish_x,X : STA var_tmpA
    LDA arr_fish_y,X : STA var_tmpB
    LDA arr_fish_frame,X : STA var_tmpC
    JSR plot_tmp
    ; k += q-2 ; n += t-6
    LDX var_fish_cursor
    LDA arr_fish_x,X : CLC : ADC arr_fish_state,X : SEC : SBC #2
    STA arr_fish_x,X
    LDA arr_fish_y,X : CLC : ADC arr_fish_vdelta,X : SEC : SBC #6
    STA arr_fish_y,X
    ; bounds: k<4 -> face right ; k>75 -> face left
    LDA arr_fish_x,X : CMP #4 : BCS ft_nrl
    LDA #3 : STA arr_fish_state,X : STA arr_fish_frame,X
.ft_nrl
    LDA arr_fish_x,X : CMP #76 : BCC ft_nrr
    LDA #1 : STA arr_fish_state,X
    LDA #2 : STA arr_fish_frame,X
.ft_nrr
    ; n<64 and q<>2 -> t=8  ELSE  n<48 and q=2 -> n=48
    LDA arr_fish_y,X : CMP #64 : BCS ft_nlow
    LDA arr_fish_state,X : CMP #2 : BEQ ft_deadfloor
    LDA #8 : STA arr_fish_vdelta,X
    JMP ft_top
.ft_deadfloor
    LDA arr_fish_y,X : CMP #48 : BCS ft_top
    LDA #48 : STA arr_fish_y,X
    JMP ft_top
.ft_nlow
.ft_top
    ; n>200 and q<>2 -> t=4
    LDA arr_fish_y,X : CMP #201 : BCC ft_draw
    LDA arr_fish_state,X : CMP #2 : BEQ ft_draw
    LDA #4 : STA arr_fish_vdelta,X
.ft_draw
    ; draw at new position with (possibly flipped) shape
    LDA arr_fish_x,X : STA var_tmpA
    LDA arr_fish_y,X : STA var_tmpB
    LDA arr_fish_frame,X : STA var_tmpC
    JSR plot_tmp
    ; live fish (q=1 or 3): mouth check against item boxes -> eat
    LDX var_fish_cursor
    LDA arr_fish_state,X
    CMP #1 : BEQ ft_eatchk
    CMP #3 : BEQ ft_eatchk
    JMP ft_advance
.ft_eatchk
    ; C% = FNc((k + 3*(F-2))*2, n-5)
    LDA arr_fish_frame,X : SEC : SBC #2     ; 0 (LFISH) or 1 (RFISH)
    STA var_tmpA
    ASL A : ADC var_tmpA                    ; *3
    CLC : ADC arr_fish_x,X
    ASL A                                   ; *2
    STA var_tmpA
    LDA arr_fish_y,X : SEC : SBC #5
    TAY
    LDX var_tmpA
    JSR check
    LDA collide_result
    BMI ft_advance
    ; --- fish eats item (PROCL-lite): kill fish, remove item ---
    TAY                                     ; Y = item index
    JSR item_draw                           ; EOR erase item char
    LDA #0
    STA arr_item_x,Y
    STA arr_item_y,Y
    DEC var_items_left
    DEC var_fish_left
    BNE fe_fishleft
    LDA #2 : STA var_gameover        ; all fish dead -> game over
.fe_fishleft
    LDX #<snd_fishdie : STX snd_ptr
    LDX #>snd_fishdie : STX snd_ptr+1
    JSR play_snd_ptr                 ; SOUND 3,2,96,4
    JSR print_counts
    LDX var_fish_cursor
    ; erase live fish, switch to dead shape, redraw
    LDA arr_fish_x,X : STA var_tmpA
    LDA arr_fish_y,X : STA var_tmpB
    LDA arr_fish_frame,X : STA var_tmpC
    JSR plot_tmp
    LDX var_fish_cursor
    LDA arr_fish_frame,X : CLC : ADC #4 : STA arr_fish_frame,X  ; DLFISH/DRFISH
    STA var_tmpC
    LDA arr_fish_x,X : STA var_tmpA
    LDA arr_fish_y,X : STA var_tmpB
    JSR plot_tmp
    LDX var_fish_cursor
    LDA #2 : STA arr_fish_state,X           ; q=2 dead
    LDA #0 : STA arr_fish_vdelta,X          ; t=0 -> sinks at -6
.ft_advance
    LDA var_fish_cursor : CLC : ADC #1 : AND #7 : STA var_fish_cursor
    RTS

; plot_tmp - plotshape(var_tmpC shape, var_tmpA x, var_tmpB y); clobbers A,X,Y
.plot_tmp
    LDX var_tmpA
    LDY var_tmpB
    LDA var_tmpC
    JMP plotshape


; ============================================================================
; shark_init - PROCs: SD%=4 ; SX%=RND(61)-1 ; if SX%<=D%+8 SD%=5 ;
;              SY%=60+l%*10 capped 160
; ============================================================================
.shark_init
    LDA #4 : STA var_shk_dir
    LDA #61 : JSR rnd_mod : STA var_shk_x   ; 0..60
    LDA var_dx : CLC : ADC #8
    CMP var_shk_x
    BCC si_noflip                           ; dx+8 < SX -> keep facing left
    LDA #5 : STA var_shk_dir
.si_noflip
    LDA var_level
    ASL A : ASL A : ADC var_level           ; l*5 (carry clear: l small)
    ASL A                                   ; l*10
    CLC : ADC #60
    CMP #161 : BCC si_ycap
    LDA #160
.si_ycap
    STA var_shk_y
    LDA #1 : STA var_shk_vspeed             ; V% = 1 (PROCo)
    LDX var_shk_x
    LDY var_shk_y
    LDA var_shk_dir
    JMP plotshape

; ============================================================================
; shark_tick - PROCE: home in on the diver, choose facing, bite.
; ============================================================================
.shark_tick
    LDA var_shk_x   : STA var_shk_x_old     ; N%
    LDA var_shk_y   : STA var_shk_y_old     ; j%
    LDA var_shk_dir : STA var_shk_dir_old   ; OA%
    ; vertical homing
    LDA var_shk_y
    CMP var_dy : BCS st_ynotup              ; SY < e% ?
    CMP #195   : BCS st_ynotup              ; and SY < 195
    CLC : ADC var_shk_vspeed : STA var_shk_y
.st_ynotup
    LDA var_shk_y
    CMP var_dy : BCC st_ydone : BEQ st_ydone ; SY > e% ?
    CMP #64    : BCC st_ydone                ; and SY > 63
    SEC : SBC var_shk_vspeed : STA var_shk_y
.st_ydone
    ; mouth offset _% = 4 / 8 (SD=5) / 4 (SD=8)  - compare SD each time!
    ; NOTE: FSHK uses 4 (not the original's 0) so the front-on shark comes to
    ; rest exactly centred on the diver - see the facing rules below.
    LDA #4 : STA var_tmpA
    LDA var_shk_dir
    CMP #5 : BNE st_off1
    LDA #8 : STA var_tmpA
.st_off1
    LDA var_shk_dir
    CMP #8 : BNE st_off2
    LDA #4 : STA var_tmpA
.st_off2
    ; horizontal homing: compare SX+_% with D%+6
    LDA var_shk_x : CLC : ADC var_tmpA : STA var_tmpB
    LDA var_dx : CLC : ADC #6
    CMP var_tmpB
    BCS st_notgt                            ; SX+off <= dx+6
    LDA var_shk_x : SEC : SBC var_shk_vspeed : STA var_shk_x
    JMP st_xdone
.st_notgt
    BEQ st_xdone                            ; equal: no move
    LDA var_shk_x : CLC : ADC var_shk_vspeed : STA var_shk_x
.st_xdone
    ; --- facing rules, CENTRE-based (author request, replaces the original's
    ; left-edge test). The side sprites are 16 units wide and the front-on
    ; sprite 8, so comparing left edges made the front-on shark sit off-centre.
    ; Here we compare sprite CENTRES:
    ;     side centre  = SX + 8      front centre = SX + 4
    ;     diver centre = D% + 6
    ; front-on engages while |shark centre - diver centre| <= dbg_sharkwin,
    ; and a state change shifts SX by 4 units so the visible centre is
    ; preserved as the sprite width halves/doubles (the original shifted 8,
    ; i.e. double what centre-preservation needs, hence the visible jump).
    LDA var_shk_dir
    CMP #8 : BEQ st_c_front
    LDA var_shk_x : CLC : ADC #8            ; side sprite centre
    JMP st_c_have
.st_c_front
    LDA var_shk_x : CLC : ADC #4            ; front sprite centre
.st_c_have
    STA var_tmpB
    LDA var_dx : CLC : ADC #6 : STA var_tmpC ; diver centre
    LDA var_tmpB : SEC : SBC var_tmpC       ; signed difference
    BCS st_c_pos
    EOR #&FF : CLC : ADC #1                 ; |difference|
    CMP dbg_sharkwin
    BEQ st_front
    BCC st_front
    JMP st_faceright                        ; shark left of diver
.st_c_pos
    CMP dbg_sharkwin
    BEQ st_front
    BCC st_front
    ; fall through: shark right of diver -> face left
.st_faceleft
    LDA var_shk_dir : CMP #8 : BNE st_fl_set
    LDA var_shk_x : SEC : SBC #4 : STA var_shk_x   ; front -> side
.st_fl_set
    LDA #4 : STA var_shk_dir
    JMP st_nfront
.st_faceright
    LDA var_shk_dir : CMP #8 : BNE st_fr_set
    LDA var_shk_x : SEC : SBC #4 : STA var_shk_x   ; front -> side
.st_fr_set
    LDA #5 : STA var_shk_dir
    JMP st_nfront
.st_front
    LDA var_shk_dir : CMP #8 : BEQ st_nfront       ; already front-on
    LDA var_shk_x : CLC : ADC #4 : STA var_shk_x   ; side -> front
    LDA #8 : STA var_shk_dir
.st_nfront
    ; bite: @% = 4 / 12 (SD=5) / 2 (SD=8) ; FNf(SX+@%, SY)
    LDA #4 : STA var_tmpA
    LDA var_shk_dir
    CMP #5 : BNE st_at1
    LDA #12 : STA var_tmpA
.st_at1
    LDA var_shk_dir
    CMP #8 : BNE st_at2
    LDA #2 : STA var_tmpA
.st_at2
    LDA var_shk_x : CLC : ADC var_tmpA : STA var_tmpA
    LDA var_shk_y : STA var_tmpB
    JSR fnf
    BCC st_nobite
    JSR hurt
.st_nobite
    ; redraw only if anything changed
    LDA var_shk_x   : CMP var_shk_x_old   : BNE st_redraw
    LDA var_shk_y   : CMP var_shk_y_old   : BNE st_redraw
    LDA var_shk_dir : CMP var_shk_dir_old : BNE st_redraw
    RTS
.st_redraw
    LDX var_shk_x_old
    LDY var_shk_y_old
    LDA var_shk_dir_old
    JSR plotshape                           ; erase old
    LDX var_shk_x
    LDY var_shk_y
    LDA var_shk_dir
    JMP plotshape                           ; draw new


; ============================================================================
; jelly_init - PROCj: U%=12+o*16 ; zz%=88+RND(12)*8 ; jv%=4*(o+1);
;              one of jellies 0-2 gets jv%=16
; ============================================================================
.jelly_init
    LDY #0
.ji_loop
    TYA : ASL A : ASL A : ASL A : ASL A     ; o*16
    CLC : ADC #12
    STA arr_jelly_x,Y
    LDA #12 : JSR rnd_mod                   ; 0..11
    CLC : ADC #1                            ; 1..12
    ASL A : ASL A : ASL A                   ; *8 -> 8..96
    CLC : ADC #88                           ; 96..184
    STA arr_jelly_y,Y
    TYA : CLC : ADC #1
    ASL A : ASL A                           ; 4*(o+1)
    STA arr_jelly_vel,Y
    STY item_saveY
    LDX arr_jelly_x,Y
    LDA arr_jelly_y,Y : STA var_tmpA
    LDA #9                                  ; JELLY shape
    LDY var_tmpA
    JSR plotshape
    LDY item_saveY
    INY
    CPY #4
    BNE ji_loop
    LDA #3 : JSR rnd_mod : TAY              ; 0..2
    LDA #16 : STA arr_jelly_vel,Y
    RTS

; ============================================================================
; jelly_tick - PROCcj: advance cursor, sting check, bounce, erase+draw.
; ============================================================================
.jelly_tick
    LDA var_jelly_cursor : CLC : ADC #1 : AND #3 : STA var_jelly_cursor
    TAX
    ; FNu(U%, zz%) = 0 (overlap) -> PROCu
    LDA arr_jelly_x,X : STA var_tmpA
    LDA arr_jelly_y,X : STA var_tmpB
    JSR fnu
    BCC jt_nosting
    JSR hurt
    LDX var_jelly_cursor
.jt_nosting
    LDA arr_jelly_y,X : STA var_tmpC        ; oz%
    ; step = jv/4 signed (quarter-step smoothing; velocity classes intact)
    LDA arr_jelly_vel,X
    CMP #&80 : ROR A
    CMP #&80 : ROR A
    STA var_tmpD
    LDA arr_jelly_y,X
    CLC : ADC var_tmpD                      ; zz += jv/4 (signed)
    STA arr_jelly_y,X
    ; if zz>200 or zz<88: jv = -jv
    CMP #201 : BCS jt_flip
    CMP #88  : BCS jt_noflip
.jt_flip
    LDA arr_jelly_vel,X
    EOR #&FF : CLC : ADC #1
    STA arr_jelly_vel,X
.jt_noflip
    ; erase at oz, draw at new zz
    STX item_saveY
    LDX var_jelly_cursor
    LDA arr_jelly_x,X : STA var_tmpA
    LDA arr_jelly_y,X : STA var_tmpB
    LDX var_tmpA
    LDY var_tmpC
    LDA #9
    JSR plotshape                           ; erase old
    LDX var_tmpA
    LDY var_tmpB
    LDA #9
    JMP plotshape                           ; draw new


; ============================================================================
; fnf - PROCE/PROCm hit box: HIT if var_tmpA in [D%, D%+12]
;       AND var_tmpB in [e%-12, e%].  Returns carry SET on hit.
; ============================================================================
.fnf
    LDA var_tmpA
    CMP var_dx : BCC fnf_miss               ; c < D%
    LDA var_dx : CLC : ADC #12
    CMP var_tmpA : BCC fnf_miss             ; c > D%+12
    LDA var_dy : SEC : SBC #12
    CMP var_tmpB
    BEQ fnf_ychk
    BCS fnf_miss                            ; d < e%-12
.fnf_ychk
    LDA var_tmpB
    CMP var_dy : BCC fnf_hit : BEQ fnf_hit  ; d <= e%
    JMP fnf_miss
.fnf_hit
    SEC
    RTS
.fnf_miss
    CLC
    RTS

; ============================================================================
; fnu - PROCcj sting box (FNu returns FALSE=overlap): here carry SET = STING.
;   No sting if (D%+10)<c OR D%>(c+6) OR (e%-12)>z OR e%<(z-12)
; ============================================================================
.fnu
    LDA var_dx : CLC : ADC #10
    CMP var_tmpA : BCC fnu_miss             ; dx+10 < c
    LDA var_tmpA : CLC : ADC #6
    CMP var_dx : BCC fnu_miss               ; dx > c+6
    LDA var_dy : SEC : SBC #12
    CMP var_tmpB
    BCC fnu_zchk : BEQ fnu_zchk
    JMP fnu_miss                            ; dy-12 > z
.fnu_zchk
    LDA var_tmpB : SEC : SBC #12
    CMP var_dy
    BCC fnu_hit : BEQ fnu_hit
    JMP fnu_miss                            ; dy < z-12
.fnu_hit
    SEC
    RTS
.fnu_miss
    CLC
    RTS

; ============================================================================
; hurt - PROCu-lite: count it and splash a bleed char near the diver.
;   (Air drain + sound arrive at M4.)  Preserves X.
; ============================================================================
.hurt
    STX hurt_saveX
    INC var_hurt
    ; PROCu: M% = 50 then an immediate air check. The air cost stays
    ; per-tick (sustained contact really should hurt).
    LDA #50 : STA var_interval
    JSR air_check
    ; The 'ouch' FEEDBACK (sound + blood) is rate-limited by var_hurtcd.
    ; Without this, a shark parked on the diver queues ~12 notes a second
    ; into the OS sound buffer, which keeps playing long after contact ends.
    LDA var_hurtcd
    BEQ hu_fire
    JMP hu_done
.hu_fire
    LDA dbg_hurtcd : STA var_hurtcd
    LDX #<snd_hurt : STX snd_ptr
    LDX #>snd_hurt : STX snd_ptr+1
    JSR play_snd_ptr
    ; x16 = D%*16 + RND(64)-ish ; y16 = e%*4 + RND(32)-ish
    LDA var_dx : STA zp_ptr1
    LDA #0 : STA zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1             ; *16
    LDA #64 : JSR rnd_mod
    CLC : ADC zp_ptr1 : STA zp_ptr1
    BCC hu_x_ok
    INC zp_ptr1+1
.hu_x_ok
    LDA var_dy : STA zp_ptr2
    LDA #0 : STA zp_ptr2+1
    ASL zp_ptr2 : ROL zp_ptr2+1
    ASL zp_ptr2 : ROL zp_ptr2+1             ; *4
    LDA #32 : JSR rnd_mod
    CLC : ADC zp_ptr2 : STA zp_ptr2
    BCC hu_y_ok
    INC zp_ptr2+1
.hu_y_ok
    LDA #1 : STA var_tmpD                   ; GCOL3,1 (red)
    LDA #BLEED_CHAR
    JSR vdu_char
.hu_done
    LDX hurt_saveX
    RTS


; ============================================================================
; vdu_char - emit VDU5 ; GCOL 3,var_tmpD ; PLOT 4, zp_ptr1;zp_ptr2; ; char A.
;   The one shared OSWRCH path for char-based EOR sprites (items, bleed,
;   critter). Clobbers A,X,Y.
; ============================================================================
.vdu_char
    PHA
    LDA #5   : JSR oswrch
    LDA #18  : JSR oswrch
    LDA #3   : JSR oswrch
    LDA var_tmpD : JSR oswrch
    LDA #25  : JSR oswrch
    LDA #4   : JSR oswrch
    LDA zp_ptr1   : JSR oswrch
    LDA zp_ptr1+1 : JSR oswrch
    LDA zp_ptr2   : JSR oswrch
    LDA zp_ptr2+1 : JSR oswrch
    PLA
    JMP oswrch


; ============================================================================
; critter_tick - PROCl: scroll the sea-bed critter (crab/shrimp - NOT the
;   boat, which is static level furniture). EOR erase old, draw new.
; ============================================================================
.critter_tick
    LDA var_crit_x     : STA var_crit_x_old
    LDA var_crit_x+1   : STA var_crit_x_old+1
    LDA var_crit_x     : CLC : ADC #6 : STA var_crit_x
    LDA var_crit_x+1   : ADC #0 : STA var_crit_x+1
    SEC
    LDA var_crit_x     : SBC #<1261
    LDA var_crit_x+1   : SBC #>1261
    BCC ct_draw
    LDA #0 : STA var_crit_x : STA var_crit_x+1
.ct_draw
    LDA var_crit_x_old   : STA zp_ptr1
    LDA var_crit_x_old+1 : STA zp_ptr1+1
    LDA #192 : STA zp_ptr2
    LDA #0   : STA zp_ptr2+1
    LDA var_crit_col : STA var_tmpD
    LDA var_crit_sprite
    JSR vdu_char                            ; erase at old x
    LDA var_crit_x   : STA zp_ptr1
    LDA var_crit_x+1 : STA zp_ptr1+1
    LDA #192 : STA zp_ptr2
    LDA #0   : STA zp_ptr2+1
    LDA var_crit_col : STA var_tmpD
    LDA var_crit_sprite
    JMP vdu_char                            ; draw at new x


; ============================================================================
; test_key - A = direction index (0..4). Returns Z=1 if that key is held.
;   dbg_forcekeys bit7 set: forced mode - low 3 bits name the pressed index.
;   Otherwise OSBYTE &81 negative INKEY via key_table.
; ============================================================================
.test_key
    TAY
    LDA dbg_forcekeys
    BPL tk_real
    AND tk_bits,Y                           ; bits 0-4 = pressed mask per index
    BEQ tk_notpressed
    LDX #&FF : CPX #&FF : RTS               ; forced: pressed (Z=1)
.tk_notpressed
    LDX #0 : CPX #&FF : RTS                 ; forced: not pressed (Z=0)
.tk_bits
    EQUB 1,2,4,8,16
.tk_real
    LDA key_table,Y
    EOR #&FF
    TAX
    LDY #&FF
    LDA #&81
    JSR osbyte
    CPX #&FF                                ; pressed -> X=&FF -> Z=1
    RTS


; ----------------------------------------------------------------------------
; check_exit - Z=1 if SPACE is held.
; ----------------------------------------------------------------------------
.check_exit
    LDX #SPACE_INKEY
    LDY #&FF
    LDA #&81
    JSR osbyte
    CPX #&FF
    RTS


; ============================================================================
; rnd8 / rnd_mod - 16-bit PRNG (state in var_rng), and A = random 0..A-1.
; ============================================================================
.rnd8
    LDA var_rng+1
    LSR A
    LDA var_rng
    ROR A
    EOR var_rng+1
    STA var_rng+1
    ROR A
    EOR var_rng
    STA var_rng
    EOR var_rng+1
    RTS

.rnd_mod
    STA rnd_n
    JSR rnd8
.rm_loop
    CMP rnd_n
    BCC rm_done
    SBC rnd_n                               ; carry known set
    JMP rm_loop
.rm_done
    RTS


; ============================================================================
; air_check - PROCD: when >= M% centiseconds have passed, drain O% by 8*g%,
;   bubble, redraw the bar tip, switch the warning colour, spawn the spare
;   tank at O%<1068, and flag game over at O%<928.
; ============================================================================
.air_check
    JSR read_clock
    SEC
    LDA clock_buf   : SBC air_base : STA ac_elapsed
    LDA clock_buf+1 : SBC air_base+1
    BNE ac_fire                     ; >=256cs certainly >= M% (M% <= 255)
    LDA ac_elapsed
    CMP var_interval
    BCS ac_fire
    RTS
.ac_fire
    LDA clock_buf   : STA air_base  ; TIME = 0
    LDA clock_buf+1 : STA air_base+1
    ; O% -= 8 * g%
    LDA var_speed : ASL A : ASL A : ASL A : STA ac_elapsed
    SEC
    LDA var_air   : SBC ac_elapsed : STA var_air
    LDA var_air+1 : SBC #0         : STA var_air+1
    LDX #<snd_bubble : STX snd_ptr
    LDX #>snd_bubble : STX snd_ptr+1
    JSR play_snd_ptr                ; SOUND 0,4,6,3
    ; if O% > 912: erase the bar tip columns at O% and O%+8
    SEC
    LDA var_air   : SBC #<913
    LDA var_air+1 : SBC #>913
    BCC ac_nobar
    JSR bar_tip_erase
.ac_nobar
    ; bar colour: cyan while O% > 999, warning otherwise
    SEC
    LDA var_air   : SBC #<1000
    LDA var_air+1 : SBC #>1000
    BCC ac_warn
    LDA #6 : JSR bar_colour
    JMP ac_tank
.ac_warn
    LDA #9 : JSR bar_colour
.ac_tank
    ; spare tank: O% < 1068 AND H%=0 AND K%=0
    SEC
    LDA var_air   : SBC #<1068
    LDA var_air+1 : SBC #>1068
    BCS ac_over
    LDA var_alarm_h : BNE ac_over
    LDA var_alarm_k : BNE ac_over
    LDX #<snd_tank : STX snd_ptr
    LDX #>snd_tank : STX snd_ptr+1
    JSR play_snd_ptr                ; SOUND 2,3,240,2
    JSR tank_draw
    LDA #1 : STA var_alarm_k
.ac_over
    ; out of air? O% < 928 -> game over
    SEC
    LDA var_air   : SBC #<928
    LDA var_air+1 : SBC #>928
    BCS ac_done
    LDA #1 : STA var_gameover
.ac_done
    RTS

; ----------------------------------------------------------------------------
; refill - PROCJ: O%=1224, sound, full bar, erase tank icon, clear flags.
; ----------------------------------------------------------------------------
.refill
    LDA #<1224 : STA var_air
    LDA #>1224 : STA var_air+1
    LDX #<snd_refill : STX snd_ptr
    LDX #>snd_refill : STX snd_ptr+1
    JSR play_snd_ptr                ; SOUND 1,1,80,1
    JSR bar_full
    LDA #6 : JSR bar_colour
    JSR tank_draw                   ; EOR erase the icon
    LDA #0
    STA var_alarm_h
    STA var_alarm_k
    LDA #1 : STA var_shk_vspeed     ; V% = 1
    RTS

; ----------------------------------------------------------------------------
; tank_draw - EOR the spare-tank char at graphics (612,850), GCOL3,6.
; ----------------------------------------------------------------------------
.tank_draw
    LDA #<612 : STA zp_ptr1
    LDA #>612 : STA zp_ptr1+1
    LDA #<850 : STA zp_ptr2
    LDA #>850 : STA zp_ptr2+1
    LDA #6 : STA var_tmpD
    LDA #TANK_CHAR
    JMP vdu_char

; ----------------------------------------------------------------------------
; bar_full - the air bar rectangle x 920-1216, y 40-52 in logical colour 14.
; ----------------------------------------------------------------------------
.bar_full
    LDA #<bar_tbl : STA zp_ptr0
    LDA #>bar_tbl : STA zp_ptr0+1
    LDA #bar_tbl_len
    JMP vdu_seq

.bar_tbl
    EQUB 5
    EQUB 18,0,14
    EQUB 25,4, <920,>920,  40,0
    EQUB 25,4, <1216,>1216,40,0
    EQUB 25,85,<920,>920,  52,0
    EQUB 25,85,<1216,>1216,52,0
bar_tbl_len = 28

; ----------------------------------------------------------------------------
; vdu_seq - send A bytes from the table at zp_ptr0 to OSWRCH.
;   Counters live in memory, not X/Y: this engine does not assume the OS
;   preserves registers (see engine-register conventions).
; ----------------------------------------------------------------------------
.vdu_seq
    STA vs_count
    LDA #0 : STA vs_idx
.vs_loop
    LDY vs_idx
    LDA (zp_ptr0),Y
    JSR oswrch
    INC vs_idx
    DEC vs_count
    BNE vs_loop
    RTS

; ----------------------------------------------------------------------------
; bar_tip_erase - two black columns at O% and O%+8 (GCOL0,15; 15 = black).
; ----------------------------------------------------------------------------
; Template lives in RAM so the two x-coordinates can be patched in place;
; far cheaper than emitting 28 bytes with LDA/JSR pairs.
.bar_tip_erase
    LDA var_air   : STA bte_tbl+6  : STA bte_tbl+12
    LDA var_air+1 : STA bte_tbl+7  : STA bte_tbl+13
    LDA var_air   : CLC : ADC #8 : STA bte_tbl+18 : STA bte_tbl+24
    LDA var_air+1 : ADC #0       : STA bte_tbl+19 : STA bte_tbl+25
    LDA #<bte_tbl : STA zp_ptr0
    LDA #>bte_tbl : STA zp_ptr0+1
    LDA #28
    JMP vdu_seq

; ----------------------------------------------------------------------------
; bar_colour - A = physical colour for logical 14 (VDU19,14,A,0,0,0).
; ----------------------------------------------------------------------------
.bar_colour
    PHA
    LDA #19 : JSR oswrch
    LDA #14 : JSR oswrch
    PLA : JSR oswrch
    LDA #0 : JSR oswrch : LDA #0 : JSR oswrch : LDA #0 : JSR oswrch
    RTS

; ============================================================================
; score_add - SED add BCD value A to var_score+X, rippling the carry.
; print_score - PROCe: six zero-padded digits at TAB(7,0).
; print_counts - PROCB: item char + P% and fish char + L% at row 30.
; ============================================================================
; NOTE: CPX clobbers the carry, so the ripple must NOT rely on carry surviving
; the bounds check - it does an explicit ADC #1 instead. (The earlier version
; used ADC #0 after CPX and silently dropped every hundreds carry, so the score
; oscillated instead of climbing.)
.score_add
    SED
    CLC
    ADC var_score,X
    STA var_score,X
    BCC sa_done
.sa_ripple
    INX
    CPX #3
    BCS sa_done             ; ran off the top of the 6-digit score
    CLC
    LDA var_score,X
    ADC #1
    STA var_score,X
    BCS sa_ripple           ; this byte overflowed too - keep rippling
.sa_done
    CLD
    RTS

.print_score
    LDA #<ps_tbl : STA zp_ptr0
    LDA #>ps_tbl : STA zp_ptr0+1
    LDA #6
    JSR vdu_seq
    LDX #2
.ps_loop
    LDA var_score,X
    LSR A : LSR A : LSR A : LSR A
    CLC : ADC #48 : JSR oswrch
    LDA var_score,X
    AND #&0F
    CLC : ADC #48 : JSR oswrch
    DEX
    BPL ps_loop
    LDA #5 : JSR oswrch
    RTS

; PROCB. The D$ prefix matters twice over: it selects background logical 15
; (black) for the whole HUD row, and it prints the "Air" label.
.print_counts
    LDA #<pc_tbl : STA zp_ptr0
    LDA #>pc_tbl : STA zp_ptr0+1
    LDA #pc_tbl_len
    JSR vdu_seq
    LDA var_item_sprite : JSR oswrch
    LDA #32 : JSR oswrch
    LDA var_items_left : CLC : ADC #48 : JSR oswrch
    ; fish counter only when fish exist this level: l% odd, or l% > 6
    LDA var_level : CMP #7 : BCS pc_fish
    LDA var_level : AND #1 : BEQ pc_tail
.pc_fish
    LDA #<pc_ftbl : STA zp_ptr0
    LDA #>pc_ftbl : STA zp_ptr0+1
    LDA #pc_ftbl_len
    JSR vdu_seq
    LDA var_fish_left : CLC : ADC #48 : JSR oswrch
.pc_tail
    LDA #17 : JSR oswrch : LDA #128 : JSR oswrch   ; background back to 0
    LDA #5  : JSR oswrch
    RTS

.pc_tbl
    EQUB 26,4                       ; reset windows, text at text cursor
    EQUB 17,143                     ; COLOUR 143 -> background logical 15
    EQUB 17,7                       ; COLOUR 7   -> foreground
    EQUB 31,11,30                   ; TAB(11,30)
    EQUB 65,105,114                 ; "Air"
    EQUB 17,7
    EQUB 31,1,30                    ; TAB(1,30) for the item counter
pc_tbl_len = 17

.pc_ftbl
    EQUB 31,6,30                    ; TAB(6,30)
    EQUB 17,6                       ; fish icon in colour 6
    EQUB 241,32
    EQUB 17,7                       ; count in colour 7
pc_ftbl_len = 9

; ============================================================================
; play_snd_ptr - OSWORD 7 with the 8-byte block at snd_ptr.
; ============================================================================
; OSWORD needs X/Y for the parameter block, so this routine saves and restores
; them: callers hold live index values in X/Y around sound effects.
.play_snd_ptr
    TYA : PHA
    TXA : PHA
    LDA #7
    LDX snd_ptr
    LDY snd_ptr+1
    JSR osword
    PLA : TAX
    PLA : TAY
    RTS

; ============================================================================
; level_clear - PROCF + advance: fish hearts bonus (PROCM), air bonus (PROCp),
;   next level, wipe, redraw HUD, re-init all subsystems.
; ============================================================================
.level_clear
    ; --- PROCM: 50 pts + heart per living fish (rising pitches) ---
    LDA var_active : AND #2 : BNE lc_mstart
    JMP lc_air
.lc_mstart
    LDA #0 : STA lc_b
    LDA #0 : STA lc_i
.lc_mloop
    LDX lc_i
    LDA arr_fish_state,X : CMP #2 : BNE lc_malive
    JMP lc_mnext
.lc_malive
    LDA arr_fish_y,X : BNE lc_mgo
    JMP lc_mnext
.lc_mgo
    ; SOUND 2,1,53+4*B,1
    LDA lc_b : ASL A : ASL A : CLC : ADC #53
    STA snd_bonus+4
    LDX #<snd_bonus : STX snd_ptr
    LDX #>snd_bonus : STX snd_ptr+1
    JSR play_snd_ptr
    INC lc_b
    LDX #0 : LDA #&50 : JSR score_add     ; S% += 50
    JSR print_score
    ; heart at (k*16, n*4+40), GCOL0,1
    LDX lc_i
    LDA arr_fish_x,X : STA zp_ptr1
    LDA #0 : STA zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1
    ASL zp_ptr1 : ROL zp_ptr1+1
    LDA arr_fish_y,X : STA zp_ptr2
    LDA #0 : STA zp_ptr2+1
    ASL zp_ptr2 : ROL zp_ptr2+1
    ASL zp_ptr2 : ROL zp_ptr2+1
    LDA zp_ptr2   : CLC : ADC #40 : STA zp_ptr2
    LDA zp_ptr2+1 : ADC #0        : STA zp_ptr2+1
    LDA #5  : JSR oswrch
    LDA #18 : JSR oswrch : LDA #0 : JSR oswrch : LDA #1 : JSR oswrch
    LDA #25 : JSR oswrch : LDA #4 : JSR oswrch
    LDA zp_ptr1 : JSR oswrch : LDA zp_ptr1+1 : JSR oswrch
    LDA zp_ptr2 : JSR oswrch : LDA zp_ptr2+1 : JSR oswrch
    LDA #HEART_CHAR : JSR oswrch
    ; ~0.3s pause between hearts (original waits 15cs)
    LDX #15
.lc_mwait
    TXA : PHA
    LDA #19 : JSR osbyte
    PLA : TAX
    DEX : BNE lc_mwait
.lc_mnext
    INC lc_i
    LDA lc_i : CMP #8 : BCS lc_air
    JMP lc_mloop
.lc_air
    ; --- PROCp: drain remaining air into the score ---
.lc_ploop
    SEC
    LDA var_air   : SBC #<920
    LDA var_air+1 : SBC #>920
    BCC lc_pdone
    ; SOUND &11,-10,O%/8,2
    LDA var_air+1 : LSR A : STA ac_elapsed+1
    LDA var_air   : ROR A
    LSR ac_elapsed+1 : ROR A
    LSR ac_elapsed+1 : ROR A
    STA snd_airbon+4
    LDX #<snd_airbon : STX snd_ptr
    LDX #>snd_airbon : STX snd_ptr+1
    JSR play_snd_ptr
    JSR bar_tip_erase
    SEC
    LDA var_air   : SBC #8 : STA var_air
    LDA var_air+1 : SBC #0 : STA var_air+1
    LDX #0 : LDA #&50 : JSR score_add
    JSR print_score
    LDA #19 : JSR osbyte
    LDA #19 : JSR osbyte
    JMP lc_ploop
.lc_pdone
    ; Level over. The engine does NOT paint the next level: it returns to
    ; BASIC, which owns the scenery (coral, hills, seagrass, boat, palette)
    ; and re-CALLs with dbg_level bumped. See the M5 ABI in memorymap.asm.
    RTS

; ----------------------------------------------------------------------------
; Sound parameter blocks (OSWORD 7: chan;amp;pitch;dur as 16-bit LE each).
; amp 1-4 = ENVELOPE number (envelopes defined by the hosting BASIC).
; ----------------------------------------------------------------------------
.snd_bubble  EQUB &00,&00, &04,&00, &06,&00, &03,&00   ; SOUND 0,4,6,3
.snd_pickup  EQUB &01,&00, &01,&00, &63,&00, &01,&00   ; SOUND 1,1,99,1
.snd_hurt    EQUB &02,&00, &02,&00, &94,&00, &04,&00   ; SOUND 2,2,148,4
.snd_fishdie EQUB &03,&00, &02,&00, &60,&00, &04,&00   ; SOUND 3,2,96,4
.snd_tank    EQUB &02,&00, &03,&00, &F0,&00, &02,&00   ; SOUND 2,3,240,2
.snd_refill  EQUB &01,&00, &01,&00, &50,&00, &01,&00   ; SOUND 1,1,80,1
.snd_bonus   EQUB &02,&00, &01,&00, &35,&00, &01,&00   ; SOUND 2,1,53+4B,1
.snd_airbon  EQUB &11,&00, &F6,&FF, &73,&00, &02,&00   ; SOUND &11,-10,O%/8,2

; ENVELOPE blocks (OSWORD 8) - verbatim from POLY1 PROCenv
.env1 EQUB 1,1,0,0,0,50,25,25,127,&FF,&FF,&FF,126,90
.env2 EQUB 2,3,&FF,0,0,246,0,0,0,0,&FF,&FD,120,120
.env3 EQUB 3,5,15,0,0,72,0,0,&FA,127,0,&F7,0,126
.env4 EQUB 4,&81,0,&F6,&FF,1,0,2,6,&FF,0,&FF,126,74


; ----------------------------------------------------------------------------
; build_row_table - row_table[r] = (screen_base + r*640) DIV 256, r = 0..31.
;   Must run AFTER all disc access (DFS trashes &D00-&D5F). Installs the &40
;   (RTI) guard at &D00 for stray NMIs, as POLY4 does.
; ----------------------------------------------------------------------------
.build_row_table
    LDA #64 : STA row_table_guard
    LDA #<screen_base : STA zp_ptr0
    LDA #>screen_base : STA zp_ptr0+1
    LDX #0
.brt_loop
    LDA zp_ptr0+1
    STA row_table,X
    LDA zp_ptr0 : CLC : ADC #<640 : STA zp_ptr0
    LDA zp_ptr0+1 : ADC #>640 : STA zp_ptr0+1
    INX
    CPX #32
    BNE brt_loop
    RTS


; ----------------------------------------------------------------------------
; read_clock - read the 5-byte centisecond system clock into clock_buf.
; ----------------------------------------------------------------------------
.read_clock
    LDA #1
    LDX #<clock_buf
    LDY #>clock_buf
    JSR osword
    RTS


; ----------------------------------------------------------------------------
; save_zp / restore_zp - preserve BASIC's reclaimed zero page &00-&6F.
; ----------------------------------------------------------------------------
.save_zp
    LDX #0
.sz_loop
    LDA &00,X
    STA zp_savebuf,X
    INX
    CPX #&70
    BNE sz_loop
    RTS

.restore_zp
    LDX #0
.rz_loop
    LDA zp_savebuf,X
    STA &00,X
    INX
    CPX #&70
    BNE rz_loop
    RTS


; ----------------------------------------------------------------------------
; Graphics module (plotshape + check + shape tables) now assembles at its
; production home &900 (as in the shipping game) - saved as its own file.
; See the ORG &900 section at the top of this file.
; ----------------------------------------------------------------------------


; ----------------------------------------------------------------------------
; Engine data (main RAM, not zero page).
; ----------------------------------------------------------------------------
; frame_count lives at fixed &250A (memorymap debug page) for HTTP peeking
.clock_buf      SKIP 5      ; OSWORD 1 destination
.item_saveY     EQUB 0
.hurt_saveX     EQUB 0
.rnd_n          EQUB 0
.air_base       EQUW 0      ; centisecond clock at last air tick (TIME=0)
.ac_elapsed     EQUW 0      ; air_check / bar scratch
.snd_ptr        EQUW 0      ; play_snd_ptr parameter block pointer
.lc_i           EQUB 0      ; level_clear loop index
.lc_b           EQUB 0      ; level_clear bonus counter (pitch steps)
.vs_count       EQUB 0      ; vdu_seq remaining bytes
.vs_idx         EQUB 0      ; vdu_seq table index
.ps_tbl         EQUB 4,17,7,31,7,0          ; print_score prefix: TAB(7,0)
.bte_tbl                                    ; bar_tip_erase, x values patched
    EQUB 5
    EQUB 18,0,15
    EQUB 25,4, 0,0, 52,0
    EQUB 25,5, 0,0, 40,0
    EQUB 25,4, 0,0, 52,0
    EQUB 25,5, 0,0, 40,0
; zp_savebuf now lives at &0B10 (memorymap debug page) to save engine bytes

.engine_end

SAVE "ENGINE", engine_base, engine_end   ; from &0E00 so the data block is included
