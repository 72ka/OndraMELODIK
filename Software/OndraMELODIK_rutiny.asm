; porty


LS174	EQU 11110111b		; memory mapping, audio_out, timers	(PORT3)
LS374	EQU 11111101b		; printer port	      			(PORT9)
LS175	EQU 11111110b		; beeper and relay    			(PORT10)
LS173	EQU 11111110b		; LED, strobe and serial_out		(PORT10)
LS373	EQU 0FFE0h		; keyboard, audio_in and serial_in      (IN-PORT)


;---------------------------------------------------------------------
; ztlumeni MELODIKU - ztlumeni celeho Melodiku, proste jen zapise
; kazdem kanalu natvrdo maximalni utlum
;---------------------------------------------------------------------
muteMELODIK:

				LD      A, 09FH
                call writeSN
                LD      A, 0BFH
                call writeSN
                LD      A, 0DFH
                call writeSN
                LD      A, 0FFH
                call writeSN
				
ret
	
;---------------------------------------------------------------------
; detekce MELODIKU - kontroluje odezvu na lince BUSY po odeslani byte,
; nutno provozovat v rezimu FAST kvuli okamzitemu nacteni stavu portu!
; Cteni na portu probehne 50x za sebou, pokud do te doby zvukovy cip
; neodpovi, povazuje se za nepripojeny. V opacnem pripade ihned po
; odezve se rutina ukonci s vysledkem "detekovan"
; melodik = 00h (MELODIK neni pripojen)
; melodik = 01h (MELODIK je pripojen)
;---------------------------------------------------------------------
melodik DB 00h ;rezervuju si byte v pameti

melodikDetect:

	;vychozi hodnota je nedetekovany MELODIK
	ld a, 00h
	ld hl, melodik
	ld (hl), a
	
	;poslu mute na MELODIK - pro generaci odezvy a zaroven uzivatel nic neslysi
	call muteMELODIK
	
	;namapuji port, přistránkuje porty do horních 16kb
	ld	a, 110b
	out	(LS174), a

	;a prectu jestli jsme dostali signal READY na chipu
	ld	b, 50 ;budeme to zkouset 50x
mdread:
	ld a,(0E00Fh) ;ctu stav na adrese E00Fh - vstup BUSY je spolecny
	bit 5,a ;BUSY linka
	jr z, .skip ;odpovedel MELODIK? preskoc rovnou k ulozeni promenne
	djnz mdread
	jr mdexit
.skip	
	ld a, 01h
	ld hl, melodik
	ld (hl), a
mdexit:	
	; obnov mapovani
	ld	a, 10b
	out (LS174), a	
ret	

;---------------------------------------------------------------------
; zapis byte do MELODIKU - zapise byte do MELODIKU z akumulatoru
;---------------------------------------------------------------------
writeSN:
		; Vytvori puls na STB signalu pro zapis byte do SN76489
		; *****
		; osvedcilo se mi ze vlastne je STB stale na LOW a jen tesne
		; pred zapisem na Melodik se vytvori kratky puls na HIGH
		; ostatni signaly PORTU10 davam natvrdo, nekontroluju jejich stav
		; kvuli uspore CPU casu
		push af
		ld a, 00011111b ;nahodi STB do high
		OUT (LS173), a ;(PORT10)
		pop af
		OUT (LS374), A ;odesle byte na paralelni port
		ld a, 00010111b ;nahodi STB do low - strobe
		OUT (LS173), a ;(PORT10)
ret
