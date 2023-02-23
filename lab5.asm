;***********************************************************
;*	This is the skeleton file for Lab 5 of ECE 375
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m32U4def.inc"				; Include definition file

;************************************************************
;* Variable and Constant Declarations
;************************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	waitcnt = r17				; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
.def	lcnt = r3				; Left bumper counter
.def	rcnt = r4				; Right bumper counter

.equ	WTime = 200				; Time to wait in wait loop

.equ	WskrR = 4				; Right Whisker Input Bit
.equ	WskrL = 5				; Left Whisker Input Bit

.equ	EngEnR = 5				; Right Engine Enable Bit
.equ	EngEnL = 6				; Left Engine Enable Bit
.equ	EngDirR = 4				; Right Engine Direction Bit
.equ	EngDirL = 7				; Left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

;**************************************************************
;* Beginning of code segment
;**************************************************************
.cseg

;--------------------------------------------------------------
; Interrupt Vectors
;--------------------------------------------------------------
.org	$0000				; Reset and Power On Interrupt
		rjmp	INIT		; Jump to program initialization

.org	$0002
		rjmp	HitRight	; Call right whisker

.org	$0004
		rjmp	HitLeft		; Call left whisker

.org	$002E				; End of Interrupt Vectors
;--------------------------------------------------------------
; Program Initialization
;--------------------------------------------------------------
INIT:
    ; Initialize the Stack Pointer (VERY IMPORTANT!!!!)
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

    ; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low

	; Initialize Port D for input
		ldi		mpr, (0 << WskrL | 0 << WskrR)		; Set wiskers on port D as output
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd		; Load Move Forward Command
		out		PORTB, mpr		; Send command to motors

	; Initialize interrupts to trigger on falling edge
		ldi 	mpr,0b00101010	;set pins to read falling edge
		sts		EICRA, mpr

	; Enable the external pins to recive the values
		ldi		mpr, 0b00001011	;enable both wiskers for when they are hit
		out		EIMSK, mpr

	; Init the LCD
		RCALL LCDInit
		RCALL LCDClr
		RCALL LCDBacklightOn
	; Clear the Counters
		CLR lcnt
		CLR rcnt
	; Show the counter
		RCALL SHOW_COUNT

	; Enable interrupts
		;should be last thing in INIT, lest we wish to anger the assembly gods

		sei 		;set global interrupt flag
	
;---------------------------------------------------------------
; Main Program
;---------------------------------------------------------------

;commented out majority of main funcitons because the function was set up for polling, with interrupts only need the main is moving forward

MAIN:
; Move Forward again
		
	; Nothing is needed in main because our move forward is called in the hit functions, so all that remains is this single comment to be skipped for all eternity, not once will the AVR board read or understand it
	
		rjmp	MAIN	;loops main so the bot will forever move forward, but it cant because it has not the legs for it nor the wheels, it lives a tragic life that I dont not envy yet hope for its happines

;---------------------------------------------------------
;grave yard for the main function, lost but not forgotten
;---------------------------------------------------------
		;in		mpr, PIND		; Get whisker input from Port D
		;andi	mpr, (1<<WskrR|1<<WskrL)
		;cpi		mpr, (1<<WskrL)	; Check for Right Whisker input (Recall Active Low)
		;brne	NEXT			; Continue with next check
		;rcall	HitRight		; Call the subroutine HitRight
		;rjmp	MAIN			; Continue with program
;NEXT:	cpi		mpr, (1<<WskrR)	; Check for Left Whisker input (Recall Active)
		;brne	MAIN			; No Whisker input, continue program
		;rcall	HitLeft			; Call subroutine HitLeft
				; Continue through main


;****************************************************************
;* Subroutines and Functions
;****************************************************************

;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:
		INC		rcnt		; Increase the amount of hits.
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		RCALL HIT_SCREEN	; Show that it's been hit
		RCALL	SHOW_COUNT	; Show the counter again.

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port
		

		;clear queue for interrupts
		ldi		mpr,$00
		out		EIFR,mpr	;clear the interrupt queue to account for excess calls

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		reti				; Return from subroutine

;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		INC	lcnt			; Increase the amount of hits.
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		RCALL HIT_SCREEN	; Show that it's been hit
		RCALL	SHOW_COUNT	; Show the counter again.

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		;clear queue for interrupts
		ldi	mpr,$00
		out	EIFR,mpr	;clear the interrupt queue to account for excess calls

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		reti				; Return from subroutine

;----------------------------------------------------------------
; Func: SHOW_COUNT
; Desc: Get the count for each hit and display it on the screen
;----------------------------------------------------------------
SHOW_COUNT:
	PUSH XL
	PUSH XH
	PUSH ZL
	PUSH ZH
	PUSH mpr
	PUSH ilcnt
	; Load in the text for the top
	LDI ZL, LOW(STR_CNT_TOP << 1)	; Program memory of the string
	LDI ZH, HIGH(STR_CNT_TOP << 1)
	LDI XL, $00 ; Data memory of the buffer
	LDI XH, $01

	; Put the string into the
	LDI ilcnt, 6
	TOP_STRING_LOOP:
		LPM mpr, Z+
		ST X+, mpr
		DEC ilcnt
		BRNE TOP_STRING_LOOP

	; Load in the count
	MOV mpr, lcnt
	; Convert to ASCII
	RCALL BIN2ASCII

	; Load in the text for the bottom
	LDI ZL, LOW(STR_CNT_BOT << 1)	; Program memory of the string
	LDI ZH, HIGH(STR_CNT_BOT << 1)
	LDI XL, $10 ; Data memory of the buffer
	LDI XH, $01

	; Put the string into the
	LDI ilcnt, 7
	BOT_STRING_LOOP:
		LPM mpr, Z+
		ST X+, mpr
		DEC ilcnt
		BRNE BOT_STRING_LOOP

	; Load in the count
	MOV mpr, rcnt
	; Convert to ASCII
	RCALL BIN2ASCII

	; Render the screen.
	RCALL LCDWrite

	POP ilcnt
	POP mpr
	POP ZH
	POP ZL
	POP XH
	POP XL

	RET


;----------------------------------------------------------------
; Func: HIT_SCREEN
; Desc: Clears the screen and flashes.
;----------------------------------------------------------------
HIT_SCREEN:
	PUSH ilcnt	; Counter for waiting .25 seconds
	PUSH olcnt	; Counter for how many flashes
	PUSH mpr	; State of the LCD backlight.
	PUSH XL
	PUSH XH
	PUSH ZL
	PUSH ZH
	; Clear the screen
	RCALL LCDClr

	; Load in the Ouch text!
	LDI ZL, LOW(STR_HIT_STRING << 1)
	LDI ZH, HIGH(STR_HIT_STRING << 1)
	; Load in the LCD buffer
	LDI XL, $05
	LDI XH, $01
	; Loop count
	LDI olcnt, 5
	HIT_LOAD_LOOP:
		LPM mpr, Z+
		ST X+, mpr
		DEC olcnt
		BRNE HIT_LOAD_LOOP

	; Render the LCD
	RCALL LCDWrite

	LDI mpr, 1	; Set to 1, as it's on by default.
	LDI olcnt, 8; Clear out outer count
	FLASH_LOOP:
		LDI ilcnt, 250
		CPI mpr, 0
		; Check to see if we should turn on or turn off the display.
		BREQ TURN_ON
			; Turn off the display
			RCALL LCDBacklightOff
			DEC mpr ; Set mpr to 0
			RJMP LCD_END
		TURN_ON:
			; Turn on the display
			RCALL LCDBacklightOn
			INC mpr ; Set mpr to 1
		LCD_END:
		; Loop 250 times to wait 1/4 second
		RCALL LCDDelay
		DEC ilcnt
		BRNE LCD_END
		; Decrement the outer count and see if we should break out
		DEC olcnt
		BRNE FLASH_LOOP
	; Done, make sure the LCD is on and the screen is cleared
	RCALL LCDBacklightOn
	RCALL LCDClr

	POP ZH
	POP ZL
	POP XH
	POP XL
	POP mpr
	POP olcnt
	POP ilcnt

	RET


;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

.include "LCDDriver.asm"

STR_CNT_TOP:
.DB		"Left: "
STR_CNT_BOT:
.DB		"Right:  "
STR_HIT_STRING:
.DB		"Ouch! "
STR_END:

