;Sahar Lando
; Input/Output Modes (ah): 1h = input char, 2h = print char, 9h = print string
IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------
	stage db 0
	errorFlag db 0
	leftover dw 0
	negative db 0
	hideEqualSign db 0
	interrupt db ?
	num dw ?
    ten dw 10
	count dw ?
	num1 dw ?
	num2 dw ?
	result dw ?
	tmp dw ?
	startMsg db "Welcome to the calculator! use (+-/*^!r) to do math.$"
	zeroDivMsg db "You can't divide by zero!$"
	numTooLongMsg db "Please enter a number lower than 65536.$"
	powerZeroMsg db "Can't calculate 0^0!$"
	inputErrorMsg db "You can't do that!$"
	factorMaxMsg db "Please choose a facorial lower than 9!$"
	resultMaxMsg db "The result is too high for this calculator to handle!$"
	exitMsg db "Thank you for using the calculator!$"
CODESEG
proc inputNumber				; Taking a number with up to 5 digits, storing the non-digit in interrupt
	xor cx, cx
    mov [num], 0
inputLoop1:
	mov ah, 1h
    int 21h
	cmp al, '0'
	jb buildNumber
	cmp al, '9'
	ja buildNumber
	cmp cx, 5
	jae returnInputError
    mov bl, al
    sub bl, '0'
    xor bh, bh
    push bx
	inc cx
    jmp inputLoop1
buildNumber:
	mov [interrupt], al
	mov [tmp], 1
	cmp cx, 0
	je exitInput
inputLoop2:
    mov ax, [tmp]
    pop bx
	xor dx, dx
    mul bx
    add [num], ax
	cmp dx, 0
	jne returnInputError
    mov ax, [tmp]
    mul [ten]
    mov [tmp], ax
	loop inputLoop2
	jmp exitInput
returnInputError:
	mov [interrupt], 0
exitInput:
	ret
endp inputNumber
proc printAx					; Printing the number stored in ax
	mov [count], 0
printLoop1:
	cmp ax, 10
	jb endPrintLoop1
	mov bx, 10
	xor dx, dx
	div bx
	push dx
	inc [count]
	jmp printLoop1
endPrintLoop1:
	push ax
	inc [count]
	mov ax, 1
	mul [count]
	mov cx, ax
	mov ah, 2
printLoop2:
	pop dx
	add dx, 30h
	int 21h
	loop printLoop2 
	ret
endp printAx
proc calcRoot					; Calculating the square root of ax
	mov [tmp], ax
	xor cx, cx
rootLoop:
	mov ax, cx
	mul cx
	cmp ax, [tmp]
	ja endRootLoop
	inc cx
	jmp rootLoop
endRootLoop:
	dec cx
	mov ax, cx
	ret							; Result will be stored in ax
endp calcRoot
proc power  					; Calculating ax ^ bx, saving result in ax
	cmp bx, 0
	je power1
	cmp bx, 1
	je exitPower
    mov [tmp], ax 
    mov cx, bx
    dec cx
	xor dx, dx
powerLoop:
    mul [tmp]
	cmp dx, 0
	jne powerError
	loop powerLoop
	jmp exitPower
power1:
	cmp ax, 0
	je power2
	mov ax, 1
	jmp exitPower
power2:
	mov [errorFlag], 2
	jmp exitPower
powerError:
	mov [errorFlag], 1
exitPower:
    ret
endp power
proc factorial  				; Calculating the factorial value of al
    push cx						; Result will be stored in ax
    push bx
    xor ch, ch
    mov cl, al
    mov bx, ax
    mov ax, 1
    mul bl
    mov [count], ax
    mov ax, 1
factorLoop:
    mul [count]
    dec [count]
    loop factorLoop
    pop bx
    pop cx
    ret
endp factorial
proc newLine					; Printing a line break
    push ax
    push dx
    mov ah, 2h
    mov dl, 10
    int 21h
    pop dx
    pop ax
    ret
endp newLine
start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
	mov dx, offset startMsg		; Showing start prompt
	mov ah, 9h
	int 21h
initCalc:						; Init calculator after an initial run or a reset
	call newLine
	jmp takeInput
takeInput:
	call inputNumber
	cmp [interrupt], 0
	jne a1
	jmp numTooLongError
a1:
	cmp [interrupt], 1Bh
	jne a2
	jmp exitPrompt
a2:
	cmp [stage], 0
	jne a3
	inc [stage]
	mov ax, [num]
	mov [num1], ax
	cmp [interrupt], '!'
	je a4
	cmp [interrupt], 'r'
	je a5
	cmp [interrupt], '+'
	je addition
	cmp [interrupt], '-'
	je substruction
	cmp [interrupt], '*'
	je a9
	cmp [interrupt], '/'
	je a8
	cmp [interrupt], '^'
	je a7
	jmp inputError
a3:
	cmp [interrupt], '='
	jne a6
	mov ax, [num]
	mov [num2], ax
	ret
a4:
	mov [hideEqualSign], 1
	jmp factor
a5:
	mov [hideEqualSign], 1
	jmp root
a6:
	jmp inputError
a7:
	jmp doPower
a8:
	jmp division
a9:
	jmp multiplication
addition:
	call takeInput
	mov ax, [num1]
	add ax, [num2]
	cmp ax, [num1]
	jb a10
	cmp ax, [num2]
	jb a10
	mov [result], ax
	jmp showResult
a10:
	jmp resultMaxError
substruction:
	call takeInput
	mov ax, [num1]
	cmp ax, [num2]
	jae b1
	mov bx, [num2]
	mov [num2], ax
	mov [num1], bx
	mov [negative], 1
b1:
	mov ax, [num1]
	sub ax, [num2]
	mov [result], ax
	jmp showResult
multiplication:
	call takeInput
	mov ax, [num1]
	xor dx, dx
	mul [num2]
	cmp dx, 0
	jne b2
	mov [result], ax
	jmp showResult
b2:
	jmp resultMaxError
division:
	call takeInput
	cmp	[num2], 0
	jne c1
	jmp zeroDivError
c1:
	mov ax, [num1]
	div [num2]
	mov [leftover], dx
	mov [result], ax
	jmp showResult
doPower:
	call takeInput
	mov ax, [num1]
	mov bx, [num2]
	call power
	mov [result], ax
	jmp showResult
factor:
	cmp [num1], 8
	jbe d1
	jmp factorMaxError
d1:
	mov ax, [num1]
	call factorial
	mov [result], ax
	jmp showResult
root:
	mov ax, [num1]
	call calcRoot
	mov [result], ax
showResult:
	cmp [errorFlag], 1
	je e3
	cmp [errorFlag], 2
	je e4
	mov ah, 2h
	cmp [hideEqualSign], 1
	jne e1
	mov dl, '='
	int 21h
e1:
	cmp [negative], 0
	je e2
	mov dl, '-'
	int 21h
e2:
	mov ax, 1
	mul [result]
	call printAx
	jmp showLeftover
e3:
	jmp resultMaxError
e4:
	jmp powerZeroError
showLeftover:
	cmp [leftover], 0
	je reset
	mov dl, '('
	int 21h
	mov ax, [leftover]
	call printAx
	mov ah, 2h
	mov dl, ')'
	int 21h
	jmp reset
inputError:
	mov dx, offset inputErrorMsg
	jmp showError
zeroDivError:
	mov dx, offset zeroDivMsg
	jmp showError
numTooLongError:
	mov dx, offset numTooLongMsg
	jmp showError
factorMaxError:
	mov dx, offset factorMaxMsg
	jmp showError
powerZeroError:
	mov dx, offset powerZeroMsg
	jmp showError
resultMaxError:
	mov dx, offset resultMaxMsg
showError:
	call newLine
	mov ah, 9h
	int 21h
	jmp reset
reset:
	mov [stage], 0
	mov [leftover], 0
	mov [negative], 0
	mov [hideEqualSign], 0
	mov [errorFlag], 0
	jmp initCalc
exitPrompt:
	mov ah, 9h
	mov dx, offset exitMsg
	int 21h
	call newLine
exit:
	mov ax, 4c00h
	int 21h
END start
