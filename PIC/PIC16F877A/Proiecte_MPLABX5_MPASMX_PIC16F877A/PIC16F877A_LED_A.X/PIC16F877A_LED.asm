;*******************************************************************************
; Fisier	        : PIC16F877A_LED.asm
; Descriere	        : Interfatare LED cu PIC 16F877A
; Autor		        : Mandache Doru
; Microcontroler    : Microchip PIC 16F877A
; Compilator	    : Microchip Assembler (MPASMX)
; IDE		        : Microchip MPLAB X IDE v5.05
; Programator	    : PICKit3
; Hardware	        : 
; Conexiuni	        : 
; Data actualizare  : 15.06.2020
; Site		        : 
;*******************************************************************************
    
    list    p=16f877A       ; list directive to define processor
    include <p16f877A.inc>  ; processor specific variable definitions
 
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _WRT_OFF & _LVP_ON & _CPD_OFF
 
; '__CONFIG' directive is used to embed configuration data within .asm file.
; The lables following the directive are located in the respective .inc file.
; See respective data sheet for additional information on configuration word.
;***** VARIABLE DEFINITIONS
w_temp      EQU 0x7D        ; variable used for context saving
status_temp EQU 0x7E        ; variable used for context saving
pclath_temp EQU 0x7F        ; variable used for context saving
;**********************************************************************
 
    ORG 0x000                ; processor reset vector
    
    goto    start            ; salt la inceputul programului
    
start
    bsf     STATUS, RP0      ; selecteaza bank 1
    movlw   b'11111110'      ; incarca registrul W cu valoarea binara b'11111110'
    movwf   TRISB            ; seteaza PORTB,1 ca iesire
    bcf	    STATUS, RP0      ; selecteaza bank 0
    clrf    PORTB            ; initializare PORTB
    bsf	    PORTB,  0        ;  RB0 only!
    
    end                      ; directiva 'end of program'


; list p=16f877A
;-------------------------------------------------------------------------------    
; Specifica asamblorului pentru ce procesor trebuie sa faca asamblarea. 
; Intotdeauna trebuie sa folositi directiva "list" la inceputul fisierului sursa.
; Daca exista vreo diferenta intre aceasta directiva si setarile MPLAB atunci MPLAB 
; va avertiza asupra acestui lucru si dv puteti corecta problema.

; #include <p16f877A.inc>
;-------------------------------------------------------------------------------    
; Urmatoarea linie utilizeaza directiva "#include" care face apel la fisierul p16f877A.inc, 
; aflat printre fisierele din directorul MPASM Suite, pentru a fi citit de catre asamblor.
    

; __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _WRT_OFF & _LVP_ON & _CPD_OFF
;-------------------------------------------------------------------------------    
; Urmatoarea linie arata modul in care este configurat microcontrolerul:
; Aceasta linie trebuie sa fie scrisa intr-o singura linie in codul sursa.  
; Microcontrolerele au cateva ?configuration words? adesea numite si ?fuses?, 
; care definesc un numar de aspecte de configurare a microcontrolerului. 

;Aici:
;Protectia codului se face pentru a ascunde de competitori, informatiile continute intr-un MCU care este vandut . 
;_CP_OFF - dezactiveaza protectia la citire a codului.
;_CP_ON - activeaza protectia la citire a codului, astfel incat atunci cand cineva doreste sa citeasca 
;codul dintr-un MCU astfel protejat, va vedea doar Zero-uri.
    
;_WDT_OFF - inseamna Watchdog Timer OFF si asigura restartul automat al unui program care a esuat sau a trezi 
;un MCU din modul sleep (?somn?) atunci cand se afla in functionarea in consum redus.
;Pentru perioada verificarilor si proiectarii aceasta functiune nu este utila si se prefera sa ramana disable.
    
;_BODEN_OFF
;Brown-out detection este disable. Functionarea MCU poate deveni nesigura atunci cand tensiunea de alimentare 
;scade foarte mult. MCU are un circuit de detectie care il va reseta in situatii de
;brown-out atunci cand este selectata varianta _BODEN_OFF
    
;_PWRTE_ON
;Atunci cand este pornita alimentarea unui MCU acestuia ii trebuie ceva timp pana se stabilizeaza 
;tensiunea de alimentare timp in care MCU este nesigur in functionare. Atunci cand este activata aceasta functiune, 
;PIC-ul este tinut in reset pe o perioada de aproximativ 72 ms pana tensiunea atinge valori nominale. 
;Este bine ca aceasta optiune sa ramana enable.
    
;_HS_OSC  Stabileste ca semnalul de clock vine de la un oscilator cu quartz cu frecventa cuprinsa intre 4 si 20MHZ.
    
;_WRT_OFF
;_LVP_ON
    
;_CPD_OFF
;Protectia codului in Data memory (flash memory sau EEPROM) este pe off. Aceasta memorie nu isi pierde 
;continutul la disparitia tensiunii de alimentare iar accesarea ei se face prin intermediul registrilor speciali. 
;Daca specificam _CPD_ON, atunci EEPROM memory va fi proejata impotriva citirii de catre un programator. 
;Dar EEPROM memory poate fi folosita pentru a pastra user data sau logged data, la care un utilizator 
;trbuie sa aiba acces. Pentru a permite flexibilitate, memoria program si data (EEPROM) este protejata independent.
   
;Urmatoarele trei linii reprezinta directive. Acestea inlocuiesc o valoare numerica cu un simbol. 
;In acest fel, unor anumite locatii din memorie li se asigneaza un nume. In cazul nostru, 
;pentru w_temp EQU 0x7D inseamna ca locatiei de memorie 07D, i se asigneaza numele w_temp. 
;Aceste locatii sunt locatii definite temporar si sunt utilizate pentru salvari.    
;w_temp EQU 0x7D ; variable used for context saving
;status_temp EQU 0x7E ; variable used for context saving
;pclath_temp EQU 0x7F ; variable used for context saving
    

    
;ORG 0x000 ; processor reset vector
;ORG specifica de obicei locatia din program memory unde se afla plasata directiva respectiva. 
;In acest caz vectorul de reset al procesorului se afla in locatia 0X00
    
;goto main ; go to beginning of program
;Instructiunea trimite la eticheta main, locul de inceput al programului.
    
;main
;Reprezinta locul de unde incepe executia propriu zisa a programului principal.
;bsf STATUS, RP0 ; selectie bank 1
;Asa cum stiti de acum instructiunile bcf si bsf sterg sau seteaza un bit din memorie. 
; Operatiunea chiar daca pare simpla nu este pentru ca CPU va citi intregul byte, va opera modificarea 
; si in final va rescrie intregul byte modificat, in locatia respectiva.
;Aici, aceasta instructiune modifica valoarea bitului RP0 (bit5) din registrul STATUS care impreuna 
; cu (RP1) bit 6 atrage dupa sine trecerea la registrii aflati in Bank1 de memorie.
;movlw b?11111110? ;  load W with binary
;Sau cum ii spune si mnemonicul, move literal to W. Se incarca valoarea binara b?11111110? 
; in registrul W (working register)
;movwf TRISB ; set PORTB,1 as output
;Continutul registrului W este mutat in registrul f . In acest moment registrul are in el 
; valoarea binara b?11111110?.In acest caz TRISB face ca pin port B0 al PORTB sa devina 0 
; (output) iar pin port B1-B7 sa devina 1 (input). In felul acesta am asignat un pin de 
; microcontroler ca OUTPUT (iesire).
;bcf STATUS, RP0 ; select bank 0
;Este instructiunea complementara lui BSF prin care se face zero bitul RB0 (bit5). 
; Aceasta face ca perechea RB5-RB6 sa formeze combinatia 00 corespunzatoare revenirii la registrii din bank1.
;clrf PORTB ; initializare PORTB
;Instructiunea face ca continutul registrului f in cazul nostru PORTB, sa fie sters
; ((bitii sai sa fie facuti zero) iar Z flag al registrului STATUS sa fie set.
;Instructiunea este utila pentru a initializa complet continutul acestui registru.
;bsf PORTB, 0 ; turn on RB0 only!
;Este instructiunea complementara celei dinainte prin care se seteaza (se aduce in 1) 
; bitul RB0 al registrului PORTB. Aceasta face ca sa aducem pe acest port, care stim ca 
; este iesire, o tensiune corespunzatoare lui 1 logic, adica 5V.   Un LED conectat aici, desigur ca va lumina.
;end ; directive ?end of program?
;Fiecare program trebuie sa fie incheiat prin utilizarea acestei directive. Numai la 
; intalnirea acestei directive, asamblorul opreste compilarea.    
