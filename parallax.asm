.include "x16.inc"
.include "macros.inc"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

  jmp start

default_irq_vector: .addr 0
VSYNC_BIT = $83 ;enable vsync, line IRQs and turning on the 8 bit of the line interupt
increment: .byte 0
scroll_ammount: .byte 4;this is the speed of the foreground.
TILESET_START = $F800
display_scale = 64
frame: .byte 0
background_list: .byte 0,1,2,3,4,5,6,7,8,9,10,11,12,13,0
line_index: .byte 0
parallax_blocks: ;these are all above 255 so just make sure ise bit is set
  .byte 0,16,32,48
  .byte 64,80,96,112
  .byte 128,144,160,176
  .byte 192,208
increment_div:
  .byte 255,128,64,32
  .byte 16,8,4,3
  .byte 2,1,1,1
  .byte 1,1
scroll: .byte 0,0,0,0 ,0,0,0,0 ,0,0,0,0 ,0,0
scroll_counter: .byte 0,0,0,0 ,0,0,0,0 ,0,0,0,0 ,0,0



start:
  sei

  lda parallax_blocks
  sta VERA_irqline_l

  lda #display_scale
  sta VERA_dc_hscale
  sta VERA_dc_vscale
  lda VERA_L1_config
  ora #$02
  sta VERA_L1_config
  lda VERA_L1_tilebase
  ora #$03
  sta VERA_L1_tilebase

  jsr loadpallet
  jsr loadtileset
  jsr fillbackground


  lda IRQVec
  sta default_irq_vector
  lda IRQVec+1
  sta default_irq_vector+1

  lda #<update
  sta IRQVec
  lda #>update
  sta IRQVec+1
  lda #VSYNC_BIT ; make VERA only generate VSYNC IRQs
  sta VERA_ien

  cli
  jmp main

scroll_positions:
  ;rather than dividing I believe this is quicker to have a counter based
  ;on a ratio. This way the slower sections are a product of forground movement
  ;rather than the latter.
  ldy #0
  @ratio_loop:
  cpy scroll_ammount
  beq @done
    inc scroll_counter
    inc scroll_counter+1
    inc scroll_counter+2
    inc scroll_counter+3
    inc scroll_counter+4
    inc scroll_counter+5
    inc scroll_counter+6
    inc scroll_counter+7
    inc scroll_counter+8
    inc scroll_counter+9
    inc scroll_counter+10
    inc scroll_counter+11
    inc scroll_counter+12
    inc scroll_counter+13
    ldx #0
    @increment_loop:
      lda increment_div,x
      inc
      cmp scroll_counter,x
      bne @next
      inc scroll,x
      stz scroll_counter,x
      lda #16
      cmp scroll,x
      bne @next
      stz scroll,x
      @next:
      inx
      cpx #14
      bne @increment_loop
    iny
    jmp @ratio_loop
  @done:
  rts

reset_screen_scroll:
  stz VERA_L1_hscroll_l
  rts

warp_screen:
  ldx increment
  lda scroll,x
  sta VERA_L1_hscroll_l
  stz VERA_L1_hscroll_h
  inc increment
  lda #14
  cmp increment
  bne @done
  stz increment
@done:
  ldx increment
  lda parallax_blocks,x
  sta VERA_irqline_l
  rts

loadpallet:
  lda #$00
  sta VERA_addr_low
  lda #$FA
  sta VERA_addr_high
  lda #$11
  sta VERA_addr_bank
  ldx 0
@loop:
  lda palette,x
  sta VERA_data0
  inx
  cpx #64
  bne @loop
  rts

divide: ;ZP_PRT_1 = dividend, ZP_PTR_2 = divisor, ZP_PTR_3 = remainder
        ;result is stored in ZP_PRT_1
  stz ZP_PTR_3
  ldx #8
@loop:
  asl ZP_PTR_1
  rol ZP_PTR_3
  lda ZP_PTR_3
  sec
  sbc ZP_PTR_2
  bcc @done
  sta ZP_PTR_3
  inc ZP_PTR_1
@done:
  dex
  bne @loop
  rts

loadtileset:
  VERA_SET_ADDR TILESET_START, 1
  store_16_value ZP_PTR_1, tileset
@loop:
  lda (ZP_PTR_1)
  sta VERA_data0
  add_16_value ZP_PTR_1, 1
  compare_16_value ZP_PTR_1, (tileset + 1792), @loop
  rts

inc_frame:
  inc frame
  lda #60
  cmp frame
  bne @continue
  lda #0
@continue:
  rts

fillbackground:
  lda #$10
  sta VERA_addr_bank
  ldy #0
  @yloop:
    stz VERA_addr_low
    tya
    sta VERA_addr_high
    ldx #0
    @xloop:
      lda background_list,y
      sta VERA_data0
      lda #$10
      sta VERA_data0
      inx
      cpx #24
      bne @xloop
    iny
    cpy #15
    bne @yloop
  rts

main:
  wai
  jmp main

update:
  lda VERA_isr
  and #$01
  bne @frame_update
  lda VERA_isr
  and #$02
  bne @line_update
  jmp @continue
@frame_update:
  jsr inc_frame
  jsr scroll_positions
  jsr reset_screen_scroll
@line_update:
  jsr warp_screen
  lda VERA_isr
  ora #$02
  sta VERA_isr
  ply
  plx
  pla
  rti
@continue:
  jmp (default_irq_vector)

palette:
  .include "palette.inc"
tileset:
  .include "tileset.inc"
