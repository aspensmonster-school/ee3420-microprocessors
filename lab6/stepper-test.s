; vim: set filetype=asmhc12:

#include ../HC12TOOLS.INC

;;DEBUG	EQU 1


          ORG $1000
MINIMUM_STEP_DELAY	EQU	5

STEP_DELAY	DC.W MINIMUM_STEP_DELAY

;ON DRAGON12-PLUS USING SN754410 QUAD HALF-H DRIVER 
;WIRE COILS A AND C(A') ON PINS 0-1, B AND D(B') ON PINS 2-3 FOR 2-PHASE BIPOLAR
COIL_A EQU BIT0
COIL_C EQU BIT1
COIL_B EQU BIT2
COIL_D EQU BIT3
	DBCA		;0101        0110           1010             1001
STEP_SEQUENCE DC.B  COIL_A+COIL_B,COIL_B+COIL_C,COIL_C+COIL_D,COIL_D+COIL_A

STEP_INCREMENT	DC.B 0
STEP_OFFSET	DC.B 0

PROMPT1	DC.B "STEPPER MOTOR CONTROL FOR 2-PHASE BIPOLAR STEPPER",CR,LF
	DC.B "VIA PORT B PINS 0-3 THROUGH SN754410",CR,LF
	DC.B "MAY ALSO BE USED FOR 4-PHASE UNIPOLAR IN DUAL COIL MODE",CR,LF,CR,LF
	DC.B "WIRE AS FOLLOWS:",CR,LF
	DC.B "COIL A TO MOTOR1 (PIN B0)",CR,LF
	DC.B "COIL C(A') TO MOTOR2 (PIN B1)",CR,LF
	DC.B "COIL B TO MOTOR3 (PIN B2)",CR,LF
	DC.B "COIL D(B') TO MOTOR4 (PIN B3)",CR,LF
	DC.B "NOTE: JUMPER J24 SHOULD BE MOVED TO J18",CR,LF
	DC.B "NOTE: PORT P0-P1 USED FOR MOTOR ENABLE, PIN J1 USED FOR LED ENABLE",CR,LF
	DC.B "NOTE,PORT H DIP SWITCHES ADJUST STEP DELAY IN MS",CR,LF,CR,LF
	DC.B "COMMANDS:",CR,LF
	DC.B "1: CONTINUOUS COUNTERCLOCKWISE STEPPING",CR,LF	
	DC.B "2: SINGLE COUNTERCLOCKWISE STEP",CR,LF	
	DC.B "3: SINGLE CLOCKWISE STEP",CR,LF
	DC.B "4: CONTINUOUS CLOCKWISE STEPPING",CR,LF,CR,LF
	DC.B "PRESS ANY OTHER KEY ON KEYBOARD TO QUIT",CR,LF,CR,LF,NULL

NEWLINE	DC.B CR, LF, NULL

DELAY_MESSAGE	DC.B "DELAY IN MILLISECONDS: ",NULL
BUFFER	DS.B	40


	ORG $2000
MAIN:	MOVB #0, DDRH		;SET PORT H FOR INPUT FROM SWITCHES
	BSET DDRJ,BIT1
	BCLR PORTJ,BIT1		;ENABLE DISCRETE LEDS	

	MOVB #$0F, DDRP		;SET PORT P FOR OUTPUT
	MOVB #$0F, PORTP	;ENABLE SN754410 CHANNELS
	MOVB #$0F, DDRB		;ENABLE PORT B OUTPUT
	LDAA STEP_SEQUENCE	;LOAD INITIAL STEPPER POSITION
	STAA PORTB

	MOVB #1,STEP_INCREMENT
	MOVB #0,STEP_OFFSET

	PUTS #PROMPT1


LOOP1: 	
	BRSET SCI0SR1,SCI_RDRF,KEY_INPUT	;IF NO KEY PRESSED 		
	LBRA TAKE_STEP

KEY_INPUT:
	GETC_SCI0
	CMPB #'1'
	LBEQ CCW_C
	CMPB #'2'
	LBEQ CCW_S
	CMPB #'3' 
	LBEQ CW_S
	CMPB #'4'
	LBEQ CW_C
	LBRA DONE

CCW_C: MOVB #-1,STEP_INCREMENT
	LBRA TAKE_STEP	

CCW_S: MOVB #0,STEP_INCREMENT
	LDAA STEP_OFFSET
	DECA
	ANDA #3
	STAA STEP_OFFSET
	LBRA LOOP1

CW_S:MOVB #0,STEP_INCREMENT
	LDAA STEP_OFFSET
	INCA
	ANDA #3
	STAA STEP_OFFSET
	LBRA LOOP1

CW_C: MOVB #1,STEP_INCREMENT
	LBRA TAKE_STEP	

TAKE_STEP:
	LDAB STEP_OFFSET
	ADDB STEP_INCREMENT
	ANDB #%00000011
	STAB STEP_OFFSET
	TFR B,X
	LDAA STEP_SEQUENCE,X
	STAA PORTB


FIND_DELAY:
	LDAB PORTH			;READ DIP SWITCHES
	CLRA
	CMPD #MINIMUM_STEP_DELAY
	BGE NEXT1
	LDD #MINIMUM_STEP_DELAY
NEXT1		CMPD STEP_DELAY
	STD STEP_DELAY
;	BEQ NEXT2
;	PUTS #DELAY_MESSAGE
;	ITOA STEP_DELAY,#BUFFER
;	PUTS #BUFFER
;	PUTS #NEWLINE
	
NEXT2 
	DELAY_BY_MS STEP_DELAY	

	LBRA LOOP1		;REPEAT INDEFINITELY



DONE:
	CLR PORTB
	CLR PORTP


	RTS			;END OF MAIN


	
