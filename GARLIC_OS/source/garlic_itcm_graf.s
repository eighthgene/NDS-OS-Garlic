@;==============================================================================
@;
@;	"garlic_itcm_graf.s":	código de rutinas de soporte a la gestión de
@;							ventanas gráficas (versión 2.0)
@;
@;==============================================================================

NVENT	= 16				@; número de ventanas totales
PPART	= 4					@; número de ventanas horizontales o verticales
							@; (particiones de pantalla)
L2_PPART = 2				@; log base 2 de PPART

VCOLS	= 32				@; columnas y filas de cualquier ventana
VFILS	= 24
PCOLS	= VCOLS * PPART		@; número de columnas totales (en pantalla)
PFILS	= VFILS * PPART		@; número de filas totales (en pantalla)

WBUFS_LEN = 68				@; longitud de cada buffer de ventana (64+4)


.section .itcm,"ax",%progbits

	.arm
	.align 2



	.global _gg_escribirLinea
	@; Rutina para escribir toda una linea de caracteres almacenada en el
	@; buffer de la ventana especificada;
	@;Parámetros:
	@;	R0: ventana a actualizar (int v)
	@;	R1: fila actual (int f)
	@;	R2: número de caracteres a escribir (int n)
_gg_escribirLinea:
	push {r0-r11,lr}
	cmp r2, #0
	beq .LfinEscribLinea
	
	ldr r3, =ptrMapa2
	ldr r3, [r3]			@; r3 = @ptrMapa2(@ inicial)
	
	mov r4, #VFILS
	mov r5, r0, lsr #L2_PPART	@; r5 = fila = v/PPART
	mul r5, r4, r5			@; r5 = fila = (v/PPART) * VFILS
	mov r4, #PCOLS
	mul r5, r4, r5			@; r5 = fila = (v/PPART) * VFILS * PCOLS
	
	mov r4, #PPART
	sub r4, #1
	and r6, r0, r4			@; r6 = col = v%PPART
	mov r4, #VCOLS			
	mul r6, r4, r6			@; r6 = col = (v%PPART) * VCOLS
	
	
	add r9, r5, r6			@; r9 = fila + col
	mov r4, #PCOLS			
	mul r10, r4, r1			@; r10 = PCOLS * f
	add r9, r10				@; r9 = (fila + col) + (PCOLS * f)
	mov r9, r9, lsl #1		@; r9 = r9 * 2 (cada baldosa = 2Bytes)
	
	ldr r7, =_gd_wbfs		@; r7 = @ _gd_wbfs
	mov r4, #WBUFS_LEN
	mul r8, r0, r4			@; r8 = [v] (desplzamiento para situar el buffer de la ventana)
	add r8, r7				@; r8 = _gd_wbfs[v]
	add r8, #4				@; r8 = _gd_wbfs[v].pChars[0] (1ª posición de pChars)
	
	mov r11, #0				@; r11  = 0
	mov r5, #0
.LforEscribLinea:
	ldrh r4, [r8,r11]		@; r4 = _gd_wbfs[v].pChars[i] = car
	@;sub r4, #32				@; r4 = car - 32
	strh r4, [r3,r9]		@; ptrMapa2[(fila + col) + PCOLS * f + i] = car 
	add r9, #2
	add r11, #2
	add r5, #1
	cmp r5, r2
	blo .LforEscribLinea

.LfinEscribLinea:
	pop {r0-r11,pc}
	
	
	.global _gg_desplazar
	@; Rutina para desplazar una posición hacia arriba todas las filas de la
	@; ventana (v), y borrar el contenido de la última fila
	@;Parámetros:
	@;	R0: ventana a desplazar (int v)
_gg_desplazar:
	push {r0-r11,lr}
	ldr r1, =ptrMapa2
	ldr r1, [r1]			@; r1 = @ptrMapa2(@ inicial)
	
	mov r2, #VFILS
	mov r3, r0, lsr #L2_PPART	@; r3 = fila = v/PPART
	mul r3, r2, r3			@; r3 = fila = (v/PPART) * VFILS
	mov r2, #PCOLS		
	mul r3, r2, r3			@; r3 = fila = (v/PPART) * VFILS * PCOLS
	
	mov r2, #PPART
	sub r2, #1
	and r4, r0, r2			@; r4 = col = v%PPART
	mov r2, #VCOLS			
	mul r4, r2, r4			@; r4 = col = (v%PPART) * VCOLS
	
	add r5, r3, r4			@; r5 = fila + col = ((v/PPART) * VFILS * PCOLS) + ((v%PPART) * VCOLS)
	mov r5, r5, lsl #1		@; r5 = r5 * 2  "Baldosas = 2 Bytes"
	add r1, r5				@; r1 = @ptrMapa2 + fila + col
	
	mov r6, #0				@; r6 = j
	mov r7, #0				@; r7 = index baldosa
	mov r2, #PCOLS
	mov r2, r2, lsl #1		@; r2 = PCOLS * 2
	mov r10, #0				@; r10 = i
	mov r11, #VFILS			
	sub r11, #1				@; r11 = VFILS - 1
	add r8, r1, r2			@; r8 = fila següent
	
.LforDespl:
	ldrh r9, [r8,r7]
	strh r9, [r1,r7]
	add r7, #2
	add r6, #1
	cmp r6, #VCOLS
	blo .LforDespl
	
	mov r7,#0				@; r7 = index baldosa = 0
	mov r6, #0				@; r6 = j = 0
	add r8, r2				@; Augmentem la fila -> fila següent = fila següent inicial + PCOLS * 2
	add r1, r2
	add r10, #1				@; r10 = i++
	cmp r10, r11
	blo .LforDespl
	
	mov r9, #0				@; r9 = espacio en blanco a escribir en la última fila
.LforDesplUltimaFila:
	strh r9,[r1,r7]
	add r7, #2
	add r6, #1
	cmp r6, #VCOLS
	blo .LforDesplUltimaFila
	
	pop {r0-r11,pc}


	
	
	.global _gg_escribirLineaTabla
	@; escribe los campos básicos de una linea de la tabla correspondiente al
	@; zócalo indicado por parámetro con el color especificado; los campos
	@; son: número de zócalo, PID, keyName y dirección inicial
	@;Parámetros:
	@;	R0 (z)		->	número de zócalo
	@;	R1 (color)	->	número de color (de 0 a 3)
_gg_escribirLineaTabla:
	push {r0-r8,lr}
	mov r4, r0				@; r4 = z
	mov r5, r1				@; r5 = color
	
	@;Escribir el num de z:
	ldr r0, =infoLiniaTabla	@; r0 = @infoLiniaTabla
	mov r1, #3				@; r1 = longitud = 3 (2 dígitos como máximo + centinela)
	mov r2, r4				@; r2 = z
	bl _gs_num2str_dec
	ldr r0, =infoLiniaTabla	@; r0 = @infoLiniaTabla
	add r1, r4, #4			@; r1 = fila = z + 4 filas iniciales
	mov r6, r1				@; r6 = fila = z + 4 filas iniciales (copia)
	mov r2, #1				@; r2 = col de z = 1
	mov r3, r5				@; r3 = color
	bl _gs_escribirStringSub
	
	@; Escribir el PID:
	ldr r7, =_gd_pcbs		@; r7 = @_gd_pcbs
	mov r8, #24				@; r8 = tamaño de cada PCB (6 atributos de int -> 6 * 4 = 24)
	mul r8, r4, r8			@; r8 = z * tamaño de cada PCB
	add r7, r8				@; r7 = @_gd_pcbs + (z * tamaño de cada PCB)
	mov r1, #4				@; r1 = longitud = 4 (3 dígitos como máximo + centinela)
	ldr r2, [r7]			@; r2 = pid
	mov r8, r2				@; r8 = pid (copia)
	cmp r2, #0				@; si (pid != 0) && (z != 0) entonces no se escribe PID y Prog
	bne .LescLinTabContPID
	cmp r4, #0
	bne .LescLinTabContPIDBorra
.LescLinTabContPID:
	ldr r0, =infoLiniaTabla	@; r0 = @infoLiniaTabla
	bl _gs_num2str_dec
	ldr r0, =infoLiniaTabla	@; r0 = @infoLiniaTabla
	b .LescLinTabContPIDEsc
.LescLinTabContPIDBorra:
	ldr r0, =espacioVacio4	@; r0 = @espacioVacio4
.LescLinTabContPIDEsc:
	mov r1, r6				@; r1 = fila
	mov r2, #5				@; r2 = col de pid = 5
	mov r3, r5				@; r3 = color
	bl _gs_escribirStringSub
	
	@; Escribir el Prog:
	cmp r4, #0
	beq .LescLinTabContProg
	cmp r8, #0				@; si (pid != 0)
	bne .LescLinTabContProg 
	ldr r0, =espacioVacio4	@; r0 = @espacioVacio4
	b .LescLinTabContProgEsc
.LescLinTabContProg:
	add r2, r7, #16			@; r2 = @keyname
	ldr r3, [r2]			@; r3 = keyname
	ldr r0, =infoLiniaTabla	@; r0 = @infoLiniaTabla
	str r3, [r0]			@; infoLiniaTabla = keyname
.LescLinTabContProgEsc:
	mov r1, r6				@; r1 = fila
	mov r2, #9				@; r2 = col
	mov r3, r5				@; r3 = color
	bl _gs_escribirStringSub

	@; Escribir separadores:
	mov r0, #0x06200000		@; r0 = @ inicial de VRAM para pantalla de abajo
	@; Obtener @ inicial de fila de z = 0
	mov r1, #VCOLS
	mov r1, r1, lsl #3		@; r1 = VCOLS * 4 filas * 2 Bytes/posición
	add r0, r1				@; r0 = @ de z=0
	@; Obtener @ inicial de fila de z pasado por parámetro
	mov r7, r4, lsl #6
	add r2, r0, r7			@; r2 = @ de z=0 + z * 64(cada fila -> 32 posiciones * 2Bytes/posición)
	mov r3, r5, lsl #7		@; r3 = color * 128
	cmp r4, #0
	@;EScribir baldosa de columna central en el mapa:
	mov r6, #104			@; r6 = índice de baldosa de columna central
	add r3, r6				@; r3 = índice de baldosa + color * 128
	strh r3, [r2]			@; Primera columna
	@; Segunda columna: 1ª columna + (3 posiciones * 2Bytes/posición = 6 Bytes) 
	strh r3, [r2,#6]		@; Columna entre z i PID
	@; Tercera columna: desde 2ª columna + (5 posiciones * 2Bytes/posición = 10 Bytes) -> 16
	strh r3, [r2,#16]		@; Columna entre PID y Prog
	@; Cuarta columna: desde 3ª columna + (5 posiciones * 2Bytes/posición = 10 Bytes) -> 26
	strh r3, [r2,#26]		@; Columna entre  Prog y PCactual
	@; Quinta columna: desde 4ª columna + (9 posiciones * 2Bytes/posición = 18 Bytes) -> 44		
	strh r3, [r2,#44]		@; Columna entre  PCactual y Pi
	@; Sexta columna: desde 5ª columna + (3 posiciones * 2Bytes/posición = 6 Bytes) -> 50	
	strh r3, [r2,#50]		@; Columna entre  Pi y E
	@; Séptima columna: desde 6ª columna + (2 posiciones * 2Bytes/posición = 4 Bytes) -> 54	
	strh r3, [r2,#54]		@; Columna entre   E y Uso
	@; Octava columna: desde 7ª columna + (4 posiciones * 2Bytes/posición = 8 Bytes) -> 62	
	strh r3, [r2,#62]		@; Columna final
	
	pop {r0-r8,pc}
	
	
	
	@; _gg_obtenerInicialVentana
	@; Rutina de soporte per obtener la dirección inicial de la ventana, pasada por el parámetro, 
	@; en el mapa de fondo 2 para los textos
	@; Parametres;
	@;		R0: número de ventana
	@; Retorna;
	@;		R0: dirección inicial de la ventana 

_gg_obtenerInicialVentana:
	push {r1-r5,lr}
	ldr r1, =ptrMapa2
	ldr r1, [r1]			@; r1 = @ptrMapa2(@ inicial)
	
	mov r2, #VFILS
	mov r3, r0, lsr #L2_PPART	@; r3 = fila = v/PPART
	mul r3, r2, r3			@; r3 = fila = (v/PPART) * VFILS
	mov r2, #PCOLS		
	mul r3, r2, r3			@; r3 = fila = (v/PPART) * VFILS * PCOLS
	
	mov r2, #PPART
	sub r2, #1
	and r4, r0, r2			@; r4 = col = v%PPART
	mov r2, #VCOLS			
	mul r4, r2, r4			@; r4 = col = (v%PPART) * VCOLS
	
	add r5, r3, r4			@; r5 = fila + col = ((v/PPART) * VFILS * PCOLS) + ((v%PPART) * VCOLS)
	mov r5, r5, lsl #1		@; r5 = r5 * 2  "índice de Baldosas = 2 Bytes"
	add r0, r1, r5			@; r0 = @ptrMapa2 + fila + col
	
	pop {r1-r5,pc}
	

	.global _gg_escribirCar
	@; escribe un carácter (baldosa) en la posición de la ventana indicada,
	@; con un color concreto;
	@;Parámetros:
	@;	R0 (vx)		->	coordenada x de ventana (0..31)
	@;	R1 (vy)		->	coordenada y de ventana (0..23)
	@;	R2 (car)	->	código del caràcter, como número de baldosa (0..127)
	@;	R3 (color)	->	número de color del texto (de 0 a 3)
	@; pila (vent)	->	número de ventana (de 0 a 15)
_gg_escribirCar:
	push {r0-r6,lr}
	mov r4, r0				@; r4 = vx
	ldr r0, [sp, #32]		@; r0 = num ventana(sp + 4*7 regsitros apilados + 4 de lr)
	bl _gg_obtenerInicialVentana	@; r0 = @ptrMapa2 + fila + col
	mov r5, r0				@; r5 = @inicialVentana
	mov r0, r4				@; r0 = vx
	
	mov r4, #PCOLS
	mul r6, r1, r4			@; r6 = vy * PCOLS
	add r6, r0				@; r6 = (vy*PCOLS) + vx
	mov r6, r6, lsl #1		@; r6 = r6 * 2 "índice de Baldosas = 2 Bytes"
	add r6, r5				@; r6 = @inicialVentana + (vy*PCOLS) + vx
	
	mov r4, r3, lsl #7		@; r4 = color * 128
	add r4, r2				@; r4 = car + color * 128
	strh r4, [r6]			@; guardamos el índice de baldosa en la posición correspondiente
	
	pop {r0-r6,pc}


	.global _gg_escribirMat
	@; escribe una matriz de 8x8 carácteres a partir de una posición de la
	@; ventana indicada, con un color concreto;
	@;Parámetros:
	@;	R0 (vx)		->	coordenada x inicial de ventana (0..31)
	@;	R1 (vy)		->	coordenada y inicial de ventana (0..23)
	@;	R2 (m)		->	puntero a matriz 8x8 de códigos ASCII (dirección)
	@;	R3 (color)	->	número de color del texto (de 0 a 3)
	@; pila	(vent)	->	número de ventana (de 0 a 15)
_gg_escribirMat:
	push {r0-r9,lr}
	mov r4, r0				@; r4 = vx
	ldr r0, [sp, #44]		@; r0 = num ventana(sp + 4*10 regsitros apilados + 4 de lr)
	bl _gg_obtenerInicialVentana	@; r0 = @ptrMapa2 + fila + col
	mov r5, r0				@; r5 = @inicialVentana
	mov r0, r4				@; r0 = vx
	
	
	mov r4, #PCOLS
	mul r6, r1, r4			@; r6 = vy * PCOLS
	add r6, r0				@; r6 = (vy*PCOLS) + vx
	mov r6, r6, lsl #1		@; r6 = r6 * 2 "índice de Baldosas = 2 Bytes"
	add r6, r5				@; r6 = @inicialVentana + (vy*PCOLS) + vx
	
	mov r4, r3, lsl #7		@; r4 = color * 128
	
	mov r5, #0				@; r5 = índice de los cars totales de la matriz m
	mov r8, #0				@; r8 = índice de la posición de baldosa del mapa
	mov r9, #0				@; r9 = índice de los cars de cada fila de la matriz m
.LforEscMat:
	ldrb r7, [r2,r5]		@; cargamos cada car de la matriz m
	cmp r7, #0				@; comparamos si se trata de centinella,
	beq .LfinforEscMat		@; entonces, pasamos al siguiente carácter
	sub r7, #32				@; Conversión de código ASCII a índice de baldosa
	add r7, r4				@; Cambio de color: baldosa + color * 128
	strh r7, [r6,r8]		@; guardamos el índice de baldosa en la posición del mapa correspondiente
	
.LfinforEscMat:
	add r5, #1				@; Aumentamos el índice de los cars totales de la matriz m
	add r8, #2				@; Aumentamos el índice de la posición de baldosa del mapa
	add r9, #1				@; Aumentamos el índice de los cars de cada fila de la matriz m
	cmp r9, #8				@; Comprabamos si ha llegado al final de la fila de la matriz m
	blo .LforEscMat
	cmp r5, #64
	beq .LfinEscMat
	mov r9, #0				@; Reiniciamos el índice de los cars de cada fila de la matriz m
	@; Cmoienzo de la posición del siguiente fila del mapa de fondo 2:
	@; @actual + (PCOLS(=VCOLS*PPART) - baldosas añadidas en la fila anterior)
	@; @actual + (32*4-8)*2Bytes/baldosa 
	@; @actual + 240
	add r8, #240
	b .LforEscMat		
.LfinEscMat:
	pop {r0-r9,pc}



	.global _gg_rsiTIMER2
	@; Rutina de Servicio de Interrupción (RSI) para actualizar la representa-
	@; ción del PC actual.
_gg_rsiTIMER2:
	push {r0-r7,lr}
	mov r4, #0				@; r4 = z (número de zócalo actual)
	ldr r5, =_gd_pcbs		@; r5 = @inicial de _gd_pcbs
	mov r6, #4				@; r6 = fila
	
.LcomprobarZiPID:
	cmp r4, #0				@; si z == 0
	beq .LactulizarPC		@; enotnces como z es del SO, siempre hay que actulizar el PC
	ldr r7, [r5]			@; r7 = pid
	cmp r7, #0				@; si pid == 0
	bne .LactulizarPC
	ldr r0, =espacioVacio9	@; r0 = @espacioVacio9
	b .LActualizarPCcont	@; 

.LactulizarPC:
	ldr r0, =pcActual		@; r0 = @pcActual
	mov r1, #9				@; r1 = longitud de str de pcActual = 9
	add r7, r5, #4			@; r7 = @PC
	ldr r2,[r7]				@; r2 = PC
	bl _gs_num2str_hex
	ldr r0, =pcActual		@; r0 = @pcActual
.LActualizarPCcont:
	mov r1, r6				@; r1 = fila
	mov r2, #14				@; r2 = col
	mov r3, #0				@; r3 = color(blanco)
	bl _gs_escribirStringSub

	add r5, #24				@; r5 = @ de siguiente PCB, donde cada uno contiene 6 atributos de int (6*4)
	add r6, #1				@; r6 = fila++
	add r4, #1				@; r4 = z++
	cmp r4, #16				
	blo .LcomprobarZiPID
	
	pop {r0-r7,pc}




.end

