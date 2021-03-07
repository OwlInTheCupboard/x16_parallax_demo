.ifndef MACROS_INC
MACROS_INC  = 1

;macros taken from Aloevera examples (https://github.com/yeastplume/aloevera)

.macro add_16_value addr, value
	clc
	lda addr
	adc #<value
	sta addr
	lda addr + 1
	adc #>value
	sta addr + 1
.endmacro

.macro store_16_value addr, value
  lda #<value
  sta addr
  lda #>value
  sta addr +1 
.endmacro

.macro compare_16_value addr, value, loop_label
  lda addr+1
  cmp #>value
  bne loop_label
  lda addr
  cmp #<value
  bne loop_label
.endmacro

.endif
