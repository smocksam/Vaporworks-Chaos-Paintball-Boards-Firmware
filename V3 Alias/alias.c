#include "alias.h"
/*
          (bits) (actually, they're bytes too...)
nRTFBit         -- Denotes whether the marker is ready to fire
nBuffer         -- Denotes a shot in the nBuffer
nEyeBypass      -- Denotes that the eye has been bypassed
           
          (bytes)
nVTimer         -- Valve solenoid timer (actual counter)
nBolDelay       -- Delay before turning on bolt (actual counter)
nBolOpMin       -- Minimum time to hold bolt open (actual counter)
nShotMin        -- Minimum time to have between shots (for ROF control purposes)
nASDLTimer      -- Timer for after-shot delay (actual counter)
nBStage         -- Bolt stage (it's a 4-stage operation, 0-3)
nEcount         -- Eye counter (timer for each eye stage)
               
          (eeprom saved bytes)
nVSetting       -- Valve time
nBolDSetting    -- Bolt Delay
nBolOMSetting   -- Bolt Open minimum time
nShotMSetting   -- Shot time (for ROF)
nDBSetting      -- Debounce Multiplier
nMode           -- Firing nMode
nEyeBypassM     -- Eye bypass setting
nEyeSens        -- Eye sensitivity
nAEDSetting     -- After-eye delay setting
    -- After-shot dleay setting
nEBShot         -- nShotMin when eye is fault bypassed
nEBBolOpMin     -- nBolOpMin when eye is fault bypassed
                  
          (words)         
nDBTmr          -- 16-bit Debounce counter (actual counter)
nLEDTmr         -- 16-bit LED blink counter
                    
          (functions)
fire           -- Initializes firing settings and starts firing timer
main           -- primary idle operation loop
controlLEDs    -- Loop for controlling LED blinks
checkEyes      -- Loop for auto-reinstate of eyes
eyeLevel (return int) -- Function to determine (and return) eye level
fireTimer (might be labeled different, it's the timer interrupt...) -- controls firing and eye operations
trig (might be labeled different, it's the ext 0 interrupt...) -- Trigger interrupt handling.
*/


volatile uint16_t LEDTmr,nShotMin,nVTimer,nBolDelay,nBolOpMin,nASDLTimer,nECount,nEyebTime,nShotTm,nLShotTm,nTriggerPullTime,nLastTriggerPullTime;
volatile uint8_t nTurboByte,nSREL,EWait,nRTFBit,nBuffer,nEyeBypassAuto,DBTmr,nBStage,nSafety,nFSCount,nDBStor,nBoltVis,nScope,nFireAfterTimer,EyeLevel,errcount,nEepnBuffer[MAXEEPROMADDRESS];//
volatile uint8_t nEyeLEDContol, nTestVar;

//"Ramping Mode" Related
volatile uint16_t nRampOffTime;
volatile uint8_t nRampMode;
volatile uint16_t nSemiShotCount; //changed to 16 bit just to make sure we don't overflow as easily if they rip a VERY long string of paint.


//"Snap Shot Mode" Related
volatile uint16_t nPauseTime;
volatile uint8_t nSnapShotCount;
volatile uint8_t nSnapShotPause;

union uMulti 
{ 
	unsigned long PDTimer;
	uint8_t PDTChar[4]; 
} uPower;

//--------------------------------------------------------
void fire() 
{
	//if the eye level is high 
	if(EyeLevel>nEyeSens || nScope==0 || nEyeBypassAuto)
	{
		errcount=0;
		nTestVar=0;				//set "stable eye" timer to 0;
		nRTFBit=0; 
		nLShotTm=nShotTm;
		nShotTm=0;
		if(nLShotTm>NSHOTTHRESHOLD)
			nFSCount=0;
		else
		{
			if(nFSCount<255)
				nFSCount++;
		}
		if(nLShotTm>ABSTIME)
			nVTimer=nVSetting+nABSVal;
		else
			nVTimer=nVSetting;                                 // Initialize all the timers
		//nBolDelay=nBolDSetting*2;                            //
		if(!(nEyeBypassManual) && (nEyeBypassAuto))                 // If the eye is fault bypassed,
		{      
			//nBolOpMin=nEBBolOpMin*2;                     // load eye bypass settings.
			nShotMin=nEBShot*2;                          //
		}                                                  //
		else                                               //
		{                                                  //
			//nBolOpMin=nBolOMSetting*2;                   // Otherwise, use normal settings.
			nShotMin=nShotMSetting*2;                    //
			if(nEyeBypassManual && nShotMin < 30 )
			{
				nShotMin = CAPROF*2;
			}
		}                                                  //
		
		if(!nBoltVis && !nEyeBypassAuto)   //DW What if we are in bolt not visible and the eye is bypassed?
		{
			EWait = nNoboltEyeWait*2;
		}
		else
		{
			EWait = nVTimer+EWAITTIME;    
		}
        
		if(nMode==4 || nMode==5)
		{
			nRampOffTime=RAMPOFFTIME;		//reset time we wait to automatically turn ramping off
			if(++nSemiShotCount>3)
			{
				nRampMode=1;
			}
		}
		if(nMode==6)
		{
			nSnapShotCount++;
		}
                                 		
		if(nBoltVis) 
			nBStage=0; 
		else
			nBStage=1;									//bolt not visible (use bolt timer) option
		
		//nASDLTimer=nASDLSetting*2;                           //
		nECount=EYEBYPASSMS; 
										
	}
	else
	{
		//we are not able to fire (open breech), or we are in SCOPE 1 
		sbi(LEDPORT,REDLED);
		sbi(LEDPORT,BLUELED);
		nEyeLEDContol=1;
		if(nBuffer==0)
		{
			//no shot in the buffer
			nShotMin=0;
			nVTimer=0;
			nBStage=1;
			nECount=EYEBYPASSMS;
			nBuffer=1;
		}
	}
	TCNT0=TIMERCOUNT;
	TIMSK |= (1 << TOIE0);                       // Enable T1!!   
										//-I moved these two lines of code to here instead of the two calls above to make memory useage more efficient.
}

//--------------------------------------------------------
void controlLEDs()
{
	if(nSafety || nPauseTime)
	{
		cbi(LEDPORT,BLUELED);
		sbi(LEDPORT,REDLED);
		sbi(LEDPORT,GREENLED);
		return;
	}
		
	if(nRTFBit)
	{
		if(nEyeLEDContol)
		{
			sbi(LEDPORT,REDLED);
			sbi(LEDPORT,BLUELED);
			cbi(LEDPORT,GREENLED);	
		}
			
		else if(++LEDTmr<LEDSWITCH)                         
		{   
			cbi(LEDPORT,GREENLED);
			if(nEyeBypassAuto)
			{
				sbi(LEDPORT,REDLED);
				sbi(LEDPORT,BLUELED);
			}
			else if(nVoltHigh < VCOMPVAL) // Battery is low condition...
			{
				sbi(LEDPORT,REDLED);
				cbi(LEDPORT,BLUELED);
			}
			else
			{
				sbi(LEDPORT,BLUELED);
				cbi(LEDPORT,REDLED);
			}
		}
		else
		{
			cbi(LEDPORT,REDLED);
			cbi(LEDPORT,BLUELED);
			cbi(LEDPORT,GREENLED);	
			if(bit_is_set(INPORT,TLock))
			{
				cbi(LEDPORT,REDLED);
				cbi(LEDPORT,BLUELED);
			}
			else
			{
				if(nEyeBypassAuto)
				{
					sbi(LEDPORT,REDLED);
					sbi(LEDPORT,BLUELED);
				}
				else if(nVoltHigh < VCOMPVAL) // Battery is low condition...
				{
					cbi(LEDPORT,BLUELED);
					sbi(LEDPORT,REDLED);
				}
				else
				{
					cbi(LEDPORT,REDLED);
					sbi(LEDPORT,BLUELED);
				}
			}
			if(LEDTmr>LEDSTOP) 
				LEDTmr=0;                                  // If above max, clear
		}
	}
}

//--------------------------------------------------------
void checkEyes()
{
	if(nEyeBypassManual==0 && nEyeBypassAuto==1 && EyeLevel<nEyeSens) 
		nEyeBypassAuto=0; 
}

//--------------------------------------------------------
void dataVerify()
{
	if(nVSetting<1 || nVSetting>37)                 // Basically, just check to verify the setting is within it's range,
		nVSetting=DEFAULTVSETTING;              // and if not, reset it to default.
	if(nShotMSetting<1 || nShotMSetting>250)        // Basically, just check to verify the setting is within it's range,
		nShotMSetting=DEFAULTSHOTMSETTING;      // and if not, reset it to default.
	if(nDBSetting<1 || nDBSetting>30)               // Basically, just check to verify the setting is within it's range,
		nDBSetting=DEFAULTDBSETTING;            // and if not, reset it to default.
	if(nMode>6 || (bit_is_clear(INPORT,TLock) && (nMode==1 || nMode==2 || nMode==3)))                                     // Basically, just check to verify the setting is within it's range,
		nMode=DEFAULTMODE;                      // and if not, reset it to default.
	if(nEyeBypassManual >1)                              // Basically, just check to verify the setting is within it's range,
		nEyeBypassManual=DEFAULTEYEBYPASSM;          // and if not, reset it to default.
	nEyeSens=DEFAULTEYESENS; 					// hard coded becuase this board doesn't have analog eyes
	if(nAEDSetting>25)                              // Basically, just check to verify the setting is within it's range,
		nAEDSetting=DEFAULTAEDSETTING;          // and if not, reset it to default.
	if(nAEDSetting==0)
		nEyeBypassManual=1;
	if(nEBShot<1 || nEBShot>250)                    // Basically, just check to verify the setting is within it's range,
		nEBShot=DEFAULTEBSHOT;                  // and if not, reset it to default.
	if(nABSVal>10)
		nABSVal=DEFAULTABSVAL;
	if(nTestCPS > 1)
		nTestCPS=DEFAULTTESTCPS;	
	if(nPowerDown >250 || nPowerDown <1)
		nPowerDown=DEFAULTPOWERDOWN;
	if(nMBounce > 15)
		nMBounce=DEFAULTMBOUNCE;
	if(nNoboltEyeWait > 60)
		nNoboltEyeWait=DEFAULTNOBOLTEYEWAIT;
	if(nTestCPS== 1)
	{
		nMode=3;
		nEyeMode=4;
		nAEDSetting=1;
	}
	
	switch(nEyeMode)
	{
		case 0:
			nBoltVis=0;
			nScope=0;
			nFireAfterTimer=0;
			break;
		case 1:
			nBoltVis=0;
			nScope=0;
			nFireAfterTimer=1;
			break;
		case 2:
			nBoltVis=0;
			nScope=1;
			nFireAfterTimer=0;
			break;
		case 3:
			nBoltVis=1;
			nScope=0;
			nFireAfterTimer=0;
			break;
		case 4:
			nBoltVis=1;
			nScope=0;
			nFireAfterTimer=1;
			break;
		case 5:
			nBoltVis=1;
			nScope=1;
			nFireAfterTimer=0;
			break;
		default:
			nEyeMode=DEFAULTEYEMODE;
			nBoltVis=1;
			nScope=1;
			nFireAfterTimer=0;
			break;
	}
	
	nBolDSetting=DEFAULTBOLDSETTING;        
	nBolOMSetting=DEFAULTBOLOMSETTING;      
	nASDLSetting=DEFAULTASDLSETTING;        
	nEBBolOpMin=DEFAULTEBBOLOPMIN;          
	n2SolMode=0;
	nTimerMode=0;
	nTimerInit=0;
	nTimerStartM=0;
	nTimerStartS=0;
	nDisplay1=0;
	nDisplay1b=0;
	nDisplay2=0;
	nDisplay2b=0;
	nMenu1=0;
	nMenu2=0;
	nMenu3=0;
	nTurboByte=0;
	
	if(nEyeBypassManual!=0)
	{
		nEyeBypassAuto=1;
	}

}

//---------------------------------------------------
void checkADC()
{
	if(bit_is_set(EYEPORT,Eye))
	{
		EyeLevel=255; // the eye isn't seeing the emitter (blocked)
		nEyeLEDContol=0;
	}
	else
	{
		EyeLevel=0; // the eye sees the emitter's beam (unblocked)
	}
	
	//now do the Battery Voltage Check
	if((ADCSRA & 64) == 0)  //Don't do anything until the busy flag clears
	{
		nVoltHigh=ADCH;
		nVoltLow=ADCH;
		nVoltHigh=(nVoltHigh >> 4);
		nVoltLow=nVoltLow & 0x0f;
		nVoltLow=nVoltLow << 4;
		ADCSRA=192;
	}
}

//---------------------------------------------------
void autoEye()
{
	nEyeSens=DEFAULTEYESENS;
}

//---------------------------------------------------
void initInts()
{
	nSafety=0;
	SREG=255; 
	MCUCR=10;          //Set int1 to Falling edge
	GICR&=~(1<<INT0); // | GICR;    //Disable int1
	GIFR&=~(1<<INTF0); // | GIFR;   // Clear Int1 flag!!
	TCCR0=2;           //Set timer prescaler to 8
	TCNT0=TIMERCOUNT;  // Reset T0 counter!!
	TIFR&=~(1<<TOV0); // | TIFR;   // Reset T0 Flag!!
	TIMSK&=~(1<<TOIE0); // | TIMSK;  // Disable T0!!
	
	ASSR=0;            // Clear asynchronous mode
	TCCR2=2;           //Set timer prescaler to 8
	TCNT2=TIMER1COUNT;  // Reset T1 counter!!
	TIFR&=~(1<<TOV2); // | TIFR;   // Reset T1 Flag!!
	TIMSK|=(1<<TOIE2); // | TIMSK;  // ensable T1!!

	nBuffer=0;
	nRTFBit=1;
	nSemiShotCount=0;
	nSnapShotPause=0;
	nSnapShotCount=0;
}

//---------------------------------------------------
void initialize()
{
	initIO();                                           // Pretty self-explanatory stuff
	
	nSREL=0;
	nShotTm=0;
	nLShotTm=65535;
	readEeprom();
	if(bit_is_clear(INPORT,Trigger))
		trigProgram();                                  // Run tprog if tourney lock is off & trigger is pulled
	dataVerify();
	ADMUX=35;          									// Initialize ADC on ADC3 for Battery Voltage
	ADCSRA=192;        									// turn on ADC
	wait(1);
	checkADC();
	eeprom_write_block(&nEepnBuffer,(void*)1,MAXEEPROMADDRESS);
	uPower.PDTChar[2]=nPowerDown; // Shift powerdown 16 bits left 
	initInts();
	LEDTmr=0;
}

//---------------------------------------------------
void initIO()
{
	sbi(DDRB,0);  // solenoid output
	cbi(PORTB,0); // solenoid off
	
	sbi(DDRD, 5); //eye emitter as out
	sbi(PORTD,5); //init emitter on
	
	cbi(DDRC,2);  // eye receiver as input
	sbi(PORTC,2); // init to on

	cbi(DDRD,2);  // trigger as input
	sbi(PORTD,2); // trigger pullup active
	
	cbi(DDRD,4);  // tourney lock as input
	sbi(PORTD,4); // tourney lock pullup active
	
	//Battery Voltage
	cbi(DDRC,3);  // Battery Voltage Pin is input of course :)
	sbi(PORTC,3); // init the pin high
	
	//LED initialization
	sbi(DDRD,GREENLED);  // GREEN is an output
	cbi(PORTD,GREENLED); //init GREEN off

	sbi(DDRD,BLUELED);  // BLUE is an output
	cbi(PORTD,BLUELED); //init BLUE off
	
	sbi(DDRD,REDLED);  // RED is an output
	cbi(PORTD,REDLED); //init RED off	
	
	//button inits
	cbi(DDRC,0);  // button1 is input with pullup
	sbi(PORTC,0); // with pullup
	cbi(DDRC,1);  // button2 is input with pullup
	sbi(PORTC,1); // with pullup
	
}

//--------------------------------------------------------
void parseSettings(uint8_t nselectionnumber, uint8_t nselection)
{
	switch(nselectionnumber)
	{
		case 1:
			nVSetting=(nselection*2)+5;
			break;
		case 2:
			if(nselection==0)
			{
				autoEye();
			}
			else
				nEyeSens=nselection*15;                              // Eye sensitivity (manual)
			break;
		case 3:
			nDBSetting=(nselection+1)*3;
			break;
			
		case 4: 
			nMBounce=nselection;
			break;
		
		case 5:
			switch(nselection)
			{
				case 0:
					nVSetting=a1DEFAULTVSETTING;
					nBolDSetting=a1DEFAULTBOLDSETTING;
					nBolOMSetting=a1DEFAULTBOLOMSETTING;
					nShotMSetting=a1DEFAULTSHOTMSETTING;  // Extreme settings
					nDBSetting=a1DEFAULTDBSETTING;
					nMode=a1DEFAULTMODE;
					nEyeBypassManual=a1DEFAULTEYEBYPASSM;
					nAEDSetting=a1DEFAULTAEDSETTING;
					nASDLSetting=a1DEFAULTASDLSETTING;
					break;
				case 1:
					nVSetting=a2DEFAULTVSETTING;
					nBolDSetting=a2DEFAULTBOLDSETTING;
					nBolOMSetting=a2DEFAULTBOLOMSETTING;
					nShotMSetting=a2DEFAULTSHOTMSETTING;
					nDBSetting=a2DEFAULTDBSETTING;
					nMode=a2DEFAULTMODE;
					nEyeBypassManual=a2DEFAULTEYEBYPASSM;
					nAEDSetting=a2DEFAULTAEDSETTING;    // Fast settings
					nASDLSetting=a2DEFAULTASDLSETTING;
					break;
				case 2:
					nVSetting=a3DEFAULTVSETTING;
					nBolDSetting=a3DEFAULTBOLDSETTING;
					nBolOMSetting=a3DEFAULTBOLOMSETTING;
					nShotMSetting=a3DEFAULTSHOTMSETTING;
					nDBSetting=a3DEFAULTDBSETTING;
					nMode=a3DEFAULTMODE;                 // Normal settings
					nEyeBypassManual=a3DEFAULTEYEBYPASSM;
					nAEDSetting=a3DEFAULTAEDSETTING;
					nASDLSetting=a3DEFAULTASDLSETTING;
					break;
				case 3:
					nVSetting=a4DEFAULTVSETTING;
					nBolDSetting=a4DEFAULTBOLDSETTING;
					nBolOMSetting=a4DEFAULTBOLOMSETTING;
					nShotMSetting=a4DEFAULTSHOTMSETTING;
					nDBSetting=a4DEFAULTDBSETTING;
					nMode=a4DEFAULTMODE;                      // conservative settings
					nEyeBypassManual=a4DEFAULTEYEBYPASSM;
					nAEDSetting=a4DEFAULTAEDSETTING;
					nASDLSetting=a4DEFAULTASDLSETTING;
					break;
				case 4:
					nVSetting=DEFAULTVSETTING;
					nBolDSetting=DEFAULTBOLDSETTING;
					nBolOMSetting=DEFAULTBOLOMSETTING;
					nShotMSetting=DEFAULTSHOTMSETTING;
					nDBSetting=DEFAULTDBSETTING;              // default settings
					nMode=DEFAULTMODE;
					nEyeBypassManual=DEFAULTEYEBYPASSM;
					nAEDSetting=DEFAULTAEDSETTING;
					nASDLSetting=DEFAULTASDLSETTING;
					break;
			}
			break;
		case 6:
			nMode=nselection;
			break;
		case 7:
			switch(nselection)
			{
				case 0:
					nShotMSetting=ROF1;
					break;
				case 1:
					nShotMSetting=ROF2;
					break;
				case 2:
					nShotMSetting=ROF3;
					break;
				case 3:
					nShotMSetting=ROF4;
					break;
				case 4:
					nShotMSetting=ROF5;
					break;
				case 5:
					nShotMSetting=ROF6;
					break;
				case 6:
					nShotMSetting=ROF7;
					break;
				case 7:
					nShotMSetting=ROF8;
					break;
				case 8:
					nShotMSetting=ROF9;
					break;
				case 9:
					nShotMSetting=ROF10;
					break;
				case 10:
					nShotMSetting=ROF11;
					break;
				case 11:
					nShotMSetting=ROF12;
					break;
				case 12:
					nShotMSetting=ROF13;
					break;
				case 13:
					nShotMSetting=ROF14;
					break;
				case 14:
					nShotMSetting=ROF15;
					break;
				case 15:
					nShotMSetting=ROF16;
					break;
			}				
			break;
		case 8:
			if(nselection==0)
			{
				nEyeBypassManual=1;
			}
			nAEDSetting=nselection;
			break;
		case 9:
			nEyeMode=nselection; // Eye mode would go here
			break;
		case 10:
			nBolDSetting=nselection*2;                        //Bolt Delay
			if(nBolDSetting==0)
				nBolDSetting=1;
			break;
		case 11:
			nBolOMSetting=(nselection)*4;
			if(nBolOMSetting==0)
				nBolOMSetting=1;
			break;
		case 12:
			nASDLSetting=nselection*2;
			break;
		case 13:
			nABSVal=nselection;
			break;
		case 14:
			nNoboltEyeWait=nselection*2;
			break;
		default:
			break;
	}
	
	//DW-make sure that if they set the ROF to unlimited and Bypassed the eye, we don't have short stroking
	if(nAEDSetting==0 && nShotMSetting==ROF1)
	{
		nShotMSetting=CAPROF;    //lock it to about 25bps for now
	}
	
}

//--------------------------------------------------------
void trigProgram()
{
	uint8_t nselectionnumber=0,nselection=0;  // init vars
	uint8_t nLimits[15]={0,16,16,10,16,5,7,16,16,6,16,16,16,13,16};
	cbi(LEDPORT,BLUELED);
	nselectionnumber=TProgFunc(14,0,0); 
	while(bit_is_set(INPORT,Trigger))
		asm("nop");   							// Now wait 'til user hits the trigger again
	nselection=TProgFunc(nLimits[nselectionnumber],1,1);  // run the trip prog routine with color green and relevant restrictions for this selection
	parseSettings(nselectionnumber,(nselection-1));
	eeprom_write_block(&nEepnBuffer,(void*)1,MAXEEPROMADDRESS);
}

//--------------------------------------------------------
int TProgFunc(uint8_t nMax, uint8_t nColor, uint8_t nMenuLevel)   // function for controlling trigger programming
{
	volatile uint8_t nTotal=0;
	wait(TIMEBETWEENSETS);        // wait
	while(bit_is_clear(INPORT,Trigger))          // While the user holds the trigger in
	{
		if(nColor == 0)
		{
			while(nTotal==1 || nTotal==9 || nTotal==10 || nTotal==11)
			{
				nTotal++;
			}
			if(bit_is_clear(INPORT,TLock))
			{
				//Tourney Lock on, skip these
				while(nTotal==0 || nTotal==1 || nTotal==2 || nTotal==3 || nTotal==4 || nTotal==5 || nTotal==12)
				{
					nTotal++;
				}
			}
		}
		if(nTotal>=nMax)              // check for overflow
		{
			if(bit_is_clear(INPORT,TLock) && !nMenuLevel)
				nTotal=6;
			else
				nTotal=0;               // To handle overflow
		}
		nTotal++;
		blink(nColor,nTotal);         // blink
		wait(TIMEBETWEENSETS);        // wait
	}
	return nTotal;
}

//--------------------------------------------------------
void wait(uint8_t nTime)
{
	volatile uint16_t nTime2=TIMEADJUSTMENT;
	while(nTime>0)
	{
		for(nTime=nTime; nTime>0; nTime--)               // loopey delay
		{
			for(nTime2=TIMEADJUSTMENT; nTime2>0; nTime2--)               // loopey delay
			{
				asm("nop");
			}
		}
	}
}

//--------------------------------------------------------
void blink(uint8_t nColor,uint8_t nNumber)  // Routine for blinking the LED certain number of times in a certain color
{
    while(nNumber>0)  //
	{
		switch(nColor)
		{
			default:
			case 0:
				sbi(LEDPORT,REDLED);
				sbi(LEDPORT,GREENLED); 
				break;
			case 1:
				sbi(LEDPORT,GREENLED);        // set the led
				break;
			case 2:
				sbi(LEDPORT,REDLED);  
				break;
			case 3:
				sbi(LEDPORT,BLUELED);  
				break;
		}
		wait(LEDONTIME);  
		cbi(LEDPORT,REDLED);          // wait
		cbi(LEDPORT,GREENLED);         // clear the led
		cbi(LEDPORT,BLUELED);   
		wait(LEDOFFTIME);            // wait
		nNumber--;                    // dec counter
		if(bit_is_clear(BTNPORT,B1))
			break;
		if(bit_is_clear(BTNPORT,B2))
			break;
	}
}

//--------------------------------------------------------
void readEeprom()
{
	eeprom_read_block(&nEepnBuffer,(void*)1,MAXEEPROMADDRESS); // writes from the nEepnBuffer, starting at eep address 1, for a block of 10 bytes
	nEepnBuffer[19]=VMAJ;
	nEepnBuffer[20]=VMIN;
	nEepnBuffer[21]=MTYPE;
}

//--------------------------------------------------------
void checkButtons()
{
	if(bit_is_set(BTNPORT,B1) && bit_is_set(BTNPORT,B2))
		asm("nop");
	else
	{
		if(bit_is_clear(BTNPORT,B1))      // B1
		{
			buttonMenu();
		}
		if(bit_is_clear(BTNPORT,B2))      // B2
		{
			nSafety=~nSafety;
		}
		btnDebounce();
	}
}

//---------------------------------------------------------
void btnDebounce()
{
	volatile uint16_t ndbcount;
	for(ndbcount=BTNDEBOUNCE; ndbcount>0; ndbcount--)			//debounce buttons
	{
		while(bit_is_clear(BTNPORT,B1) || bit_is_clear(BTNPORT,B2))
		{
			ndbcount=BTNDEBOUNCE;
		}
		wait(1);
	}
}

//----------------------------------------------------------
void buttonMenu()
{
	cbi(LEDPORT,GREENLED);
	cbi(LEDPORT,BLUELED); 
	cbi(LEDPORT,REDLED);
	btnDebounce();
	LEDTmr=nSafety;
	nSafety=1;
	GICR&=~(1<<INT0); // | GICR; //Disable int1
	uint8_t nExitCondition=0, nMnu=0;
	uint16_t BPCounter=0;
	uint8_t nSlct;
	
	//Initialize array values!!
		
	uint8_t nLimits[14]={16,16,10,16,5,7,16,16,6,16,16,16,13,16}; 
	if(bit_is_clear(INPORT,TLock))
		nMnu=5; 
		nSlct=0;
	while(nExitCondition==0)
	{
		if(bit_is_clear(INPORT,Trigger))
		{
			BPCounter=MNUTRIGHOLD;
			while(bit_is_clear(INPORT,Trigger) && BPCounter)
				BPCounter--;
			if(BPCounter)
			{
				parseSettings((nMnu+1),nSlct);	// Write the nSlct value into the nMnu variable with whatever adj's are necessary.
				blink(0,3);
				wait(STIMEBETWEENSETS);
			}
			else
			{
				blink(3,3);
				nExitCondition=1;
			}
			BPCounter=BPCOUNTTIME;
		}
		if(bit_is_clear(BTNPORT,B1))
		{
			BPCounter=BPCOUNTTIME; //*****NEED TO INITIALIZE SELECTION TO CURRENT
			nMnu++;
			while(nMnu==1 || nMnu==9 || nMnu==10 || nMnu==11)
			{
				nMnu++;
				nSlct=0;
			}
			if(nMnu==13)
				nMnu=0;
			if(bit_is_clear(INPORT,TLock))
			{
				while(nMnu==0 || nMnu==1 || nMnu==2 || nMnu==3 || nMnu==4 || nMnu==5 || nMnu==12)
				{
					nMnu++;
				}//Put tourney lock restrictions here...
			}
			btnDebounce();
		}
		if(bit_is_clear(BTNPORT,B2))
		{
			BPCounter=BPCOUNTTIME; //*****NEED TO INITIALIZE SELECTION TO CURRENT
			nSlct++;
			if(nSlct>=nLimits[nMnu])
				nSlct=0;
			btnDebounce();
		}
		if(BPCounter>0)
		{
			BPCounter--;
		}
		else
		{
			blink(2,(nMnu+1));  
			wait(STIMEBETWEENSETS);
			blink(1,(nSlct+1)); 
			BPCounter=BPCOUNTTIME; 
		}
	}
	DBTmr=nDBSetting;				// Ensure trigger is released
	while(bit_is_clear(INPORT,Trigger))
		asm("nop");
	nSafety=LEDTmr;
}

//------------------------------------------------------
void PowerDown()
{
	DDRB=0;
	PORTB=3;
	DDRC=0;
	PORTC=0;
	DDRD=0;
	PORTD=0;
	MCUCR=160;
	cbi(VALVEPORT,VALVEBIT);
	while(1); // endless loop.
}

//--------------------------------------------------------
int main()
{
	initialize();                            // Just initialize once, then
	if(bit_is_set(INPORT,Trigger))
		DBTmr=nDBSetting;				// Ensure trigger is released
	
	nRTFBit=1;
	GICR|=(1<<INT0); // | GICR; //Enable int1
	while(1)                                 // Loop eternally - running LED & eye functions.
	{ 
		controlLEDs();
		checkEyes();
		checkButtons();
		checkADC();
	}
	return 0;
}

//------------------------------------------------------------------------
SIGNAL(SIG_INTERRUPT0) // was: void trig()     //Probably need to change name; set up as trigger interrupt
{
	if(bit_is_set(INPORT,Trigger) || nSafety || nSnapShotPause) 
		return;
		
	GICR&=~(1<<INT0); // | GICR; //Disable int1
	if(nFSCount>=nMBounce)
		DBTmr=nDBSetting;			// Otherwise, initialize the timer
	else
		DBTmr=MBOUNCENUMBER;         
	nDBStor=DBTmr;
	nEyebTime=EYEBYPASSTIME;
	
	fireCycle();
	uPower.PDTChar[2]=nPowerDown; // Shift powerdown 16 bits left 
	
	//Auto Response Check
	if(nMode==2)
		nSREL=1;
	//Turbo Check
	if(nMode==1)
	{
		if(nTurboByte)
		{
			nTurboByte=0;
			nSREL=1;
		}
		else
		{
			nTurboByte=1;
		}
	}
	nLastTriggerPullTime=nTriggerPullTime;
	nTriggerPullTime=0;
}

//--------------------------------------------
void fireCycle()
{
	//time to fire, are we ready?
	if(nRTFBit==1)   
	{
		//yes, go do it
		fire();	
	}
	else
	{
		//no we are not, queue the shot
		nBuffer=1;
	}
}

//-------------------------------------------------
SIGNAL(SIG_OVERFLOW0) //was: void fireTimer() 
{
	TCNT0=TIMERCOUNT; 						// Reset T1 counter!!
	
	//added eye check code just to make sure we get a reading no matter what.
	if(bit_is_set(EYEPORT,Eye))
		EyeLevel=255; // the eye isn't seeing the emitter (blocked)
	else
		EyeLevel=0; // the eye sees the emitter's beam (unblocked)
	
	if(nShotMin!=0)                           // count down shot time
		nShotMin--;
	if(nVTimer != 0)                          // Check valve solenoid time
	{
		sbi(LEDPORT,GREENLED);
		sbi(VALVEPORT,VALVEBIT);			//Turn on valve solenoid
		nVTimer--;
	}
	if(nVTimer==0)
		cbi(VALVEPORT,VALVEBIT);			//Turn off valve solenoid
	if(nEyeBypassAuto)
	{
		nBStage=3;
		nECount=0;
	}
	if(EWait==0)
	{
		switch(nBStage)
		{
			case 0:					// Stage 0 - waiting for bolt to open
				if((EyeLevel>nEyeSens) && (nECount>0))         // Wait for up to EYEBYPASSMS (100ms) (init in 'fire' section)
				{
					nECount--;
					nTestVar=0;
				}
				else
				{
					//nECount hit 0 (never saw bolt open), or the eyes are unblocked.
					if(nECount==0)
					{
						nEyeBypassAuto=1;                    // Bypass if it doesn't open in time.
						nBStage = 3;
					}
					else
					{
						//EyeLevel is below sensitivity (breech open)
						//let's make sure its open long enough to be considered stable (no "eye jitter").
						if(++nTestVar>STABLEOPENTIME)
						{
							nBStage=1;
							nECount=BALLWAITTIME;
						}
					}
				}
				break;
			case 1:
				if((EyeLevel<=nEyeSens) && nECount>0 && nTestCPS==0)
					nECount--;
				else
				{
					nBStage=2;
					if(nECount!=0)
					{
						nECount=(nAEDSetting-1)*2;
					}
					else
					{
						if(nFireAfterTimer==0)
							nBuffer=0;
						nECount=0;                       // If timed out, aed is 0 (forces skip of that routine)
     						nBStage=3;                           // Whether timed out or ball visible, end segment.
					}
				}
				break;
			case 2:
				if(nECount!=0)
				{
					if(EyeLevel>nEyeSens)                    // Finally, run after-eye delay
						nECount--;							  //counting down AE Delay
					else
					{
						nBStage=1;
						nECount=BALLWAITTIME;                  // Basically, as long as the eyes are blocked, count down...
					}
				}
				else                                        // But if the eye un-blocks, reset the countdown
				{
					nBStage=3;                               // If the countdown hits 0, skip to next segment.
				}                                           
				break;
			default:
				break;
		}
	}
	else
	{
		//still waiting for timer to expire before we start looking for the bolt.
		EWait--;
		if(EWait==0 && (EyeLevel<=nEyeSens && !nBStage))
		{
			if(++errcount<50)
				EWait = 1;
		}
	}
	if(nShotMin==0 && nVTimer==0 && nBStage==3)            // AFter seperately dealing with mechanical, timing, and eye firing functions, now check them all...
	{                                                   // If they're not all complete, exit...
		//if nothing in the buffer
		//and trigger is not 
		//if the trigger bit is set, the trigger is not pulled.
		if(nBuffer==0 && (bit_is_set(INPORT,Trigger) || nMode!=3))                                   // But if they are, check the nBuffer.
		{
			//nothing in the buffer AND trigger isn't pulled
			//OR
			// we are not in mode 3 (full auto), check for other modes possiblities.
			if(!nRampMode || !(nTriggerPullTime<RAMPRATE && nLastTriggerPullTime < RAMPRATE))
			{
				if(nMode==5 && nRampMode && bit_is_clear(INPORT,Trigger))
				{
					//NXL mode in ramping mode with the trigger in, fire a shot.
					nBuffer=0;                                  
					fire();
				}
				else
				{
					//not ramping
					TIMSK&=~(1<<TOIE0); // | TIMSK;        // Disable T1!!  // If the nBuffer's empty, kick back to RTF.
					nRTFBit=1;
				}
			}
			else
			{
				nBuffer=0;                                  
				fire();
			}
		}
		else
		{
			//queue up the next shot.
			nBuffer=0;                                  
			fire();
		}
	}
}

//--------------------------------------------------------------------------
SIGNAL(SIG_OVERFLOW2)
{
	TCNT2=TIMER1COUNT; // Reset T1 counter!!
	if(DBTmr!=0)
	{
		if(bit_is_set(INPORT,Trigger))
			DBTmr--;
		else
		{
			DBTmr=nDBStor;         // Otherwise, initialize the timer
			if(--nEyebTime==0 && nMode !=3)
			{
				//make sure we are not in the full auto part of the NXL mode.
				if(!(nMode==5 && nSemiShotCount>3))
				{
					nEyeBypassManual=~nEyeBypassManual;
					nEyeBypassAuto=nEyeBypassManual;
				}
			}
			
		}
	}
	else 
	{
		GIFR&=~(1<<INTF0); // | GIFR; // Clear Int1 flag!!
		GICR|=(1<<INT0); // | GICR; //Enable int1
		if(nSREL==1)
		{
			fireCycle();
			nSREL=0;
		}
	}
	if(uPower.PDTimer-- == 0)
		PowerDown();
	if(nSnapShotCount>=4)
		nSnapShotPause=1;
		
	if(nMode==6 && nSnapShotPause)
	{
		if(nPauseTime++>nShotSetPauseTime)
		{
			nPauseTime=0;
			nSnapShotPause=0;
			nSnapShotCount=0;
		}
	}
	
	if(nRampMode==1)
	{
		if(nRampOffTime-- == 0)
		{
			nRampMode=0;
			nSemiShotCount=0;
		}
	}
	if(nTriggerPullTime<65000)
	{
		nTriggerPullTime++;
	}
	if(nShotTm<65000)
		nShotTm++;
	TIFR&=~(1<<TOV2); // | TIFR; // Reset T1 Flag!!
}







