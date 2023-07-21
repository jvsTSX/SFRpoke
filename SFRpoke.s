	.org 0   ; entry point
  jmpf Start
	.org $03 ; External int. (INT0)                 - I01CR
  reti
	.org $0B ; External int. (INT1)                 - I01CR
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
	.org $43 ; Maple                                - 160 and 161
  reti
	.org $4B ; Port 3 interrupt                     - P3INT
	clr1 P3INT, 1
	mov #$F0, WaitCount
  reti

 	.org	$1F0 ; exit app mode
goodbye:	
	not1	EXT, 0
	jmpf	goodbye

	.org $200
	.byte "VMU SFR poke    " ; ................... 16-byte Title
	.byte "by https://github.com/jvsTSX    " ; ... 32-byte Description

	.org $240 ; >>> ICON HEADER
	.include icon "SFRpoke_DCicon.gif"

;    /////////////////////////////////////////////////////////////
;   ///                       GAME CODE                       ///
;  /////////////////////////////////////////////////////////////

	.include "sfr.i" 
LastKeys =      $5
SFRselect =     $6
SFRread =       $7
PokeMask =      $8
Dummy =         $9 ; to test open bus, a dummy write to RAM is done here before reading back the result
PokeMode =      $A
CursorInt =     $B
CursorBit =     $C
LastCurInt =    $D
WaitCount =     $E ; will count some interations of the main loop and sleep when it hits zero
Flags =         $F 
; b7 = update 'W' row
; b6 = update 'R' row
; b5 = update SFR number
; b4 = update mode indicator
; b3 = update cursor
; b2 = unused
; b1 = unused
; b0 = select mode (1 = bit edit mode)
	
; ////// START 
Start: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	xor ACC
	mov #%10000000, VCCR ; LCD ON
	mov #%00001001, MCR ; LCD REFRESH ON, LCD GRAPHICS MODE, 83HZ
	mov #%10100001, OCR

	mov #%11110000, Flags
	mov #$FF, LastCurInt
	mov #$01, CursorBit
	mov #$F0, WaitCount
	st PokeMode
	st SFRselect
	st SFRread
	st CursorInt
	st PokeMask
	st LastKeys

	clr1 T1CNT, 7
	clr1 BTCR, 6
	mov #%00000101, P3INT

	; initialize screen
	mov #$80, 2
	mov #0, XBNK
.Loop:
	xor ACC
	st @r2 ; line 1
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2 ; line 2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	ld 2
	add #5
	st 2
  bnz .Loop
  bp XBNK, 0, .LoopDone
	inc XBNK
	mov #80, 2
  br .Loop
.LoopDone:


; copy the bits row
	mov #<BitNumbers, TRL
	mov #>BitNumbers, TRH
	mov #0, C
	mov #$80, 2
	mov #0, XBNK
	call RowCopy ; draw the bits indication


; draw letters for indicating what row is what
	mov #<ReadIcon, TRL
	mov #>ReadIcon, TRH
	mov #0, C
	mov #$D1, 2
	; XBNK is 1 already
	call RowCopy ; draw R icon
	mov #$D4, 2
	call RowCopy ; draw W icon
	jmp EnterMain



SkipInputs:
  jmp EndMain

MainLoop: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN START
	ld P3 ; get keys from port 3
	st C

	ld LastKeys
  be C, SkipInputs
	ld C
	st LastKeys
  be #$FF, SkipInputs ; whenever the routine enters on key release

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INPUTS
  bp Flags, 0, BitEdit 
; or else select	


  bp C, 0, .NoUp    ;;;;;;;;;;;;;;;;;;;;; increment SFR selector's MSB
	ld SFRselect
	add #$10
	st SFRselect
	set1 Flags, 5
.NoUp:


  bp C, 1, .NoDown  ;;;;;;;;;;;;;;;;;;;;; decrement SFR selector's MSB
	ld SFRselect
	sub #$10
	st SFRselect
	set1 Flags, 5
.NoDown:


  bp C, 2, .NoLeft  ;;;;;;;;;;;;;;;;;;;;; decrement SFR selector's LSB
	dec SFRselect
	set1 Flags, 5
.NoLeft:


  bp C, 3, .NoRight ;;;;;;;;;;;;;;;;;;;;; increment SFR selector's LSB
	inc SFRselect
	set1 Flags, 5
.NoRight:


  bp C, 7, .NoSleep ;;;;;;;;;;;;;;;;;;;;; enter bit edit mode
	not1 Flags, 0
	set1 Flags, 3
.NoSleep:
  br CommonInputs


BitEdit: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  bp C, 0, .NoUp ;;;;;;;;;;;;;;;;;;;;;;;; move cursor up
	ld CursorInt
	sub #%00100000
	st CursorInt
	ld CursorBit
	ror
	st CursorBit
	set1 Flags, 3
.NoUp:


  bp C, 1, .NoDown ;;;;;;;;;;;;;;;;;;;;;; move cursor down
	ld CursorInt
	add #%00100000
	st CursorInt
	ld CursorBit
	rol
	st CursorBit
	set1 Flags, 3
.NoDown:


  bp C, 2, .NoLeft ;;;;;;;;;;;;;;;;;;;;;; flip bit
	ld PokeMask
	xor CursorBit
	st PokeMask
	set1 Flags, 7
	set1 Flags, 3
.NoLeft:


  bp C, 3, .NoRight ;;;;;;;;;;;;;;;;;;;;; flip bit
	ld PokeMask
	xor CursorBit
	st PokeMask
	set1 Flags, 7
	set1 Flags, 3
.NoRight:


  bp C, 7, .NoSleep ;;;;;;;;;;;;;;;;;;;;; exit bit edit mode
	not1 Flags, 0
	mov #0, XBNK ; clear last cursor position, really dumb but fast
	clr1 $189, 1
	clr1 $1A9, 1
	clr1 $1C9, 1
	clr1 $1E9, 1
	inc XBNK	
	clr1 $189, 1
	clr1 $1A9, 1
	clr1 $1C9, 1
	clr1 $1E9, 1
.NoSleep:



CommonInputs:	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  bp C, 4, .NoA ;;;;;;;;;;;;;;;;;;;;;;;;; write
	push C   ; if you write to these, it breaks the app if you do
	push PSW ; so backing 'em up just in case

	ld SFRselect
	st 2
  bp PokeMode, 1, .WrSecondhalf
  bp PokeMode, 0, .WrModeXRAM
	; or else SFR mode
	clr1 2, 7
  br .WrEnd

.WrModeXRAM:
	rolc
	mov #0, ACC
	rolc
	st XBNK
	set1 2, 7
  br .WrEnd

.WrSecondhalf:
  bn PokeMode, 0, .WrModeICON
	set1 T1CNT, 7
	set1 BTCR, 6
	pop PSW
	pop C
  jmpf goodbye ; or else EXIT

.WrModeICON:
	rolc
	mov #1, ACC
	rolc
	st XBNK
	set1 2, 7
.WrEnd:
	ld PokeMask
	st @r2
	set1 Flags, 7

	pop PSW
	pop C

	bn Flags, 0, .NoA
	set1 Flags, 3
.NoA:



  bp C, 5, .NoB ;;;;;;;;;;;;;;;;;;;;;;;;; read
	ld SFRselect
	st 2
  bp PokeMode, 1, .RdSecondHalf
  bp PokeMode, 0, .RdModeXRAM
	; or else SFR mode
	clr1 2, 7
  br .RdEnd

.RdModeXRAM:
	rolc
	mov #0, ACC
	rolc
	st XBNK
	set1 2, 7
  br .RdEnd

.RdSecondHalf:
  bp PokeMode, 0, .NoB
	; or else ICON
	rolc
	mov #1, ACC
	rolc
	st XBNK
	set1 2, 7
.RdEnd:
	mov #%01010101, ACC
	st Dummy
	ld Dummy
	st Dummy
	ld Dummy
	ld @r2
	st SFRread
	set1 Flags, 6
.NoB:


  bp C, 6, .NoMode ;;;;;;;;;;;;;;;;;;;;;; change mode
	ld PokeMode
	inc ACC
	and #%00000011
	st PokeMode
	set1 Flags, 4
	set1 Flags, 5
.NoMode:



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; GRAPHICS UPDATE
EnterMain: ; main loop starts at here for the first time, so graphics are initialized propperly

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; update bit columns
  bn Flags, 7, .NoWriteColRefresh
	ld PokeMask
	mov #$83, 2
	call BitsDraw
	clr1 Flags, 7
.NoWriteColRefresh:

  bn Flags, 6, .NoReadColRefresh
	ld SFRread
	mov #$82, 2
	call BitsDraw
	clr1 Flags, 6
.NoReadColRefresh:



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; update SFR number indicator
  bn Flags, 5, .NoSFRnoRefresh
	mov #<NumbersDisplay, TRL
	mov #>NumbersDisplay, TRH
	mov #0, XBNK
	mov #$84, 2
	ld SFRselect
	ror
	ror
	ror
	ror
	and #$0F
	st C

	ld PokeMode
	bnz .DontResB7
	clr1 C, 3
.DontResB7
	call DrawNumber
	
	mov #$85, 2
	ld SFRselect
	and #$0F
	st C
	call DrawNumber
	
	clr1 Flags, 5
.NoSFRnoRefresh:



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; update mode name
  bn Flags, 4, .NoModeRefresh
	mov #<ModeNames, TRL
	mov #>ModeNames, TRH
	mov #0, XBNK
	ld PokeMode
	rol
	rol
	rol
	st C

	ldc         ; this looks stupid but trust me
	st $1BA    	; a propper loop wouldn't be much better lol
	inc C
	ld C
	ldc
	st $1BB
	inc C
	ld C
	ldc
	st $1C4
	inc C
	ld C
	ldc
	st $1C5
	inc C
	ld C
	ldc
	st $1CA
	inc C
	ld C
	ldc
	st $1CB
	inc C
	ld C
	ldc
	st $1D4
	inc C
	ld C
	ldc
	st $1D5
	
	clr1 Flags, 4
.NoModeRefresh:



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; update cursor position 
  bn Flags, 3, .NoCursorRefresh
	mov #0, XBNK ; clear last cursor position, really dumb but fast
	clr1 $189, 1
	clr1 $1A9, 1
	clr1 $1C9, 1
	clr1 $1E9, 1
	inc XBNK	
	clr1 $189, 1
	clr1 $1A9, 1
	clr1 $1C9, 1
	clr1 $1E9, 1

	mov #0, XBNK  ; locate which half of the screen the cursor is at
  bn CursorInt, 7, .XBNKlow 
	inc XBNK
.XBNKlow:
	
	ld CursorInt ; draw cursor
	or #%10001001
	st 2
	ld @r2
	set1 ACC, 1
	st @r2
	
	clr1 Flags, 3
.NoCursorRefresh:



EndMain:
	; do main a few times before halting to save battery power
	dec WaitCount
	ld WaitCount
  bnz .KeepOnLoop
	mov #1, PCON
.KeepOnLoop: 
  jmp MainLoop






DrawNumber: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; C = number
; 2 = position

	xor ACC
	mov #6, B
	mul
	mov #3, B

.loop:
	ld C
	ldc
	st @r2
	inc C
	ld 2
	add #$6
	st 2

	ld C
	ldc
	st @r2
	inc C
	ld 2
	add #$A
	st 2

	dec B
	ld B
  bnz .loop
  ret



BitsDraw:  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ACC = bits
; C = current bit being drawn
; B = numbers left
; 2 = position
; 3 = bits

	mov #0, XBNK
	mov #<ZeroIcon, TRL
	mov #>ZeroIcon, TRH
	mov #8, B
	st 3

.Loop:
	; get what bit to draw
	mov #0, C
	ld 3
	ror
  bn ACC, 7, .ZeroBit
	set1 C, 2
.ZeroBit:
	st 3
	ld C
	ldc
	st @r2
	ld 2
	add #$6
	st 2
	inc C
	
	ld C
	ldc
	st @r2
	ld 2
	add #$A
	st 2
	inc C
	
	ld C
	ldc
	st @r2
	ld 2
	add #$10
	st 2
	
	dec B
	ld B
  bz .Exit
  bp 2, 7, .Loop
	inc XBNK
	set1 2, 7
  br .Loop	
.Exit:
  ret



RowCopy:    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld C
	ldc
	st @r2
	inc C
	ld 2
	add #$6
	st 2

	ld C
	ldc
	st @r2
	inc C
	ld 2
	add #$A
	st 2

  bn PSW, 7, RowCopy
  bp XBNK, 0, .Exit
	set1 2, 7
	inc XBNK
  br RowCopy
.Exit:
  ret



ZeroIcon: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.byte %01110000
	.byte %10001000
	.byte %01110000
	.byte 0
OneIcon:
	.byte %01100000
	.byte %00100000
	.byte %11111000
	.byte 0

ReadIcon:
	.byte %00110000
	.byte %00101000
	.byte %00110000
	.byte %00101000
	.byte %00101000
	.byte %00101000
WriteIcon:
	.byte %10100000
	.byte %10100000
	.byte %10100000
	.byte %11100000
	.byte %11100000
	.byte %10100000


NumbersDisplay:
	.byte %01111100 ; 0
	.byte %10001010
	.byte %10010010
	.byte %10010010
	.byte %10100010
	.byte %01111100
	.byte %00010000 ; 1
	.byte %00110000
	.byte %01010000
	.byte %00010000
	.byte %00010000
	.byte %11111110
	.byte %01111100 ; 2
	.byte %10000010
	.byte %00000010
	.byte %00011100
	.byte %01100000
	.byte %11111110
	.byte %01111100 ; 3
	.byte %10000010
	.byte %00011100
	.byte %00000010
	.byte %10000010
	.byte %01111100
	.byte %00100100 ; 4
	.byte %01000100
	.byte %10000100
	.byte %11111110
	.byte %00000100
	.byte %00000100
	.byte %11111110 ; 5
	.byte %10000000
	.byte %11111100
	.byte %00000010
	.byte %10000010
	.byte %01111100
	.byte %00111100 ; 6
	.byte %01000000
	.byte %10000000
	.byte %11111100
	.byte %10000010
	.byte %01111100
	.byte %11111110 ; 7
	.byte %00000010
	.byte %00000100
	.byte %00001000
	.byte %00010000
	.byte %00100000
	.byte %00111100 ; 8
	.byte %01000010
	.byte %00111100
	.byte %11000010
	.byte %10000010
	.byte %01111100
	.byte %01111100 ; 9
	.byte %10000010
	.byte %01111110
	.byte %00000010
	.byte %00000100
	.byte %01111000
	.byte %00000110 ; A
	.byte %00001010
	.byte %00010010
	.byte %00111110
	.byte %01000010
	.byte %10000010
	.byte %11111100 ; B
	.byte %10000010
	.byte %11111100
	.byte %10000010
	.byte %10000010
	.byte %11111100
	.byte %01111100 ; C
	.byte %10000010
	.byte %10000000
	.byte %10000000
	.byte %10000010
	.byte %01111100
	.byte %11111000 ; D
	.byte %10000110
	.byte %10000010
	.byte %10000010
	.byte %10000110
	.byte %11111000
	.byte %11111110 ; E
	.byte %10000000
	.byte %11111000
	.byte %10000000
	.byte %10000000
	.byte %11111110
	.byte %11111110 ; F
	.byte %10000000
	.byte %11111000
	.byte %10000000
	.byte %10000000
	.byte %10000000


BitNumbers:
	.byte %11100000 ; 0
	.byte %10100000
	.byte %10100000
	.byte %11100000
	.byte %00011000 ;  1
	.byte %00001000
	.byte %00001000
	.byte %00011100
	.byte %11000000 ; 2
	.byte %00100000
	.byte %11000000
	.byte %11100000
	.byte %00011100 ;  3
	.byte %00001100
	.byte %00000100
	.byte %00011100
	.byte %00100000 ; 4
	.byte %10100000
	.byte %11100000
	.byte %00100000
	.byte %00011100 ;  5
	.byte %00011000
	.byte %00000100
	.byte %00011000
	.byte %11100000 ; 6
	.byte %10000000
	.byte %11100000
	.byte %11100000
	.byte %00011100 ;  7
	.byte %00000100
	.byte %00001000 
	.byte %00001000


ModeNames:
	.byte %01101110, %11000000 ; SFR
	.byte %11001000, %10100000
	.byte %00101100, %11000000
	.byte %11101000, %10100000

	.byte %10100100, %10010001 ; XRAM
	.byte %01001001, %01011011
	.byte %10101001, %11010101
	.byte %10101001, %01010001

	.byte %10011001, %10010010 ; ICON
	.byte %10100010, %01011010
	.byte %10100010, %01010110
	.byte %10011001, %10010010

	.byte %11101010, %10111000 ; EXIT
	.byte %11000100, %10010000
	.byte %10001010, %10010000
	.byte %11101010, %10010000
	
	.cnop 0, $200 