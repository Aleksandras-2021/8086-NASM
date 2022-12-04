%include 'yasmmac.inc'

org 100h 

section .text 

start:
macPutString 'Aleksandras Bukelis 1 kursas 2 grupe','$'
macNewLine
;;;;;;;;;;File handling part;;;;;;;;;;;;;;;

;;;;;File reading part from Command line;;;;;;;;;;;
   
  mov di, [skaitymoFailas]
   mov bx, 82h
   call getFileName
   getFileName:

   fileName:
   mov dl, [es:bx]
   inc bx
   cmp dl, ' '
   jbe quit
   mov skaitymoFailas[di], dl
   inc di
   jmp fileName
   quit:
   mov byte skaitymoFailas[di], 0

;***************open up a file for reading**********************
    mov dx, skaitymoFailas
    call procFOpenForReading
    jc failedToOpen ; print and error if file failed to open
    mov dx, buffer
    mov cx,45000
    call procFRead
;*****************************************************************

   ;;;;;;;Outfile file part;;;;;;;;;;;;

   macPutString 'Ivesk rasomo failo varda', crlf, '$'
   mov al, 254                  ; ilgiausia eilute
   mov dx, outputFile      ; 
   call procGetStr   
   macNewLine      
   
   ;create output file and open it for writing
   mov dx, outputFile
   call procFCreateOrTruncate 
   jc failedToOpen

   mov dx,outputFile
   call procFOpenForWriting 
   mov [handle], bx

   mov dx, tempFile
   call procFCreateOrTruncate 
   jc failedToOpen
   mov dx,tempFile
   call procFOpenForWriting 
   mov [handleTemp],bx

   mov dx, buffer
   mov di,0
   mov bp,di
   mov cx,100; for ~200 iterations from [-100;100]
   mov si,0

;**************Read the header
header:
   mov dl,[buffer+di]
   mov al,dl
   mov bx,[handle]
   call procFPutChar
   cmp dl,10
   je startasLoop
   mov dl,10
   mov [buffer+di], dh
   inc di
jmp header
;**********************************

;***********Calculation part *********
startasLoop:
   cmp cx, -101
   je finish
   mov dl,[buffer+di]
   cmp dl, 10 ; is it endline?
   je saveBP  ; save the coordinates of newline into bp
back:
   inc di
   cmp dl, 0
   je decCX ; setTemp
   cmp dl, 59 ;'is it ';'
   jne startasLoop
   inc si
   cmp si, 4  ;did we count 4 ';' symbols?
   je parseNumber
   jmp startasLoop
 ;**********************Saves the newline coordinates into BP
saveBP:
   mov bp, di 
   inc bp
   jmp back ;Continue the cycle

;*************************************

;Parse the numbers after 4 ';'
parseNumber:
   mov si, -1
   lea dx, [buffer+di]; load effective adress of buffer+di (to parse the numbers)
   call procParseInt16
   cmp ax,cx ; if ax == cx, write that line into file
   je printLine
   jne startasLoop ; if not, then repeat the whole process again on new line
;***********************************************************

;***************writes to temp file
printLine:
   mov dh,[buffer+bp]
   mov al,dh
   mov bx,[handleTemp]
   call procFPutChar
   inc bp
   cmp dh,10
   je startasLoop
jmp printLine
;*********************************************

;***************Decriment CX and reset absolutely everything
decCX:
   jmp sortTemp
goBack:
mov bx, [handleTemp]
   mov dx, tempFile
   call procFClose
   pop cx
   call procFCreateOrTruncate 
   jc failedToOpen 
   call procFOpenForWriting
   dec cx
   xor bp,bp
   xor si,si
   xor di,di
jmp startasLoop
;************************************************************

;*****************sorts temp by 4th collumn*******************
sortTemp:
   push cx ; Save the previous value of CX

   mov bx, [handleTemp]
   mov dx, tempFile
   call procFClose
   mov dx,tempFile
   call procFOpenForReading
   mov [handleTemp],bx


    
   mov dx, buffer2
   mov cx,25000
   call procFRead ;Read everything from temp file
 
   mov dl, 0
   mov bx,ax
   mov [buffer2+bx],dl
   mov bx,[handleTemp]
   mov di,0
   mov bp,di
   mov cx,100; for ~200 iterations from [-100;100]
   mov si,0
;************ACTION***********************
startasLoop2:
   cmp cx, -101
   je goBack
   mov dl,[buffer2+di]
   cmp dl, 10 ; is it endline?
   je saveBP2  ; save the coordinates of newline into bp
back2:
   inc di
   cmp dl, 0
   je decCX2 ; setTemp
   cmp dl, 59 ;'is it ';'
   jne startasLoop2
   inc si
   cmp si, 3  ;did we count 3 ';' symbols?
   je parseNumber2
   jmp startasLoop2
 ;**********************Saves the newline coordinates into BP
saveBP2:
   mov bp, di 
   inc bp
   jmp back2 ;Continue the cycle

;*************************************

;Parse the numbers after 3 ';'
parseNumber2:
   mov si, -2
   lea dx, [buffer2+di]; load effective adress of buffer+di (to parse the numbers)'
   call procParseInt16
   cmp ax,cx ; if ax == cx, write that line into file
   je printLine2
   jne startasLoop2 ; if not, then repeat the whole process again on new line
;***********************************************************

;***************writes to temp file
printLine2:
   mov bx,[handle]
   mov dh,[buffer2+bp]
   mov al,dh
   call procFPutChar
   inc bp
   cmp dh,10
   je startasLoop2
jmp printLine2
;*********************************************

;***************Decriment CX and reset absolutely everything
decCX2:
   dec cx
   xor bp,bp
   xor si,si
   xor di,di
jmp startasLoop2


finish:
mov bx,[handleTemp]
call procFClose
mov ah,41h
int 21h
exit

failedToOpen:
macPutString 'Klaida atidarant faila', crlf, '$'
exit

%include 'yasmlib.asm'

 section .DATA 
    skaitymoFailas:
    times 254 db 00
    buffer:
    times 45000 db 0
    buffer2:
    times 15000 db 0
    outputFile:
    times 254 db 0
    tempFile db "temp.txt",0
    handle:
    times 100 db 00
    handleTemp:
    times 100 db 00
    digits:
    times 20 db 0

section .bss

