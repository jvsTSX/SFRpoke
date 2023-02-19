	.org 0   ; entry point
  jmpf Start
	.org $03 ; External int. (INTO)                 - IO1CR
  reti
	.org $0B ; External int. (INT1)                 - IO1CR
  reti
	.org $13 ; External int. (INT2) and Timer 0 low - I23CR and T0CNT
  reti
	.org $1B ; External int. (INT3) and base timer  - I23CR and BTCR
  reti
	.org $23 ; Timer 0 high                         - T0CNT
  reti
	.org $2B ; Timer 1 Low and High                 - T1CNT
  reti
	.org $33 ; Serial IO 1                          - SCON0
  reti
	.org $3B ; Serial IO 2                          - SCON1
  reti
	.org $43 ; VMU to VMU comms                     - not listed? (160h/161h)
  reti
	.org $4B ; Port 3 interrupt                     - P3INT
  reti
  
  
 	.org	$1f0 ; exit app mode
goodbye:	
	not1	ext,0
	jmpf	goodbye
  
  
  
	.org $200
	.byte "VMU SFR poke    " ; ................... 16-byte Title
	.byte "by https://github.com/jvsTSX    " ; ... 32-byte Description
	.org $240 ; >>> ICON HEADER
	.org $260 ; >>> PALETTE TABLE
	.org $280 ; >>> ICON DATA

;    /////////////////////////////////////////////////////////////
;   ///                       GAME CODE                       ///
;  /////////////////////////////////////////////////////////////

	.include "sfr.i" 
CurrentFrame = $4
LastKeys =     $5
SFRtoPoke =    $6
SFRpoked0 =    $7
SFRpoked1 =    $8
PokeMask =     $9 ; bits to not write to so you can test the other bits in PCON for example
Dummy =        $A ; to test open bus, a dummy write is done here before reading back the result
CurrentMode =  $B
LastMode =     $C
Cursor =       $D
SelMode =      $E

	
	
; ////// START 
Start: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov #0, IE    ; disable ints to configure them first
	mov #%10000000, VCCR
	mov #%00001001, MCR
	mov #%10000001, OCR
	mov #0, P3INT ; i don't want joypad ints
	
	; setup T0
	mov #%01000001, T0CON ; Low running, int enabled
	mov #0, T0PRR
	mov #1, T0L
	mov #$BF, T0LR
	
	; i don't know what these do but they enable T1 to output audio to P1
	mov #$80, P1FCR
	clr1 P1, 7
	mov #$80, P1DDR
	mov #%11010000, T1CNT ; except this one
	mov #$80, IE
	
	mov #$FF, LastKeys
	mov #0, SFRtoPoke
	mov #0, CurrentFrame
	
	mov #1, Cursor
	mov #0, CurrentMode
	mov #1, LastMode
	mov #0, SelMode
	mov #0, PokeMask
	
	mov #$80, P1DDR
	mov #$80, P1FCR
	
MainLoop: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	not1 P1, 7 ; T0 timing check
	
	ld P3 ; get keys from port 3
	st B
;	st $183 ; input test
	ld LastKeys
  be B, .SkipInputs

	push B
	st C
	callf DoInputs
	pop B
	ld B
	st LastKeys
.SkipInputs:
	

; check modes to wipe the screen and change text if needed
	ld CurrentMode
  be LastMode, .NoScreenUpdate
	
	st LastMode
	xor ACC
	st XBNK
	mov #$81, 2
.copyloop:
	mov #0, @r2
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2
	
	ld 2
	add #4
	st 2
	
	mov #0, @r2
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2
	
	ld 2
	add #8
	st 2
  bn PSW, 7, .copyloop
  bp XBNK, 0, .exitloop
	inc XBNK
	set1 2, 7
  br .copyloop
.exitloop:
	
	; update the text in the corner
	mov #<ModeNames, TRL
	mov #>ModeNames, TRH
	ld CurrentMode
	rol
	rol
	rol
	st C
	
	ld C
	ldc
	st $1E4
	inc C
	ld C
	ldc
	st $1E5
	inc C
	ld C
	ldc
	st $1EA
	inc C
	ld C
	ldc
	st $1EB
	inc C
	ld C
	ldc
	st $1F4
	inc C
	ld C
	ldc
	st $1F5
	inc C
	ld C
	ldc
	st $1FA
	inc C
	ld C
	ldc
	st $1FB
.NoScreenUpdate:
	
	; draw the cursor
	mov #<ZeroIcon, TRL
	mov #>ZeroIcon, TRH
  bp CurrentMode, 1, .OtherModes
  bn CurrentMode, 0, .BothRows
	; draw mask row
	xor ACC
	st XBNK
	st B
	ld PokeMask
	st C
	mov #$83, 2
  callf DrawBitReadsRow

  bn SelMode, 0, .NoCursor
; show cursor pos
  bn Cursor, 0, .notat0
	set1 $189, 1
.notat0:
  bn Cursor, 1, .notat1
	set1 $1A9, 1
.notat1:
  bn Cursor, 2, .notat2
	set1 $1C9, 1
.notat2:
  bn Cursor, 3, .notat3
	set1 $1E9, 1
.notat3:
	inc XBNK
  bn Cursor, 4, .notat4
	set1 $189, 1
.notat4:
  bn Cursor, 5, .notat5
	set1 $1A9, 1
.notat5:
  bn Cursor, 6, .notat6
	set1 $1C9, 1
.notat6:
  bn Cursor, 7, .notat7
	set1 $1E9, 1
.notat7:
	dec XBNK
.NoCursor:
	
	; draw other rows
  bp CurrentMode, 0, .SkipDraw ; if write (01), skip
.BothRows:
	
	xor ACC ; draw 1 row (middle)
	st XBNK
	st B
	ld SFRpoked1
	st C
	mov #$82, 2
  callf DrawBitReadsRow
	
.OnlyFirstRow:
	xor ACC ; draw 0 row (first)
	st XBNK
	st B
	ld SFRpoked0
	st C
	mov #$81, 2
  callf DrawBitReadsRow
  br .SkipDraw
	
.OtherModes:
  bp CurrentMode, 0, .SkipDraw ; if quit (11), skip
  br .OnlyFirstRow
.SkipDraw:

	xor ACC
	st XBNK
  callf DrawSFRnumber ; draw what SFR is selected
  jmpf DrawBitNumber  ; refresh the bit indicators
backfrombitnumber:
	mov #1, PCON
  jmp MainLoop

	
	
	
	
DoInputs:  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  bp SelMode, 0, .BitmaskControls
	
	; otherwise regular controls
  bp C, 0, .NoKeyUp
	ld SFRtoPoke
	add #$10
	st SFRtoPoke
.NoKeyUp:

  bp C, 1, .NoKeyDown
	ld SFRtoPoke
	sub #$10
	st SFRtoPoke
.NoKeyDown:

  bp C, 2, .NoKeyLeft
	dec SFRtoPoke
.NoKeyLeft:

  bp C, 3, .NoKeyRight
	inc SFRtoPoke
.NoKeyRight:

	push C
  bp C, 4, .NoA
  bp CurrentMode, 1, .ReadOrQuit
	; or else first two
  bn CurrentMode, 0, .Poke
  br .Write
	
.ReadOrQuit:
  bn CurrentMode, 0, .Read
	mov #0, IE
  jmpf goodbye
	
.Poke:
	ld SFRtoPoke
	st 2
	xor ACC
;	ld @r2
;	and PokeMask
	st @r2
	mov #$AA, ACC
	st Dummy
	ld @r2
	st SFRpoked0

	mov #$FF, ACC	
;	ld @r2
;	or PokeMask
	st @r2
	mov #$AA, ACC
	st Dummy
	ld @r2
	st SFRpoked1
  br .NoA
	
.Write:
	ld SFRtoPoke
	st 2
	ld PokeMask
	st @r2
  br .NoA
	
.Read:
	ld SFRtoPoke
	st 2
	ld @r2
	st SFRpoked0
.NoA:
	pop C

  bp C, 5, .NoB
	bp CurrentMode, 1, .NoB
	bn CurrentMode, 0, .NoB
	not1 SelMode, 0
.NoB:

  bp C, 7, .NoSlp
	inc CurrentMode
	ld CurrentMode
  bne #4, .NoSlp
	mov #0, CurrentMode
.NoSlp:
  ret



.BitmaskControls: ;;;;;;;
  bp C, 0, .NoKeyUpBM
	ld Cursor
	ror
	st Cursor
.NoKeyUpBM:

  bp C, 1, .NoKeyDownBM
	ld Cursor
	rol
	st Cursor
.NoKeyDownBM:	
	
  bp C, 4, .NoABM
	ld PokeMask
	xor Cursor
	st PokeMask
.NoABM:

  bp C, 5, .NoBBM
	not1 SelMode, 0
.NoBBM:
  ret
	
	
	
DrawSFRnumber: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld SFRtoPoke
	and #%11110000
	ror
	ror
	ror
	ror
	st C
	xor ACC
	mov #5, B
	mul
	ld C
	
	mov #<NumbersDisplay, TRL
	mov #>NumbersDisplay, TRH

	ldc
	st $184
	inc C
	ld C
	ldc
	st $18A
	inc C
	ld C
	ldc
	st $194
	inc C
	ld C
	ldc
	st $19A
	inc C
	ld C
	ldc
	st $1A4

	
	
	ld SFRtoPoke ; low nibble
	and #%00001111
	st C
	mov #5, B
	xor ACC
	mul
	
	ld C
	ldc
	st $185
	inc C
	ld C
	ldc
	st $18B
	inc C
	ld C
	ldc
	st $195
	inc C
	ld C
	ldc
	st $19B
	inc C
	ld C
	ldc
	st $1A5

	
	
  ret ; end here
	
	
	
DrawBitReadsRow: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NOTICE THE BYTE YOU WANT TO DISPLAY MUST BE IN C REG
.copyloop:
  bp C, 0, .BitIsOne
	mov #0, B
  br .Skip
.BitIsOne:
	mov #3, B
.Skip:
	
	ld B
	ldc 
	st @r2
	ld 2
	add #6
	st 2
	
	inc B
	ld B
	ldc
	st @r2
	ld 2
	add #10
	st 2
	
	inc B
	ld B
	ldc 
	st @r2
	ld 2
	add #16
	st 2
	
	ld C
	ror
	st C
	
  bn PSW, 7, .copyloop
  bp XBNK, 0, .exit
	inc XBNK
	set1 2, 7
  br .copyloop
	
.exit:
	mov #0, XBNK
  ret
	
	
	
	
DrawBitNumber: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	not1 CurrentFrame, 0
	bp CurrentFrame, 0, .frame0
	; otherwise frame 1 (dark)
	mov #<BitNumbersDark, TRL
	mov #>BitNumbersDark, TRH
  br .gotocopy
.frame0:
	mov #<BitNumbersLight, TRL
	mov #>BitNumbersLight, TRH
.gotocopy:
	
	xor ACC
	st XBNK
	st C
	mov #$80, 2
.copyloop:
	ld C
	ldc
	st @r2
	inc C
	ld 2
	add #6
	st 2
	
	ld C
	ldc
	st @r2
	inc C
	ld 2
	add #10
	st 2

  bn PSW, 7, .copyloop
  bp XBNK, 0, .exit
	inc XBNK
	set1 2, 7
  br .copyloop
	
.exit:
	mov #0, XBNK
  jmpf backfrombitnumber
	
	
ZeroIcon: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.byte %01110000
	.byte %10001000
	.byte %01110000
OneIcon:
	.byte %01100000
	.byte %00100000
	.byte %11111000

NumbersDisplay:
	.byte %01111100 ; 0
	.byte %10001010
	.byte %10010010
	.byte %10100010
	.byte %01111100
	.byte %00110000 ; 1
	.byte %01010000
	.byte %00010000
	.byte %00010000
	.byte %11111110
	.byte %01111100 ; 2
	.byte %10000010
	.byte %00001100
	.byte %01110000
	.byte %11111110
	.byte %01111100 ; 3
	.byte %10000010
	.byte %00011110
	.byte %10000010
	.byte %01111100
	.byte %00100100 ; 4
	.byte %01000100
	.byte %11111110
	.byte %00000100
	.byte %00000100
	.byte %11111110 ; 5
	.byte %10000000
	.byte %11111100
	.byte %00000010
	.byte %11111100
	.byte %01111100 ; 6
	.byte %10000000
	.byte %11111100
	.byte %10000010
	.byte %01111100
	.byte %11111110 ; 7
	.byte %00000010
	.byte %00000100
	.byte %00001000
	.byte %00010000
	.byte %01111100 ; 8
	.byte %10000010
	.byte %01111100
	.byte %10000010
	.byte %01111100
	.byte %01111100 ; 9
	.byte %10000010
	.byte %01111110
	.byte %00000010
	.byte %01111100
	.byte %00010000 ; A
	.byte %00101000
	.byte %01000100
	.byte %11111110
	.byte %10000010
	.byte %11111000 ; B
	.byte %10000110
	.byte %11111000
	.byte %10000110
	.byte %11111000
	.byte %00111110 ; C
	.byte %11000000
	.byte %10000000
	.byte %11000000
	.byte %00111110
	.byte %11111000 ; D
	.byte %10000110
	.byte %10000010
	.byte %10000110
	.byte %11111000
	.byte %11111110 ; E
	.byte %10000000
	.byte %11111100
	.byte %10000000
	.byte %11111110
	.byte %11111110 ; F
	.byte %10000000
	.byte %11111100
	.byte %10000000
	.byte %10000000

BitNumbersLight: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.byte %00110000
	.byte %01001000
	.byte %01001000
	.byte %00110000
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte %01111000
	.byte %00001000
	.byte %00110000
	.byte %01111000
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte %00101000
	.byte %01001000
	.byte %01111000
	.byte %00001000
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte %01111000
	.byte %01000000
	.byte %01111000
	.byte %01111000
	.byte 0
	.byte 0
	.byte 0
	.byte 0

BitNumbersDark:
	.byte %00110000
	.byte %01001000
	.byte %01001000
	.byte %00110000
	.byte %00110000
	.byte %00010000
	.byte %00010000
	.byte %01111000
	.byte %01111000
	.byte %00001000
	.byte %00110000
	.byte %01111000
	.byte %01111000
	.byte %00111000
	.byte %00001000
	.byte %01111000
	.byte %00101000
	.byte %01001000
	.byte %01111000
	.byte %00001000
	.byte %01111000
	.byte %01110000
	.byte %00001000
	.byte %01111000
	.byte %01111000
	.byte %01000000
	.byte %01111000
	.byte %01111000
	.byte %01111000
	.byte %00010000
	.byte %00100000
	.byte %01000000
	
ModeNames:
	.byte %11101110, %10101110
	.byte %10101010, %11001100
	.byte %11101010, %10101000
	.byte %10001110, %10101110

	.byte %10101110, %10111011
	.byte %10101010, %10010011
	.byte %11101100, %10010010
	.byte %11101010, %10010011
	
	.byte %11101110, %01001100
	.byte %10101100, %10101010
	.byte %11001000, %11101010
	.byte %10101110, %10101100
	
	.byte %11101010, %10111000
	.byte %10101010, %10010000
	.byte %11101010, %10010000
	.byte %00101110, %10010000
	