name "Practica 6, Implementacion, Eduardo Perez Regin, D05"                        
org 100h                                                                      
                                                                         
; NO CONSIDERA EL PUNTO FLOTANTE, POR LO TANTO EL RESULTADO VA A DIFERIR DE LA CALCULADORA
; EN CASO DE HABER DECIMALES. 

mov ax, 1003h   
mov bx, 0
int 10h

JMP main

linea     DB 20 DUP (0) ; Arreglo de la cadena. 
aux       DW 20 DUP (0) ; Sera usado como un arreglo auxiliar que contendra las operaciones cambiantes.  
auxOper   DW 0          ; Almacenara el resultado de las operaciones previas.           
contador  DW 0          ; Contador que nos ayudara a saber cuantos caracteres hay en el primer operando.    
contador2 DW 0          ; Contador que nos ayudara a saber cuantos caracteres hay en el segundo operando.                                                                                                                
                                                                                                             
; Ambos operandos guardaran el numero que se usara para las operaciones, pero como cadena de caracteres.
operando1 DW 20 DUP(?)
operando2 DW 20 DUP(?)                                                                                  

; Ambos operandos ahora guardaran el numero que esta representado en cadenas de caracteres como numeros.
oper1     DW 0
oper2     DW 0

flagMulDivTermino DB 0 ; Bandera que servira cuando va a iniciar analizar las sumas y restas.  
flagMulFirst      DB 1 ; Bandera que nos ayuda para saber si hay primero una multiplicacion o no.   
firstTime         DB 0 ; Bandera que nos va ayudar cuando fue la primera vez que termino de analizar las multiplicaciones y divisiones para reiniciar los valores.   

t_linea  DB 0          ; Tamano de la cadena.
salir    DB 0          ; Bandera para terminar un ciclo.

main:  
    ; msg1     
    mov dx, 0700h
    mov bx, 0
    mov bl, 0011_1011b   
    mov cx, msg1Size
    mov al, 01b
    mov bp, msg1
    mov ah, 13h
    int 10h
    
    ; msg2 
    mov dx, 0800h
    mov bx, 0
    mov bl, 0011_1011b   
    mov cx, msg2Size
    mov al, 01b
    mov bp, msg2  
    mov ah, 13h
    int 10h

    ; msg3
    mov dx, 0A00h
    mov bx, 0
    mov bl, 0011_1011b   
    mov cx, msg3Size
    mov al, 01b
    mov bp, msg3                                                             
    mov ah, 13h
    int 10h         
    
    xor ax, ax
    xor dx, dx
    mov cx, 20         ; Tamano de la cadena para la funcion leecad
    lea si, linea      ; Arreglo en el que se alacenara la cadena completa del usuario 1+2+3+4.  
    lea di, aux        ; Arreglo donde apunta a nuestro auxiliar, contendra las operaciones ya echas. 
    mov [di-1], 0dh    ; El arreglo aux 0dh, para saber cuando llego al inicio del arreglo.   
    call leecad                
    
    mov al, [si]
    mov [di], al   
    inc contador
        
    cmp al, 0       ; Saltar sino se escribio nada, pues al dar ENTER al tiene 0.
    je fin          
    call asc2num    

; Continuará dependiendo si se está analizando primero las multiplicaciones/divisiones o solamente
; sumas o restas.   
nvocar:
    ; Va a continuar dependiendo si ya termino de analizar todas las multiplicaciones y divisiones.
    cmp flagMulDivTermino, 0
    je  continuar  
    jmp continuar2     
    
; Va a continuar hacer las operaciones pero solamente las multiplicaciones y divisiones, si es que las hay.   
continuar:
    inc contador  
    inc si          ; Al incrementar SI, obtendremos los operadores y operandos.
    inc di
    
    mov al, [si] 
    cmp al, 0dh
    je fin 
    mov [di], al
            
    ; test hace una operacion AND, pero afectando a los flags, no al registro, mas especificamente
    ; Parity flag, Sign flag, zero flag, por lo tanto, cuando sea igual saltara a fin.
    test al, 0FFh
    je fin
    call asc2num
    cmp al, 0fh     ; Si es un operador, saltar a leeop  
    ja leeop     
    jmp nvocar 

; Continuara pero ahora solamente hara las operaciones de sumas y restas.
continuar2:
    cmp firstTime, 0
    je reiniciar 
          
    inc contador  
    inc si          ; Al incrementar SI, obtendremos los operadores y operandos. 
    mov al, [si]   
    
    ; test hace una operacion AND, pero afectando a los flags, no al registro, mas especificamente
    ; Parity flag, Sign flag, zero flag, por lo tanto, cuando sea igual saltara a fin.
    test al, 0FFh
    je fin
    call asc2num
    cmp al, 0fh     ; Si es un operador, saltar a leeop  
    ja leeop       
    jmp nvocar

; Jerarquia de operadores.
leeop:
    mov al, [si]    ; Pasar los caracteres.           
opMult:    
    cmp al, '*'
    je mult
opDiv:
    cmp al, '/' 
    je division
opRest:
    cmp al, '-'
    je resta
opSum:
    cmp al, '+'
    je suma    
op0:
    jmp nvocar

; Realizara la multiplicacion entre dos numeros.
mult:
    ; Si salta significa que ya hay una operacion previamente hecha.
    cmp auxOper, 0
    jne mult2
    
    xor cx, cx
    mov cx, contador   
    push di
    push bx
    push si
    push cx  
    dec cx       
    lea di, operando1   
    dec si
    xor ax, ax
    
    call getPrimerOperando  
    lea di, operando1  
    
    ; Recuperar cuantos caracteres hemos leido, pues 
    ; necesitamos saber eso para poder saber cuantos elementos sacer de la pila.
    pop cx
    mov contador, cx
    push cx    
    dec contador
    mov bx, contador
    call invertir    
    
    ; Recuperamos los valores, sobre todo si, porque contiene la posicion de donde
    ; va en la linea del usuario.
    pop cx
    pop si    
       
    xor bx, bx
    xor ax, ax
                 
    lea di, operando2  ; Apuntar ahora a nuestro segundo operando.      
    inc si             ; Incrementamos porque en esta posicion, [si] es un operando.
    call getSegundoOperando
    
    push si        
    mov contador, cx    
    
    ; Ambos apuntan al ahora a los operadores indicados.      
    lea si, operando1   
    call convertirStringToNumero
    lea di, operando2
    call convertirStringToNumero2                          
    
    ; Realizar la operaciones de los operandos.
    xor ax, ax
    xor bx, bx
    mov ax, oper1
    mov bx, oper2
    mul bx
    mov auxOper, ax
    
    pop si
    pop bx 
       
    push si
    push bx
    lea si, aux
    call escribirResultado          
         
    ; Movemos la posicion de nuestro arreglo auxiliar, pues contiene nuestra ultima posicion, nos interesa. 
    mov ax, si                           
                  
    ; Recuperar valores, en este punto si volvera apuntar en la posicion que se quedo en nuestra linea principal.
    pop bx
    pop si 
    
    pop di 
    mov di, ax 
    
    ; Si salta, significa que hay otra multiplicacion o divisón seguida.
    cmp [si], '*'
    je mult      
    cmp [si], '/'
    je division
    
    dec si  
    inc bx 
    mov auxOper, 0   
    mov oper1, 0
    mov oper2, 0 
    dec di
    jmp op0    
mult2:    
    push di
    mov oper2, 0   
    xor bx, bx
    xor ax, ax             
    lea di, operando2  ; Apuntar ahora a nuestro segundo operando.      
    inc si             ; Incrementamos porque en esta posicion, [si] es un operando.
    call getSegundoOperando
    push si
    
    ; Se apunta ahora al operando2.      
    lea di, operando2
    call convertirStringToNumero2                          
                           
    xor ax, ax
    xor bx, bx
    mov ax, auxOper
    mov bx, oper2
    mul bx
    mov auxOper, ax
    
    pop si 
    pop di
    
    ; Si salta significa que hay otra multiplicación o división seguida. 
    cmp [si], '*'
    je mult2
    cmp [si], '/'
    je division2    
    push si 
     
    lea si, aux 
    call iterarCadena
             
    dec si      ; Decrementamos la posicion porque estamos una posicion de mas.              
    inc bx
    call analizarCaracteresIzquierdo     
 
    ; En este punto, si contiene la ultima posición de nuestro arreglo aux, movemos esta posición
    ; para poder escribir el resultado en la posición correcta en el arreglo aux.   
    mov di, si   
    pop si 
    dec si  
    dec di
    mov contador, 0
    jmp op0   
    
; Realizara la division entre dos numeros.
division:    
    ; Si salta significa que ya hay una operacion previamente hecha.
    cmp auxOper, 0
    jne division2
    
    xor cx, cx
    mov cx, contador   
    push di
    push bx
    push si
    push cx  
    dec cx       
    lea di, operando1   
    dec si
    xor ax, ax
    
    call getPrimerOperando  
    lea di, operando1  
    
    ; Recuperar cuantos caracteres hemos leido, pues 
    ; necesitamos saber eso para poder saber cuantos elementos sacer de la pila.
    pop cx
    mov contador, cx
    push cx    
    dec contador
    mov bx, contador
    call invertir    
    
    ; Recuperamos los valores, sobre todo si, porque contiene la posicion de donde
    ; va en la linea del usuario.
    pop cx
    pop si    
       
    xor bx, bx
    xor ax, ax
                 
    lea di, operando2  ; Apuntar ahora a nuestro segundo operando.      
    inc si             ; Incrementamos porque en esta posicion, [si] es un operando.
    call getSegundoOperando
    
    push si        
    mov contador, cx    
    
    ; Ambos apuntan al ahora a los operadores indicados.      
    lea si, operando1   
    call convertirStringToNumero
    lea di, operando2
    call convertirStringToNumero2                          
    
    ; Realizar la operaciones de los operandos.
    xor ax, ax
    xor bx, bx
    mov ax, oper1
    mov bx, oper2
    div bx
    mov auxOper, ax
    
    pop si
    pop bx 
       
    push si
    push bx
    lea si, aux
    call escribirResultado          
         
    ; Movemos la posicion de nuestro arreglo auxiliar, pues contiene nuestra ultima posicion, nos interesa. 
    mov ax, si                           
                  
    ; Recuperar valores, en este punto si volvera apuntar en la posicion que se quedo en nuestra linea principal.
    pop bx
    pop si 
    
    pop di 
    mov di, ax 
    
    ; Si salta, significa que hay otra multiplicacion seguida o división seguida.
    cmp [si], '/'
    je division   
    cmp [si], '*'
    je mult
    
    dec si  
    inc bx 
    mov auxOper, 0   
    mov oper1, 0
    mov oper2, 0 
    dec di
    jmp op0

division2:
    push di
    mov oper2, 0   
    xor bx, bx
    xor ax, ax             
    lea di, operando2  ; Apuntar ahora a nuestro segundo operando.      
    inc si             ; Incrementamos porque en esta posicion, [si] es un operando.
    call getSegundoOperando
    push si
    
    ; Se apunta ahora al operando2.      
    lea di, operando2
    call convertirStringToNumero2                          
                           
    xor ax, ax
    xor bx, bx
    mov ax, auxOper
    mov bx, oper2
    div bx
    mov auxOper, ax
    
    pop si 
    pop di  
    
    ; Si salta significa que hay otra multiplicación o división seguida.
    cmp [si], '/'
    je division2   
    cmp [si], '*'
    je mult2 
    push si 
     
    lea si, aux 
    call iterarCadena
          
    dec si ; Decrementamos la posicion porque estamos una posicion de mas.              
    inc bx
    call analizarCaracteresIzquierdo   
    
    ; En este punto, si contiene la ultima posición de nuestro arreglo aux, movemos esta posición
    ; para poder escribir el resultado en la posición correcta en el arreglo aux.
    mov di, si      
    pop si 
    dec si
    dec di
    mov contador, 0   
    jmp op0

; Escribira el resultado de la muliplicacion o division en la cadena de caracteres.
escribirResultado:
    mov al, [si] 
    cmp al, '*'
    je analizarCaracteresIzquierdo
    cmp al, '/'        
    je analizarCaracteresIzquierdo
    inc si
    jmp escribirResultado  
; Analizara los caracteres hasta encontrar el inicio de la cadena o algun operador.
analizarCaracteresIzquierdo:
    dec si
    mov al, [si]
    cmp al, '+'
    je escribirResultado2
    cmp al, '-'
    je escribirResultado2  
    cmp al, 0
    je escribirResultado2
    cmp bx, 0          
    je escribirResultado2
    dec bx
    jmp analizarCaracteresIzquierdo
escribirResultado2:
    ; Incrementamos SI para volver apuntar a la primera posicion de nuestro arreglo.
    inc si       
    
    xor dx, dx
    xor bx, bx  
    xor ax, ax
    mov cx, 0        ; Contador que nos va ayudar saber cuantos elementos hay en la pila.
    mov ax, auxOper 
    
    cmp ax, 9        ; Si nuestro resultado es mayor a 9.
    ja convertirDecimal    
       
convertirDecimal:
    inc cx  
    mov dx, 0h
    mov bx, 10
    div bx   
    push dx
    cmp ax, 0
    jnz convertirDecimal    
    mov dx, cx ; Obtener cuantos caracteres tiene la cadena.
    jmp sacarValoresP 
; Sacara los valores de la pila y los escribira en nuestro arreglo.
sacarValoresP: 
    pop ax
    add ax, 30h
    mov [si], al 
    
    ; Se hace esto porque a la hora de dividir, puede quedar valores basura, al quedar valores basura, el programa
    ; agarra esos valores y los usa para las operaciones, dando un resultado erroneo, se soluciona simplemente limpiando
    ; un valor en la siguiente posicion.  
    mov [si+1], 0
    inc si
    dec cx
    cmp cx, 0             
    jne sacarValoresP
    jmp return    

; Reiniciara los valores usados para las operaciones, asi tambien apuntara a nuestro nuevo arreglo donde
; ya tiene las multiplicaciones y divisiones echas.
reiniciar:     
    lea si, aux   
    dec si
    mov firstTime, 01h   
    mov contador, 0
    mov contador2, 0
    mov operando1, 0
    mov operando2, 0    
    mov oper1, 0
    mov oper2, 0
    mov auxOper, 0 
    
    cmp flagMulDivTermino, 1   ; Acabo de analizar todas las multiplicaciones y divisiones.
    je continuar2
    
    cmp al, 0dh
    je fin
       
    lea si, linea      ; Arreglo en el que se alacenara la cadena completa del usuario 1+2+3+4.
    mov al, [si]        
    inc contador                  
    jmp continuar2                                      

return:
    ret

resta:
    ;cmp flagMulFirst, 1   ; tal vez ocupo hacer lo mismo para la resta
    ;je setFlagMulFirst
    
    ; Si aun no ha terminado las analizar las divisiones y multiplicaciones.
    cmp flagMulDivTermino, 0
    je continue    
    
    ; Si salta significa que ya hay una operacion previamente hecha.
    cmp auxOper, 0
    jne resta2
    
    xor cx, cx
    mov cx, contador
    push si
    push cx  
    dec cx       
    lea di, operando1   
    dec si
    xor ax, ax
    
    call getPrimerOperando  
    lea di, operando1  
    
    ; Recuperar cuantos caracteres hemos leido, pues 
    ; necesitamos saber eso para poder saber cuantos elementos sacer de la pila.
    pop cx
    mov contador, cx
    push cx    
    dec contador
    mov bx, contador
    call invertir    
    
    ; Recuperamos los valores, sobre todo si, porque contiene la posicion de donde
    ; va en la linea del usuario.
    pop cx
    pop si    
       
    xor bx, bx
    xor ax, ax
                 
    lea di, operando2  ; Apuntar ahora a nuestro segundo operando.      
    inc si             ; Incrementamos porque en esta posicion, [si] es un operando.
    call getSegundoOperando
    
    push si
            
    mov contador, cx
    ; Ambos apuntan al ahora a los operadores indicados.      
    lea si, operando1   
    call convertirStringToNumero
    lea di, operando2
    call convertirStringToNumero2                          
    
    xor ax, ax
    xor bx, bx
    mov ax, oper1
    mov bx, oper2
    sub ax, bx
    mov auxOper, ax
    
    pop si
    dec si 
    mov contador, 0
    jmp op0

; Realizara la suma pero ahora ya con una operacion previamente hecha, en este punto ya se 
; tiene el operando1 como numero.
resta2:   
    mov oper2, 0   
    xor bx, bx
    xor ax, ax             
    lea di, operando2  ; Apuntar ahora a nuestro segundo operando.      
    inc si             ; Incrementamos porque en esta posicion, [si] es un operando.
    call getSegundoOperando
    push si
    
    ; Se apunta ahora al operando2.      
    lea di, operando2
    call convertirStringToNumero2                          
                           
    xor ax, ax
    xor bx, bx
    mov ax, auxOper
    mov bx, oper2
    sub ax, bx
    mov auxOper, ax
    
    pop si
    dec si 
    mov contador, 0
    jmp op0
    
suma:
    cmp flagMulDivTermino, 0
    je continue    
    
    ; Si salta significa que ya hay una operacion previamente hecha.
    cmp auxOper, 0
    jne suma2
    
    xor cx, cx
    mov cx, contador
    push si
    push cx  
    dec cx       
    lea di, operando1   
    dec si
    xor ax, ax
    
    call getPrimerOperando  
    lea di, operando1  
    
    ; Recuperar cuantos caracteres hemos leido, pues 
    ; necesitamos saber eso para poder saber cuantos elementos sacer de la pila.
    pop cx
    mov contador, cx
    push cx    
    dec contador
    mov bx, contador
    call invertir    
    
    ; Recuperamos los valores, sobre todo si, porque contiene la posicion de donde
    ; va en la linea del usuario.
    pop cx
    pop si    
       
    xor bx, bx
    xor ax, ax
                 
    lea di, operando2  ; Apuntar ahora a nuestro segundo operando.      
    inc si             ; Incrementamos porque en esta posicion, [si] es un operando.
    call getSegundoOperando
    
    push si
            
    mov contador, cx
    ; Ambos apuntan al ahora a los operadores indicados.      
    lea si, operando1   
    call convertirStringToNumero
    lea di, operando2
    call convertirStringToNumero2                          
    
    xor ax, ax
    xor bx, bx
    mov ax, oper1
    mov bx, oper2
    add ax, bx
    mov auxOper, ax
    
    pop si
    dec si 
    mov contador, 0
    jmp op0

; Realizara la suma pero ahora ya con una operacion previamente hecha, en este punto ya se 
; tiene el operando1 como numero.
suma2:   
    mov oper2, 0   
    xor bx, bx
    xor ax, ax             
    lea di, operando2  ; Apuntar ahora a nuestro segundo operando.      
    inc si             ; Incrementamos porque en esta posicion, [si] es un operando.
    call getSegundoOperando
    push si
    
    ; Se apunta ahora al operando2.      
    lea di, operando2
    call convertirStringToNumero2                          
                           
    xor ax, ax
    xor bx, bx
    mov ax, auxOper
    mov bx, oper2
    add ax, bx
    mov auxOper, ax
    
    pop si
    dec si 
    mov contador, 0
    jmp op0

getPrimerOperando:     
    mov al, [si]   
    cmp al, 0dh
    je return
    cmp al, '+'
    je return
    cmp al, '-'
    je return
    cmp al, '*'
    je return 
    cmp al, '/'
    je return
    cmp contador, 0
    je return    
getPrimerOperando2:    
    mov [di], ax
    inc di
    dec si
    dec contador
    jmp getPrimerOperando  
    
; A la hora de obtener primer operando los valores estan invertidos, usara la 
; pila para acomodar los caracteres del primer operando.
invertir:
    mov ax, [di]
    push ax
    inc di
    dec contador
    cmp contador, 0
    jne invertir
    lea di, operando1
sacarValoresPila:
    pop ax
    mov [di], al
    inc di
    dec bx
    cmp bx, 0
    jne sacarValoresPila
    jmp return      
    
escribirRestante:  
    mov al, [si]
    mov [di], al
    inc di
    inc si
    cmp [si], 0
    je return
    jmp escribirRestante   
        
      
; Obtendra el segundo operando para realizar las operaciones.    
getSegundoOperando:     
    mov al, [si]
    ; Cuando se hace una operacion que contiene multiplicaciones o divisiones, el 0dh no queda en su lugar.
    ; Por lo tanto el primero que encuentra es el 00, indicandonos que ya llego al final de la cadena. 
    cmp al, 0    
    je return
    ; Saltar si ya se llego al final de la linea (se llego al enter).
    cmp al, 0dh
    je  return
    cmp al, '+' 
    je return
    cmp al, '-'
    je return
    cmp al, '*'
    je return  
    cmp al, '/'
    je return
getSegundoOperando2:
    mov [di], al
    inc si
    inc di  
    inc contador2
    jmp getSegundoOperando     

; Convertira la cadena del primer operando en un numero
; donde sera almacenado en oper1  
convertirStringToNumero:
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx 
    
    dec contador
    mov cx, 0        ; Pues sera primero 10^0
    add si, contador ; Apuntara ahora a la ultima posicion.
obtenerElevadoTo10:
    cmp cx, 0
    je primeraVez
    mov ax, 10
    mul cx           ; cx * 10, cx * 100, ...
    mov cx, ax
    jmp convertirCaracterToNumero   
primeraVez:
    mov cx, 1 ; La primera vez es 10^0 = 1
convertirCaracterToNumero:    
    dec si        ; Apuntara a nuestro actual caracter.  
    mov al, [si]  
    sub al, 30h
    mov ah, 0
    mul cx        ; ax * cx    
    add oper1, ax 
    dec contador
    cmp contador, 0
    jne obtenerElevadoTo10   
    ret 
    
; Convertira la cadena del segundo operando en un numero
; donde sera almacenado en oper2    
convertirStringToNumero2:
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx
    mov cx, 0        ;  Pues sera primero 10^0
    add di, contador2 ; Apuntara ahora a la ultima posicion.
obtenerElevadoTo102:
    cmp cx, 0
    je primeraVez2
    mov ax, 10
    mul cx           ; cx * 10, cx * 100, ...
    mov cx, ax
    jmp convertirCaracterToNumero2    
primeraVez2:
    mov cx, 1 ; La primera vez es 10^0 = 1
convertirCaracterToNumero2:    
    dec di        ; Apuntara a nuestro actual caracter.  
    mov al, [di]  
    sub al, 30h
    mov ah, 0
    mul cx        ; ax * cx    
    add oper2, ax 
    dec contador2
    cmp contador2, 0
    jne obtenerElevadoTo102   
    ret  

setFlagMulFirst:
    mov flagMulFirst, 0
    jmp suma   
    
iterarCadena:  
    inc si
    mov al, [si]
    cmp al, 0
    jne iterarCadena
    ret     
    
leecad:
    push di
    push si ; Respaldando nuestra posicion del arreglo que apunta a linea.
    push cx ; Respaldando el tamano de la cadena a recibir.
    push ax
    mov [t_linea], cl

; Encargado de obtener la cadena que el usuario ponga.
ntecla:
    jcxz enc        ; Jump if cx = 0. 
    mov ah, 0
    int 16h
    
    mov [si], al    ; Ingresar el caracter a nuestra cadena linea.           
    inc si
    dec cx
    cmp al, 1bh     ; If ESC was pressed, jump to FINCAD.
    jne sigue     
    mov [salir], 1  
    jmp FINCAD 

sigue:
    cmp al, 0dh     ; If ENTER was pressed jump to FINCAD.
    je FINCAD
    cmp al, 08h     ; If DELETE key was pressed.
    je borra        
    mov ah, 0eh
    int 10h         ; Print the character.
    jmp ntecla                             

; Borrara el caracter previo, pues al parecer escribe un caracter en blanco
; en el caracter que se va a "borrar".     
borra:                            
    dec si
    dec si              
    mov [si], 20h ; Caracter en blanco sobre lo que queremos borrar. 
    inc cx  ; ? Por que inc cx dos veces?
    mov ah, 0eh ; ?
    int 10h
    mov al, 20h 
    int 10h     ; Escribe un caracter en blanco.   
    mov al, 08h 
    int 10h     ; Pondra el cursor en la posicion anterior.
    jmp ntecla   
    
FINCAD:
    dec si
    mov ah,0eH  ; ?  
    mov al,0dH  ; ?      
    int 10h     ; ?
    mov al, 0ah ; ?
    int 10h     ; ?
    sub [t_linea], cl
    pop ax
    pop cx
    pop si
    pop di
    ret

continue:
    mov contador, 0
    jmp op0
      
enc:
    call imprime 
    mov dh, 03
    mov dl, 0
    mov bh, 0
    mov ah, 2
    int 10h  
    lea si, linea ; Volver a posicionar a la primera posicion de linea, pues se encuentra en la ultima posicion de linea.
    mov cx, 19
    call limpia 
    call limpiarPantalla
    
    ; msg1     
    mov dx, 0700h
    mov bx, 0
    mov bl, 0011_1011b   
    mov cx, msg1Size
    mov al, 01b
    mov bp, msg1
    mov ah, 13h
    int 10h
    
    ; msg2 
    mov dx, 0800h
    mov bx, 0
    mov bl, 0011_1011b   
    mov cx, msg2Size
    mov al, 01b
    mov bp, msg2  
    mov ah, 13h
    int 10h

    ; msg3
    mov dx, 0A00h
    mov bx, 0
    mov bl, 0011_1011b   
    mov cx, msg3Size
    mov al, 01b
    mov bp, msg3
    mov ah, 13h
    int 10h         
    
    lea si, linea
    mov cx, 20
    jmp ntecla
    

imprime:         
    push ax
    push bx
    push cx
    
    ; msg4
    mov dx, 0B00h
    mov bx, 0
    mov bl, 0011_1011b   
    mov cx, msg4Size
    mov al, 01b
    mov bp, msg4
    mov ah, 13h
    int 10h
    mov ah, 0
    int 16h 
    pop cx
    pop bx
    pop ax      
    ret 
   

; Limpia el arreglo de caracteres que se encuentra en la memoria, este es el arreglo que el usuario puso; si contiene linea.   
; Se hace push tanto en si como en cx porque queremos guardar los valores y recuperarlos,
; sobre todo SI, que contendra la direccion donde apunta al inicio del arreglo, pues al final
; de limpia, como incrementamos SI, ya no apuntaria al inicio del arrelgo.     
limpia:
    push si
    push cx
l_lim:
    mov [si], 0
    inc si
    loop l_lim
    pop cx
    pop si
    ret

limpiarPantalla: 
    mov ah, 0
    mov al, 3
    int 10h
    ret

; Convertir a ascii.
asc2num:
        sub     al,48
        cmp     al,9
        jle     f_asc
        sub     al,7
        cmp     al,15
        jle     f_asc
        sub     al,32
f_asc:  ret        

; Fin del programa.
fin:        
    mov bx, 0h
    cmp flagMulDivTermino, 0   ; Acabo de analizar todas las multiplicaciones y divisiones.
    je verdadero
    
    ; msg4
    mov dx, 0D00h
    mov bx, 0
    mov bl, 0001_1011b   
    mov cx, msg5Size
    mov al, 01b
    mov bp, msg5
    mov ah, 13h
    int 10h
    
    xor dx, dx
    xor bx, bx  
    xor ax, ax
    mov cx, 0        ; Contador que nos va ayudar saber cuantos elementos hay en la pila.
    mov ax, auxOper  
    
    ; Comprobar si el resultado es negativo, si lo es, saltar para convertirlo a complemento 2.
    ;test ax, 80h
    ;jne esNegativo
    
    cmp ax, 9        ; Si nuestro resultado es mayor a 9.
    ja fin2
          
    add al, 30h
    mov ah, 0eh
    int 10h
    
    xor ax, ax
    int 20h

; Convertir el numero de negativo a positivo, complemento 2.
esNegativo:
    neg ax
    mov b.auxOper, al
    ; Debido que a la hora de usar neg ah queda con valores en ah, estos valores interfieren
    ; a la hora de comparar si el resultado es mayor a 9, por lo cual se limpia y se 
    ; vuelve asignar el valor convertido a ax.
    xor ax, ax
    mov ax, b.auxOper 
    
    cmp ax, 9        ; Si nuestro resultado es mayor a 9.
    ja fin3
    
    mov al, '-'
    mov ah, 0eh
    int 10h
    
    mov ax, b.auxOper 
    add ax, 30h
    mov ah, 0eh
    int 10h
    
    xor ax, ax
    int 20h

; Como es mayor a 9 y el resultado es hexadecimal, se convierte a decimal.   
fin2:    
    inc cx  
    mov dx, 0h
    mov bx, 10
    div bx   
    push dx
    cmp ax, 0
    jnz fin2
    jmp poop


; fin3 sera usado para hacer las operaciones correspondientes al numero convertido. 
fin3:
    inc cx  
    mov dx, 0h
    mov bx, 10
    div bx   
    push dx
    cmp ax, 0
    jnz fin3
    
    mov al, '-'
    mov ah, 0eh
    int 10h
    
    jmp poop
    
; Iterar para sacar los numeros de la pila e imprimirlos en la pantalla.
poop:
    pop dx
    dec cx  
    
    mov ax, dx
    add ax, 30h
    mov ah, 0eh
    int 10h
    
    cmp cx, 0
    jne poop
    
    xor ax, ax
    int 20h    

; Pondra la bandera como verdadero (1) indicando que las multiplicaciones y divisiones se realizaron con exito.
; En este punto se debe tener una cadena con puras sumas, restas o combinadas.
verdadero:                     
    mov flagMulDivTermino, 01h
    je nvocar

msg1: db "Practica 6, Implementacion"
msg2: db "Ingrese una cadena de caracteres de menos de 20 caracteres"
msg3: db "Debera ingresar una ecuacion aritmetica valida, no use parentesis y solo numeros enteros: " 
msg4: db "Excede el numero de caracteres, presione una tecla para continuar" 
msg5: db "El resultado es: "   

msgTail:
    msg1Size = msg2 - msg1  
    msg2Size = msg3 - msg2 
    msg3Size = msg4 - msg3
    msg4Size = msg5 - msg4
    msg5Size = msgTail - msg5
 
  