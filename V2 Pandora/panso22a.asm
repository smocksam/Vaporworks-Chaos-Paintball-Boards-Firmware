;
;  PROGDESC: Multi-Marker Entropy code
;  LANGUAGE: 8051 Assembler
;   VERSION: 02.00 - 01/05/2004
;   COMPANY: Vaporworks
;    AUTHOR: Richard D. Slaughter
;
;****************************************************************************
;
;  WARNING: This program source code and compiled object code is copyright
;           (c) 2003 Richard D. Slaughter, 712 Walnut, Little Rock
;		AR 72205 and Vaporworks
;
;           All rights reserved.  Use, sale, duplication, or copying entirely,
;           or in part, without the express written permission of Defiance Custom
;           Paintball is a violation of federal and international copyright
;           laws and is subject to criminal prosecution to the full extent 
;           of the law.
;f
;****************************************************************************
.list off
;
; Modification history (Most recent first)                    
;
;   Version  Date      Description                       
;   -------  --------  ------------------------------------------------------
;	01.00	04/25/03	Initial release
;	01.10	12/16/03	Initial update for Intimidator
;	01.11	....		bug fixes
;	01.12	....		bug fixes
;	01.13	....		bug fixes
;	01.14	....		bug fixes
;	01.15	....		bug fixes
;	01.16	....		bug fixes
;	01.17	....		bug fixes
;	01.18	....		bug fixes
;	01.18a	....		bug fixes
;	02.00	01/05/2003	Added 2-solenoid detection, menus, and operations
;	02.01
;	02.02
;	02.03	01/09/2003	Minor bugfixes^^
;	02.04	01/09/2004	Updated eye bypass routine
;
;****************************************************************************
;
;   Overview of program:                           
;   1. This program is the main code module for the Entropy
;      gun controller upgrade microprocessor.   
;
;   2. This program is an embedded application designed to run on a
;      Atmel 89S8252.
;
;***************************************************************************
;
; 89C8252 I/O Port Definitions 
;
;       89S8252
;            Port    Mode    Function
;
;	P0.7	IO	FREE
;	P0.6	IO	FREE
;	P0.5	IO	FREE
;	P0.4	IO	FREE
;	P0.3	IO	FREE
;	P0.2	IO	FREE
;	P0.1	IO	FREE
;	P0.0	IO	FREE
;
;	P1.7	Out	LCD data 4 (data)
;	P1.6	Out	LCD data 3 (data)
;	P1.5	Out	LCD data 2 (data)	(ALSO ISP data)
;	P1.4	Out	LCD data 1 (data)	(ALSO ISP data)
;	P1.3	Out	LCD con 1 (data)	(ALSO ISP data)
;	P1.2	In	Tourney Lock (low=lock)
;	P1.1	In	Button 1 input (low=push)
;	P1.0	In	Button 2 input (low=push)
;
;	P2.7	IO	V-meter CLK
;	P2.6	IO	Solenoid 2 detection pin
;	P2.5	IO	V-meter DATA
;	P2.4	IO	Solenoid 2 output
;	P2.3	IO	FREE
;	P2.2	IO	FREE
;	P2.1	IO	FREE
;	P2.0	IO	FREE
;
;	P3.7	In	Eye input (low=blocked)
;	P3.6	Out	LED2 output (high=on)
;	P3.5	Out	Valve output (low=on)
;	P3.4	Out	LED output (high=on)
;	P3.3	Out	Eye enable (high=on)
;	P3.2	In	Trigger input (low=pull)
;	P3.1	Out	LCD Con 2 (data)
;	P3.0	Out	LCD Backlight (low=on)
;
;	-	Reset	Reset - Active high 
;	-	X2	12 Mhz crystal 
;	-	X1	12 Mhz crystal
;
;	-	Power	Vss
;	-	Power	Vcc
;
; ======================================================================
;                         System Constants
; ======================================================================
.chip	8051
.fillchar	0ffh
	program:	.section	CODE
	udata:		.section	CODE
.program
				;
				;
				; Software version definition
				;
MAJ	EQU	"2"		; Major software release version
MIN	EQU	"2"		; Minor software release version
				;
				; CPU initialization constants
				;
PSWX    EQU     000H    	; Initialize processor status word (PSW)
				; PSW.7  Carry flag (CY)
				; PSW.6  Auxiliary carry flag (AC)
				; PSW.5  Flag 0 (HV delta sign flag)
				; PSW.4  Register bank select (RS1)
				; PSW.3  Register bank select (RS0)
				; PSW.2  Overflow flag (OV)
				; PSW.1  User flag (Serial interrupt flag)
				; PSW.0  Parity flag (P)
				;
PCONX   EQU     000H    	; Initialize Power Control Register (PCON)
				; PCON.7  Not used on 89C1051
				; PCON.6  Reserved
				; PCON.5  Reserved
				; PCON.4  Reserved
				; PCON.3  General purpose flag (GF1)
				; PCON.2  General purpose flag (GF0)
				; PCON.1  Power down bit (PD)
				; PCON.0  Idle mode bit (IDL)
				;
IEX     EQU     083H    	; Initialize interrupt enable register (IE)
				; IE.7  Disable all interrupts
				; IE.6  Reserved
				; IE.5  Not used on 89C1051
				; IE.4  Not used on 89C1051
				; IE.3  Not used on 89C1051
				; IE.2  Enable External Interrupt 1
				; IE.1  Enable the Timer0 interrupt
				; IE.0  Enable External Interrupt 0
				;
IPX     EQU     000H    	; Initialize interrupt priority register (IP)
				; IP.7  Reserved
				; IP.6  Reserved 
				; IP.5  8052 use only (PT2)
				; IP.4  Not used on 89C1051
				; IP.3  Not used on 89C1051
				; IP.2  External interrupt 1 priority (PX1)
				; IP.1  Timer 0 interrupt priority (PT0)
				; IP.0  External interrupt 0 priority (PX0)
				;
TCONX   EQU     005H    	; Initialize timer control register (TCON)
				; TCON.7  Not used on 89C1051
				; TCON.6  Not used on 89C1051
				; TCON.5  Timer 0 overflow flag (TF0)
				; TCON.4  Timer 0 run control bit (TR0)
				; TCON.3  External interrupt 1 active flag (IE1)
				; TCON.2  External interrupt 1 edge sensitive (IT1)
				; TCON.1  External interrupt 0 active flag (IE0)
				; TCON.0  External interrupt 0 edge sensitive (IT0)
				;
TMODX   EQU     001H    	; Initialize timer/counter control register
				; T1:Mode 2, T0:Mode 1 
				; TMOD.7  Not used on 89C1051
				; TMOD.6  Not used on 89C1051
				; TMOD.5  Not used on 89C1051
				; TMOD.4  Not used on 89C1051
				; TMOD.3  Timer 0 gate (GATE)
				; TMOD.2  Timer 0 counter/timer mode (C/T)
				; TMOD.1  Timer 0 mode selector bit (M1)
				; TMOD.0  Timer 0 mode selector bit (M0)
				;
				; Program constants		
EPORT	EQU	0B0H		; eye is port 3
EBIT	EQU	7		; pin 7
L2PORT	EQU	0B0H		; LED is p3
L2BIT	EQU	6		; pin 4
VPORT	EQU	0B0H		; valve is p3
VBIT	EQU	5		; pin 5
LPORT	EQU	0B0H		; LED is p3
LBIT	EQU	4		; pin 4
EEPORT	EQU	0B0H		; Eye Enable port is p3
EEBIT	EQU	3		; pin 3
TPORT	EQU	0B0H		; trigger is p3
TBIT	EQU	2		; pin 2
E_PORT	EQU	0B0H		; LCD Control 1 port is 3
E_BIT	EQU	1		; pin 1
LBLPORT	EQU	0B0H		; LCD Backlight is port 3
LBLBIT	EQU	0		; pin 0
LDPORT	EQU	090H		; LCD 4-bit data bus is port 1 (bits 7-4)
RSPORT	EQU	090H		; LCD control 3 port is 1
RSBIT	EQU	3		; pin 3
TLPORT	EQU	090H		; Tourney Lock is port 1
TLBIT	EQU	2		; pin 2
B2PORT	EQU	090h		; button 2 is port 1
B2BIT	EQU	1		; pin 1
B1PORT	EQU	090h		; button 1 is port 1
B1BIT	EQU	0		; pin 0
VCPORT	EQU	0A0h		; V-in clk is port 2
VCBIT	EQU	5		; V-in clk is bit 7
VDPORT	EQU	0A0h		; V-in data is port 2
VDBIT	EQU	7		; V-in data is bit 5
V2PORT	EQU	0A0h		; 
V2BIT	EQU	4		; 
VTPORT	EQU	0A0h		; 
VTBIT	EQU	6		; 
FT1	EQU	0D		; 20/UL bps
FT2	EQU	55D		; 18 bps
FT3	EQU	62D		; 16 bps
FT4	EQU	70D		; 14 bps
FT5	EQU	76D		; 13 bps
FT6	EQU	82D		; 12 bps
FT7	EQU	99D		; 10 bps
FT8	EQU	110D		; 9 bps
DFT1	EQU	49D		; 20/UL bps
DFT2	EQU	55D		; 18 bps
DFT3	EQU	62D		; 16 bps
DFT4	EQU	70D		; 14 bps
DFT5	EQU	76D		; 13 bps
DFT6	EQU	82D		; 12 bps
DFT7	EQU	99D		; 10 bps
DFT8	EQU	110D		; 9 bps
OS1	equ	'2'		;
OS2	equ	'1'		;
OS3	equ	'1'		;
OS4	equ	'1'		;
OS5	equ	'1'		;
OS6	equ	'1'		;
OS7	equ	'1'		;
OS8	equ	'0'		;
OS1a	equ	'0'		;
OS2a	equ	'8'		;
OS3a	equ	'6'		;
OS4a	equ	'4'		;
OS5a	equ	'3'		;
OS6a	equ	'2'		;
OS7a	equ	'0'		;
OS8a	equ	'9'		;
T0MSB	EQU	0FCH		; 3E8H x 1.000 uS = 1 mS tick rate
T0LSB	EQU	050H		; 12.00 MHz clock	-*17*18*25*30*40*50 --- TARGET --- 
LEDON	EQU	150D		; 100mS LED blink on
LEDOF	EQU	200D		; 150mS LED blink off
				;
;				;
; Valve off-time values (1x)	;
;				;
; ======================================================================
;              Internal 64 byte RAM Memory Organization
; ======================================================================
;				;
; General Purpose Registers R0-R7
;				;
Reg0		EQU	00H	; R0
Reg1		EQU	01H	; R1
Reg2		EQU	02H	; R2
Reg3		EQU	03H	; R3
Reg4		EQU	04H	; R4
Reg5		EQU	05H	; R5
Reg6		EQU	06H	; R6
Reg7		EQU	07H	; R7
;				;
; ======================================================================
;                        Bit addressable area 
; ======================================================================
;					;
					;
					;
EYTICK		EQU	010H		; eye ticker
TICK		EQU	011H		; 1mS ticker 
OFTIMR		EQU	012H		; Valve off timer
TMRMSH		EQU	013H		; 1000 mS counter MSB
TMRMSL		EQU	014H		; 1000 mS counter LSB (counts 0-500, 2mS tick)
TMRS		EQU	015H		; Seconds counter (0-60)
TMRM		EQU	016H		; Minutes counter (0-255)
FDTML		EQU	017H		; Feed system timer low bit
FDTMH		EQU	018H		; Feed system timer high bit
OTMIR		equ	019h		; Storage for ON timer value
FTMIR		equ	01ah		; Storage for OFF timer value
SCNTH		equ	01bh		; Shot counter high byte
SCNTL		equ	01ch		; Shot counter low byte
TMRON		equ	01dh		; Timer on flag
TMROMSL		equ	01eh		;
TMROMSH		equ	01fh		;
FLAGS		EQU	020H		; General flag register
PDTIMER:	reg	FLAGS.7		; D7: Power-down timer expired
lcdupdate:	reg	FLAGS.6		; D6: Enable display update
firing:		reg	FLAGS.5		; D5: currently firing
ebpass:		reg	FLAGS.4		; D4: eye is bypassed
mswapbt:	reg	FLAGS.3		; D3: 1ms swap bit
wfire:		reg	FLAGS.2		; D2: shot buffer
ES1OK:		reg	FLAGS.1		; D1: eye stage 1 completed (eye has been blocked)
ES2OK:		reg	FLAGS.0		; D2: eye stage 2 completed (eye has come un-blocked)
					;
flag2		equ	021h		; Second flag reg
RSCHG:		reg	flag2.0		; Set if mode change occurs
carryflag2:	reg	flag2.1		; Used in 16-bit ops
subzero:	reg	flag2.2		; ^
subzero2:	reg	flag2.3		; ^
data1:		reg	flag2.4		; Used for LCD data transfer
data2:		reg	flag2.5		; ^
data3:		reg	flag2.6		; ^
data4:		reg	flag2.7		; ^
					;
					;
TMROM		equ	022h		; Minutes in timer
CURRENTNUM	equ	023h		; Used for parsing hex numbers into 2-digit dec nbrs
ALTMP		equ	023h		; Also this byte is storage for dwell conversion
HROFNUM		equ	024h		; Storage byte
tmenbyte	equ	025h		; Set if timer is enabled
mnunum		equ	026h		; MNU option number
mnuopt		equ	027h		; MNU option selection number
TMROS		equ	028h		; Timer seconds
ERRCNT		equ	029h		; Error count
addrttl		equ	02ah		; Address total for offsetting in menu displays
ONTIMR		equ	02bh		; Valve timer
AEDEL		equ	02ch		; After eye delay
debouncetimer	equ	02dh		; Total for debounce multiplier
esect2ok	equ	02eh		; Set when eye is clear but AED is not
SEBPASS		equ	02fh		; Set if eye is bypassed in software, disables auto-re-enable
;***********BEGIN DATA MEMORY STORED VARIABLES
mode		EQU	030h		; mode
ROFOFST		equ	031h		; Offset nuber for ROF
DWELL		equ	032h		; Dwell
dbonc		EQU	033h		; multiplier for debounce
AEDELNC		EQU	034H		; Offset number for after-eye delay
TIMMOD		EQU	035h		; Timer mode
TIMINT		EQU	036h		; Timer initiator
TIMSTT		EQU	037h		; Timer start minutes
TIMST2		EQU	038h		; Timer start seconds
DIS1		EQU	039h		; Display section 1
DIS2		EQU	03ah		; Display Section 2
DIS1B		EQU	03bh		; Display section 1b
DIS2B		EQU	03ch		; Display section 2b
EYEMOD		EQU	03dh		; Eye mode
tmdstat		equ	03eh		; Operation mode
SCOPEMD		equ	03fh		; SCOPE mode
SDELAYOFF	equ	040h		; Solenoid 2 start delay (in ref to dwell)
SMINIMOFF	equ	041h		; Solenoid 2 dwell offset
ASDL		equ	042h		; After-shot delay time
VMAJ		equ	043h		; Version number, Major
VMIN		equ	044h		; Version number, Minor
MTYPE		equ	045h		; Marker type storage byte
DROFOFST	equ	046h		; Default ROF offset byte
JMPFLAG1	equ	047h		; Used as flags for menu skipping
MNU1ACT:	reg	CURRENTNUM.0	; Used as flags for menu skipping
MNU2ACT:	reg	CURRENTNUM.1	; Used as flags for menu skipping
MNU3ACT:	reg	CURRENTNUM.2	; Used as flags for menu skipping
MNU4ACT:	reg	CURRENTNUM.3	; Used as flags for menu skipping
MNU5ACT:	reg	CURRENTNUM.4	; Used as flags for menu skipping
MNU6ACT:	reg	CURRENTNUM.5	; Used as flags for menu skipping
MNU7ACT:	reg	CURRENTNUM.6	; Used as flags for menu skipping
MNU8ACT:	reg	CURRENTNUM.7	; Used as flags for menu skipping
					;	
JMPFLAG2	equ	048h		; Used as flags for menu skipping
MNU9ACT:	reg	CURRENTNUM.0	; Used as flags for menu skipping
MNU10ACT:	reg	CURRENTNUM.1	; Used as flags for menu skipping
MNU11ACT:	reg	CURRENTNUM.2	; Used as flags for menu skipping
MNU12ACT:	reg	CURRENTNUM.3	; Used as flags for menu skipping
MNU13ACT:	reg	CURRENTNUM.4	; Used as flags for menu skipping
MNU14ACT:	reg	CURRENTNUM.5	; Used as flags for menu skipping
MNU15ACT:	reg	CURRENTNUM.6	; Used as flags for menu skipping
MNU16ACT:	reg	CURRENTNUM.7	; Used as flags for menu skipping

JMPFLAG3	equ	049h		; Used as flags for menu skipping
MNU17ACT:	reg	CURRENTNUM.0	; Used as flags for menu skipping
MNU18ACT:	reg	CURRENTNUM.1	; Used as flags for menu skipping
MNU19ACT:	reg	CURRENTNUM.2	; Used as flags for menu skipping

PDTMAX		EQU	04AH		;
;***********END DATA MEMORY STORED VARIABLES
					;
HROFNUMH	equ	023h		; >
HROFL1		equ	04bh		; >
HROFH1		equ	04ch		; >
HROFL2		equ	04dh		; >
HROFH2		equ	04eh		; >
HROFL3		equ	04fh		; >
HROFH3		equ	050h		; >
HROFNUML	equ	051h		; >
HROFTMPL	equ	052h		; ^
HROFTMPH	equ	053h		; ^
eyebuffer	equ	054h		; Used for buffering eye functions
LBLCTH		equ	055h		; LCD backlight counter high
LBLCTL		equ	056h		; ^, low
TRIGBIT		equ	057h		; trigger buffer bit
UPDCNT		equ	058h		; Update count
HROFHTOTL	equ	059h		; Used for HROF figuring
SCOPEFP		equ	05ah		; Scope counter
BUFFBYTE	equ	05bh		; Buffer byte for scope
VOLTL		equ	05ch		; Voltage low byte
DLTMP		equ	05ch		; Also this byte is storage for dwell conversion
VOLTH		equ	05dh		; Voltage high byte
SLTMP		equ	05dh		; Also this byte is storage for solenoid 2 conversion
HROFLTOTL	equ	05eh		; Used for HROF figuring
HROFDIG3	equ	05fh		; Used for HROF figuring
HROFL1b		equ	060h		; Used for HROF figuring
SDELMIR		equ	061h		; Solenoid delay mirror
SMNMIR		equ	062h		; Solenoid dwell mirror
V2SOLMODE	equ	063h		; Set if 2-solenoid mode enabled
S10K		equ	064h		; Set if section one of solenoid action complete
S20K		equ	065h		; Set if section 2 of solenoid action complete
ASDLMIR		equ	066h		; ASDL mirror byte
SDELAY		equ	067h		; Figured delay using offset
SMINIM		equ	068h		; Figured minim using offset
OPBOLTBUF	equ	069h		; Buffer for bolt opening
HROFH1b		equ	06ah		; Used for high rate of fire figuring
HROFL2b		equ	06bh		; >
HROFH2b		equ	06ch		; >
HROFL3b		equ	06dh		; >
HROFH3b		equ	06eh		; >
HROFTEMP	equ	06fh		; >
					;
STACK		EQU	070H		; Stack starts here, LOTSA room still left
					;
	.list on			;
	.program			;
RESET:					;
	JMP	START			; Skip interrupt area
.ds	3-$				;
INTR1:					;
	JMP	XINT0			; IE0 external interrupt (IE.0) 
.ds	0bh-$				;
INTR2:					;
	JMP	TMR0			; Timer 0 interrupt (IE.1)
.ds	13h-$				;
INTR3:					;
	JMP	XINT1			; IE1 external interrupt (IE.2)
					;
START:					;
	MOV	SP,#STACK		; Load the stack pointer before any calls
 	clr	A			; Clear accumlator
	MOV	FLAGS,A			; Clear program flags/modes
	CALL	InitializeCpu		; Initialize variables and hardware
	clr	A			;
	MOV	TMRMSH,A		; 1000 mS counter MSB
	MOV	TMRMSL,A		; 1000 mS counter LSB (counts 0-500, 2mS tick)
	MOV	TMRS,A			; Seconds counter
	MOV	TMRM,A			; Minutes counter
	MOV	FDTMH,A			; Clear feed timer
	MOV	FDTML,A			; (low)
	MOV	TMRON,A			;
	MOV	TMROMSL,A		;
	MOV	TMROMSH,A		;
	MOV	TMROS,A			;
	MOV	TMROM,A			;
	MOV	SCNTL,A			;
	MOV	SCNTH,A			;
	MOV	tmenbyte,A		;
	MOV	SDELMIR,A		;
	MOV	SMNMIR,A		;
	mov	HROFL1,#ffh		;
	mov	HROFH1,#ffh		;
	mov	HROFL2,#ffh		;
	mov	HROFH2,#ffh		;
	mov	HROFL3,#ffh		;
	mov	HROFH3,#ffh		;
	MOV	HROFNUM,#3		;
	mov	LBLCTL,#20d		;
	mov	LBLCTH,#250d		;
	clr	L2PORT.L2BIT		;
	clr	EEPORT.EEBIT		;
	mov	TRIGBIT,#0d		; ^^^ Clearing off all the stuff
	jb	ebpass,ENDSTARTFXROUT	;
	setb	ebpass			;
	mov	ONTIMR,#0d		; Setting up to check for eye status on bootup
	mov	OFTIMR,#0d		;
	mov	EYTICK,#01d		;
	MOV	SDELAYOFF,#0D		;
	MOV	SMINIMOFF,#0D		;
	MOV	ASDL,#0D		;
	MOV	SDELMIR,#0D		;
	MOV	SMNMIR,#0D		;
	setb	ES1OK			;
	setb	ES2OK			;
	setb	wfire			;
	setb	firing			;
	call	WAIT1MS			;
	call	WAIT1MS			;
	call	WAIT1MS			;
	clr	wfire			;
	clr	firing			;
	clr	VPORT.VBIT		;
	CLR	V2PORT.V2BIT		;
	clr	ebpass			;
ENDSTARTFXROUT:				;
	setb	VTPORT.VTBIT		; Checking for 2nd solenoid
	MOV	V2SOLMODE,#0D		;
	JB	VTPORT.VTBIT,NO2SOL	;
	MOV	V2SOLMODE,#1D		;
NO2SOL:					;
	call	READ_EEP		; Get settings
INITISNOWDONE:				;
	CALL	INITDISP		; Initialize LCD 
					;
; ======================================================================
;               Initialization complete ... start main loop
; ======================================================================
;					;
MAIN:					;
	acall	TIMERRESET		; Set timer to start
	mov	A,TIMINT		; If timer mode is 0,
	jnz	MAINPT2			;
	acall	TIMERSTART		; Start timer
MAINPT2:				;
	CLR	wfire			; Clear shots
	clr	RSCHG			; Clear 'options changed' byte
	JB	TPORT.TBIT,NOTPROG	; Check to see if trigger programming
	call	TPROG			; If so, call trigger programming routine
NOTPROG:				;
	call	MAINCONVERT		; Convert all saved variables into used variables, and confirm acceptable
	call	WaitRelease		; Wait for trigger release
	call	DISVOLT			;
	call	WRVOEEP			;
	mov	A,mode			; open up mode
	clr	LPORT.LBIT		; Turn on LED
	acall	TLCHECK			; Check for tourney lock
NOTPROG2:				;

; ---------------------------------------------------------------------
;                           Semi-Auto Mode
; ---------------------------------------------------------------------
;					;
SAM10a:					;
	setb	lcdupdate		; Update LCD
	CLR	wfire			; Clear shots
	clr	firing			;
SAM10:					;
	call	WaitRelease		; Wait for trigger release
SAM20:					;
	acall	TLCHECK			; Update Tourney lock status
	jnb	lcdupdate,SAM22		; if update LCD is set, 
	ACALL	UPDISP			; Call update routine
SAM22:					;
	jnb	PDTIMER,SAM25		; Stay powered up?
	JMP	PowerDown		; Shutdown
SAM25:					;
	jb	B1PORT.B1BIT,SAM26	; Check for button press
	acall	BPROCESS		; If so, run BPROCESS
SAM26:					;
	jb	B2PORT.B2BIT,SAM27	; Check for button press
	acall	BPROCESS		; If so, run BPROCESS
SAM27:					;
	jb	RSCHG,NOTPROG2		; If settings are updated, return to mode parsing routine
	mov	A,TRIGBIT		; check to see if the trigger bit has been set
	jz	SAM20			; If not, skip back to start
	mov	TRIGBIT,#0d		; If so, 
	;JB	TPORT.TBIT,SAM20	; Wait here for trigger press
	SETB	wfire			;
	MOV	TMRS,#000H		; Clear power-down seconds counter
	MOV	TMRM,#000H		; Clear power-down minutes counters
	CALL	WaitRelease		;
	SJMP	SAM20			; Loop back and wait
; ======================================================================
;           Initialize CPU hardware and control variables
; ======================================================================
;					;
					;
BPROCESS:				;
	mov	LBLCTL,#250d		;	
	mov	LBLCTH,#40d		;	
	call	WAIT1MS			;	
	call	WAIT1MS			;	
	jb	B1PORT.B1BIT,BPROCESS2	;	
BPROCESS1A:				;
	jb	B2PORT.B2BIT,BPROCESS1B	;	
startafterel:				;	This whole segment just means if both buttons are pressed
	acall	BUTDBOUNCE		;	
	acall	MENUSTARTUP		;	
	jmp	BPROCESSOVR		;	
					;
BPROCESS1B:				;
	setb	EEPORT.EEBIT		;
	jnb	B1PORT.B1BIT,BPROCESS1A	;	
	acall	TIMERSTARTSTP		;	
	jmp	BPROCESSOVR		;	
					;
BPROCESS2:				;
	setb	EEPORT.EEBIT		;
	jb	B1PORT.B1BIT,BPROCESS2B	;	
	jmp	startafterel		;	
BPROCESS2B:				;
	jnb	B2PORT.B2BIT,BPROCESS2	;	
	acall	TIMERRESET		;	
BPROCESSOVR:				;
	acall	BUTDBOUNCE		;	
	mov	TRIGBIT,#0d		;	
	clr	EEPORT.EEBIT		;
	mov	HROFL1,#ffh		;
	mov	HROFL2,#ffh		;
	mov	HROFL3,#ffh		;
	mov	HROFH1,#ffh		;
	mov	HROFH2,#ffh		;
	mov	HROFH3,#ffh		;
	mov	HROFTMPL,#ffh		;
	mov	HROFTMPH,#ffh		;
	ret				;
					;
BUTDBOUNCE:				;
	jnb	B1PORT.B1BIT,BUTDBOUNCE	;	start up the menu as soon as they're released.
	jnb	B2PORT.B2BIT,BUTDBOUNCE	;	
	call	WAIT1MS			;
	jnb	B1PORT.B1BIT,BUTDBOUNCE	;
	jnb	B2PORT.B2BIT,BUTDBOUNCE	;	
	call	WAIT1MS			;
	jnb	B1PORT.B1BIT,BUTDBOUNCE	;
	jnb	B2PORT.B2BIT,BUTDBOUNCE	;	
	call	WAIT1MS			;
	jnb	B1PORT.B1BIT,BUTDBOUNCE	;
	jnb	B2PORT.B2BIT,BUTDBOUNCE	;	
	call	WAIT1MS			;
	jnb	B1PORT.B1BIT,BUTDBOUNCE	;
	jnb	B2PORT.B2BIT,BUTDBOUNCE	;	
	call	WAIT1MS			;
	jnb	B1PORT.B1BIT,BUTDBOUNCE	;
	jnb	B2PORT.B2BIT,BUTDBOUNCE	;	
	call	WAIT1MS			;
	jnb	B1PORT.B1BIT,BUTDBOUNCE	;
	jnb	B2PORT.B2BIT,BUTDBOUNCE	;	
	call	WAIT1MS			;
	jnb	B1PORT.B1BIT,BUTDBOUNCE	;
	jnb	B2PORT.B2BIT,BUTDBOUNCE	;	
	mov	LBLCTL,#250d		;
	mov	LBLCTH,#40d		;
	ret				;
					;
TIMERSTARTSTP:				;
	mov	A,tmenbyte		;
	jz	TIMERSTART		;
	MOV	tmenbyte,#0d		;
	jmp	TIMERDONESTARTED	;	
TIMERSTART:				;
	mov	tmenbyte,#1d		;
TIMERDONESTARTED:			;
	ret				;
					;
TIMERRESET:				;
	mov	A,TIMMOD		;
	jz	TMRREST2		;
	mov	A,TIMSTT		;
	MOV	DPTR,#TMRSTTABLE	;
	MOVC	A,@A+DPTR		;
	MOV	TMROM,A			;
	mov	A,TIMST2		;
	mov	B,#5d			;
	mul	AB			;
	mov	TMROS,A			;
	jmp	TMRREST3		;
TMRREST2:				;
	MOV	TMROM,#0d		;
	MOV	TMROS,#0d		;
TMRREST3:				;
	MOV	TMROMSL,#0d		;
	MOV	TMROMSH,#0d		;
	ret				;
					;
MENUSTARTUP:				;
	call	CONVERTIN		;
	mov	mnunum,#0d		;
	mov	mnuopt,#0d		;
	mov	R0,#30h			;
	mov	mnuopt,@R0		;
DISPCHG:				;
	call	mnuverify		;
	jnb	lcdupdate,mnunochg	;
	jmp	mnuchg			;
mnunochg:				;
	acall	CLEARDISP		;
	call	WAIT1MS			;
	acall	LINE1DISP		;
	mov	DPTR,#MNUHEADS		;
	mov	a,mnunum		;
	cjne	a,#15,mnucontin5	;
	mov	DPTR,#MNUHEADS2		;
	mov	a,#0d			;
mnucontin5:				;
	cjne	a,#16,mnucontin5B	;
	mov	DPTR,#MNUHEADS3		;
	mov	a,#0d			;
mnucontin5B:				;
	cjne	a,#17,mnucontin5C	;
	mov	DPTR,#MNUHEADS4		;
	mov	a,#0d			;
mnucontin5C:				;
	cjne	a,#18,mnucontin5d	;
	mov	DPTR,#MNUHEADS5		;
	mov	a,#0d			;
mnucontin5d:				;
	mov	B,#17d			;
	mul	AB			;
	mov	b,a			;
mnucontin6:				;
	acall	DISPSTRG		;
	acall	LINE2DISP		;
	mov	A,mnunum		;
	cjne	A,#0,ROFCHG		;
	MOV	DPTR,#MODMNU		;
	mov	A,mnunum		;
ROFCHG:					;
	cjne	a,#1,DWLCHG		;
	MOV	DPTR,#ROFMNU		;
DWLCHG:					;
	cjne	a,#2,DBCCHG		;
	MOV	DPTR,#DWLMNU		;
DBCCHG:					;
	cjne	a,#3,AEDCHG		;
	MOV	DPTR,#DBCMNU		;
AEDCHG:					;
	cjne	a,#4,TMMCHG		;
	MOV	DPTR,#AEDMNU		;
TMMCHG:					;
	cjne	a,#5,TMICHG		;
	MOV	DPTR,#TMMMNU		;
TMICHG:					;
	cjne	a,#6,TMTCHG		;
	MOV	DPTR,#TMIMNU		;
TMTCHG:					;
	cjne	a,#7,TM2CHG		;
	MOV	DPTR,#TMTMNU		;
TM2CHG:					;
	cjne	a,#8,DS1CHG		;
	MOV	DPTR,#TM2MNU		;
DS1CHG:					;
	cjne	a,#9,DS2CHG		;
	MOV	DPTR,#DS1MNU		;
DS2CHG:					;
	cjne	a,#10d,D1BCHG		;
	MOV	DPTR,#D1BMNU		;
D1BCHG:					;
	cjne	a,#11d,D2BCHG		;
	MOV	DPTR,#D2BMNU		;
D2BCHG:					;
	cjne	a,#12d,EYMCHG		;
	MOV	DPTR,#DS2MNU		;
EYMCHG:					;
	cjne	a,#13d,TMDCHG		;
	MOV	A,V2SOLMODE		;
	JNZ	mnuchg			;
	MOV	DPTR,#EYMMNU		;
TMDCHG:					;
	cjne	a,#14d,SCMCHG		;
	MOV	DPTR,#TMDMNU		;
SCMCHG:					;
	cjne	a,#15d,S2DCHG		;
	MOV	A,V2SOLMODE		;
	JNZ	mnuchg			;
	MOV	DPTR,#SCMMNU		;
S2DCHG:					;
	cjne	a,#16d,S2MCHG		;
	MOV	A,V2SOLMODE		;
	JZ	mnuchg			;
	MOV	DPTR,#S2DMNU		;
S2MCHG:					;
	cjne	a,#17d,ASDCHG		;
	MOV	A,V2SOLMODE		;
	JZ	mnuchg			;
	MOV	DPTR,#S2MMNU		;
ASDCHG:					;
	cjne	a,#18d,DONCHG		;
	MOV	A,V2SOLMODE		;
	JZ	mnuchg			;
	MOV	DPTR,#ASDMNU		;
DONCHG:					;
	mov	A,mnuopt		;
	cjne	A,#255d,DONCHG2		;
	mov	DPTR,#OTHEROPT		;
	mov	A,#0d			;
	mov	B,#0d			;
	jmp	DONCHG3			;
DONCHG2:				;
	mov	B,#17d			;
	mul	AB			;
	mov	B,A			;
DONCHG3:				;
	acall	DISPSTRG		;
DISPCHG2:				;
	setb	EEPORT.EEBIT		;
	jnb	B1PORT.B1BIT,mnuchg	;
	jnb	B2PORT.B2BIT,mnochg	;
	JNB	TPORT.TBIT,mnuoutgo	;
	jmp	DISPCHG2		;
mnuchg:					;
	acall	BUTDBOUNCE		;
	setb	EEPORT.EEBIT		;
	mov	@R0,mnuopt		;
	inc	mnunum			;
	mov	A,mnunum		;
	cjne	A,#19d,mnuchgcont	;
	jmp	mnuout			;
mnuchgcont:				;
	inc	R0			;
	mov	mnuopt,@R0		;
DISPCHGJMP:				;
	cjne	A,#20d,DISPCHGJMP3	;
	jmp	MENURESET		;
DISPCHGJMP3:				;
	jmp	DISPCHG			;
					;
					;
MENURESET:				;
	mov	R0,#30h			;
	mov	mnunum,#0d		;
	mov	mnuopt,@R0		;
	jmp	DISPCHG			;
					;
mnochg:					;
	acall	BUTDBOUNCE		;
	setb	EEPORT.EEBIT		;
	mov	DPTR,#OPTTBL		;
	mov	A,mnunum		;
	movc	A,@A+DPTR		;
	inc	mnuopt			;
	cjne	A,mnuopt,DISPCHGJMP3	;
	mov	mnuopt,#0d		;
	jmp	DISPCHG			;
					;
mnuout:					;
	acall	LINE1DISP		;
	mov	DPTR,#OUTMESSAGE	;
	mov	A,#0d			;
	acall	DISPSTRG		;
	acall	LINE2DISP		;
	mov	A,#17d			;
	acall	DISPSTRG		;
mnuoutloop:				;
	jnb	B2PORT.B2BIT,mnuoutgo	;
	jb	B1PORT.B1BIT,mnuoutloop	;
	acall	BUTDBOUNCE		;
	jmp	mnuchg			;
					;
mnuoutgo:				;
	acall	BUTDBOUNCE		;
	setb	lcdupdate		;
	setb	RSCHG			;
	call	CONVERTOUT		;
	call	MAINCONVERT		;
	ret				;
					;					;
DISPSTRG:				;
	mov	B,A			;
DISPSTRGx:				;
	movc	A,@a+DPTR		;
	cjne	A,#255d,DISPSTRG2	;
	mov	LDPORT,#ffh		;
	ret				;
					;
DISPSTRG2:				;
	acall	DISPCHAR		;
	inc	B			;
	mov	A,B			;
	jmp	DISPSTRGx		;
					;
InitializeCpu:				;
	CLR	A			; Clear the accumulator
	MOV	B,A			; Clear 'B'
	mov	DPTR,#0			; Clear the data pointer DPTR
	MOV	P1,#0FFH		; Set all P1 bits high
	MOV	P3,#0FFH		; Set all P3 bits high
	clr	VPORT.VBIT
	clr	V2PORT.V2BIT		;
	MOV	PSW,#PSWX		; Initialize Processor Status Word (PSW)
	MOV	PCON,#PCONX		; Initialize Power Control Register (PCON)
	MOV	IE,#IEX			; Initialize interrupt enable register (IE)
	MOV	IP,#IPX			; Initialize interrupt priority register (IP)
	MOV	TCON,#TCONX		; Initialize timer control register (TCON)
	MOV	TMOD,#TMODX		; Initialize timer/counter control register (TMOD) 
	MOV	TH0,#T0MSB		; Load Timer0 values
	MOV	TL0,#T0LSB		;
	SETB	TCON.4			; Start Timer0 (TR0 = 1)
	MOV	IE,#IEX			; Enable Timer0(IE.1)/INT0 (IE.0) interrupt
	CLR	TCON.0			;
	RET				; Return
;					;
; ======================================================================
;                    General I/O Subroutines
; ======================================================================
;					;
TLCHECK:				;
	jb	TLPORT.TLBIT,TLOFF	;
	mov	a,mode			;
	jz	TL2			;
	mov	mode,#0d		;
	setb	RSCHG			;
TL2:					;
;	mov	A,dbonc			;
;	mov	B,#3d			;
;	subb	A,B			;
;	jnc	TLOFF			;
;	mov	dbonc,#3d		;
;	setb	RSCHG			;
TLOFF:					;
	ret				;
					;
INITDISP:				;
	mov	a,#20d			;
initdisplp:				;
	call	WAITLCD			;
	djnz	a,initdisplp		;
	clr	LPORT.LBIT		;
	mov	LDPORT,#28h		;
	clr	RSPORT.RSBIT		;
	nop				;
	setb	E_PORT.E_BIT		;
	nop				;
	clr	E_PORT.E_BIT		;
	call	WAITLCD			;
	mov	a,#28h			;
	acall	EXECCOMM		;
	mov	a,#0Ch			;
	acall	EXECCOMM		;
	mov	a,#06h			;
	acall	EXECCOMM		;
	acall	CLEARDISP		;
	mov	LDPORT,#ffh		;
	ret				;
					;
CLEARDISP:				;
	mov	a,#1h			;
	acall	EXECCOMM		;
	call	WAIT1MS			;
	ret				;
					;
LINE1DISP:				;
	mov	a,#80h			;
	acall	EXECCOMM		;
	ret				;
					;
LINE1BDISP:				;
	mov	a,#88h			;
	acall	EXECCOMM		;
	ret				;
					;
LINE2DISP:				;
	mov	a,#C0h			;
	acall	EXECCOMM		;
	ret				;
					;
LINE2BDISP:				;
	mov	a,#C8h			;
	acall	EXECCOMM		;
	ret				;
					;
LCDDATASND:				;
	mov	flag2,A			;
	setb	LDPORT.7		;
	jb	data4,datalcsnd1x	;
	clr	LDPORT.7		;
datalcsnd1x:				;
	setb	LDPORT.6		;
	jb	data3,datalcsnd2x	;
	clr	LDPORT.6		;
datalcsnd2x:				;
	setb	LDPORT.5		;
	jb	data2,datalcsnd3x	;
	clr	LDPORT.5		;
datalcsnd3x:				;
	setb	LDPORT.4		;
	jb	data1,datalcsnd4x	;
	clr	LDPORT.4		;
datalcsnd4x:				;
	mov	flag2,#0d		;
	ret				;
					;
					;
DISPCHAR:				;
	acall	LCDDATASND		;
	setb	RSPORT.RSBIT		;
	nop				;
	setb	E_PORT.E_BIT		;
	nop				;
	clr	E_PORT.E_BIT		;
	call	WAITLCD			;
	rl	a			;
	rl	a			;
	rl	a			;
	rl	a			;
	acall	LCDDATASND		;
	setb	RSPORT.RSBIT		;
	nop				;
	setb	E_PORT.E_BIT		;
	nop				;
	clr	E_PORT.E_BIT		;
	call	WAITLCD			;
	nop				;
	ret				;
					;
EXECCOMM:				;
	acall	LCDDATASND		;
	clr	RSPORT.RSBIT		;
	nop				;
	setb	E_PORT.E_BIT		;
	nop				;
	clr	E_PORT.E_BIT		;
	call	WAITLCD			;
	rl	a			;
	rl	a			;
	rl	a			;
	rl	a			;
	acall	LCDDATASND		;
	clr	RSPORT.RSBIT		;
	nop				;
	setb	E_PORT.E_BIT		;
	nop				;
	clr	E_PORT.E_BIT		;
	call	WAITLCD			;
	nop				;
	ret				;
					;
UPDISP:					;
	mov	A,UPDCNT		;
	mov	B,#50d			;
	SUBB	A,B			;
	jc	NOUPYET			;
	acall	LINE1DISP		;
	mov	A,DIS1			;
	acall	DISPIT			;
	acall	LINE2DISP		;
	mov	A,DIS2			;
	acall	DISPIT			;
	acall	LINE1BDISP		;
	mov	A,DIS1B			;
	acall	DISPIT			;
	acall	LINE2BDISP		;
	mov	A,DIS2B			;
	acall	DISPIT			;
	call	eyeverf			;
	mov	LDPORT,#ffh		;
NOUPYET:				;
	inc	UPDCNT			;
	ret				;
					;
DISPIT:					;
	cjne	A,#0d,DISPIT1		;
	acall	TIMRDISP		;
	jmp	DISPITDONE		;
DISPIT1:				;
	cjne	A,#1d,DISPIT2		;
	acall	SCDISP			;
	jmp	DISPITDONE		;
DISPIT2:				;
	cjne	A,#2d,DISPIT3		;
	acall	DISPROF			;
	jmp	DISPITDONE		;
DISPIT3:				;
	cjne	A,#3d,DISPIT4		;
	acall	DISPROFA		;
	jmp	DISPITDONE		;
DISPIT4:				;
	cjne	A,#4d,DISPIT5		;
	mov	A,mode			;
	call	DISPMODE		;
	jmp	DISPITDONE		;
DISPIT5:				;
	cjne	A,#5d,DISPIT6		;
	acall	DISPDWEL		;
	jmp	DISPITDONE		;
DISPIT6:				;
	cjne	A,#6d,DISPIT7		;
	acall	DISESTT	; done		;
	jmp	DISPITDONE		;
DISPIT7:				;
	cjne	A,#7d,DISPIT8		;
	acall	DISVERS			;
	jmp	DISPITDONE		;
DISPIT8:				;
	cjne	A,#8d,DISPIT9		;
	acall	DISVOLT			;
	jmp	DISPITDONE		;
DISPIT9:				;
	acall	DISNOTHING		;
					;
DISPITDONE:				;
	ret				;
					;
DISVOLT: 				; clear clock 
	clr VCPORT.VCBIT 		; To prevent sending a "stop" when data comes up 
	setb VDPORT.VDBIT		; set data high 
	SETB VCPORT.VCBIT		; set clock high 
	JnB VDPORT.VDBIT,SKIPVOLT	; wait until all otuputs are high (this will catch 'busy') 
	JnB VCPORT.VCBIT,SKIPVOLT	; 
	CLR VDPORT.VDBIT 		; clr data while clock high for a 'start' signal 
	NOP 				; 
	CLR VCPORT.VCBIT 		; 
	mov A,#10011011b		; 4-bit device code, 3-bit ID, and 'read' bit. 
	ACALL BYTESEND 			; send that byte 
	ACALL ACKSTART			; Acknowledge the byte 
	ACALL BYTEREAD			; read next byte (routine has ack built in) 
	ANL a,#0fh 			; ignore top half of byte (unused) 
	mov VOLTH,A 			; save in VOLTH variable 
	ACALL BYTEREAD 			; read next byte (built in ack) 
	mov VOLTL,A 			; save in VOLTL variable 
	ACALL ACKSTOP 			; send stop condition 
					;
	ANL	a,#0fh 			; ignore top half of byte (unused) 
	mov	VOLTH,A 		; save in VOLTH variable 
	ACALL	BYTEREAD 		; read next byte (built in ack) 
	mov	VOLTL,A 		; save in VOLTL variable 
	ACALL	ACKSTOP 		; send stop condition 
	inc	a			;
	jnz	DISVOLT2		;
	mov	A,VOLTH			;
	ORL	a,#f0h			;
	inc	a			;
	jnz	DISVOLT2		;
	mov	VOLTH,#AAh		;
	jmp	DISNOTHING		;
DISVOLT2:				;
	mov	a,#'B'			;
	acall	DISPCHAR		;
	mov	a,#':'			;
	acall	DISPCHAR		;
	mov	a,VOLTH			;
	call	x10NUMCONV		;
	push	A			;
	mov	A,CURRENTNUM		;
	add	a,#30h			;
	acall	DISPCHAR		;
	pop	A			;
	add	a,#30h			;
	acall	DISPCHAR		;
	mov	a,#'.'			;
	acall	DISPCHAR		;
					;
	mov	a,VOLTL			;
	mov	b,#26d			;
	div	ab			;
	add	a,#30h			;
	acall	DISPCHAR		;
	mov	a,#'v'			;
	acall	DISPCHAR		;
	mov	a,#' '			;
	acall	DISPCHAR		;
SKIPVOLT:				;
	ret 				; 
					; 
BYTESEND: 				; 
	mov B,#8d 			; set to run through bit routine 8-times 
BITSEND: 				; 
	rlc A 				; mov c into msb of A, all other bits left 
	mov VDPORT.VDBIT,c 		; set data to this bit's value 
	nop 				; give 1 cycle for value assurance on output 
	setb VCPORT.VCBIT		; set clock high 
	acall Wait5us 			; wait 5 microseconds 
	clr VCPORT.VCBIT 		; clear clock 
	acall Wait5us 			; wait 5 microseconds 
	djnz b,BITSEND 			; repeat until count is 0 
	RET 				; 
					; 
BYTEREAD: 				; 
	SETB VDPORT.VDBIT		; set data high (input) 
	mov B,#8d			; set to run bit 8x 
BITREAD: 				; 
	setb VCPORT.VCBIT		; set clock cycled high 
	acall Wait5us 			; wait 5 microseconds 
	mov c,VDPORT.VDBIT		; put value from databit in c 
	rlc A				; move into lsb of A, rotate a left 
	clr VCPORT.VCBIT		; clear clcok 
	acall Wait5us 			; wait 5 microseconds 
	djnz b,BITREAD 			; repeat 8x 
	CLR VDPORT.VDBIT		; clear datapin for input ack 
	nop 				; wait 1 clock cycle for output assurance 
	SETB VCPORT.VCBIT		; set clock pulse 
	acall Wait5us 			; wait 5 microseconds 
	CLR VCPORT.VCBIT		; clear clock pulse 
	acall Wait5us 			; wait 5 microseconds 
	RET 				; 
					; 
ACKSTART: 				; 
	CLR VDPORT.VDBIT		; 
	nop 				; 
	setb VCPORT.VCBIT 		; 
	acall Wait5us 			; 
	clr VCPORT.VCBIT		; 
	acall Wait5us 			; 
	ret 				;
ACKSTOP: 				; 
	clr VDPORT.VDBIT		; 
	acall Wait5us 			; 
	setb VCPORT.VCBIT		; 
	NOP 				; 
	SETB VDPORT.VDBIT		; 
	NOP				; 
	RET 				; 
					; 
Wait5us:				; 
	nop				; 
	nop				; 
	nop				; 
	ret				;
					;					;
DISVERS:				;
	mov	DPTR,#VERSION		;
	mov	A,#0d			;
	acall	DISPSTRG		;
	ret				;
					;
DISESTT:				;
	jb	ebpass,DISPESTT2	;
	mov	DPTR,#ESTATON		;
	mov	A,#0d			;
	acall	DISPSTRG		;
	jmp	DISPESTTDN		;
DISPESTT2:				;
	mov	DPTR,#ESTATOFF		;
	mov	A,#0d			;
	acall	DISPSTRG		;
	jmp	DISPESTTDN		;
DISPESTTDN:				;
	ret				;
					;
DISPDWEL:				;
	MOV	DPTR,#DWELLTABLE	;
	acall	DISPSTRG		;
	mov	a,DWELL			;
	acall	x10NUMCONV		;
	push	a			;
	mov	a,CURRENTNUM		;
	add	a,#30h			;
	acall	DISPCHAR		;
	pop	a			;
	add	a,#30h			;
	acall	DISPCHAR		;
	MOV	DPTR,#DWELLTABLE2	;
	acall	DISPSTRG		;
	RET				;
					;
					;
DIV16by3:				;
	mov	B,#3d			;
	mov	A,R7			;
	div	AB			;
	mov	R7,A			;
	push	B			;
	mov	A,R6			;
	mov	B,#3d			;
	DIV	AB			;
	mov	R5,B			;
	pop	B			;
	push	a			;
	mov	A,B			;
	mov	B,#85d			;
	mul	AB			;
	mov	B,A			;
	pop	A			;
	add	A,B			;
	mov	R6,A			;
	ret				;
					;
DISPROFA:				;
	mov	DPTR,#SHORTSPACES	;
	mov	A,#0d			;
	acall	DISPSTRG		;
					;
	mov	R7,HROFH1		;
	mov	R6,HROFL1		;
	acall	DIV16by3		;
	mov	HROFDIG3,R5		;
	mov	HROFH1b,R7		;
	mov	HROFL1b,R6		;
	mov	R7,HROFH2		;
	mov	R6,HROFL2		;
	acall	DIV16by3		;
	mov	A,R5			;
	add	A,HROFDIG3		;
	mov	HROFDIG3,A		;
	mov	HROFH2b,R7		;
	mov	HROFL2b,R6		;
	mov	R7,HROFH3		;
	mov	R6,HROFL3		;
	acall	DIV16by3		;
	mov	A,R5			;
	add	A,HROFDIG3		;
	mov	HROFDIG3,A		;
	mov	HROFH3b,R7		;
	mov	HROFL3b,R6		;
	clr	subzero2		;
	mov	A,HROFDIG3		;
	mov	B,#3d			;
	div	AB			;
	add	A,HROFL1b		;
	jnc	disprofa1		;
	setb	subzero2		;
disprofa1:				;
	add	A,HROFL2b		;
	jnc	disprofa2		;
	setb	subzero2		;
disprofa2:				;
	add	A,HROFL3b		;
	jnc	disprofa3		;
	setb	subzero2		;
disprofa3:				;
	mov	HROFLTOTL,A		;
	mov	A,HROFH1b		;
	add	A,HROFH2b		;
	add	A,HROFH3b		;
	jnb	subzero2,disprofa4	;
	inc	A			;
disprofa4:				;
	mov	HROFHTOTL,A		;
	jnz	divisorloopdone		;
	mov	A,HROFLTOTL		;
	jnz	divisorloopdone		;
	mov	HROFNUMH,#0d		;
	mov	HROFNUML,#0d		;
	jmp	rofach5			;
divisorloopdone:			;
	mov	HROFNUML,#0d		;
	mov	HROFNUMH,#0d		;
	mov	R3,#10h			;
	mov	R2,#27h			;
	mov	R5,HROFLTOTL		;
	mov	R4,HROFHTOTL		;
					;
rofach4loop:				;
	mov	a,R3			;
	mov	R7,A			;
	mov	a,R2			;
	mov	R6,A			;
					;
	acall	SUBB16_16		;
	jb	subzero,rofach5		;
					;
	inc	HROFNUML		;
	mov	A,HROFNUML		;
	cjne	A,#100d,rofach4loop	;
	mov	HROFNUML,#0d		;
	inc	HROFNUMH		;
	jmp	rofach4loop		;
					;
rofach5:				;
	mov	a,HROFNUMH		;
	acall	x10NUMCONV		;
	add	a,#30h			;
	acall	DISPCHAR		;
					;
	mov	A,HROFNUML		;
	acall	x10NUMCONV		;
	push	a			;
	mov	a,CURRENTNUM		;
	add	a,#30h			;
	acall	DISPCHAR		;
					;
	mov	A,#'.'			;
	acall	DISPCHAR		;
					;
	pop	a			;
	add	a,#30h			;
	acall	DISPCHAR		;
	mov	DPTR,#SHORTSPACES	;
	mov	A,#0d			;
	acall	DISPSTRG		;
					;
	ret				;
					;
					;
					;
SUBB16_16:				;
	clr	subzero			;
	clr	subzero2		;
	MOV	A,R7			;
	CLR	C			;
	SUBB	A,R5			;
	jnc	subb16_162		;
	setb	subzero2		;
subb16_162:				;
	MOV	R3,A			;
	MOV	A,R6			;
	SUBB	A,R4			;
	jc	highersub16		;
	MOV	R2,A			;
	RET				;
					;
highersub16:				;
	setb	subzero			;
	MOV	R2,A			;
	RET				;
					;
DISNOTHING:				;
	mov	DPTR,#SHORTSPACES	;
	mov	A,#0d			;
	acall	DISPSTRG		;
	mov	DPTR,#SHORTSPACES	;
	mov	A,#0d			;
	acall	DISPSTRG		;
	mov	DPTR,#SHORTSPACES	;
	mov	A,#0d			;
	acall	DISPSTRG		;
	mov	DPTR,#SHORTSPACES	;
	mov	A,#0d			;
	acall	DISPSTRG		;
	ret				;
					;
TIMRDISP:				;
	mov	DPTR,#SHORTSPACES	;
	mov	A,#0d			;
	acall	DISPSTRG		;
	mov	a,TMROM			;
	acall	x10NUMCONV		;
	push	a			;
	mov	a,CURRENTNUM		;
	add	a,#30h			;
	acall	DISPCHAR		;
	pop	a			;
	add	a,#30h			;
	acall	DISPCHAR		;
	mov	a,#3ah			;
	acall	DISPCHAR		;
	mov	A,TMROS			;
	acall	x10NUMCONV		;
	push	a			;
	mov	a,CURRENTNUM		;
	add	a,#30h			;
	acall	DISPCHAR		;
	pop	a			;
	add	a,#30h			;
	acall	DISPCHAR		;
	mov	a,#20h			;
	acall	DISPCHAR		;
	ret				;
					;
SCDISP:					;
	mov	DPTR,#SHORTSPACES	;
	mov	A,#0d			;
	acall	DISPSTRG		;
	mov	a,SCNTH			;
	acall	x10NUMCONV		;
	push	a			;
	mov	a,CURRENTNUM		;
	jnz	UD11			;
	mov	a,#FEh			;
	jmp	UD11a			;
UD11:					;
	add	a,#30h			;
UD11a:					;
	acall	DISPCHAR		;
	pop	a			;
	add	a,#30h			;
	acall	DISPCHAR		;
	mov	a,SCNTL			;
	acall	x10NUMCONV		;
	push	a			;
	mov	a,CURRENTNUM		;
	add	a,#30h			;
	acall	DISPCHAR		;
	pop	a			;
	add	a,#30h			;
	acall	DISPCHAR		;
	mov	DPTR,#SHORTSPACES	;
	mov	A,#0d			;
	acall	DISPSTRG		;
	ret				;
					;
x10NUMCONV:				;
	mov	CURRENTNUM,#0		;
	push	a			;
	clr	c			;
	subb	a,#10d			;
	jc	NUMLPOVR		;
NUMLOOP:				;
	pop	b			;
	inc	CURRENTNUM		;
	push	a			;
	clr	c			;
	subb	a,#10d			;
	jnc	NUMLOOP			;
NUMLPOVR:				;
	pop	a			;
	ret				;
					;
STARTDISP:				;
	push	a			;
	acall	LINE1DISP		;
	pop	a			;
	push	a			;
	call	DISPMODE		;
	acall	LINE2DISP		;
	acall	DISPROF			;
	pop	a			;
	ret				;
					;
DISPROF:				;
	mov	a,#20h			;
	acall	DISPCHAR		;
	mov	a,#20h			;
	acall	DISPCHAR		;
	mov	a,#20h			;
	acall	DISPCHAR		;
	mov	a,ROFOFST		;
	MOV	DPTR,#OSAB		; Load valve off-time base address
	MOVC	A,@A+DPTR		; Get value from DPTR+A in FTAB or 
	acall	DISPCHAR		;
	mov	a,ROFOFST		;
	MOV	DPTR,#OSABa		; Load valve off-time base address
	MOVC	A,@A+DPTR		; Get value from DPTR+A in FTAB or 
	acall	DISPCHAR		;
	mov	a,#20h			;
	acall	DISPCHAR		;
	mov	a,#20h			;
	acall	DISPCHAR		;
	mov	a,#20h			;
	acall	DISPCHAR		;
	RET				;
					;
MODSWDISP:				;
	push	b			;
	push	a			;
	acall	LINE1DISP		;
	pop	a			;
	push	a			;
	call	DISPMODE		;
	call	LINE2DISP		;
	mov	DPTR,#MNUHEADS		;
	mov	A,#0d			;
	call	DISPSTRG		;
	pop	a			;
	pop	b			;
	ret				;
					;
DISPMODE:				;
	mov	B,#5d			;
	mul	AB			;
	mov	DPTR,#MODEDISP		; point to jump table
	call	DISPSTRG		;
	RET				;
					;
WAITLCD:				;
	nop				;
	nop				;
	nop				;
	nop				;
	nop				;
	nop				;
	nop				;
	ret				;
					;
					;
; ---------------------------------------------------------------------
;                           PowerDown
; ---------------------------------------------------------------------
;					;
; Power down the 89C1051		;
;					;
PowerDown:				;
	call	CLEARDISP
	MOV	B,#10D			;
	CALL	BlinkLED		; Blink LED ten times
	MOV	TCON,#000H		; Stop the timer
	MOV	IE,#000H		; Disable all interrupts
	MOV	P0,#0FFH		; Clear the ports
	MOV	P1,#0FFH		;
	CLR	VPORT.VBIT		;
	CLR	V2PORT.V2BIT		;
	MOV	PCON,#002H		; Set the PD bit in PCON
PD90:					;
	JMP	PD90			; Program stopped
; ---------------------------------------------------------------------
;                           WaitRelease
; ---------------------------------------------------------------------
;					;
;WaitRelease:				;
;	push	a			;
;	push	b			;
;WR01:					;
;	mov	b,#3d			;
;WR10:					;
;	mov	a,debouncetimer		;
;WR20:					;
;	JNB	TPORT.TBIT,WR01		;
;	djnz	a,WR20			;
;	djnz	b,WR10			;
;WR25:					;
;	pop	b			;
;	pop	a			;
					;
;WaitReturn:				;
;	JB	wfire,WaitReturn	;
;	setb	IE.0			;
;	ret				;
					;
WaitRelease:				;
	push	a			;
	push	b			;
	mov	BUFFBYTE,#2d		;
WR01:					;
	mov	b,#25d			;
WR10:					;
	mov	a,debouncetimer		;
	add	a,#1d			;
WR20:					;
	push	a			;
	mov	a,BUFFBYTE		;
	jnz	COMEBACKWR		;
;	jnb	B1PORT.B1BIT,WREYESWITCH ;
;	jnb	B2PORT.B2BIT,WREYESWITCH ;
	jmp	WREYESWITCH		;
					;	remove above line & reenable 2 above if re-instating button push
COMEBACKWR:				;
	pop	a			;
					;
	JNB	TPORT.TBIT,WR01		;
	djnz	a,WR20			;
	djnz	b,WR10			;
WR25:					;
	pop	b			;
	pop	a			;
					;
WaitReturn:				;
	JB	wfire,WaitReturn	;
	setb	IE.0			;
	ret				;
					;
WREYESWITCH:				;
	mov	A,SEBPASS		;
	jnz	WREYESWITCH2		;
	mov	SEBPASS,#1d		;
	setb	ebpass			;
	mov	A,DROFOFST		;
	MOV	DPTR,#DFTAB		; Load valve off-time base address
	MOVC	A,@A+DPTR		; Get value from DPTR+A in FTAB or 
	MOV	B,ONTIMR		;
	SUBB	A,B			;
	MOV	OFTIMR,A		;
WREYESWITCHOK:				;
	mov	BUFFBYTE,#10d		;
	jmp	COMEBACKWR		;
WREYESWITCH2:				;
	mov	SEBPASS,#0d		;
	mov	BUFFBYTE,#10d		;
	mov	a,V2SOLMODE		;
	jz	COMEBACKWR		;
	mov	ebpass,#0d		;
	jmp	COMEBACKWR		;
; ---------------------------------------------------------------------
;                           GetTiming
; ---------------------------------------------------------------------
					;
MAINCONVERT:				;
	mov	mode,#0d		;
MCROK:					;
	mov	B,DWELL			;
	mov	A,#030d			;
	SUBB	A,B			;
	jnc	MCDOK			;
	mov	A,V2SOLMODE		;
	jz	MCROK2			;
	MOV	DWELL,#6d		;
	jmp	MCDOK			;
MCROK2:					;
	MOV	DWELL,#10d		;
	MOV	A,V2SOLMODE		;
	JZ	MCDOK			;
	MOV	DWELL,#5D		;
MCDOK:					;
	mov	A,DWELL			;
	mov	ONTIMR,A		;
	mov	B,dbonc			;
	mov	A,#15d			;
	subb	A,B			;
	jnc	MCD2OK			;
	mov	dbonc,#4d		;
MCD2OK:					;
	mov	A,dbonc			;
	mov	B,#15d			;
	mul	AB			;
	mov	debouncetimer,A		;
	mov	B,ROFOFST		;
	mov	A,#07d			;
	SUBB	A,B			;
	jnc	MCR2OK			;
	mov	ROFOFST,#0d		;
MCR2OK:					;
	mov	A,ROFOFST		;
	MOV	DPTR,#FTAB		; Load valve off-time base address
	MOVC	A,@A+DPTR		; Get value from DPTR+A in FTAB or 
	jz	GT2			;
	MOV	B,ONTIMR		;
	SUBB	A,B			;
GT2:					;
	MOV	OFTIMR,A		;
	MOV	B,AEDELNC		;
	MOV	A,#07d			;
	SUBB	A,B			;
	jnc	MCAOK			;
	MOV	AEDELNC,#2d		;
MCAOK:					;
	MOV	A,AEDELNC		;
	clr	ebpass			;
	mov	SEBPASS,#0d		;
	jnz	MCAOK2			;
	setb	ebpass			;
	mov	SEBPASS,#1d		;
	mov	A,OFTIMR		;
	jnz	MCAOK2			;
	mov	A,#49d			;
	mov	B,ONTIMR		;
	SUBB	A,B			;
	MOV	OFTIMR,A		;
MCAOK2:					;
	DEC	A			;
	mov	B,A			;
	ADD	A,B			;
	mov	AEDEL,a			;
	mov	B,TIMMOD		;
	MOV	A,#01d			;
	subb	A,B			;
	jnc	MCT1OK			;
	MOV	TIMMOD,#1d		;
MCT1OK:					;
	MOV	B,TIMINT		;
	MOV	A,#02d			;
	SUBB	A,B			;
	jnc	MCT2OK			;
	MOV	TIMINT,#1d		;
MCT2OK:					;
	MOV	B,TIMSTT		;
	MOV	A,#07d			;
	SUBB	A,B			;
	jnc	MCT3OK			;
	mov	TIMSTT,#3d		;
MCT3OK:					;
	MOV	B,TIMST2		;
	MOV	A,#11d			;
	SUBB	A,B			;
	jnc	MCT3aOK			;
	mov	TIMST2,#0d		;
MCT3aOK:				;
	MOV	B,DIS1			;
	MOV	A,#10d			;
	SUBB	A,B			;
	jnc	MCD1OK			;
	MOV	DIS1,#0d		;
MCD1OK:					;
	MOV	B,DIS2			;
	MOV	A,#10d			;
	SUBB	A,B			;
	jnc	MCDS2OK			;
	MOV	DIS2,#1d		;
MCDS2OK:				;
	MOV	A,V2SOLMODE		;
	jz	MCDS2OKB		;
	mov	EYEMOD,#1d		;
MCDS2OKB:				;
	MOV	B,EYEMOD		;
	MOV	A,#01d			;
	SUBB	A,B			;
	jnc	MCDS3OK			;
	MOV	EYEMOD,#0d		;
MCDS3OK:				;
	MOV	B,tmdstat		;
	MOV	A,#01d			;
	SUBB	A,B			;
	jnc	MCDS4OK			;
	MOV	tmdstat,#0d		;
MCDS4OK:				;
	MOV	B,DIS2B			;
	MOV	A,#10d			;
	SUBB	A,B			;
	jnc	MCDS5OK			;
	MOV	DIS2B,#3d		;
MCDS5OK:				;
	MOV	B,DIS1B			;
	MOV	A,#10d			;
	SUBB	A,B			;
	jnc	MCDS6OK			;
	MOV	DIS1B,#6d		;
MCDS6OK:				;
	;MOV	B,AROFT			;
	;MOV	A,#03d			;
	;SUBB	A,B			;
	;jnc	MCDS7OK			;
	;MOV	AROFT,#0d		;
MCDS7OK:				;
	MOV	A,V2SOLMODE		;
	jz	MCDS7OKB		;
	mov	SCOPEMD,#0d		;
MCDS7OKB:				;
	MOV	A,SCOPEMD		;
	jz	MCDS8OK			;
	MOV	EYEMOD,#0d		;
	MOV	SCOPEMD,#1d		;
MCDS8OK:				;
	MOV	B,SDELAYOFF		;
	MOV	A,#60D			;
	SUBB	A,B			;
	JNC	MCDS9OK			;
	MOV	SDELAYOFF,#6D		;
MCDS9OK:				;
	MOV	A,DWELL			;
	MOV	B,SDELAYOFF		;
	ADD	A,B			;
	MOV	SDELAY,A		;
	MOV	B,SMINIMOFF		;
	MOV	A,#60D			;
	SUBB	A,B			;
	JNC	MCDS10OK		;
	MOV	SMINIMOFF,#50D		;
MCDS10OK:				;
	MOV	A,SMINIMOFF		;
	MOV	SMINIM,A		;
	MOV	B,ASDL			;
	MOV	A,#60D			;
	SUBB	A,B			;
	JNC	MCDS11OK		;
	MOV	ASDL,#30D		;
MCDS11OK:				;
	MOV	B,DROFOFST		;
	mov	A,#7d			;
	SUBB	A,B			;
	JNC	MCDS12OK		;
	MOV	DROFOFST,#5d		; Default default (heh) is 12bps
MCDS12OK:				;
	mov	VMAJ,#2d		; Major version number
	mov	VMIN,#20d		; Minor version number
	mov	MTYPE,#2d		; 0= Chaos, 1= Entropy
	call	WRITE_EEP		;
	RET				;
					;
CONVERTIN:				;
	mov	DLTMP,DWELL		;
	mov	SLTMP,SMINIMOFF		;
	mov	ALTMP,ASDL		;
	mov	A,DWELL			;
	mov	B,#2d			;
	DIV	AB			;
	dec	A			;
	mov	DWELL,A			;
	mov	A,B			;
	jz	CONVERTIN2		;
	mov	DWELL,#255d		;
CONVERTIN2:				;
	mov	A,SMINIMOFF		;
	jz	CONVERTINDN		;
	cjne	A,#60d,CONVERTIN3	;
	jmp	CONVERTINFL		;
CONVERTIN3:				;
	mov	B,#15d			;
	subb	A,B			;
	jc	CONVERTINFL		;
	mov	B,#3d			;
	add	A,B			;
	div	AB			;
	mov	SMINIMOFF,A		;
	mov	A,B			;
	jz	CONVERTINDN		;
CONVERTINFL:				;
	mov	SMINIMOFF,#255d		;
CONVERTINDN:				;
	mov	A,ASDL			;
	mov	B,#2d			;
	DIV	AB			;
	dec	A			;
	mov	ASDL,A			;
	mov	A,B			;
	jz	CONVERTIN4		;
	mov	ASDL,#255d		;
CONVERTIN4:				;
	ret				;
					;
CONVERTOUT:				;
	mov	A,DWELL			;
	cjne	A,#255d,CONVERTDWLD	;
	mov	DWELL,DLTMP		;
	jmp	CONVERTSMN		;
CONVERTDWLD:				;
	inc	A			;
	mov	b,#2d			;
	mul	ab			;
	mov	DWELL,A			;
CONVERTSMN:				;
	mov	A,SMINIMOFF		;
	cjne	A,#255d,CONVERTSMND	;
	mov	SMINIM,SLTMP		;
	jmp	CONVS2MNDONEC		;
CONVERTSMND:				;
	jz	CONVS2MNDONEB		;
	mov	B,#3			;
	mul	AB			;
	mov	B,#12d			;
	add	A,B			;
CONVS2MNDONEB:				;
	mov	SMINIMOFF,A		;
CONVS2MNDONEC:				;
	mov	A,ASDL			;
	cjne	A,#255d,CONVERTASLD	;
	mov	ASDL,ALTMP		;
	jmp	CONVERTSMNX		;
CONVERTASLD:				;
	inc	A			;
	mov	b,#2d			;
	mul	ab			;
	mov	ASDL,A			;
CONVERTSMNX:				;
	ret				;
;					;
; ---------------------------------------------------------------------
;                           BlinkLED
; ---------------------------------------------------------------------
BlinkLED:				;
	push	a			;
BlinkLED1:				;
	clr	LPORT.LBIT		; Turn on LED
	MOV	TICK,#LEDON		;
BL10:					;
	MOV	A,TICK			; Interrupt based LED on delay
	JNZ	BL10			;
	setb	LPORT.LBIT		; Turn off LED
	MOV	TICK,#LEDOF		;
BL20:					;
	MOV	A,TICK			; Interrupt based LED off delay
	JNZ	BL20			;
	DJNZ	B,BlinkLED1		; Loop 'B' times
	pop	a			;
	RET				;
; ---------------------------------------------------------------------
;                              Pause
; ---------------------------------------------------------------------
PAUSE:					;
	push	a			;
PAUSE1:					;
	MOV	TICK,#100d		; Load 100mS constant
PA10:	MOV	A,TICK			; Interrupt based delay
	JNZ	PA10			;
	DJNZ	B,PAUSE1		; Loop 'B' times
	pop	a			;
	RET				;
;					;
; ---------------------------------------------------------------------
;                              Wait1mS
; ---------------------------------------------------------------------
WAIT1MS:				;
	PUSH	A			;
wt1a:					;
	jb	mswapbt,wt1a		;
wt1b:					;
	jnb	mswapbt,wt1b		;
	POP	A			;
	RET				;
					;
READ_EEP:				;
	CLR	TR0			; Stop T0
	mov	dptr,#0			;
	mov	R0,#2fh			;
	mov	addrttl,#28d		;
	DB	#43h,#96h,#8d		; =orl	96h, #8d
READ_EEPx:				;
	nop				;
	nop				;
	movx	a,@dptr			;
	inc	r0			;
	mov	@r0,A			;
	inc	dptr			;
	djnz	addrttl,READ_EEPx	;
	setb	TR0			; Stop T0
NOREAD:					;
	DB	#63h,#96h,#8d		; =xrl	96h, #8d		
	ret				;
					;
WRVOEEP:				;
	MOV	HROFLTOTL,V2SOLMODE		;
	CLR	TR0			;
	mov	dptr,#29d		;
	mov	addrttl,#5d		;
	mov	r0,#5bh			;
	jmp	WRITE_EEPx		;
WRITE_EEP:				;
	CLR	TR0			; Stop T0
	mov	dptr,#0			;
	mov	r0,#2fh			;
	mov	addrttl,#23d		;
WRITE_EEPx:				;
	inc	r0			;
	mov	a,@r0			;
	DB	#43h,#96h,#8d		; =orl	96h, #8d
	DB	#43h,#96h,#16d		; =orl	96h, #16d
	nop				;
	nop				;
	movx	@dptr,a			;
	inc	dptr			;
					;
	mov	mnuopt,#250d		;
	mov	mnunum,#40d		;
waitforeeprom:				;
	djnz	mnuopt,waitforeeprom	;
	mov	mnuopt,#250d		;
	djnz	mnunum,waitforeeprom	;
					;
					;
	djnz	addrttl,WRITE_EEPx	;
	DB	#63h,#96h,#8d		; =xrl	96h, #8d
	DB	#63h,#96h,#16d		; =xrl	96h, #16d
	SETB	TR0			;
	MOV	HROFLTOTL,#FFH			;
	ret				;
					;
TPROG:					;
	mov	tmenbyte,#255d		;
	setb	EEPORT.EEBIT		;
	clr	L2PORT.L2BIT		;
	setb	TLPORT.TLBIT		;
TPROGCONT:				;
	MOV	A,#0			;
TPROGALP:				;
	cjne	A,#1d,tprogok		;
	jmp	TPROGCHG		;
tprogok:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,ENDTPROGA	;
TPROGCHG:
	inc	A			;
	JNB	VTPORT.VTBIT,TPROGALP2	;
	cjne	A,#8,TPROGALP		;
	jmp	TPROG			;
TPROGALP2:				;
	cjne	A,#11,TPROGALP		;
	jmp	TPROG			;
					;
ENDTPROGA:				;
	jb	TPORT.TBIT,ENDTPROGA	;
	mov	b,a			; keep a copy
	rl	a			; multiply by two
	add	a,b			; convert to jump offset
	mov	DPTR,#TPROGAJMP		; point to jump table
	jmp	@A+DPTR			; and jump out
TPROGAJMP:				;
	ljmp	TPROGALL		;
	ljmp	TPROGMODE		; 
	ljmp	TPROGROFF		;
	ljmp	TPROGDWEL		;
	ljmp	TPROGDBNC		; 
	ljmp	TPROGAEDL		; 
	ljmp	TPROGEMOD		; 
	ljmp	TPROGSCOP		;
	ljmp	TPROGS2DL		;
	ljmp	TPROGS2MN		;
	ljmp	TPROGASDL		;
TPROGMODE:				;
	jb	TLPORT.TLBIT,TPROGNODONE ;
	setB	LDPORT.5		;
	CLR	LDPORT.6		;
	JNB	LDPORT.5,TPROGNODONE	;
	jmp	TPROGDONE
TPROGNODONE:
	MOV	A,#0			;
TPROGMODELP:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,TPROGMODEDONE ;
	inc	A			;
	cjne	A,#4,TPROGMODELP	; for testing, should be 5
	jmp	TPROGMODE		;
TPROGMODEDONE:				;
	mov	mode,A			;
	jmp	TPROGDONE		;
					;
TPROGROFF:				;
	MOV	A,#0			;
TPROGROFFLP:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,TPROGROFFDONE ;
	inc	A			;
	cjne	A,#8,TPROGROFFLP	; for testing, should be 8
	jmp	TPROGROFF		;
TPROGROFFDONE:				;
	mov	ROFOFST,A		;
	jmp	TPROGDONE		;
					;
TPROGDWEL:				;
	jb	TLPORT.TLBIT,TPROGNODONE2 ;
	setB	LDPORT.5		;
	CLR	LDPORT.6		;
	JNB	LDPORT.5,TPROGNODONE2	;
	jmp	TPROGDONE
TPROGNODONE2:
	MOV	A,#0			;
TPROGDWELLP:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,TPROGDWELDONE ;
	inc	A			;
	cjne	A,#15d,TPROGDWELLP	; for testing, should be 8
	jmp	TPROGDWEL		;
TPROGDWELDONE:				;
	inc	A			;
	mov	b,#2d			;
	mul	ab			;
	mov	DWELL,A			;
	jmp	TPROGDONE		;
					;
TPROGDBNC:				;
	jb	TLPORT.TLBIT,TPROGNODONE3 ;
	setB	LDPORT.5		;
	CLR	LDPORT.6		;
	JNB	LDPORT.5,TPROGNODONE3	;
	jmp	TPROGDONE
TPROGNODONE3:
	MOV	A,#0			;
TPROGDBNCLP:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,TPROGDBNCDONE ;
	inc	A			;
	cjne	A,#15d,TPROGDBNCLP	; for testing, should be 8
	jmp	TPROGDBNC		;
TPROGDBNCDONE:				;
	mov	dbonc,A			;
	jmp	TPROGDONE		;
					;
TPROGAEDL:				;
	MOV	A,#0			;
TPROGAEDLLP:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,TPROGAEDLDONE ;
	inc	A			;
	cjne	A,#8,TPROGAEDLLP	; for testing, should be 8
	jmp	TPROGAEDL		;
TPROGAEDLDONE:				;
	mov	AEDELNC,A		;
	jmp	TPROGDONE		;
					;
TPROGEMOD:				;
	MOV	A,#0			;
TPROGEMODLP:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,TPROGEMODDONE ;
	inc	A			;
	cjne	A,#2,TPROGEMODLP	; for testing, should be 2
	jmp	TPROGEMOD		;
TPROGEMODDONE:				;
	mov	EYEMOD,A		;
	jmp	TPROGDONE		;
					;
TPROGSCOP:				;
	MOV	A,#0			;
TPROGSCOPLP:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,TPROGSCOPDONE ;
	inc	A			;
	cjne	A,#2,TPROGSCOPLP	; for testing, should be 2
	jmp	TPROGSCOP		;
TPROGSCOPDONE:				;
	mov	SCOPEMD,A		;
	jmp	TPROGDONE		;
					;
TPROGS2DL:				;
	MOV	A,#0			;
TPROGS2DLLP:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,TPROGS2DLDONE ;
	inc	A			;
	cjne	A,#15,TPROGS2DLLP	; for testing, should be 2
	jmp	TPROGS2DL		;
TPROGS2DLDONE:				;
	mov	SDELAYOFF,A		;
	jmp	TPROGDONE		;
					;
TPROGS2MN:				;
	MOV	A,#0			;
TPROGS2MNLP:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,TPROGS2MNDONE ;
	inc	A			;
	cjne	A,#15,TPROGS2MNLP	; for testing, should be 2
	jmp	TPROGS2MN		;
TPROGS2MNDONE:				;
	jz	TPROGS2MNDONEB		;
	mov	B,#3			;
	mul	AB			;
	mov	B,#12d			;
	add	A,B			;
TPROGS2MNDONEB:				;
	mov	SMINIMOFF,A		;
	jmp	TPROGDONE		;
					;
TPROGASDL:				;
	MOV	A,#0			;
TPROGASDLLP:				;
	MOV	B,A			;
	inc	B			;
	lCALL	BlinkLED		;
	MOV	B,#5d			;
	lCALL	PAUSE			;
	jb	TPORT.TBIT,TPROGASDLDONE ;
	inc	A			;
	cjne	A,#15,TPROGASDLLP	; for testing, should be 2
	jmp	TPROGASDL		;
TPROGASDLDONE:				;
	inc	A			;
	mov	B,#2d			;
	mul	AB			;
	mov	ASDL,A			;
	jmp	TPROGDONE		;
					;
TPROGALL:				;
	jb	TLPORT.TLBIT,TPROGNODONE4 ;
	setB	LDPORT.5		;
	CLR	LDPORT.6		;
	JNB	LDPORT.5,TPROGNODONE4	;
	jmp	TPROGDONE
TPROGNODONE4:
	MOV	A,#0			;
TPROGALLLP:
	MOV	B,A			;
	inc	B			;
	CALL	BlinkLED		;
	MOV	B,#5d			;
	CALL	PAUSE			;
	jb	TPORT.TBIT,TPROGALLDONE ;
	inc	A			;
	cjne	A,#4,TPROGALLLP		;
	jmp	TPROGALL		;
TPROGALLDONE:				;
					;
	mov	b,a			; keep a copy
	rl	a			; multiply by two
	add	a,b			; convert to jump offset
	mov	DPTR,#TPROGALLJMP	; point to jump table
	jmp	@A+DPTR			; and jump out
TPROGALLJMP:				;
	ljmp	TPROGCNSV		;
	ljmp	TPROGNORM		;
	ljmp	TPROGFAST		;
	ljmp	TPROGXTRM		;
TPROGCNSV:				;
	mov	DWELL,#10d		;
	mov	mode,#0d		;
	mov	ROFOFST,#4d		;
	mov	dbonc,#4d		;
	mov	AEDELNC,#6d		;
	mov	EYEMOD,#0d		;
	mov	tmdstat,#0d		;
	mov	SCOPEMD,#1d		;
	mov	SDELAYOFF,#6d		;
	mov	SMINIMOFF,#50d		;
	mov	ASDL,#30d		;
	mov	a,V2SOLMODE		;
	JZ	TPROGDONE		;
	MOV	DWELL,#5D		;
	jmp	TPROGDONE		;
TPROGNORM:				;
	mov	DWELL,#10d		;
	mov	mode,#0d		;
	mov	ROFOFST,#2d		;
	mov	dbonc,#4d		;
	mov	AEDELNC,#5d		;
	mov	EYEMOD,#0d		;
	mov	tmdstat,#0d		;
	mov	SCOPEMD,#1d		;
	mov	SDELAYOFF,#6d		;
	mov	SMINIMOFF,#45d		;
	mov	ASDL,#28d		;
	JZ	TPROGDONE		;
	MOV	DWELL,#5D		;
	jmp	TPROGDONE		;
TPROGFAST:				;
	mov	DWELL,#10d		;
	mov	mode,#0d		;
	mov	ROFOFST,#1d		;
	mov	dbonc,#3d		;
	mov	AEDELNC,#3d		;
	mov	EYEMOD,#0d		;
	mov	tmdstat,#0d		;
	mov	SCOPEMD,#1d		;
	mov	SDELAYOFF,#6d		;
	mov	SMINIMOFF,#40d		;
	mov	ASDL,#22d		;
	JZ	TPROGDONE		;
	MOV	DWELL,#5D		;
	jmp	TPROGDONE		;
TPROGXTRM:				;
	mov	DWELL,#10d		;
	mov	mode,#0d		;
	mov	ROFOFST,#0d		;
	mov	dbonc,#3d		;
	mov	AEDELNC,#2d		;
	mov	EYEMOD,#0d		;
	mov	tmdstat,#0d		;
	mov	SCOPEMD,#1d		;
	mov	SDELAYOFF,#6d		;
	mov	SMINIMOFF,#0d		;
	mov	ASDL,#20d		;
	JZ	TPROGDONE		;
	MOV	DWELL,#5D		;
					;
TPROGDONE:				;
	setB	LDPORT.5		;
	CLR	LDPORT.6		;
	JNB	LDPORT.5,INFLOOP	;
	mov	tmenbyte,#0d		;
	clr	EEPORT.EEBIT		;
	ret				;
INFLOOP:				;
	JMP	INFLOOP			;
					;
eyeverf:				;
	jnb	FLAGS.ebpass,eyeverfdone ;
	mov	a,SEBPASS		;
	jnz	eyeverfdone		;
	clr	EEPORT.EEBIT		;
	call	WAIT1MS			;
	jb	EPORT.EBIT,eyeverfdone	;
	clr	FLAGS.ebpass		;
	mov	A,ROFOFST		;
	MOV	DPTR,#FTAB		; Load valve off-time base address
	MOVC	A,@A+DPTR		; Get value from DPTR+A in FTAB or 
	jz	EVGT2			;
	MOV	B,ONTIMR		;
	SUBB	A,B			;
EVGT2:					;
	MOV	OFTIMR,A		;
					;
eyeverfdone:				;
	ret				;
					;
mnuverifiedb:				;
	jmp	mnuverified		;
					;
mnuverify:				;
	mov	A,mnunum		;
	CLR	lcdupdate		;
	setb	TLPORT.TLBIT		;
	jb	TLPORT.TLBIT,mnucontin4	;
	cjne	A,#0d,mnucontin1	;
	setb	lcdupdate		;
mnucontin1:				;
	cjne	A,#1d,mnucontin2	;
	setb	lcdupdate		;
mnucontin2:				;
	cjne	A,#2d,mnucontin3	;
	setb	lcdupdate		;
mnucontin3:				;
	cjne	A,#3d,mnucontin4	;
	setb	lcdupdate		;
mnucontin4:				;
	mov	CURRENTNUM,JMPFLAG1	;
	cjne	A,#0d,mnu2verify	;
	jb	MNU1ACT,mnuverifiedb	;
	setb	lcdupdate		;
mnu2verify:				;
	cjne	A,#1d,mnu3verify	;
	jb	MNU2ACT,mnuverifiedb	;
	setb	lcdupdate		;
mnu3verify:				;
	cjne	A,#2d,mnu4verify	;
	jb	MNU3ACT,mnuverifiedb	;
	setb	lcdupdate		;
mnu4verify:				;
	cjne	A,#3d,mnu5verify	;
	jb	MNU4ACT,mnuverifiedb	;
	setb	lcdupdate		;
mnu5verify:				;
	cjne	A,#4d,mnu6verify	;
	jb	MNU5ACT,mnuverifiedb	;
	setb	lcdupdate		;
mnu6verify:				;
	cjne	A,#5d,mnu7verify	;
	jb	MNU6ACT,mnuverifiedb	;
	setb	lcdupdate		;
mnu7verify:				;
	cjne	A,#6d,mnu8verify	;
	jb	MNU7ACT,mnuverified	;
	setb	lcdupdate		;
mnu8verify:				;
	cjne	A,#7d,mnu9verify	;
	jb	MNU8ACT,mnuverified	;
	setb	lcdupdate		;
mnu9verify:				;
	mov	CURRENTNUM,JMPFLAG2	;
	cjne	A,#8d,mnu10verify	;
	jb	MNU9ACT,mnuverified	;
	setb	lcdupdate		;
mnu10verify:				;
	cjne	A,#9d,mnu11verify	;
	jb	MNU10ACT,mnuverified	;
	setb	lcdupdate		;
mnu11verify:				;
	cjne	A,#10d,mnu12verify	;
	jb	MNU11ACT,mnuverified	;
	setb	lcdupdate		;
mnu12verify:				;
	cjne	A,#11d,mnu13verify	;
	jb	MNU12ACT,mnuverified	;
	setb	lcdupdate		;
mnu13verify:				;
	cjne	A,#12d,mnu14verify	;
	jb	MNU13ACT,mnuverified	;
	setb	lcdupdate		;
mnu14verify:				;
	cjne	A,#13d,mnu15verify	;
	jb	MNU14ACT,mnuverified	;
	setb	lcdupdate		;
mnu15verify:				;
	cjne	A,#14d,mnu16verify	;
	jb	MNU15ACT,mnuverified	;
	setb	lcdupdate		;
mnu16verify:				;
	cjne	A,#15d,mnu17verify	;
	jb	MNU16ACT,mnuverified	;
	setb	lcdupdate		;
mnu17verify:				;
	mov	CURRENTNUM,JMPFLAG3	;
	cjne	A,#16d,mnu18verify	;
	jb	MNU17ACT,mnuverified	;
	setb	lcdupdate		;
mnu18verify:				;
	cjne	A,#17d,mnu19verify	;
	jb	MNU18ACT,mnuverified	;
	setb	lcdupdate		;
mnu19verify:				;
	cjne	A,#18d,mnuverified	;
	jb	MNU19ACT,mnuverified	;
	setb	lcdupdate		;
mnuverified:				;
	ret				;;					;
; ======================================================================
;                      Timer 0 Interrupt Processing
; ======================================================================
TMR0:					;
	PUSH	A			; Save A
	PUSH	PSW			; Save PSW
	CLR	TR0			; Stop T0
	MOV	TH0,#T0MSB		; Reload counter
	MOV	TL0,#T0LSB		;
	MOV	A,TICK			; Get the 2 mS tick value
	JZ	TMR05			; don't go below zero
	DEC	TICK			; Decrement the ticker
TMR05:					;
	jnb	firing,NOTMRFIRE	;
	jmp	TMRFIRE			;
NOTMRFIRE:				;
	jnb	wfire,TMRPDTJMP		;
					;
	mov	A,tmdstat		;
	jnz	TMRBUFR			;
	mov	A,SCOPEMD		;
	jz	TMRBUFR			;
	jb	ebpass,TMRBUFR		;
	jb	EPORT.EBIT,TMRBUFR	;
	mov	OTMIR,#0d		;
	mov	FTMIR,#0d		;
	setb	firing			;
	setb	ES1OK			;
	setb	ES2OK			;
	MOV	EYTICK,#200D		;
	setb	wfire			;
	jmp	TMRFIRE			;
TMRPDTJMP:				;
	jmp	TMRPDT			;
					;
					;
TMRBUFR:				;
	clr	wfire			;
	setb	firing			;
					;
					;
	mov	a,HROFL1		;
	mov	b,HROFTMPL		;
	subb	a,b			;
	mov	a,HROFH1		;
	mov	b,HROFTMPH		;
	subb	a,b			;
	jc	NOMAXING		;
					;
	mov	HROFL1,HROFTMPL		; only LAST or MAX section must be enabled
	mov	HROFH1,HROFTMPH		; 
NOMAXING:				;
	mov	HROFL2,HROFL1		;
	mov	HROFH2,HROFH1		;
	mov	HROFL3,HROFL1		;
	mov	HROFH3,HROFH1		;
	jmp	TMRBUFRNONUM		;
TMRBUFRNUM1:				;
	mov	A,HROFNUM		;
	cjne	A,#2d,TMRBUFRNUM2	;
	mov	HROFL3,HROFTMPL		;
	mov	HROFH3,HROFTMPH		;
	jmp	TMRBUFRNONUM		;
TMRBUFRNUM2:				;
	mov	HROFL2,HROFTMPL		;
	mov	HROFH2,HROFTMPH		;
TMRBUFRNONUM:				;
	mov	HROFTMPL,#0d		;
	mov	HROFTMPH,#0d		;
	mov	A,TIMINT		;
	cjne	A,#2d,NOTNEXTONE	;
	jmp	NEXTONEIMGOINFOR	;
NOTNEXTONE:				;
	mov	tmenbyte,#1d		;
NEXTONEIMGOINFOR:			;
	inc	SCNTL			;
	mov	a,SCNTL			;
	subb	a,#99d			;
	jc	TMRBUFR2		;
	mov	SCNTL,#0		;
	inc	SCNTH			;
	subb	a,#99d			;
	jc	TMRBUFR2		;
	mov	SCNTH,#0		;
TMRBUFR2:				;
	MOV	UPDCNT,#0d		;
	MOV	OTMIR,ONTIMR		;
	DEC	OTMIR			;
	MOV	FTMIR,OFTIMR		;
	MOV	S10K,#0D		;
	MOV	S20K,#0D		;
	mov	OPBOLTBUF,#3d		;
	MOV	A,tmdstat		;
	jz	TMRBUFR2A		;
	MOV	OPBOLTBUF,#0D		;
TMRBUFR2A:				;
	MOV	SDELMIR,SDELAY		;
	MOV	SMNMIR,SMINIM		;
	MOV	ASDLMIR,ASDL		;
	MOV	FDTMH,#5		;
	MOV	FDTML,#250		;
	setb	LPORT.LBIT		;
	clr	EEPORT.EEBIT		;
	clr	ES1OK			;
	clr	ES2OK			;
	MOV	EYTICK,#200		; wait time after trigger pull to allow for ball-bolt interference (wait for the bolt to get in front of the eye)
	mov	A,V2SOLMODE		;
	JNZ	TMRBUFR2B		;
	setb	VPORT.VBIT		;
	jmp	TMRPDT			;
TMRBUFR2B				;
	setb	V2PORT.V2BIT		;
	jmp	TMRPDT			;
TMRFIRE:				;
	MOV	A,OTMIR			;
	JZ	TMRFIRO			;
	DEC	OTMIR			;
	JMP	TMREYE1			;
TMRFIRO:				;
	mov	A,V2SOLMODE		;
	JNZ	TMRFIROB		;
	clr	VPORT.VBIT		;
	JMP	TMRFIROC		;
TMRFIROB:				;
	clr	V2PORT.V2BIT		;
TMRFIROC:				;
	clr	LPORT.LBIT		;
	MOV	A,FTMIR			;
	JZ	TMREYE1			;
	DEC	FTMIR			;
TMREYE1:				;
	jb	ebpass,TMREYE3JMP	;
	mov	A,OTMIR			;
	jnz	TMREYE2notOK2		;
	setb	L2PORT.L2BIT		;
	mov	A,esect2ok		;
	jnz	TMREYE3OKyjmp		;
	Jb	ES1OK,TMREYE2		;
	MOV	A,EYTICK		;
	JZ	TMREYE1OK		;
	DEC	EYTICK			;
	jb	EPORT.EBIT,TMREYE1OK	;
	JMP	TMRPDT			;
TMREYE3OKyjmp:				;
	jmp	TMREYE3OKy		;
TMREYE1OK:				;
	setb	ES1OK			;
	MOV	EYTICK,#255		;
TMREYE2:				;
	Jb	ES2OK,TMREYE3		;
	MOV	A,EYTICK		;
	JZ	TMREYEBP		;
	DEC	EYTICK			;
	Jb	EPORT.EBIT,TMREYE2notOK	;
	mov	a,OPBOLTBUF		;
	jz	TMREYE2OK		;
	dec	OPBOLTBUF		;
	jmp	TMREYE2notOK2		;
TMREYE2notOK:				;
	mov	OPBOLTBUF,#5d		;
	MOV	A,tmdstat		;
	JZ	TMREYE2notOK2		;
	MOV	OPBOLTBUF,#0D		;
TMREYE2notOK2:				;
	JMP	TMRPDT			;
TMREYE3JMP:				;
	jmp	TMREYE3OK		;
TMREYEBP:				;
	setb	ebpass			;
	clr	wfire			;
	mov	A,DROFOFST		;
	MOV	DPTR,#DFTAB		; Load valve off-time base address
	MOVC	A,@A+DPTR		; Get value from DPTR+A in FTAB or 
	MOV	B,ONTIMR		;
	SUBB	A,B			;
	MOV	OFTIMR,A		;
TMREYE2OK:				;
	setb	ES2OK			;
	MOV	EYTICK,#200D		;
TMREYE3:				;
	jb	EPORT.EBIT,TMREYE3OKx	;
	mov	A,tmdstat		;
	jnz	TMREYE3OKx		;
	mov	A,EYEMOD		;
	jnz	TMREYE3B		;
	jmp	TMREYE3C		;
TMREYE3B:				;
	MOV	A,EYTICK		;
	JZ	TMREYE3OK		;
	DEC	EYTICK			;
	jmp	TMRPDT			;
TMREYE3C:				;
	mov	A,EYTICK		;
	jz	TMREYE3D		;
	DEC	EYTICK			;
	jmp	TMRPDT			;
TMREYE3D:				;
	clr	wfire			;
	mov	EYTICK,#200d		;
	MOV	FDTMH,#1		;
	MOV	FDTML,#250		;
	JMP	TMRPDT			;
TMREYE3OKx:				;
	inc	esect2ok		;
	mov	EYTICK,AEDELNC		;
TMREYE3OKy:				;
	mov	A,tmdstat		;
	jnz	TMREYE3OKy2		;
	jb	EPORT.EBIT,TMREYE3OKy2	;
	mov	EYTICK,AEDELNC		;
	jmp	TMRPDT			;
TMREYE3OKy2:				;
	MOV	A,EYTICK		;
	JZ	TMREYE3OK		;
	DEC	EYTICK			;
	JMP	TMRPDT			;
TMREYE3OK:				;
	MOV	S10K,#1D		;
	MOV	A,S20K			;
	JZ	TMRPDT			;
	clr	L2PORT.L2BIT		;
	mov	esect2ok,#0d		;
	mov	A,FTMIR			;
	jnz	TMRPDT			;
	clr	firing			;
TMRPDT:					;
	MOV	A,V2SOLMODE		;
	JZ	TMRPDTSTTJMP		;
	MOV	A,SDELMIR		;
	JZ	SOL2P2			;
	DEC	SDELMIR			;
	JMP	TMRPDTSTT		;
SOL2P2:					;
	MOV	A,SMNMIR		;
	JZ	SOL2P3			;
	setb	VPORT.VBIT		;
	DEC	SMNMIR			;
	JMP	TMRPDTSTT		;
SOL2P3:					;
	MOV	A,S10K			;
	JNZ	SOL2P4			;
	setb	VPORT.VBIT		;
	jmp	TMRPDTSTT		;
SOL2P4:					;
	clr	VPORT.VBIT		;
	MOV	A,ASDLMIR		;
	JZ	TMRPDTSTTJMP		;
	DEC	ASDLMIR			;
	JMP	TMRPDTSTT		;
					;
TMRPDTSTTJMP:				;
	MOV	S20K,#1D		;
TMRPDTSTT:				;
	INC	TMRMSL			;
	MOV	A,TMRMSL		; 1000 mS counter LSB (counts 0-500, 2mS tick)
	CJNE	A,#250D,TMR80		; Wait for a 250 count	
	MOV	TMRMSL,#0		; Reset LSB
	INC	TMRMSH			;
	MOV	A,TMRMSH		; 1000 mS counter MSB
	CJNE	A,#004H,TMR80		; Wait for 2x250 count
	MOV	TMRMSH,#0		; Reset MSB
	INC	TMRS			; Increment seconds
	SETB	lcdupdate		;
	MOV	A,TMRS			; Get seconds counter
					;
	mov	a,BUFFBYTE		;
	jz	TMRPDTA2		;
	dec	BUFFBYTE		;
TMRPDTA2:				;
	MOV	A,TMRS			; Get seconds counter
					;
	CJNE	A,#60D,TMR80		; Wait for a 60 count	
	MOV	TMRS,#0			; Reset LSB
	INC	TMRM			; Increment minutes
	MOV	A,TMRM			; Get minutes counter
	CJNE	A,PDTMAX,TMR80		; Wait for power-down time (up to 255 minutes)
	setb	PDTIMER			; Set power-down flag
TMR80:					;
	jb	mswapbt,TMRSWP2		;
	setb	mswapbt			;
	jmp	TMRSWP3			;
TMRSWP2:				;
	CLR	mswapbt			;
TMRSWP3:				;
	;setb	EEPORT.EEBIT		;
	MOV	A,FDTML			;
	JZ	FDTMR1			;
	DEC	FDTML			;
	clr	EEPORT.EEBIT		;
	JMP	FDTMR2			;
FDTMR1:					;
	MOV	A,FDTMH			;
	JZ	FDTMR2			;
	DEC	FDTMH			;
	clr	EEPORT.EEBIT		;
	MOV	FDTML,#250d		;
FDTMR2:					;
	mov	a,tmenbyte		;
	jz	TMRENDED		;
	mov	A,TIMMOD		;
	jz	FTDMR3			;
	mov	A,TMROMSL		;
	jz	FDTMR22			;
	dec	TMROMSL			;
	jmp	TMRENDED		;
FDTMR22:				;
	mov	TMROMSL,#249d		;
	mov	A,TMROMSH		;
	jz	FDTMR23			;
	dec	TMROMSH			;
	jmp	TMRENDED		;
FDTMR23:				;
	mov	TMROMSH,#3d		;
	mov	A,TMROS			;
	jz	FDTMR24			;
	dec	TMROS			;
	jmp	TMRENDED		;
FDTMR24:				;
	mov	A,TMROM			;
	jz	FDTMR25			;
	mov	TMROS,#59d		;
	dec	TMROM			;
	jmp	TMRENDED		;
FDTMR25:				;
	mov	tmenbyte,#0d		;
	jmp	TMRENDED		;
FTDMR3:					;
	inc	TMROMSL			;
	mov	a,TMROMSL		;
	cjne	a,#250d,TMRENDED	;
	mov	TMROMSL,#0		;
	inc	TMROMSH			;
	mov	a,TMROMSH		;
	cjne	a,#4,TMRENDED		;
	mov	TMROMSH,#0		;
	inc	TMROS			;
	mov	a,TMROS			;
	cjne	a,#60d,TMRENDED		;
	mov	TMROS,#0		;
	inc	TMROM			;
	mov	a,TMROM			;
	cjne	a,#99d,TMRENDED		;
	mov	TMROM,#0		;
TMRENDED:				;
	inc	HROFTMPL		;
	mov	a,HROFTMPL		;
	cjne	A,#0d,TMRENDEDAGAIN	;
	inc	HROFTMPH		;
	mov	a,HROFTMPH		;
	cjne	A,#0d,TMRENDEDAGAIN	;
	mov	HROFTMPH,#255d		;
TMRENDEDAGAIN:				;
	mov	a,LBLCTL		;
	jz	LBLCTP2			;
	dec	LBLCTL			;
	clr	LBLPORT.LBLBIT		;
	jmp	TMRENDEDONELASTTIME	;
LBLCTP2:				;
	mov	a,LBLCTH		;
	jz	NOBL			;
	dec	LBLCTH			;
	mov	LBLCTL,#250d		;
	clr	LBLPORT.LBLBIT		;
	jmp	TMRENDEDONELASTTIME	;
NOBL:					;
	setb	LBLPORT.LBLBIT		;
TMRENDEDONELASTTIME:			;
	mov	A,tmenbyte		;
	inc	A			;
	jz	BLINKINDONE		;
	jb	firing,BLINKINDONE	;
	clr	LPORT.LBIT
	jnb	TLPORT.TBIT,BLINKINDONE	;
	mov	a,TMRMSH		;
	anl	A,#1d			;
	jz	BLINKINDONE		;
	setb	LPORT.LBIT		;
BLINKINDONE:
	CLR	TF0			;
	SETB	TR0			; Re-enable timer
	POP	PSW			; Restore PSW	
	POP	A			; Restore A
	RETI				; Return from T0 interrupt
;					;
; ======================================================================
;                    External Interrupt 0 Processing
; ======================================================================
XINT0:					;
	push	PSW
	push	A			;
	mov	TRIGBIT,#1d		;
	clr	IE.0			;
	mov	a,mode			;
	dec	a			;
	jnz	int0done		;
;	mov	OTICK,TICK		;
;	mov	TICK,#160d		;
int0done:				;
	pop	A			;
	pop	PSW
	RETI				; Return from interrupt
; ======================================================================
;                    External Interrupt 1 Processing
; ======================================================================
;					;
XINT1:					;
	RETI				; Return from interrupt
;					;
; ======================================================================
;                         Data Tables
; ======================================================================
					;
					;
FTAB:	DB	FT1			; Off time 1
	DB	FT2			; Off time 2
	DB	FT3			; Off time 3
	DB	FT4			; Off time 4
	DB	FT5			; Off time 5
	DB	FT6			; Off time 6
	DB	FT7			; Off time 7
	DB	FT8			; Off time 8

DFTAB:	DB	DFT1			; Off time 1
	DB	DFT2			; Off time 2
	DB	DFT3			; Off time 3
	DB	DFT4			; Off time 4
	DB	DFT5			; Off time 5
	DB	DFT6			; Off time 6
	DB	DFT7			; Off time 7
	DB	DFT8			; Off time 8
					;
OSAB:	DB	OS1			; Off time 1
	DB	OS2			; Off time 2
	DB	OS3			; Off time 3
	DB	OS4			; Off time 4
	DB	OS5			; Off time 5
	DB	OS6			; Off time 6
	DB	OS7			; Off time 7
	DB	OS8			; Off time 8
					;
OSABa:	DB	OS1a			; Off time 1
	DB	OS2a			; Off time 2
	DB	OS3a			; Off time 3
	DB	OS4a			; Off time 4
	DB	OS5a			; Off time 5
	DB	OS6a			; Off time 6
	DB	OS7a			; Off time 7
	DB	OS8a			; Off time 8
MODEDISP:				;	
MNUHEADS:				;
MNUHEADS2:				;;
MNUHEADS3:				;;
MNUHEADS4:				;;
MNUHEADS5:				;;
MODMNU:					;
ROFMNU					;
DWLMNU					;
DBCMNU					;
AEDMNU					;
TMMMNU					;
TMIMNU					;
TMTMNU					;
TM2MNU					;
DS1MNU					;
DS2MNU					;
D1BMNU					;
D2BMNU					;
EYMMNU					;
TMDMNU					;
SCMMNU					;
S2DMNU					;
S2MMNU					;
ASDMNU					;
OUTMESSAGE				;
VERSION: 				;
OTHEROPT:				;
NOTHINGNESS:				;
SHORTSPACES:				;
ESTATOFF				;
ESTATON					;
DWELLTABLE				;
DWELLTABLE2				;
x25pBPS					;
LOWROF					;
	DB	"#255d			;
OPTTBL:					;
	DB	#4,#8,#15d,#15d,#15d,#2,#3,#8,#12d,#10d,#10d,#10d,#10d,#2,#2,#2,#15d,#15d,#15d ;switch to this one to enable other displays
TMRSTTABLE:				;
	DB	#1,#2,#3,#5,#7,#10,#12,#15 
 					;
;					;
;					;
; ======================================================================
;                         End of Main Program        
; ======================================================================
.program				;
	END				;