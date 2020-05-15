.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern getchar: proc
extern system: proc

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

score DD 0
score_max EQU 1000

points_alien_1 EQU 1
points_alien_2 EQU 5
points_alien_3 EQU 10
points_alien_4 EQU 15
points_alien_5 EQU 20

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
include alien.inc
include aliendisappear.inc
include alien_blast.inc
include playericon.inc
include playericondisappear.inc

playericon_width EQU 25
playericon_height EQU 24

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
blast_speed DD 40

can_shoot DD 1

alien_blast_x DD 0
alien_blast_y DD 0
alien_blast_speed DD 40

alien_can_shoot DD 1

alien_width EQU 45
alien_height EQU 45

alien_init_x DD 499
alien_init_direction DD 1

alien_x DD 0
alien_y DD 175
alien_speed DD 3

alien_direction DD 0
alien_alive DD 0

timer DD 0

game_start DD 1

game_over DD 0
game_over_text_x EQU 477
game_over_text_y EQU 20

player_lives DD 2

alien_model DD -1

system_arg DB "pause", 0

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

	mov eax, [ebp + arg1] ; citim simbolul de afisat

	cmp eax, '{'
	je make_playericon

	cmp eax, '}'
	je make_playerdisappear

	cmp eax, '+'
	je make_aliendisappear

	cmp eax, '@'
	je make_alien

	cmp eax, '|'
	je make_alien_blast

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

make_playericon:
	mov eax, 0
	lea esi, playericon
	jmp draw_playericon

make_playericondisappear:
	mov eax, 0
	lea esi, playericondisappear
	jmp draw_playericon

make_aliendisappear:
	mov eax, 0
	lea esi, aliendisappear
	jmp draw_alien

make_alien:
	mov eax, 0
	add eax, alien_model
	lea esi, alien
	jmp draw_alien

make_alien_blast:
	mov eax, 0
	lea esi, alien_blast
	jmp draw_text

make_blast:
	mov eax, 0
	lea esi, blast
	jmp draw_text

make_playerdisappear:
	mov eax, 0
	lea esi, playerdisappear
	jmp draw_spaceship

make_douapuncte:
	mov eax, 0
	lea esi, douapuncte
	jmp draw_text

make_dreptunghi:
	mov eax, 0
	lea esi, dreptunghi
	jmp draw_text

make_player:
	mov eax, 0
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

draw_playericon:
	mov ebx, playericon_width
	mul ebx
	mov ebx, playericon_height
	mul ebx
	add esi, eax
	mov ecx, playericon_height

bucla_playericon_linii:
	mov edi, [ebp + arg2] ; pointer la matricea de pixeli
	mov eax, [ebp + arg4] ; pointer la coord y
	add eax, playericon_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp + arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, playericon_width

bucla_playericon_coloane:
	cmp byte ptr [esi], 1
	je playericon_pixel_color

	mov dword ptr [edi], 0
	jmp playericon_pixel_next

playericon_pixel_color:
	mov dword ptr [edi], 0FF00h

playericon_pixel_next:
	inc esi
	add edi, 4
	loop bucla_playericon_coloane
	pop ecx
	loop bucla_playericon_linii
	popa
	mov esp, ebp
	pop ebp
	ret

draw_alien:
	mov ebx, alien_width
	mul ebx
	mov ebx, alien_height
	mul ebx
	add esi, eax
	mov ecx, alien_height

bucla_alien_linii:
	mov edi, [ebp + arg2] ; pointer la matricea de pixeli
	mov eax, [ebp + arg4] ; pointer la coord y
	add eax, alien_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp + arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, alien_width

bucla_alien_coloane:
	cmp byte ptr [esi], 1
	je alien_pixel_turcoaz

	cmp byte ptr [esi], 2
	je alien_pixel_roz

	cmp byte ptr [esi], 3
	je alien_pixel_galben

	cmp byte ptr [esi], 4
	je alien_pixel_violet

	cmp byte ptr [esi], 5
	je alien_pixel_rosu

	mov dword ptr [edi], 0
	jmp alien_pixel_next

alien_pixel_turcoaz:
	mov dword ptr [edi], 00ffffh
	jmp alien_pixel_next

alien_pixel_roz:
	mov dword ptr [edi], 0ff1493h
	jmp alien_pixel_next

alien_pixel_galben:
	mov dword ptr [edi], 0ffff00h
	jmp alien_pixel_next

alien_pixel_violet:
	mov dword ptr [edi], 08a2be2h
	jmp alien_pixel_next

alien_pixel_rosu:
	mov dword ptr [edi], 0dc143Ch

alien_pixel_next:
	inc esi
	add edi, 4
	loop bucla_alien_coloane
	pop ecx
	loop bucla_alien_linii
	popa
	mov esp, ebp
	pop ebp
	ret

draw_spaceship:
	mov ebx, spaceship_width
	mul ebx
	mov ebx, spaceship_height
	mul ebx
	add esi, eax
	mov ecx, spaceship_height

bucla_spaceship_linii:
	mov edi, [ebp + arg2] ; pointer la matricea de pixeli
	mov eax, [ebp + arg4] ; pointer la coord y
	add eax, spaceship_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp + arg3] ; pointer la coord x
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
	mov edi, [ebp + arg2] ; pointer la matricea de pixeli
	mov eax, [ebp + arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp + arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width

bucla_simbol_coloane:
	cmp byte ptr [esi], 1
	je simbol_pixel_verde

	cmp byte ptr [esi], 2
	je simbol_pixel_alb

	cmp byte ptr [esi], 3
	je simbol_pixel_rosu

	mov dword ptr [edi], 0
	jmp simbol_pixel_next

simbol_pixel_verde:
	mov dword ptr [edi], 0FF00h
	jmp simbol_pixel_next

simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
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

	mov edx, 0
	cmp edx, game_over
	je not_exit

	push offset system_arg
	call system
	push -1
	call exit

	; varianta alternativa:
	;call getchar
	;call exit

not_exit:
	mov edx, score_max
	cmp score, edx
	jl game_not_over

	push offset system_arg
	call system
	push 1
	call exit

game_not_over:
	mov edx, 0
	cmp edx, alien_alive
	je restore_alien

next_instruction:
	mov edx, can_shoot
	cmp edx, 1
	je eticheta

	mov edx, alien_x
	cmp blast_x, edx
	jl eticheta

	mov edx, alien_x
	add edx, alien_width
	cmp blast_x, edx
	jg eticheta

	mov edx, alien_y
	cmp blast_y, edx
	jl eticheta

	mov edx, alien_y
	add edx, alien_height
	cmp blast_y, edx
	jg eticheta

	mov alien_alive, 0

	mov edx, 0
	cmp edx, alien_model
	je add_1

	mov edx, 1
	cmp edx, alien_model
	je add_2

	mov edx, 2
	cmp edx, alien_model
	je add_3

	mov edx, 3
	cmp edx, alien_model
	je add_4

	jmp add_5

add_1:
	mov edx, points_alien_1
	jmp change_score

add_2:
	mov edx, points_alien_2
	jmp change_score

add_3:
	mov edx, points_alien_3
	jmp change_score

add_4:
	mov edx, points_alien_4
	jmp change_score

add_5:
	mov edx, points_alien_5

change_score:
	add score, edx
	make_text_macro '+', area, alien_x, alien_y
	make_text_macro ' ', area, blast_x, blast_y
	;call exit
	jmp reset_blast

eticheta:
	inc timer
	mov edx, alien_speed
	cmp timer, edx
	jne alien_shoot

	mov timer, 0

back:
	mov ecx, 0
	cmp ecx, alien_direction
	je right_dir

	mov eax, alien_x
	mov ebx, spaceship_speed
	cmp eax, ebx
	jle change_dir

	make_text_macro '+', area, alien_x, alien_y
	mov ecx, alien_x
	sub ecx, spaceship_speed
	mov alien_x, ecx
	jmp alien_shoot

right_dir:
	mov eax, alien_x
	mov ebx, area_width
	mov ecx, spaceship_speed
	add ecx, 35
	sub ebx, ecx
	cmp eax, ebx
	jge change_dir

	make_text_macro '+', area, alien_x, alien_y
	mov ecx, alien_x
	add ecx, spaceship_speed
	mov alien_x, ecx
	jmp alien_shoot

change_dir:
	mov edx, alien_direction
	xor edx, 1
	mov alien_direction, edx
	jmp back

restore_alien:
	mov edx, alien_model
	inc edx
	mov alien_model, edx
	mov edx, 5
	cmp alien_model, edx
	jne valid_alien_model

	mov alien_model, 0

valid_alien_model:
	mov edx, alien_init_x
	mov alien_x, edx
	mov alien_alive, 1
	xor alien_init_direction, 1
	mov edx, alien_init_direction
	mov alien_direction, edx

alien_shoot:
	mov edx, 2
	cmp game_start, edx
	jle increase_game_start

	mov edx, 1
	cmp edx, alien_can_shoot
	jne spaceship_hit

	mov alien_can_shoot, 0

	mov edx, alien_x
	mov alien_blast_x, edx
	add alien_blast_x, 18

	mov edx, alien_y
	mov alien_blast_y, edx
	add alien_blast_y, 45

	make_text_macro '|', area, alien_blast_x, alien_blast_y

	jmp increase_game_start

spaceship_hit:
	mov edx, spaceship_x
	cmp alien_blast_x, edx
	jl move_alien_blast

	mov edx, spaceship_x
	add edx, spaceship_width
	cmp alien_blast_x, edx
	jg move_alien_blast

	mov edx, alien_blast_y
	add edx, 20
	cmp edx, spaceship_y
	jl move_alien_blast

	mov edx, spaceship_y
	add edx, spaceship_height
	mov ecx, alien_blast_y
	add ecx, 20
	cmp ecx, edx
	jg move_alien_blast

	;mov alien_can_shoot, 1

	mov edx, 0
	cmp edx, player_lives
	jne decrease_lives

	mov game_over, 1
	make_text_macro 'G', area, game_over_text_x, game_over_text_y
	make_text_macro 'A', area, game_over_text_x + 10, game_over_text_y
	make_text_macro 'M', area, game_over_text_x + 20, game_over_text_y
	make_text_macro 'E', area, game_over_text_x + 30, game_over_text_y
	make_text_macro ' ', area, game_over_text_x + 40, game_over_text_y
	make_text_macro 'O', area, game_over_text_x + 50, game_over_text_y
	make_text_macro 'V', area, game_over_text_x + 60, game_over_text_y
	make_text_macro 'E', area, game_over_text_x + 70, game_over_text_y
	make_text_macro 'R', area, game_over_text_x + 80, game_over_text_y
	jmp afisare_litere

decrease_lives:
	dec alien_speed
	mov timer, 0
	make_text_macro '+', area, alien_x, alien_y
	mov edx, alien_y
	add edx, alien_blast_speed
	mov alien_y, edx
	mov edx, player_lives
	dec edx
	mov player_lives, edx
	mov alien_can_shoot, 1
	make_text_macro ' ', area, alien_blast_x, alien_blast_y
	jmp next

move_alien_blast:
	mov edx, 520
	cmp edx, alien_blast_y
	jle reset_alien_blast

	make_text_macro ' ', area, alien_blast_x, alien_blast_y
	mov edx, alien_blast_speed
	add alien_blast_y, edx
	mov edx, 520
	cmp edx, alien_blast_y
	jle reset_alien_blast

	make_text_macro '|', area, alien_blast_x, alien_blast_y
	jmp increase_game_start

reset_alien_blast:
	mov alien_can_shoot, 1

increase_game_start:
	mov edx, 3
	cmp game_start, edx
	je blast_shoot

	inc game_start

blast_shoot:
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
	jz afisare_litere ; nu s-a efectuat click pe nimic
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
	mov eax, [ebp + arg2]
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

	mov edx, 1
	cmp edx, player_lives
	je one_more_life

	mov edx, 0
	cmp edx, player_lives
	je no_life_left

	make_text_macro '{', area, 984, 20
	make_text_macro '{', area, 984, 60
	jmp alien_dead_verification

one_more_life:
	make_text_macro '{', area, 984, 20
	make_text_macro '}', area, 984, 60
	jmp alien_dead_verification

no_life_left:
	make_text_macro '}', area, 984, 20

alien_dead_verification:
	mov edx, 0
	cmp edx, alien_alive
	je final_draw

	make_text_macro '@', area, alien_x, alien_y

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
	call malloc ; alocam memorie in mod dinamic (pe heap) pentru zona de desenat
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
	call BeginDrawing ; apelam functia/procedura de desenat
	add esp, 20 ; curatam stiva

	;terminarea programului
	push 0
	call exit
end start
