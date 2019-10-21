;----------------------------------------------------------------------
; DS18B20-Testprogramm mit ATtiny13, im 2- oder 3-Leitungs-Modus
; (DS18B20 = digitaler Temperatursensor)
; Erläuterungen: www.schramm-software.de/tipps
;----------------------------------------------------------------------
; Prozessor: ATtiny13
; Takt     : 1,2 MHz
; Sprache  : Assembler
; Version  : 1.1
; Autor    : Dr. Michael Schramm, siehe www.schramm-software.de
; Datum    : 2.2012
;----------------------------------------------------------------------
; Portbelegung:
; PB0,PB1: O  Tonsignal (Piezo-Piepser oder Lautspr. über R-C)
; PB2:     O  Error-LED gegen GND
; PB3:     O  VDD-Pegel, solange Controller aktiv (für Sensor und R1)
; PB4:   I O  Datenbus für DS18B20, über 4k7 (R1) an VDD (+)
;----------------------------------------------------------------------
.include "tn13def.inc"
.include "../makros.inc"
; Als globale Variablen genutzte Register:
.def intreg  = r13 ;SREG-Zwischenspeicher bei Interrupt
.def timovl  = r14 ;Zähler für Timer-Overflow-Interrupts
.def nullreg = r15 ;Konstante Null
.def status  = r25 ;Status / Phase für Fehlercode-Ausgabe
;----------------------------------------------------------------------
.DSEG ;SRAM-Belegung
dezzahl: .byte 3 ;für akustische Zahlenausgabe
rdbuff:  .byte 9 ;Lesepuffer
;----------------------------------------------------------------------
.CSEG
;Reset- und Interruptvektoren
  rjmp start ;0 RESET, Brown-out Reset, Watchdog Reset
  reti       ;1 INT0 External Interrupt Request 0
  reti       ;2 PCINT0 Pin Change Interrupt Request 0
;i_t0ov:     ;3 TIM0_OVF Timer/Counter Overflow
; Prescaler=256 => 18,3 Overflow-Interrupts pro Sekunde
  in intreg,sreg ;Statusregister merken
  inc timovl ;Zähler für (in etwa) 18tel Sekunden
  out sreg,intreg ;Statusregister wiederherstellen
  reti
;(Routine für letzten genutzten Interrupt direkt angehängt)
;----------------------------------------------------------------------
start:
; zunächst Stromsparmaßnahmen und Initialisierung
  out_i DDRB, 0b001111  ;Datenrichtung von Port B
  out_i PORTB,0b101000  ;Startzustand (mit VDD an PB3)
  sbi ACSR,ACD          ;Analog-Comparator ausschalten
  out_i SPL,low(RAMEND) ;Stackpointer setzen, 8bit-Pointer bei Tiny13
  clr nullreg           ;bleibt dauerhaft null
  out_i TIMSK0,1<<TOIE0 ;Timer-Overflow-Interrupt aktivieren
  sei                   ;für Timer-Overflow-Interrupt

; Nach dem Einschalten kopiert der Sensor seinen EEPROM-Inhalt in sein
; RAM (scratchpad). Daher warten, bis Sensor sicher bereit.
  ldi r17,3
  rcall waitr17 ;etwa 164 ms

; ROM-Kommando zum Lesen der Sensor-Adresse senden und Ergebnis einlesen
  ldi status,1
  ldi r18,$33 ;READ ROM
  rcall ds_romcmd
; der Sensor antwortet mit insgesamt 8 Bytes
  ldi r19,8
  rcall ds_rec_bytes
; nun das Function Command, um die Temperatur zu messen
  ldi r18,$44 ;CONVERT TEMPERATURE
  rcall ds_sendbyte
; damit der Sensor auch im Zweidrahtmodus genug Energie für die Messung
; bekommt, vorübergehend die Busleitung niederohmig auf VDD legen
  sbi PORTB,4
  sbi DDRB,4
; während der Sensor noch misst (braucht bis zu 750 ms), schon mal die
; Sensoradresse ausgeben
  ldi r19,8
  rcall morse_zahlen
  rcall waithalbsek ;zusätzliche Pause nach Ausgabe der Zahlengruppe
  sbi PORTB,2 ;Error-LED kurz an, um den Wechsel zusätzlich anzuzeigen
  rcall waithalbsek ;so lange blinkt die LED auf
  cbi PORTB,2 ;Error-LED aus
; die Messung muss inzwischen abgeschlossen sein - Ergebnis anfordern
  cbi DDRB,4 ;aber erst einmal die Busleitung wieder in Normalzustand
  cbi PORTB,4
  ldi status,4
  ldi r18,$CC ;SKIP ROM COMMAND - da nur ein Sensor angeschlossen
  rcall ds_romcmd
  ldi r18,$BE ;READ SCRATCHPAD - RAM-Inhalt abfragen
  rcall ds_sendbyte
; der Sensor antwortet mit insgesamt 9 Bytes
  ldi r19,9
  rcall ds_rec_bytes
  ldi r19,9
  rcall morse_zahlen ;Ergebnis gleich ausgeben

; Ende der Messungen
  out PORTB,nullreg ;alle Ports in Grundzustand (PB3 auf GND)
prgm_end:
  out_i MCUCR,(1<<SE)+(1<<SM1) ;Power-down-Modus
  sleep ;Tiefschlaf, warten auf Reset-Signal

error_end:
  out_i PORTB,0b000100 ;Grundzustand, jedoch Error-LED an
  mov r0,status
  rcall zifferton
  rjmp prgm_end
;======================================================================

; ******************* Unterprogramme / Funktionen *********************

ds_romcmd: ;ROM-Kommando aus R18 senden
  sbis PINB,4 ;Busleitung abfragen, sollte über R1 auf VDD liegen
  rjmp error_end ;da stimmt etwas nicht! Kurzschluss gegen GND?
; Initialisierung - Einleitung der Übertragung. Die Busleitung muss für
; mindestens 480 µs auf GND gezogen werden (= 576 Taktzyklen).
  sbi DDRB,4
  ldi r17,70
  rcall waitr17short
  cbi DDRB,4 ;Busleitung wieder als Input
  inc status
  ldi r16,6
  ds_pp_wt1: ;etwa 15 µs warten (= minimale Reaktionszeit des DS18B20)
    subi r16,1 ;SUBI löscht als Nebeneffekt das C-Flag
  brne ds_pp_wt1
; weitere 465 µs warten und permanent prüfen, ob ein '0'-Signal
; (presence pulse) vom Sensor kommt
  for r16,111,ds_pp_wt2
    sbis PINB,4
    sec ;presence pulse erkannt
  next_down r16,ds_pp_wt2
  brcc error_end ;keine Antwort vom DS18B20!
  inc status
  sbis PINB,4 ;Busleitung muss inzwischen wieder über R1 auf VDD liegen
  rjmp error_end ;da stimmt etwas nicht - Senden wäre nun sinnlos
; ROM command senden, einfach in die Senderoutine laufen
;----------------------------------------------------------------------
; Die Byte-Sende-Routine verändert R16, R17, R18
ds_sendbyte: ;R18 Bit für Bit senden
  for r17,8,ds_send_lp
    rcall ds_sendbit
  next_down r17,ds_send_lp
ret
;----------------------------------------------------------------------
; Die Bit-Sende-Routinen verändern R16
ds_sendbit: ;Bit 0 von R18 senden, R18 rotieren
  ror r18
ds_sendcf: ;C-Flag senden, 'write time slot' erzeugen
  sbi DDRB,4 ;Busleitung auf GND
  nop
  brcc ds_sendbit_wait ;nur bei '0' GND-Potenzial halten
  cbi DDRB,4 ;für eine '1' genügt das schon, Busleitung wieder als Input
  ds_sendbit_wait:
  for r16,28,ds_send_wt ;gut 60 µs warten, Länge 'write time slot'
  next_down r16,ds_send_wt
  ds_sendbit_end:
  cbi DDRB,4 ;Busleitung in jedem Fall als Input, über R1 auf VDD
ret
;----------------------------------------------------------------------
ds_rec_bit: ;'read time slot' erzeugen, Ergebnisbit im C-Flag
; 60-µs-Empfangsintervall setzen und das vom Sensor gesendete Bit im
; C-Flag bereitstellen. Das Timing ist hier relativ kritisch, da der
; Sensor bereits auf die fallende Flanke des Bussignals reagiert.
; R16 wird verändert.
  sbi DDRB,4 ;Busleitung auf GND
  nop ; 1 µs GND-Potenzial genügt schon!
  cbi DDRB,4 ;Busleitung wieder auf VDD über R1
  ldi r16,4
  ds_rec_wt1: ;kurz warten
    subi r16,1 ;anstatt DEC, um als Nebeneffekt das C-Flag zu löschen
  brne ds_rec_wt1
; seit der fallenden Flanke sind bisher 15 T = 12,5 µs vergangen
  sbic PINB,4 ;jetzt muss ein gültiges Signal vorliegen
  sec
  for r16,17,ds_rec_wt2 ;nochmals warten, um die 60 µs voll zu machen
  next_down r16,ds_rec_wt2
ret
;----------------------------------------------------------------------
ds_rec_bytes: ;R19 Bytes vom Sensor anfordern und im Buffer ablegen
; R0, R1, R16-R19 werden verändert
  clr r0 ;R0 nimmt den CRC-Wert auf (Algorithmus => siehe Datenblatt)
  ldi_hl z,rdbuff
  ds_rec_lp:
    for r17,8,ds_rec_byte ;8 Bits pro Byte
      rcall ds_rec_bit ;Bit 0 bis Bit 7 einsammeln
      in r16,SREG ;C-Flag zwischenspeichern für CRC-Berechnung
      ror r18 ;Empfangsbyte zusammenschieben
; Start CRC-Berechnung
      eor r16,r0
      andi r16,1 ;Bit 0 (C-Flag) 'freistellen'
      mov r1,r16 ;wird später noch gebraucht zum Einrotieren
      lsl r16
      lsl r16
      lsl r16
      eor r0,r16 ;an Bit-Position 3
      lsl r16
      eor r0,r16 ;an Bit-Position 4
      lsr r1 ;wieder ins C-Flag
      ror r0 ;und somit nun in Bit 7 des vorläufigen Ergebnisses
; Ende CRC-Berechnung
    next_down r17,ds_rec_byte ;weiter, bis Byte komplett
    st z+,r18 ;in den Empfangsbuffer
  next_down r19,ds_rec_lp
  tst r0 ;ungleich null zeigt Übertragungsfehler an
  breq ds_recby_ret
  sbi PORTB,2 ;Error-LED einschalten
ds_recby_ret:
ret
;----------------------------------------------------------------------
morse_zahlen: ;R19 Bytes aus dem Empfangsbuffer akustisch ausgeben
; wirklich gemorst wird nicht, aber es klingt ähnlich
  ldi_hl z,rdbuff
  morse_lp:
    ld r10,z+
    ldi_hl y,dezzahl ;Speicherbereich für Dezimalzahl-Ergebnis
    rcall bin2dec ;Dezimalzahlstring aus R10
    ziff_ausg: ;R18 Ziffern ab (Y) ausgeben
      ld r0,y+
      rcall zifferton
    next_down r18,ziff_ausg
    sbi PINB,2 ;LED umschalten
    ldi r17,1
    rcall waitr17 ;LED soll nur ganz kurz aufblitzen
    sbi PINB,2 ;LED umschalten
    ldi r17,18
    rcall waitr17 ;nach jeder Zahlenausgabe 1 Sek. Pause
  next_down r19,morse_lp
  cbi PORTB,2 ;Error-LED aus (sie leuchtete ggf. bei CRC-Error)
ret
;======================================================================
tonsignal: ; *** Tonsignal an PB0/PB1 ausgeben, ohne Timer-Verwendung
; abgestimmt auf 1,2 MHz CPU-Takt
; R16: Periodenlänge als Vielfaches von 100 µs
; R17: 1/10 der Anzahl der zu erzeugenden Perioden
  push xl
  push xh
  push r20
  push r2
  sbi PORTB,0
  cbi PORTB,1 ;Startzustand der Port-Leitungen
  tonsiglp:
    for r20,10,ton_10per ;10 Perioden erzeugen
      for xh,2,ton_period ;für die beiden halben Perioden
        mov r2,r16 ;R16 halbe Perioden erzeugen
        wt_halb_per: ;1/2 Periode erzeugen
          for xl,19,wt50lp ;50 µs warten (bei Taktfrequenz 1,2 MHz)
          next_down xl,wt50lp
        next_down r2,wt_halb_per
        ldi xl,3
        out PINB,xl ;Ports B0 und B1 umschalten
      next_down xh,ton_period
    next_down r20,ton_10per
  next_down r17,tonsiglp
  cbi PORTB,0
  cbi PORTB,1 ;Lautsprecher stromlos
  pop r2
  pop r20
  pop xh
  pop xl
ret
;----------------------------------------------------------------------
zifferton: ; *** R0 als Tonsignalfolge ausgeben
  push r0
  push r16
  push r17
  tst r0
  brne ziff_pieps
  ldi r16,20 ;500 Hz für die Ziffer 0
  ldi r17,25 ;250 Perioden = 1/2 Sekunde
  inc r0 ; damit die folgende Schleife 1mal durchlaufen wird
  rjmp ausg_ziff_ton ;Sprung in die Schleife ...
  ziff_pieps: ;R0 Piepser für eine Dezimalziffer
    ldi r16,10 ;1 kHz
    ldi r17,25 ;250 Perioden = 1/4 Sekunde
    ausg_ziff_ton:
    rcall tonsignal
    ldi r17,5
    rcall waitr17 ;nach jedem Pieps 5/18 Sek. warten (knapp 300 ms)
  next_down r0,ziff_pieps
  ldi r17,11
  rcall waitr17 ;nach jeder Ziffer zusätzlich gut 600 ms Pause
  pop r17
  pop r16
  pop r0
ret
;----------------------------------------------------------------------
; Warte-Routinen sind energiesparend mit Timer + SLEEP-Modus realisiert
waithalbsek: ; ***  etwa 1/2 Sekunde warten
  ldi r17,9 ; R17 wird verändert
waitr17: ;  *** R17 * 1/18 Sekunde warten
  push r16
  clr timovl ;Überlauf-Reg. für den Timer, wird in Int.-Rout. inkrementiert
  out TCNT0,nullreg ;Counter-Wert nullsetzen
  out_i TCCR0B,(1<<CS02) ;Timer starten mit Systemtakt / 256 = 4,6875 kHz
  wtr17lp:
    out_i MCUCR,(1<<SE) ;Idle-Modus
    sleep ;CPU schläft, wartet auf Interrupt (Timer)
    cp timovl,r17 ;r17 Timer-Überläufe erreicht?
  brcs wtr17lp ;noch nicht => weiter warten
  out TCCR0B,nullreg ;Timer stoppen
  pop r16
ret
;----------------------------------------------------------------------
waitr17short: ;R17 * 6,67 + 29 µs warten (inkl. rcall+ret)
  out OCR0A,r17 ;nur so weit soll gezählt werden
  out TCNT0,nullreg ;Counter-Wert nullsetzen
;Timer starten mit Systemtakt / 8 = 150 kHz und TOP = OCR0A
  out_i TCCR0A,3<<WGM00 ;Modus FAST PWM für Timer 0
  out_i TCCR0B,(1<<WGM02)+(1<<CS01)
  out_i MCUCR,1<<SE ;Idle-Modus
  sleep ;CPU schläft, wartet auf Interrupt durch Timer
  out TCCR0B,nullreg ;Timer stoppen
  out TCCR0A,nullreg ;normal mode
ret
;----------------------------------------------------------------------
bin2dec: ; *** Dezimaldarstellung einer 1-Byte-Binärzahl berechnen
; Input:  R10 enthält die Binärzahl
;         Y zeigt auf Beginn des SRAM-Speicherbereichs der Dezimalzahl
; Output: Dezimalzahl ab (Y), eine Dez.ziffer pro Byte, Start mit MSD
;         R18 = Anzahl der Dezimalziffern (1 Ziffer für Zahl 0)
  push r0
  push r1
  push r10
  push r16
  clr r18 ;Anzahl geschriebener Ziffern
  ldi r16,100 ;zunächst die 100er-Stelle
  b2d_for_ziff: ;pro Ziffer / Zehnerpotenz
    clr r1 ;die einzelne Ziffer
    b2d_ziff_lp: ;Ziffer aufbauen
      cp r10,r16
      brcs b2d_ziff_end ;Ziffer fertig
      sub r10,r16 ;einmal geht noch...
      inc r1
    rjmp b2d_ziff_lp
    b2d_ziff_end:
    tst r1
    brne b2d_wr_ziff ;Ziffer > 0 immer schreiben
    cpi r16,1
    breq b2d_wr_ziff ;Einerstelle immer schreiben
    tst r18
    breq b2d_nxt_ziff ;anderenfalls führende Nullen ignorieren
    b2d_wr_ziff:
    st y+,r1
    inc r18
    b2d_nxt_ziff:
    cpi r16,10 ;10er- bzw. 1er-Stelle ist die nächste
    ldi r16,1
    breq b2d_for_ziff
    ldi r16,10
  brcc b2d_for_ziff
  b2d_end:
  sub yl,r18 ;y auf Beginn der Zahlendarstellung
; sbc yh,nullreg ;überflüssig bei kleinem RAM
  pop r16
  pop r10
  pop r1
  pop r0
ret

; ******************************* ENDE *******************************
