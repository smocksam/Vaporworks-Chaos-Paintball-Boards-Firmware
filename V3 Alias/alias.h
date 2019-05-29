#include <avr/eeprom.h>
#include <inttypes.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/signal.h>

#define VCOMPVAL 7			
#define MAXEEPROMADDRESS 35
#define VMAJ 3
#define VMIN 0
#define MTYPE 8
#define LEDSWITCH 8000        // defines the point where the LED comes on (in microseconds) (non-tourney lock blink)
#define LEDSTOP 15000          // defines the point where the LED counter resets (in microseconds) (non-tourney lock blink)
#define EYEBYPASSMS 200       // Half milliseconds for eye to bypass if bolt doesn't open.  
#define BALLWAITTIME 1200      // Milliseconds to wait for ball to drop   
#define TIMERCOUNT 194        // 256 - (microseconds between cycle/8)  -- 256-125 = 131, minus 1 microsecond for the reinit instruction.
#define TIMER1COUNT 130       // 256- 62 = 194 (half-millisecond - 4 microseconds under)
#define ESTIME 100            // Not yet used...   Probably will never be.
#define LEDONTIME 10           // self explanatory, I think :) (trig prog blink)
#define LEDOFFTIME 10          // self explanatory, I think :) (trig prog blink)
#define BLEDONTIME 4           // self explanatory, I think :) (trig prog blink)
#define BLEDOFFTIME 4          // self explanatory, I think :) (trig prog blink)
#define TIMEBETWEENSETS 28   // Time between trigger programming segments (trig prog blink)
#define BTNDEBOUNCE 3
#define EYEBYPASSTIME 3000  // time the user will hold the trigger down to bypass the eye
#define ABSTIME 30000       // Milliseconds between 'first' shots
#define NSHOTTHRESHOLD 0
#define EWAITTIME 30 		//time the eyes wait at the beginning of the fire cycle for the bolt to get in the way (in half-milliseconds)
#define STABLEOPENTIME 3     //time to wait for the eyes to see each other to make sure we don't have bolt jitter (in half-milliseconds)

//ramping related...
#define RAMPOFFTIME 1000  	// time the gun will wait to return to "normal fire" from ramp (approx 1 second)
#define RAMPRATE 210				//ramp at about 5.5bps

//SnaPShot Mode related...
#define nAllowedShotsCount 4	//number of shots allowed before pausing 
#define nShotSetPauseTime 2000     //wait time between sets.

#define DEFAULTMBOUNCE 0		//mechanical debounce
#define DEFAULTPOWERDOWN 60		//timer to wait for inactivity (in minutes)
#define DEFAULTEYEMODE 5		//eye mode
#define MBOUNCENUMBER 15			
#define DEFAULTNOBOLTEYEWAIT 35
#define DEFAULTTESTCPS 0
#define DEFAULTABSVAL 0			//Anti-Bolt Stick dwell time default
#define DEFAULTVSETTING 16     // default dwell
#define DEFAULTBOLDSETTING 6 // default bolt delay
#define DEFAULTBOLOMSETTING 45 // default minimum bolt open time
#define DEFAULTSHOTMSETTING 1 // default rof limiter (in milliseconds)
#define DEFAULTDBSETTING 7   // default debounce
#define DEFAULTMODE 0         // default mode
#define DEFAULTEYEBYPASSM 0   //
#define DEFAULTEYESENS 100    //
#define DEFAULTAEDSETTING 4   //
#define DEFAULTASDLSETTING 28 //
#define DEFAULTEBSHOT 83     //
#define DEFAULTEBBOLOPMIN 50  //

#define a1DEFAULTMODE 0         // default mode
#define a1DEFAULTEYEBYPASSM 0   //
#define a1DEFAULTASDLSETTING 20 // 1 - Extreme
#define a1DEFAULTBOLDSETTING 6 // default bolt delay
#define a1DEFAULTBOLOMSETTING 1 // default minimum bolt open time
#define a1DEFAULTVSETTING 12     // default dwell
#define a1DEFAULTSHOTMSETTING 1 // default rof limiter (in milliseconds)
#define a1DEFAULTDBSETTING 5   // default debounce
#define a1DEFAULTAEDSETTING 1   //

#define a2DEFAULTMODE 0         // default mode
#define a2DEFAULTEYEBYPASSM 0   //
#define a2DEFAULTVSETTING 16     // default dwell
#define a2DEFAULTBOLDSETTING 6 // default bolt delay
#define a2DEFAULTBOLOMSETTING 40 // default minimum bolt open time
#define a2DEFAULTSHOTMSETTING 1 // default rof limiter (in milliseconds)
#define a2DEFAULTDBSETTING 7   // default debounce
#define a2DEFAULTAEDSETTING 2   //
#define a2DEFAULTASDLSETTING 22 // 2 - Fast

#define a3DEFAULTMODE 0         // default mode
#define a3DEFAULTEYEBYPASSM 0   //
#define a3DEFAULTVSETTING 16     // default dwell
#define a3DEFAULTBOLDSETTING 6 // default bolt delay
#define a3DEFAULTBOLOMSETTING 50 // default minimum bolt open time
#define a3DEFAULTSHOTMSETTING 50 // default rof limiter (in milliseconds)
#define a3DEFAULTDBSETTING 7   // default debounce
#define a3DEFAULTAEDSETTING 4   //
#define a3DEFAULTASDLSETTING 28 // 3 - Normal

#define a4DEFAULTMODE 0         // default mode
#define a4DEFAULTEYEBYPASSM 0   //
#define a4DEFAULTVSETTING 20     // default dwell
#define a4DEFAULTBOLDSETTING 6 // default bolt delay
#define a4DEFAULTBOLOMSETTING 50 // default minimum bolt open time
#define a4DEFAULTSHOTMSETTING 67 // default rof limiter (in milliseconds)
#define a4DEFAULTDBSETTING 10   // default debounce
#define a4DEFAULTAEDSETTING 6   //
#define a4DEFAULTASDLSETTING 30 // 4 - Conservative

#define TIMEADJUSTMENT 1000   // modifies the timeframe of the "wait" subroutine.

#define ROF1  1                 // milliseconds in ROF setting 1 unlimited
#define ROF2  45                // milliseconds in ROF 22
#define ROF3  50                // milliseconds in ROF 20
#define ROF4  53                // milliseconds in ROF 19
#define ROF5  56                // milliseconds in ROF 18
#define ROF6  59                // milliseconds in ROF 17
#define ROF7  63                // milliseconds in ROF 16
#define ROF8  67                // milliseconds in ROF 15
#define ROF9  71                // milliseconds in ROF 14
#define ROF10 77                // milliseconds in ROF 13
#define ROF11 83                // milliseconds in ROF 12
#define ROF12 91                // milliseconds in ROF 11
#define ROF13 100               // milliseconds in ROF 10
#define ROF14 111               // milliseconds in ROF 9
#define ROF15 125               // milliseconds in ROF 8
#define ROF16 167               // milliseconds in ROF 6
#define CAPROF 35				// capped ROF for "Eye Bypassed/dry fire"

#define INPORT PIND
#define Trigger 2            //- PD3 - Pullup on
#define TLock 4              //- PD4   - Pullup on

#define EYEPORT PINC
#define Eye 2                //- PD2     - Pullup off **PROBABLY WILL NOT USE THIS INPUT FOR EYE! (need a-in)

#define BTNPORT PINC
#define B1 0
#define B2 1

#define STIMEBETWEENSETS 10
#define BPCOUNTTIME 30000
#define MNUTRIGHOLD 60000
#define BTNDEBOUNCE 3

#define LEDPORT PORTD
#define REDLED 6
#define GREENLED 3
#define BLUELED 7
#define VALVEPORT PORTB
#define VALVEBIT 0

#define	nMode nEepnBuffer[0]
#define	nShotMSetting nEepnBuffer[1]        // Takes all the settings and puts it in the array
#define	nVSetting nEepnBuffer[2]
#define	nDBSetting nEepnBuffer[3]
#define	nAEDSetting nEepnBuffer[4]
#define nTimerMode nEepnBuffer[5]//5=timer mode
#define nTimerInit nEepnBuffer[6]//6=timer initiation
#define nTimerStartM nEepnBuffer[7]//7=timer start m
#define nTimerStartS nEepnBuffer[8]//8= timer start s
#define nDisplay1 nEepnBuffer[9]//9=dis1
#define nDisplay1b nEepnBuffer[10]//10=dis1
#define nDisplay2 nEepnBuffer[11]//11=dis1
#define nDisplay2b nEepnBuffer[12]//12=dis1
#define nEyeMode nEepnBuffer[13]
#define	nEyeBypassManual nEepnBuffer[14]
#define nTestCPS nEepnBuffer[15] //15= could be implemented later for test mode
#define	nBolDSetting nEepnBuffer[16]
#define	nBolOMSetting nEepnBuffer[17]
#define	nASDLSetting nEepnBuffer[18]
#define	nEBShot nEepnBuffer[22]
#define nMenu1 nEepnBuffer[23]//23 menus
#define nMenu2 nEepnBuffer[24]//24 menus
#define nMenu3 nEepnBuffer[25]//25 menus
#define nPowerDown nEepnBuffer[26]//26 could be implemented later for powerdown
#define	nEyeSens nEepnBuffer[27] // Eye Sensitivity (Reflective only, not used on this board)
#define nABSVal nEepnBuffer[28]//28 Anti-Bolt Stick added dwell (in ms)
#define nVoltLow nEepnBuffer[29]//29 voltage low
#define nVoltHigh nEepnBuffer[30]//30 voltage high
#define	nEBBolOpMin nEepnBuffer[31]
#define n2SolMode nEepnBuffer[32]
#define nMBounce nEepnBuffer[33]
#define nNoboltEyeWait nEepnBuffer[34]
                                    
void fire(void);              // -- Initializes firing settings and starts firing timer
                                 
void debounce(void);         // -- monitors for trigger stability.  Also controls mode functions.
                                   
int main(void);             // -- primary idle operation loop
                                   
void controlLEDs(void);      // -- Loop for controlling LED blinks
                                   
void checkEyes(void);        // -- Loop for auto-reinstate of eyes
                                   
int TProgFunc(uint8_t max, uint8_t color, uint8_t nMenuLevel);

void wait(uint8_t time);             // Waits for about a time determined by the argument

void blink(uint8_t color, uint8_t number); // blinks number of times, green if color=0, red if color=1.
                                   
void blinkf(uint8_t color, uint8_t number); // blinks number of times, green if color=0, red if color=1.

void initialize(void);       // -- Set up variables, set up IO, read eeprom, handle trigger programming, etc., etc...
                                 
void readEeprom(void);       // -- Read in settings

void autoEye(void);
                                 
void trigProgram(void);      // -- Trigger programming if applicable
                                
void initIO(void);           // -- Initialize ports

void dataVerify(void);       // -- Checks and validates all settings

void initInts(void);         // -- initializes interrupts

void buttonMenu(void);       // - handles button programming of settings

void checkButtons(void);     // -- button processing looped routine

void parseSettings(uint8_t nselectionnumber, uint8_t nselection);

void btnDebounce(void);

void fireCycle(void);

void PowerDown(void);

void checkADC(void);
