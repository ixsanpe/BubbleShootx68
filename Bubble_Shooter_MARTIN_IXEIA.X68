*-----------------------------------------------------------
* Title      : BUBBLE SHOOTER
* Written by : Martin Bertol e Ixeia Sanchez
* Date       : 20/05/2019
* Description: Trabajo SMICRO
*-----------------------------------------------------------

SIZE EQU 30
ORIX EQU 20 *donde colocamos el mapa en el visualizador
ORIY EQU 20

RANGO EQU 5

******************************** Programa Principal ************************************
    ORG    $1000
 
START    
 
*    MOVE.B #0,PUNTOS
    MOVE.B #0,CONTADORBAJARFILA     *Para iniciar el contador
*Hacemos el recuadro blanco   
    MOVEM.L D0-D1/A4,-(A7)      
    MOVE.L #$00FFFFFF,D1                
    MOVE.L #81,D0
    TRAP #15                    *En este momento tenemos el COLOR de la bola que queremos dibujar
    MOVEM.L (A7)+,D0-D1/A4      *Recuperamos los registros donde teniamos: D0 color que contiene mapa, D1: size (14), A4: vuelve a 0, ya no señala tabla

    MOVE.L #15,D1
    MOVE.L #15,D2    
    JSR RECUADROBLANCO
    
RECUADROBLANCO
    MOVE.L #87,D0   *Circulo CON relleno
    MOVE.L D1,D3
    MOVE.L D2,D4    *Copio coordenadas esquina izquierda en D3,D4
    ADD.L #325,D3
    ADD.L #420,D4  *Creo coordenadas esquina derecha separándolas SIZE pixels
    TRAP #15
 
             
    MOVE.L #80,D0           *Cambiamos el pen color a BLANCO
    MOVE.L D1,D5
    MOVE.L #$00FFFFFF,D1
    TRAP #15
    MOVE.L D5,D1 
    
    
    JSR SHOWMAP             *1) Saltamos a la subrutina que nos dibuja el mapa
    *Primera bola
    JSR PRIMERABOLA
    *Bola pequeña    
    JSR BALL                *Subrutina que dibuja una bola en la parte inferior

*Aquí va lo de clicar en la pantalla y la dirección obtenida se guarda en A3
LOOP
    MOVE.L #61,D0
    MOVE.L #0,D1
    TRAP #15
            
    BTST #0,D0   *Comprueba el bit 0 (corresponde con click izqdo)
    BEQ LOOP     *Si no hay click izqdo, se mantiene el bucle
            
    CLR.L D2
    SWAP D1      *En D1 tenemos 00|YY|00|XX
    MOVE.W D1,D2
    EXT.L D2     *Extiende el signo de Word a Long (para incluir negativos)
    CLR.W D1
    SWAP D1      *Hemos pasado Y a D2 y dejamos X en D1
    EXT.L D1     *Extiende el signo de Word a Long (para incluir negativos)
            
           
*Empezamos con la coordenada Y
    SUB.L #ORIY,D2   *Restamos el borde superior
    DIVU #SIZE,D2     *Primero resto, luego cociente 
    *SWAP D2
    AND.L #$0000FFFF,D2
    ADD.L #1,D2     *Le añadimos 1 para empezar en la fila 1. Esta en el D2 el num fila  
            
*Continuamos con la coordenada X  
    SUB.L #ORIX,D1   *Restamos el borde superior
    MOVE.L D2,D3    *Esto lo hago para mantener D2 intacto (Y)
    DIVU #2,D3      *Esto es para saber si estoy en una fila par o impar (voy a mirar si el resto es exacto o no) 
    SWAP D3
    AND.L #$0000FFFF,D3 *Para quedarme solo con el resto
    CMP.B #0,D3
    BNE IMPAR
    SUB.L #SIZE/2,D1    *Solo lo hace si es par          
IMPAR            
    DIVU #SIZE,D1    *Divido la X
    AND.L #$0000FFFF,D1
    ADD.L #1,D1     *Le añadimos 1 para empezar en la columna 1  

    *D1 columna (X), D2 fila(Y)            
    *Ahora que tenemos la columna y la fila en D1 y D2 respectivamente, seguimos con la posicion de la memoria
    MULU #12,D2
    ADD.L #$4000,D2
    ADD.L D1,D2     *Tenemos la direccion de memoria donde ponemos la bola en D2
    MOVE.L D2,A3
    MOVE.L A3,GUARDARDIRECCION

    *Dibujar bola disparada o no
    CMP.B #0,(A3)
    BNE LOOP
    MOVE.B COLORGRANDE,(A3)
    MOVE.B COLORBOLA,COLORGRANDE
    JSR SHOWMAP
    JSR BOLAGRANDE
    JSR BALL
    MOVE.L GUARDARDIRECCION,A3
     
    *MOVE.L #$4044,A3        *La bola con la que comparamos los colores "DISPARADA" manualmente
    
    MOVE.L #$0,INICIOMAPA   *Etiqueta que utilizaremos para diferenciar los 3 mapas
    MOVE.B #0,CONTNEWBALLS


    MOVE.L #23,D0           *DELAY   
    MOVE.L #50,D1
    TRAP #15
    
    JSR EXPLOTAR            *2) Subrutina en la que comparamos las bolas del mismo color que la disparada
   
INICIOCOLOR

    MOVE.L #MAPACOLOR+13,A3 *Posición de la primera casilla real
    MOVE.L #$1000,INICIOMAPA
    MOVE.L A3,LASTDIR
    
NEXTCOLOR                   *OJO!!! NUNCA LLEGAMOS AQUI PORQUE SALTAMOS DESDE FINAL DE LA SUBRUTINA
    JSR RECORREMAPACOLOR
REPETICION
    MOVE.B #1,D0
    ADD.B D0,REPETIR
    CMP.B #10,REPETIR
    BNE INICIOCOLOR
    
VACIADO                     * 3) Vaciado de las bolas del mismo color. Venimos desde SUBRUTINA EXPLOTAR --> Recorremapacolor
    CMP.B #03,CONTNEWBALLS
    BCS COMPROBACIONDESCOLGADAS *BCS: si es menor que no vacía y salta a comparar las descolgadas
    JSR VACIARMAPA3
     
COMPROBACIONDESCOLGADAS
    
*    MOVEM.L D5,-(A7)
*    MOVE.B PUNTUACION,D5    *Guardamos la puntuacion
*    ADD.B D5,PUNTOS
*    MOVEM.L (A7)+,D5
    
    MOVEM.L A3,-(A7)
    MOVE.L #MAPA+13,A3
COMPROBACIONDESCOLGAR       *Mira si la primera fila de MAPADESCOLGADO tienen que ser todo unos o no
    CMP.L #$4017,A3
    BEQ DESCOLGAR
    CMP.B #0,(A3)+
    BNE COMPROBACIONDESCOLGAR
    ADD.L #$1FFF,A3
    MOVE.B #0,(A3)
    SUB.L #$1FFF,A3
    CMP.L #$4017,A3
    BNE COMPROBACIONDESCOLGAR
    MOVEM.L (A7)+,A3
DESCOLGAR
    JSR DESCOLGADAS         * 4) Subrutina que guarda un 0 en las que no tienen camino (sueltas)
    
REPETICION2
    MOVE.B #1,D0
    ADD.B D0,REPETIR2
    CMP.B #10,REPETIR2
    BNE DESCOLGAR           
    
VACIADO2
    JSR VACIARMAPA5         * 5) Elimina las del mapadescolgado con un 0

NUEVAVUELTA                 * 6) Ha terminado un disparo y limpia los dos mapas auxiliares

    MOVE.L #ORIX,D1         *Primero limpiamos el descolgado, menos la primera linea
    MOVE.L #ORIX,D2
    MOVE.L #MAPADESCOLGADO+25,A3
LOOPMAP7
    MOVE.B (A3)+,D0
    CMP.B #$80,D0
    BEQ NEXTROW7
    SUB.L #1,A3
    MOVE.B #$00,(A3)+
    JMP LOOPMAP7
NEXTROW7
    MOVE.L #ORIX,D1
    ADD.L #SIZE,D2
    CMP.B #$40,(A3)+
    BNE NODESPL7
    ADD.L #SIZE/2,D1
NODESPL7
    CMP.B #$80,(A3)
    BNE LOOPMAP7
    
    MOVE.L #ORIX,D1         *Limpiamos el mapa color
    MOVE.L #ORIX,D2
    MOVE.L #MAPACOLOR+13,A3
LOOPMAP8
    MOVE.B (A3)+,D0
    CMP.B #$80,D0
    BEQ NEXTROW8
    SUB.L #1,A3
    MOVE.B #$00,(A3)+
    JMP LOOPMAP8
NEXTROW8
    MOVE.L #ORIX,D1
    ADD.L #SIZE,D2
    CMP.B #$40,(A3)+
    BNE NODESPL8
    ADD.L #SIZE/2,D1
NODESPL8
    CMP.B #$80,(A3)
    BNE LOOPMAP8    
    
DELAYFALLOS                 *Evitar dobles clicks y cambios de color
    MOVE.L #23,D0
    MOVE.L #50,D1
    TRAP #15 
    
    ADD.B #1,CONTADORBAJARFILA
    CMP.B #5,CONTADORBAJARFILA
    BNE NOBAJARFILA  

BAJARFILA
    MOVE.B #0,CONTADORBAJARFILA
    MOVE.L #$4084,A3
    MOVE.B #0,CONTADORBAJAR
BUCLEBAJAR
    ADD.L #1,A3
    MOVE.B (A3),BAJABOLA
    ADD.L #12,A3
    MOVE.B BAJABOLA,(A3)
    SUB.L #12,A3
    CMP.B #$80,(A3)
    BNE BUCLEBAJAR
    SUB.L #23,A3
    ADD.B #1,CONTADORBAJAR
    CMP.B #11,CONTADORBAJAR
    BEQ CREANUEVAFILA
    JMP BUCLEBAJAR
CREANUEVAFILA
    MOVE.L #$400D,A3
BUCLEFILANUEVA
    JSR BALL2

    MOVE.L #23,D0
    MOVE.L #10,D1
    TRAP #15 
    
    MOVE.B BOLALEATORIA,(A3)+
    CMP.L #$4017,A3
    BNE BUCLEFILANUEVA
    
*Hacemos el recuadro blanco de nuevo para eliminar las que coinciden con un hueco   
    MOVEM.L D0-D1/A4,-(A7)      
    MOVE.L #$00FFFFFF,D1                
    MOVE.L #81,D0
    TRAP #15                   
    MOVEM.L (A7)+,D0-D1/A4      
    
    MOVE.L #15,D1
    MOVE.L #15,D2    
    JSR RECUADROBLANCO2
    
RECUADROBLANCO2
    MOVE.L #87,D0   *Circulo CON relleno
    MOVE.L D1,D3
    MOVE.L D2,D4    *Copio coordenadas esquina izquierda en D3,D4
    ADD.L #325,D3
    ADD.L #385,D4  *Creo coordenadas esquina derecha separándolas SIZE pixels
    TRAP #15

    JSR SHOWMAP
    
    *Aqui tiene que volver a hacer descolgadas
    
NOBAJARFILA

    *Puntuacion a un registro en ASCII
    
*    MOVE.L PUNTOS,D0
*    MOVE.L #NUMASC,A0
*    JSR ITOA
*    
*    JMP SHOWPUNTOS
*    
*ITOA    MOVEM.L A0-A1/D0,-(A7)  
*        MOVE.L A0,A1 *Hace una copia del inicio de la cadena
*BUCDIG
*        DIVU #10,D0
*        SWAP D0
*        ADD.B #$30,D0   *Suma
*        MOVE.B D0,(A0)+ *Va guardando los restos de dividir por 10
*        CLR.W D0        *Borra el resto ya almacenado
*        SWAP D0         *Recupera el cociente para seguir dividiendo
*        BEQ FINDIGS
*        JMP BUCDIG  
*    
*FINDIGS *Pasamos a invertir la cadena porque las cifras se calculaban
*        *en orden inverso
* 
*        MOVE.B #0,(A0)  *Marca de fin de cadena
*INVERT              *Intercambia los dígitos del final con los del principio.
*        MOVE.B -(A0),D0 *Usa D0 como registro intermedio                    
*        CMP.L A1,A0     *¿Se han encontrado los registros en el centro?
*        BCS FINITOA     *Si es así, hemos acabado
*        MOVE.B (A1),(A0) *Intercambiando valores
*        MOVE.B D0,(A1)+
*        JMP INVERT      *bucle
*FINITOA
*        MOVE.B #0,(A0)
*        MOVEM.L (A7)+,A0-A1/D0
*        RTS 
* 
*SHOWPUNTOS
*
*    MOVE.L #80,D0           *Cambiamos el pen color a BLANCO
*    MOVE.L D1,D5
*    MOVE.L #$00000000,D1
*    TRAP #15
*    MOVE.L D5,D1 
*    
*    MOVEM.L D1-D2/A1,-(A7)
*    MOVE.L #PUNTOS,A1
*    
*    MOVE.W #400,D1
*    MOVE.W #60,D2
*    MOVE.L #95,D0
*    TRAP #15
*    MOVEM.L (A7)+,D1-D2/A1
   
    JMP LOOP
FIN 
        
    SIMHALT 
    
*FIN PROGRAMA PRINCIPAL

  

            
SHOWMAP ******************************** 1) Subrutina que muestra el estado del mapa en las coordenadas ORIX, ORIY ************************************
    
    MOVE.L #ORIX,D1
    MOVE.L #ORIY,D2         *Coordenadas iniciales del tablero
    MOVE.L #MAPA+13,A3      *Posición de la primera casilla real
   
LOOPMAP
    MOVE.B (A3)+,D0         *Obtiene el contenido
    CMP.B #$80,D0
    BEQ NEXTROW
    CMP.B #$00,D0
    BEQ EMPTY               *Está vacía 
    JSR COLOUR              *Coge el color y va directamente a FILLED
    
FILLED
    JSR FILLEDSQUARE
    ADD.L #SIZE,D1
    JMP LOOPMAP    
        
EMPTY
    JSR EMPTYSQUARE
    ADD.L #SIZE,D1
    JMP LOOPMAP
    
COLOUR                          
    MOVEM.L D0-D1/A4,-(A7)      *Nos mueve el contenido D0,D1,A4 a (A7). Se queda señalando a la dir mas baja (donde empieza D0)
    MOVE.L #TABLA,A4            *La dir donde tenemos los colores
    MULU #4,D0  * o LSL #2,D0   *Si el color es 2, esta en la dir de TABLA+2*4 (porque es LONG)
    MOVE.L (A4,D0),D1           *Combina A4=$6090 con D0=8 --> Mueve a D1 lo que contiene la posicion $6098(Long) EL COLOR
    MOVE.L #81,D0
    TRAP #15                    *En este momento tenemos el COLOR de la bola que queremos dibujar
    MOVEM.L (A7)+,D0-D1/A4      *Recuperamos los registros donde teniamos: D0 color que contiene mapa, D1: size (14), A4: vuelve a 0, ya no señala tabla
    RTS        
    
NEXTROW
    MOVE.L #ORIX,D1         *Retorno coordenada X inicial
    ADD.L #SIZE,D2          *Avance coordenada Y
    CMP.B #$40,(A3)+
    BNE NODESPL
    ADD.L #SIZE/2,D1
    
NODESPL                 
    CMP.B #$80,(A3)
    BNE LOOPMAP 
    RTS                    *Termina de recorrer mapa (todas filas y columnas)
                           *Vuelve a PROGRAMA PRINCIPAL (JSR SHOWMAP)
                                                      

******************************** 2) Subrutina de comparacion de la bola disparada ************************************  
EXPLOTAR1
    SUB.L #1,A3
    MOVE.L A3,LASTDIR
    ADD.L #1,LASTDIR
EXPLOTAR
    
    SUB.L INICIOMAPA,A3
    MOVE.L A3,A5
    MOVE.L A3,A6
    ADD.L INICIOMAPA,A3
    
    MOVE.L A5,D6           *Pasos que utilizamos para comprobar si estamos en fila par o impar
    SUB.L #$4000,D6
    DIVU #12,D6
    SWAP D6
    AND.L #$000000FF,D6
    SUB.L D6,A5
    MOVE.L #1,D6
    CMP.B #$40,(A5)
    BEQ FILAPAR
    JSR FILAIMPAR

FILAPAR                    *Comparacion de las de alrededor de una fila par
    MOVE.L A6,A5
    
    SUB.L #12,A5
    JSR COMPARACION 
    ADD.L #1,A5
    JSR COMPARACION
    ADD.L #10,A5
    JSR COMPARACION 
    ADD.L #2,A5  
    JSR COMPARACION
    ADD.L #11,A5  
    JSR COMPARACION 
    ADD.L #1,A5  
    JSR COMPARACION 
    
    MOVE.L LASTDIR,D1
    CMP.L #$FFFFFFFF,D1
    BEQ INICIOCOLOR
    JMP RECORREMAPACOLOR2     
    

FILAIMPAR                   *Comparacion de las de alrededor de una fila impar
    MOVE.L A6,A5
    
    SUB.L #13,A5
    JSR COMPARACION 
    ADD.L #1,A5
    JSR COMPARACION
    ADD.L #11,A5
    JSR COMPARACION 
    ADD.L #2,A5  
    JSR COMPARACION
    ADD.L #10,A5  
    JSR COMPARACION 
    ADD.L #1,A5  
    JSR COMPARACION 
   
    MOVE.L LASTDIR,D1
    CMP.L #$FFFFFFFF,D1
    BEQ INICIOCOLOR
    JMP RECORREMAPACOLOR2          
    
    
COMPARACION             *SUBRUTINA QUE COMPARA EL COLOR DE LA BOLA DISPARADA Y LAS DE ALREDEDOR
    MOVE.B (A5),D7
    MOVE.B (A6),D5 *ESTAMOS MACHACANDO D5 QUE LO USABAMOS PARA EL COLOR DEL PEN
    CMP.L D5,D7
    BEQ METERUNO
    RTS
    
METERUNO 
    ADD.L #$1000,A5
    CMP.B #$01,(A5)
    BEQ AVANCE 
    MOVE.B #1,D5
    MOVE.B D5,(A5)
    ADD.L #1,D6
    ADD.B #1,CONTNEWBALLS
    
AVANCE    
    SUB.L #$1000,A5
    RTS   
    
    ************************** Continuacion de la subrutina que compara las bolas del mismo color *********************
RECORREMAPACOLOR2 
    ADD.L #1,A3
    MOVE.L D1,LASTDIR
    ADD.L #1,LASTDIR

RECORREMAPACOLOR

LOOPMAP2    
    MOVE.B (A3)+,D0 *Obtiene el contenido
    CMP.B #$80,D0
    BEQ NEXTROW2
    CMP.B #$01,D0
    BEQ EXPLOTAR1               *Compara la siguiente bola con un 1 en MAPACOLOR
    JMP LOOPMAP2
    
NEXTROW2
    MOVE.L #ORIX,D1 *Retorno coordenada X inicial
    ADD.L #SIZE,D2  *Avance coordenada Y
    CMP.B #$40,(A3)+
    BNE NODESPL2
    ADD.L #SIZE/2,D1
    
NODESPL2
    CMP.B #$80,(A3)
    BNE LOOPMAP2
    JMP REPETICION             * Volvemos al programa principal despues de recorrer todo el mapa
                               * (Si ponemos RTS vuelve a JSR IMPAR y se lia parda) 
    

******************************** 3) EXPLOSION de las BOLAS que tienen 1 en MAPACOLOR ************************************
VACIARMAPA3
*    MOVE.B #0,PUNTUACION
*    MOVE.B CONTNEWBALLS,PUNTUACION
*    MOVE.L D5,-(A7)
*    MOVE.B PUNTUACION,D5
*    MULU #10,D5
*    MOVE.B D5,PUNTUACION
*    MOVE.L (A7)+,D5
    
    MOVE.L #ORIX,D1
    MOVE.L #ORIY,D2 *Coordenadas iniciales del tablero

*VACIARMAPA
    MOVE.L #MAPACOLOR+13,A3 *Posición de la primera casilla real
    MOVE.L #$1000,INICIOMAPA
    
LOOPMAP3    
    MOVE.B (A3)+,D0 *Obtiene el contenido
    CMP.B #$80,D0
    BEQ NEXTROW3
    CMP.B #$01,D0
    BEQ COLOUR3
    JSR EMPTY3
    JMP LOOPMAP3
    
EMPTY3
    JSR EMPTYSQUARE
    ADD.L #SIZE,D1
    JMP LOOPMAP3 
   
COLOUR3
    MOVE.L D1,-(A7)      *Nos mueve el contenido D1 (A7). Se queda señalando a la dir mas baja (donde empieza D1)
    MOVE.L #$0,D1
    MOVE.L #81,D0
    TRAP #15                   *En este momento tenemos el COLOR de la bola que queremos dibuja
    MOVE.L (A7)+,D1      *Recuperamos los registros donde teniamos: D0 color que contiene mapa, D1: size (14), A4: vuelve a 0, ya no señala tabla
     
FILLED3 
    SUB.L #$1001,A3
    MOVE.B #$00,(A3)
    ADD.L #$1001,A3
    JSR FILLEDSQUARE
    ADD.L #SIZE,D1
    JMP LOOPMAP3    
    
NEXTROW3
    MOVE.L #ORIX,D1 *Retorno coordenada X inicial
    ADD.L #SIZE,D2  *Avance coordenada Y
    CMP.B #$40,(A3)+
    BNE NODESPL3
    ADD.L #SIZE/2,D1
    
NODESPL3
    CMP.B #$80,(A3)
    BNE LOOPMAP3
    *CMP.B CONTNEWBALLS,D6
    *BNE INICIOCOLOR
    JMP COMPROBACIONDESCOLGADAS


**************** 4) Subrutina de las bolas descolgadas *********************
DESCOLGADAS
    MOVE.L #ORIX,D1
    MOVE.L #ORIY,D2 *Coordenadas iniciales del tablero
    MOVE.L #MAPA+13,A3 *Posición de la primera casilla real
    
LOOPMAP4
    MOVE.B (A3)+,D0 *Obtiene el contenido
    CMP.B #$80,D0
    BEQ NEXTROW4
    CMP.B #$00,D0
    BNE UNOADYACENTE       *SI TIENE UNA BOLA MIRO LAS ADYACENTES
    ADD.L #SIZE,D1
    JMP LOOPMAP4    
             
NEXTROW4
    MOVE.L #ORIX,D1 *Retorno coordenada X inicial
    ADD.L #SIZE,D2  *Avance coordenada Y
    CMP.B #$40,(A3)+
    BNE NODESPL4
    ADD.L #SIZE/2,D1
    
NODESPL4
    CMP.B #$80,(A3)
    BNE LOOPMAP4 
    JMP REPETICION2

UNOADYACENTE   
    MOVE.L A3,A5 *ESTO LO HAGO PARA MANTENER INTACTO A3
    MOVE.L A3,A6
    SUB.L #$1,A6
    SUB.L #$1,A5
    MOVE.L A5,D6
    SUB.L #$4000,D6
    DIVU #12,D6
    SWAP D6
    AND.L #$000000FF,D6
    SUB.L D6,A5
    MOVE.L #1,D6
    CMP.B #$40,(A5)
    BEQ FILAPAR2
    JSR FILAIMPAR2

FILAPAR2 
    MOVE.L A6,A5
   
    SUB.L #12,A5
    JSR COMPARACION2 
    ADD.L #1,A5
    JSR COMPARACION2
    ADD.L #10,A5
    JSR COMPARACION2
    ADD.L #2,A5  
    JSR COMPARACION2
    ADD.L #11,A5  
    JSR COMPARACION2
    ADD.L #1,A5  
    JSR COMPARACION2  
    
    JMP LOOPMAP4

FILAIMPAR2
    MOVE.L A6,A5   
    
    SUB.L #13,A5
    JSR COMPARACION2
    ADD.L #1,A5
    JSR COMPARACION2
    ADD.L #11,A5
    JSR COMPARACION2
    ADD.L #2,A5  
    JSR COMPARACION2
    ADD.L #10,A5  
    JSR COMPARACION2
    ADD.L #1,A5  
    JSR COMPARACION2 

    JMP LOOPMAP4       
    
COMPARACION2
    ADD.L #$2000,A5 *SUMO 2000 A LA BOLA CON LA QUE LA ESTOY COMPARANDO
    MOVE.B (A5),D7
    SUB.L #$2000,A5
    CMP.B #$01,D7
    BEQ METERUNOMAPADESC
    RTS
     
METERUNOMAPADESC
    ADD.L #$2000,A3 
    SUB.L #$1,A3    *PARA CORREGIR EL ERROR DEL INCREMENTO
    MOVE.B #1,D5
    MOVE.B D5,(A3)
    ADD.L #$1,A3
    SUB.L #$2000,A3
    JMP LOOPMAP4 
    
**************** 5) Subrutina que elimina las que tienen un 0 en MAPADESCOLGADO ***********************************

VACIARMAPA5
    MOVE.L #ORIX,D1
    MOVE.L #ORIY,D2 *Coordenadas iniciales del tablero

*VACIARMAPA
    MOVE.L #MAPADESCOLGADO+13,A3 *Posición de la primera casilla real
    MOVE.L #$2000,INICIOMAPA
    
LOOPMAP5    
    MOVE.B (A3)+,D0 *Obtiene el contenido
    CMP.B #$80,D0
    BEQ NEXTROW5
    CMP.B #$00,D0
    BEQ COLOUR5
    JSR EMPTY5
    JMP LOOPMAP5
    
EMPTY5
    JSR EMPTYSQUARE
    ADD.L #SIZE,D1
    JMP LOOPMAP5     
      
COLOUR5
    MOVEM.L D0-D1/A4,-(A7)
    MOVE.L #0,D0            ;directamente rellenamos con blanco
    MOVE.L #TABLA,A4
    MOVE.L (A4,D0),D1
    MOVE.L #81,D0
    TRAP #15
    MOVEM.L (A7)+,D0-D1/A4
    
FILLED5
    SUB.L #$2001,A3
    MOVE.B #$00,(A3)
    ADD.L #$2001,A3 
    JSR FILLEDSQUARE
    ADD.L #SIZE,D1
    JMP LOOPMAP5
    
NEXTROW5
    MOVE.L #ORIX,D1 *Retorno coordenada X inicial
    ADD.L #SIZE,D2  *Avance coordenada Y
    CMP.B #$40,(A3)+
    BNE NODESPL5
    ADD.L #SIZE/2,D1
    
NODESPL5
    CMP.B #$80,(A3)
    BNE LOOPMAP5
    JMP NUEVAVUELTA
    
********************* SUBRUTINA DEL CLICK **************************************


********************* SUBRUTINAS DEL PROGRAMA PRINCIPAL ************************
EMPTYSQUARE
    MOVE.L #91,D0   *Circulo SIN relleno (avanza el hueco y no rellena)
    MOVE.L D1,D3
    MOVE.L D2,D4    *Copio coordenadas esquina izquierda en D3,D4
    ADD.L #SIZE,D3
    ADD.L #SIZE,D4  *Creo coordenadas esquina derecha separándolas SIZE pixels
    TRAP #15
    RTS
   
FILLEDSQUARE
    MOVE.L #88,D0   *Circulo CON relleno
    MOVE.L D1,D3
    MOVE.L D2,D4    *Copio coordenadas esquina izquierda en D3,D4
    ADD.L #SIZE,D3
    ADD.L #SIZE,D4  *Creo coordenadas esquina derecha separándolas SIZE pixels
    TRAP #15
    RTS

********************* SUBRUTINA DIBUJAR PRIMERA BOLA ***************************
PRIMERABOLA
    MOVE.B #2,COLORGRANDE
BOLAGRANDE
    MOVE.B COLORGRANDE,D0
    MOVEM.L D0-D1/A4,-(A7)      
    MOVE.L #TABLA,A4            
    MULU #4,D0                  
    MOVE.L (A4,D0),D1           
    MOVE.L #81,D0
    TRAP #15                    
    MOVEM.L (A7)+,D0-D1/A4     

    MOVE.L #155,D1
    MOVE.L #400,D2    
    JSR PRIMERCIRCULO
    
PRIMERCIRCULO
    MOVE.L #88,D0   *Circulo CON relleno
    MOVE.L D1,D3
    MOVE.L D2,D4    *Copio coordenadas esquina izquierda en D3,D4
    ADD.L #SIZE,D3
    ADD.L #SIZE,D4  *Creo coordenadas esquina derecha separándolas SIZE pixels
    TRAP #15
    RTS

********************* SUBRUTINA DIBUJAR BOLA ABAJO *****************************
BALL
    
        JSR INIRND    ;Inicializa la semilla (SOLO SE LLAMA UNA VEZ POR EJECUCIÓN DE PROGRAMA)
        
NEWLIN  MOVE.L #30,D2    ;30 números por línea    
OTRO    MOVE.L #RANGO,D0

        JSR LAB_RND   ;Obtiene un valor entre 0-RANGO

        ADD.L #2,D0    *Esta guardando el numero en D1
  

        SUB.L #1,D2
        BNE OTRO
        MOVE.B D0,COLORBOLA *Guardamos el color de la bola en COLORBOLA
                         
    MOVEM.L D0-D1/A4,-(A7)     
    MOVE.L #TABLA,A4            
    MULU #4,D0                 
    MOVE.L (A4,D0),D1          
    MOVE.L #81,D0
    TRAP #15                    
    MOVEM.L (A7)+,D0-D1/A4      
    
    MOVE.L #185,D1 *155
    MOVE.L #415,D2 *400

    MOVE.L #88,D0   *Circulo CON relleno
    MOVE.L D1,D3
    MOVE.L D2,D4    *Copio coordenadas esquina izquierda en D3,D4
    ADD.L #SIZE/2,D3
    ADD.L #SIZE/2,D4  *Creo coordenadas esquina derecha separándolas SIZE pixels
    TRAP #15   
    RTS

***************************************SUBRUTINAS DEL ALEATORIO***************************************

INIRND                *Esta subrutina inicializa la semilla (variable PRNL) a partir del reloj
        MOVE.L  #8,D0
        TRAP    #15
        MOVE.L D1,PRNL *En D1 obtenemos las centesimas de segundo desde media noche que asignamos a PRNL
        RTS
        
LAB_RND MOVEM.L D1-D3,-(A7) ;guarda registros utilizados
 
        MOVE.L D0,D1
        ADD.L #1,D1       * calculamos el rango para un valor más (luego lo eliminamos)
        MOVE.L #$FFFF,D0
        DIVU D1,D0        * obtiene el factor de escala rango
        AND.L #$FFFF,D0   * elimina resto
        ADD.L #1,D0       * sumamos 1 al factor de escala para eliminar el posible valor de más
        MOVE.L D0,D3      * pasamos factor de escala a D3
       
        MOVE.L  PRNL,D0     * get current seed longword
        MOVEQ       #$AF-$100,d1        * set EOR value
        MOVEQ       #19,d2          * do this 19 times
Ninc0
        ADD.L       d0,d0               * shift left 1 bit
        BCC.S       Ninc1               * if bit not set skip feedback
 
        EOR.B       D1,D0               * do Galois LFSR feedback
Ninc1
        SUBQ #1,D2
        BNE         Ninc0           * loop
 
        MOVE.L  D0,PRNL     * save back to seed longword
   
        SWAP D0      ;Obtiene la palabra alta
        AND.L #$FFFF,D0  ;Se queda con esa palabra 0-65535
       
        DIVU D3,D0       ;aplicamos factor de escala    
        AND.L #$FFFF,D0  ;Se queda solo con el cociente (solo 16 bits)
        MOVEM.L (A7)+,D1-D3
        RTS

********************* SUBRUTINA DIBUJAR BOLAS NUEVAS *****************************
BALL2
    
        JSR INIRND2    ;Inicializa la semilla (SOLO SE LLAMA UNA VEZ POR EJECUCIÓN DE PROGRAMA)
        
NEWLIN2  MOVE.L #30,D2    ;30 números por línea    
OTRO2    MOVE.L #RANGO,D0

        JSR LAB_RND2   ;Obtiene un valor entre 0-RANGO
        ADD.L #2,D0    
  
        SUB.L #1,D2
        BNE OTRO2
        MOVE.B D0,BOLALEATORIA 
        
INIRND2                *Esta subrutina inicializa la semilla (variable PRNL) a partir del reloj
        MOVE.L  #8,D0
        TRAP    #15
        MOVE.L D1,PRNL2 *En D1 obtenemos las centesimas de segundo desde media noche que asignamos a PRNL
        RTS
        
LAB_RND2 MOVEM.L D1-D3,-(A7) ;guarda registros utilizados
 
        MOVE.L D0,D1
        ADD.L #1,D1       * calculamos el rango para un valor más (luego lo eliminamos)
        MOVE.L #$FFFF,D0
        DIVU D1,D0        * obtiene el factor de escala rango
        AND.L #$FFFF,D0   * elimina resto
        ADD.L #1,D0       * sumamos 1 al factor de escala para eliminar el posible valor de más
        MOVE.L D0,D3      * pasamos factor de escala a D3
       
        MOVE.L  PRNL2,D0     * get current seed longword
        MOVEQ       #$AF-$100,d1        * set EOR value
        MOVEQ       #19,d2          * do this 19 times
Ninc02
        ADD.L       d0,d0               * shift left 1 bit
        BCC.S       Ninc12               * if bit not set skip feedback
 
        EOR.B       D1,D0               * do Galois LFSR feedback
Ninc12
        SUBQ #1,D2
        BNE         Ninc02           * loop
 
        MOVE.L  D0,PRNL2     * save back to seed longword
   
        SWAP D0      ;Obtiene la palabra alta
        AND.L #$FFFF,D0  ;Se queda con esa palabra 0-65535
       
        DIVU D3,D0       ;aplicamos factor de escala    
        AND.L #$FFFF,D0  ;Se queda solo con el cociente (solo 16 bits)
        MOVEM.L (A7)+,D1-D3
        RTS

********************* Variables y constantes ***********************************    

    ORG $4000
   
* Variables and Strings
MAPA
    DC.B $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
    DC.B $80,$02,$07,$06,$04,$05,$03,$07,$05,$02,$05,$80
    DC.B $40,$03,$03,$05,$02,$07,$05,$04,$04,$03,$03,$80
    DC.B $80,$05,$07,$06,$04,$02,$03,$05,$07,$05,$02,$80
    DC.B $40,$04,$04,$05,$03,$02,$02,$04,$06,$06,$07,$80
    DC.B $80,$04,$07,$06,$06,$06,$06,$06,$06,$05,$04,$80
    DC.B $40,$02,$03,$04,$02,$02,$05,$06,$06,$03,$06,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80 
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80   
    DC.B $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
    
    ORG $5000
MAPACOLOR *Aqui guardamos un 1 en la dir que tenga el mismo color que la bola lanzada
    DC.B $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
FINMAPACOLOR
    
    ORG $6000
MAPADESCOLGADO *Aqui guardamos un 1 en la bola que tenga camino hasta el techo
    DC.B $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
    DC.B $80,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80
    DC.B $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80     
    DC.B $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80

TABLA *se puede mejorar con etiquetas
    DC.L $00FFFFFF BLANCO           *TABLA
    DC.L $00000000 FALLO            *TABLA+4: nos daba problemas al guardar 1 como lleno y coincidir con el color ROJO (lo reordenamos)
    DC.L $000EB30E VERDE OSCURO     *TABLA+8
    DC.L $00FF0000 AZUL             *TABLA+12
    DC.L $00FF00FF MAGENTA          *TABLA+16   
    DC.L $000DDDE3 AMARILLO OSCURO  *TABLA+20
    DC.L $00EED910 CIAN OSCURO      *TABLA+24
    DC.L $000000FF ROJO             *TABLA+28

CONTNEWBALLS DS.B 1
*PUNTUACION DS.B 1
*PUNTOS DS.B 1
*NUMASC  DS.B 10
*MENSAJE DC.B 'PUNTUACION ',0

INICIOMAPA DS.L 1
LASTDIR DS.L 1
REPETIR DS.B 1
REPETIR2 DS.B 1

GUARDARDIRECCION DS.L 1

COLORBOLA DS.B 1
COLORGRANDE DS.B 1
BOLALEATORIA DS.B 1

BAJABOLA DS.B 1
CONTADORBAJAR DS.B 1
CONTADORBAJARFILA DS.B 1


PRNL    DS.L 1
PRNL2    DS.L 1

    END    START






























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
