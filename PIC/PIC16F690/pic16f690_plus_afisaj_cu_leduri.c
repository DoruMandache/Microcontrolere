/*
Connections
PORTC.0- C
PORTC.1- G
PORTC.2- B
PORTC.3- D
PORTC.4- E
PORTC.5- F
PORTC.6- A
PORTC.7- dp

/* #include <htc.h> //LED Display Conversion Table
const zero= 0b10000010; //Forms Digit 0
const one= 0b11111010; //Forms Digit 1
const two= 0b10100001; //Forms Digit 2
const three= 0b10110000; //Forms Digit 3
const four= 0b11011000; //Forms Digit 4
const five= 0b10010100; //Forms Digit 5
const six= 0b10000100; //Forms Digit 6
const seven= 0b10111010; //Forms Digit 7
const eight= 0b10000000; //Forms Digit 8
const nine= 0b10010000; //Forms Digit 9


//PIC16F690 Configuration _CONFIG (INTIO & WDTDIS & MCLRDIS & UNPROTECT); //this sets the internal clock on, watchdog off, MCLR Off, and code unprotected 

void pause (unsigned short usvalue); //establishes puase routine function

main()
{
 unsigned char state_led= 0; //creates an 8 bit variable to store switch count CM1CON0= 0;
 CM2CON0= 0;

 PORTC= 0x00;
 TRISC= 0x00;

 while (1)
 {
  state_led++;
  //increments the LED state variable
  switch (state_led)
  {
   case 1: 
    PORTC=one; 
    break;
   case 2: 
    PORTC= two;
    break;
   case 3:
    PORTC= three;
    break;
   case 4:
    PORTC= four;
    break;
   case 5:
    PORTC= five;
    break;
   case 6:
    PORTC= six;
    break;
   case 7:
    PORTC= seven;
    break;
   case 8:
    PORTC= eight;
    break;
   case 9:
    PORTC= nine;
    break;
   default:
    state_led= 0;
    PORTC= zero;
    break;
  } // ends switch block 

  pause(500); //delays 500 milliseconds (half a second) and check again for switch count 

 } ends while loop
} ends main loop
