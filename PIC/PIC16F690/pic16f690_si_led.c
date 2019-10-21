#include "16F690.h" // header-ul pentru microcontroler

#use delay(clock=4000000) // setarea frecvenţei de tact

void main () // funcţia principală
 {
   while(1) // bucla fără sfârşit
    {
      output_high(PIN_C0); // aprinderea ledului conectat la pinul RC0 (trecerea în 1 logic)
      delay_ms(1000); // întârziere de 1000 ms
      output_low(PIN_C0); // stingerea ledului conectat la pinul RC0 (trecerea în 0 logic)
      delay_ms(1000); // întârziere de 1000 ms
    }
 }
