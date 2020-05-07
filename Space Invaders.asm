.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Proiect PLA 2020 - Stanciu Cristian", 0
area_width EQU 1024
area_height EQU 620
area DD 0

score DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20

include digits.inc
include letters.inc
include player.inc
include dreptunghi.inc
include douapuncte.inc
include playerdisappear.inc
include blast.inc

buttonShoot_x EQU 485
buttonShoot_y EQU 545
buttonShoot_length EQU 50
buttonShoot_width EQU 70

buttonLeft_x EQU 415
buttonLeft_y EQU 545
buttonLeft_length EQU 50
buttonLeft_width EQU 70

buttonRight_x EQU 555
buttonRight_y EQU 545
buttonRight_length EQU 50
buttonRight_width EQU 70

spaceship_width EQU 45
spaceship_height EQU 40

spaceship_x DD 499
spaceship_y EQU 455
spaceship_speed DD 86

blast_x DD 0
blast_y DD 0
blast_speed DD 30


can_shoot DD 1

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, '*'
	je make_blast
	cmp eax, '%'
	je make_playerdisappear
	cmp eax, ':'
	je make_douapuncte
	cmp eax, '#'
	je make_dreptunghi
	cmp eax, '$'
	je make_player
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_blast:
	sub eax, '*'
	lea esi, blast
	je draw_text
make_playerdisappear:
	sub eax, '%'
	lea esi, playerdisappear
	je draw_spaceship
make_douapuncte:
	sub eax, ':'
	lea esi, douapuncte
	je draw_text
make_dreptunghi:
	sub eax, '#'
	lea esi, dreptunghi
	je draw_text
make_player:
	sub eax, '$'
	lea esi, player
	je draw_spaceship
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	jmp draw_text

draw_spaceship:
	mov ebx, spaceship_width
	mul ebx
	mov ebx, spaceship_height
	mul ebx
	add esi, eax
	mov ecx, spaceship_height
bucla_spaceship_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, spaceship_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, spaceship_width
bucla_spaceship_coloane:
	cmp byte ptr [esi], 0
	jne spaceship_pixel_verde
	mov dword ptr [edi], 0
	jmp spaceship_pixel_next
spaceship_pixel_verde:
	mov dword ptr [edi], 0FF00h
spaceship_pixel_next:
	inc esi
	add edi, 4
	loop bucla_spaceship_coloane
	pop ecx
	loop bucla_spaceship_linii
	popa
	mov esp, ebp
	pop ebp
	ret

draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 1
	je simbol_pixel_verde
	cmp byte ptr [esi], 2
	je simbol_pixel_rosu
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_verde:
	mov dword ptr [edi], 0FF00h
	jmp simbol_pixel_next
simbol_pixel_rosu:
	mov dword ptr [edi], 0FF0000h
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha

	mov edx, 1
	cmp edx, can_shoot
	je next
	make_text_macro ' ', area, blast_x, blast_y
	mov ecx, blast_speed
	sub blast_y, ecx
	mov edx, 0
	cmp edx, blast_y
	jge reset_blast
	make_text_macro '*', area, blast_x, blast_y
	jmp next

reset_blast:
	mov can_shoot, 1

next:
	mov eax, [ebp + arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli negri
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0h
	push area
	call memset
	add esp, 12
	jmp afisare_litere

bucla_linii:
	mov eax, [ebp+arg2]
	and eax, 0FFh
	; provide a new (random) color
	mul eax
	mul eax
	add eax, ecx
	push ecx
	mov ecx, area_width

bucla_coloane:
	mov [edi], eax
	add edi, 4
	add eax, ebx
	loop bucla_coloane
	pop ecx
	loop bucla_linii
	jmp afisare_litere

evt_click:
	mov eax, [ebp + arg2]
	cmp eax, buttonLeft_x
	jle buttonLeft_fail
	cmp eax, buttonLeft_x + buttonLeft_width
	jge buttonLeft_fail
	mov eax, [ebp + arg3]
	cmp eax, buttonLeft_y
	jle buttonLeft_fail
	cmp eax, buttonLeft_y + buttonLeft_length
	jge buttonLeft_fail
	jmp buttonLeft

buttonLeft:
	make_text_macro ' ', area, 20, 20
	make_text_macro ' ', area, 30, 20
	make_text_macro ' ', area, 40, 20
	make_text_macro ' ', area, 50, 20
	make_text_macro ' ', area, 60, 20

	make_text_macro 'L', area, 20, 20
	make_text_macro 'E', area, 30, 20
	make_text_macro 'F', area, 40, 20
	make_text_macro 'T', area, 50, 20
	jmp move_left
	jmp afisare_litere

move_left:
	mov eax, spaceship_x
	mov ebx, spaceship_speed
	cmp eax, ebx
	jle afisare_litere

	make_text_macro '%', area, spaceship_x, spaceship_y
	mov ebp, spaceship_x
	sub ebp, spaceship_speed
	mov spaceship_x, ebp
	jmp afisare_litere

buttonLeft_fail:
	mov eax, [ebp + arg2]
	cmp eax, buttonShoot_x
	jle buttonShoot_fail
	cmp eax, buttonShoot_x + buttonShoot_width
	jge buttonShoot_fail
	mov eax, [ebp + arg3]
	cmp eax, buttonShoot_y
	jle buttonShoot_fail
	cmp eax, buttonShoot_y + buttonShoot_length
	jge buttonShoot_fail
	jmp buttonShoot

buttonShoot:
	make_text_macro ' ', area, 20, 20
	make_text_macro ' ', area, 30, 20
	make_text_macro ' ', area, 40, 20
	make_text_macro ' ', area, 50, 20
	make_text_macro ' ', area, 60, 20

	make_text_macro 'S', area, 20, 20
	make_text_macro 'H', area, 30, 20
	make_text_macro 'O', area, 40, 20
	make_text_macro 'O', area, 50, 20
	make_text_macro 'T', area, 60, 20
	jmp shoot

line_horizontal macro x, y, len, color
	local bucla_line
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
	bucla_line:
		mov dword ptr[eax], color
		add eax, 4
		loop bucla_line
endm

line_vertical macro x, y, len, color
	local bucla_line
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
	bucla_line:
		mov dword ptr[eax], color
		add eax, 4 * area_width
		loop bucla_line
endm

shoot:
	mov eax, 1
	mov ebx, can_shoot
	cmp eax, ebx
	jne afisare_litere

	mov can_shoot, 0

	mov ecx, spaceship_x
	mov blast_x, ecx
	add blast_x, 18

	mov edx, spaceship_y
	mov blast_y, edx
	sub blast_y, 20

	make_text_macro '*', area, blast_x, blast_y
	jmp afisare_litere

buttonShoot_fail:
	mov eax, [ebp + arg2]
	cmp eax, buttonRight_x
	jle buttonRight_fail
	cmp eax, buttonRight_x + buttonRight_width
	jge buttonRight_fail
	mov eax, [ebp + arg3]
	cmp eax, buttonRight_y
	jle buttonRight_fail
	cmp eax, buttonRight_y + buttonRight_length
	jge buttonRight_fail
	jmp buttonRight

buttonRight:
	make_text_macro ' ', area, 20, 20
	make_text_macro ' ', area, 30, 20
	make_text_macro ' ', area, 40, 20
	make_text_macro ' ', area, 50, 20
	make_text_macro ' ', area, 60, 20

	make_text_macro 'R', area, 20, 20
	make_text_macro 'I', area, 30, 20
	make_text_macro 'G', area, 40, 20
	make_text_macro 'H', area, 50, 20
	make_text_macro 'T', area, 60, 20
	jmp move_right

move_right:
	mov eax, spaceship_x
	mov ebx, area_width
	mov ecx, spaceship_speed
	add ecx, 35
	sub ebx, ecx
	cmp eax, ebx
	jge afisare_litere

	make_text_macro '%', area, spaceship_x, spaceship_y
	mov ebp, spaceship_x
	add ebp, spaceship_speed
	mov spaceship_x, ebp
	jmp afisare_litere

buttonRight_fail:
	jmp reset

reset:
	make_text_macro ' ', area, 20, 20
	make_text_macro ' ', area, 30, 20
	make_text_macro ' ', area, 40, 20
	make_text_macro ' ', area, 50, 20
	make_text_macro ' ', area, 60, 20
	jmp afisare_litere

evt_timer:
	; inc score
	
afisare_litere:
	make_text_macro 'S', area, 20, 560
	make_text_macro 'P', area, 30, 560
	make_text_macro 'A', area, 40, 560
	make_text_macro 'C', area, 50, 560
	make_text_macro 'E', area, 60, 560

	make_text_macro 'I', area, 80, 560
	make_text_macro 'N', area, 90, 560
	make_text_macro 'V', area, 100, 560
	make_text_macro 'A', area, 110, 560
	make_text_macro 'D', area, 120, 560
	make_text_macro 'E', area, 130, 560
	make_text_macro 'R', area, 140, 560
	make_text_macro 'S', area, 150, 560

	make_text_macro 'S', area, 900, 560
	make_text_macro 'C', area, 910, 560
	make_text_macro 'O', area, 920, 560
	make_text_macro 'R', area, 930, 560
	make_text_macro 'E', area, 940, 560
	make_text_macro ':', area, 950, 560

	;afisam valoarea score-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, score

	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 990, 560

	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 980, 560

	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 970, 560

	line_horizontal 0, 520, area_width, 0FF00h

	make_text_macro 'S', area, 495, 560
	make_text_macro 'H', area, 505, 560
	make_text_macro 'O', area, 515, 560
	make_text_macro 'O', area, 525, 560
	make_text_macro 'T', area, 535, 560
	line_horizontal buttonShoot_x, buttonShoot_y, buttonShoot_width, 0FF00h
	line_horizontal buttonShoot_x, buttonShoot_y + buttonShoot_length, buttonShoot_width, 0FF00h
	line_vertical buttonShoot_x, buttonShoot_y, buttonShoot_length, 0FF00h
	line_vertical buttonShoot_x + buttonShoot_width, buttonShoot_y, buttonShoot_length, 0FF00h

	make_text_macro 'L', area, 430, 560
	make_text_macro 'E', area, 440, 560
	make_text_macro 'F', area, 450, 560
	make_text_macro 'T', area, 460, 560
	line_horizontal buttonLeft_x, buttonLeft_y, buttonLeft_width, 0FF00h
	line_horizontal buttonLeft_x, buttonLeft_y + buttonLeft_length, buttonLeft_width, 0FF00h
	line_vertical buttonLeft_x, buttonLeft_y, buttonLeft_length, 0FF00h
	line_vertical buttonLeft_x + buttonLeft_width, buttonLeft_y, buttonLeft_length, 0FF00h

	make_text_macro 'R', area, 565, 560
	make_text_macro 'I', area, 575, 560
	make_text_macro 'G', area, 585, 560
	make_text_macro 'H', area, 595, 560
	make_text_macro 'T', area, 605, 560
	line_horizontal buttonRight_x, buttonRight_y, buttonRight_width, 0FF00h
	line_horizontal buttonRight_x, buttonRight_y + buttonRight_length, buttonRight_width, 0FF00h
	line_vertical buttonRight_x, buttonRight_y, buttonRight_length, 0FF00h
	line_vertical buttonRight_x + buttonRight_width, buttonRight_y, buttonRight_length, 0FF00h

	make_text_macro '$', area, spaceship_x, spaceship_y

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width ; EAX = area_width
	mov ebx, area_height ; EBX = area_height
	mul ebx ; EAX = area_width * area_height
	shl eax, 2 ; EAX = area_width * area_height * 4
	push eax ; punem pe stiva valoarea din registrul eax
	call malloc
	add esp, 4 ; curatam stiva
	mov area, eax

	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20

	;terminarea programului
	push 0
	call exit
end start
