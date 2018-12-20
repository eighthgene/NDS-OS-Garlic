@;==============================================================================
@;
@;	"garlic_itcm_proc.s":	código de las rutinas de control de procesos (2.0)
@;						(ver "garlic_system.h" para descripción de funciones)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2

	.global _gp_WaitForVBlank
	@; rutina para pausar el procesador mientras no se produzca una interrupción
	@; de retrazado vertical (VBL); es un sustituto de la "swi #5", que evita
	@; la necesidad de cambiar a modo supervisor en los procesos GARLIC
_gp_WaitForVBlank:
	push {r0-r1, lr}
	ldr r0, =__irq_flags
.Lwait_espera:
	mcr p15, 0, lr, c7, c0, 4	@; HALT (suspender hasta nueva interrupción)
	ldr r1, [r0]			@; R1 = [__irq_flags]
	tst r1, #1				@; comprobar flag IRQ_VBL
	beq .Lwait_espera		@; repetir bucle mientras no exista IRQ_VBL
	bic r1, #1
	str r1, [r0]			@; poner a cero el flag IRQ_VBL
	pop {r0-r1, pc}


	.global _gp_IntrMain
	@; Manejador principal de interrupciones del sistema Garlic
_gp_IntrMain:
	mov	r12, #0x4000000
	add	r12, r12, #0x208	@; R12 = base registros de control de interrupciones	
	ldr	r2, [r12, #0x08]	@; R2 = REG_IE (máscara de bits con int. permitidas)
	ldr	r1, [r12, #0x0C]	@; R1 = REG_IF (máscara de bits con int. activas)
	and r1, r1, r2			@; filtrar int. activas con int. permitidas
	ldr	r2, =irqTable
.Lintr_find:				@; buscar manejadores de interrupciones específicos
	ldr r0, [r2, #4]		@; R0 = máscara de int. del manejador indexado
	cmp	r0, #0				@; si máscara = cero, fin de vector de manejadores
	beq	.Lintr_setflags		@; (abandonar bucle de búsqueda de manejador)
	ands r0, r0, r1			@; determinar si el manejador indexado atiende a una
	beq	.Lintr_cont1		@; de las interrupciones activas
	ldr	r3, [r2]			@; R3 = dirección de salto del manejador indexado
	cmp	r3, #0
	beq	.Lintr_ret			@; abandonar si dirección = 0
	mov r2, lr				@; guardar dirección de retorno
	blx	r3					@; invocar el manejador indexado
	mov lr, r2				@; recuperar dirección de retorno
	b .Lintr_ret			@; salir del bucle de búsqueda
.Lintr_cont1:	
	add	r2, r2, #8			@; pasar al siguiente índice del vector de
	b	.Lintr_find			@; manejadores de interrupciones específicas
.Lintr_ret:
	mov r1, r0				@; indica qué interrupción se ha servido
.Lintr_setflags:
	str	r1, [r12, #0x0C]	@; REG_IF = R1 (comunica interrupción servida)
	ldr	r0, =__irq_flags	@; R0 = dirección flags IRQ para gestión IntrWait
	ldr	r3, [r0]
	orr	r3, r3, r1			@; activar el flag correspondiente a la interrupción
	str	r3, [r0]			@; servida (todas si no se ha encontrado el maneja-
							@; dor correspondiente)
	mov	pc,lr				@; retornar al gestor de la excepción IRQ de la BIOS


	.global _gp_rsiVBL
	@; Manejador de interrupciones VBL (Vertical BLank) de Garlic:
	@; se encarga de actualizar los tics, intercambiar procesos, etc.
_gp_rsiVBL:
	push {r4-r7, lr}
		
	@; incremenntem contador de ticks
	ldr r4, =_gd_tickCount	@; carrega de direccio variable _gd_tickCount
	ldr r5, [r4]			@; r5 valor de variable _gd_tickCount
	add r5, #1				@; incrementem el tick per 1
	str r5, [r4]			@; actualitzem valor de variable _gd_tickCount
	
	bl _gp_actualizarDelay	@; actualitzar la cua de processos retardats

	@; comprovar si hi ha algun proces pendent a la cua Ready 
	@; consultan numero de procesos a la cola
	ldr r4, =_gd_nReady		@; r4 = adreça de variable _gd_nReady
	ldr r5, [r4]			@; r5 = valor de _gd_nReady
	cmp r5, #0				@; comprovem si la cua te com a minim 1 process
	beq .Lfi_canvi_context	
	
	@; comprovem si proces es de SO
	ldr r4, =_gd_pidz		@; r4 = @_gd_pidz 
	ldr r5, [r4]			@; r5 = valor _gd_pidz (28 bits PID + 4 bits Zocalo)
	cmp r5, #0
	beq .Lsalvar_context	
	
	@; comprovem si es su PID == 0
	mov r5, r5, lsr #4		@; r5 = PID
	cmp r5, #0				@; comprovem si PID == 0, si es 0 vol dir que el proces ha acabat la seve execucio.
	beq .Lrestaura_Proc
	
	@; passem parametres per la funcio _gp_salvarProc i la cridem
.Lsalvar_context:
	ldr r4, =_gd_nReady		@; r4 = @_gd_nReady
	ldr r5, [r4]			@; r5 = valor _gd_nReady (num processos en espera)
	ldr r6, =_gd_pidz		@; r6 = @_gd_pidz
	bl _gp_salvarProc		@; cridaem funcio _gp_salvarProc
	str r5, [r4]
	
	@; passem parametres per la funcio _gp_restaurarProc i la cridem
.Lrestaura_Proc:
	ldr r4, =_gd_nReady		@; r4 = @_gd_nReady
	ldr r5, [r4]			@; r5 = valor _gd_nReady (num processos en espera)
	ldr r6, =_gd_pidz		@; r6 = @_gd_pidz
	bl _gp_restaurarProc	@; cridaem funcio _gp_restaurarProc
	
.Lfi_canvi_context:	
	@; incrementem el contador de workTics de cada process
	ldr r6, =_gd_pidz  
	ldr r4, [r6]			@; r4 = _gd_pidz
	and r4, #15				@; r4 = zocalo de process
	mov r5, #24				@; mida de block PCB (6*4bytes = 24)
	ldr r6, =_gd_pcbs
	mla r6, r4, r5, r6		@; @PCB zocalo actual
	ldr r4, [r6, #20]		@; r4 = workTics
	add r4, #1				@; workTics++
	str r4, [r6, #20]		@; guardem workTics
	
	pop {r4-r7, pc}


	@; Rutina para salvar el estado del proceso interrumpido en la entrada
	@; correspondiente del vector _gd_pcbs
	@;Parámetros
	@; R4: dirección _gd_nReady
	@; R5: número de procesos en READY
	@; R6: dirección _gd_pidz
	@;Resultado
	@; R5: nuevo número de procesos en READY (+1)
_gp_salvarProc:
	push {r8-r11, lr}
	@; guardem z de process a desbancar a ultima posicio de la cua READY
	ldr r8, [r6]			@; r8 = _gd_pidz
	lsr r10, r8, #31		@; r10 = bit 32 de _gd_pidz (bit flag de retardar process)
	and r8, #0xF			@; aplicem la mascara sobre _gd_pidz -> 5 bits baixos
	ldr r9, =_gd_qReady		@; r9 = @_gd_qReady
	
	@; comprovem si es un process de retard (Si ho es, no guardem a la cola Ready)
	cmp r10, #1				@; comprovem si bit de mes pes es 1
	beq .L_salvarProc_Ratardar
	
	@; guardar zocalo a la cola de Ready
	strb r8, [r9, r5]		@; r8 = num zocalo
	add r5, #1				@; incrementem contador de procesos pendents _gd_nReady++
	
.L_salvarProc_Ratardar:
	@; Guardar R15 -> PCB[PC]
	ldr r11, =_gd_pcbs		@; r11 = @_gd_pcbs
	mov r10, #24			@; r10 = 24 (struct es de 6 pos de 4 bytes)
	mla r11, r8, r10, r11	@; r10 = num zocalo * estructura (6 pos * 4 bytes) => (z * 24) + @_gd_pcbs
	
	mov r9, sp				@; r9 = SP_IRQ
	ldr r8, [r9, #60]		@; r8 = PC (ret. Proc)
	str r8, [r11, #4]		@; PCB[z]->PC = PC(r15)
	
	@; Guardar CPSR
	mrs r8, SPSR			@; SPSR esta guardant el contingu de CPSR del mode anterior
	str r8, [r11, #12]		@; Guardem SPRS_irq = CPSR(proces) a PCB[z]->status
	
	@; Cambiar mod -> System
	mrs r8, CPSR
	orr r8, #0x1F			@; mascar de 5 bits (11111) que es mode de Systema
	msr CPSR, r8			
	
	@; apilem el valor de registres r0 - r12 + r14
	push {r14}				@; apilem LR(r14) de mode Systema a la pila de 
	
	ldr r8, [r9, #56]		@; r8 = r12 guardem de la pila SP_IRQ a la pila de Systema
	push {r8}				@; apilem r12
	
	ldr r8, [r9, #12]
	push {r8}				@; apilem r11
	
	ldr r8, [r9, #8]
	push {r8}				@; apilem r10
	
	ldr r8, [r9, #4]
	push {r8}				@; apilem r9
	
	ldr r8, [r9]
	push {r8}				@; apilem r8
	
	ldr r8, [r9, #32]
	push {r8}				@; apilem r7
	
	ldr r8, [r9, #28]
	push {r8}				@; apilem r6
	
	ldr r8, [r9, #24]
	push {r8}				@; apilem r5
	
	ldr r8, [r9, #20]
	push {r8}				@; apilem r4
	
	ldr r8, [r9, #52]
	push {r8}				@; apilem r3
	
	ldr r8, [r9, #48]
	push {r8}				@; apilem r2
	
	ldr r8, [r9, #44]
	push {r8}				@; apilem r1
	
	ldr r8, [r9, #40]
	push {r8}				@; apilem r0
	
	@; Guardem el SP_programa a PCB[z]->SP
	str r13, [r11, #8]
	
	@; Camviem el mode a IRQ
	mrs r8, CPSR
	bic r8, #0x1F			@; it clear 5 bits baixos
	orr r8, #0x12			@; mascara de mode IRQ (10010)
	msr CPSR, r8
		
	pop {r8-r11, pc}


	@; Rutina para restaurar el estado del siguiente proceso en la cola de READY
	@;Parámetros
	@; R4: dirección _gd_nReady
	@; R5: número de procesos en READY
	@; R6: dirección _gd_pidz
_gp_restaurarProc:
	push {r8-r11, lr}
	
	@; decrementem el contador de processos de cua Ready
	sub r5, #1				@; r5 = r5 - 1 decrementem el contador de num de proc a cua Ready
	str r5, [r4]			@; actualitzem el contador de processon en cua Ready
	
	@; carregem el zocalo 
	ldr r8, =_gd_qReady		@; r8 = @_gd_qReady
	ldrb r9, [r8]			@; r9 = zocalo de primera posicio de la cua Ready
	
	mov r10, #0				@; i = 0;
	
.Lfor_reordenar_cua:		
	cmp r10, r5				@; i > r5
	beq .Lfi_reordenar_cua
	ldrb r11, [r8, #1]		@; r11 = _gd_qReady[i+1]
	strb r11, [r8]			@; guardem valor de i+1 a i
	
	add r8, #1				@; @_gd_qReady movem a una posicio
	add r10, #1				@; i++
	
	b .Lfor_reordenar_cua
.Lfi_reordenar_cua:
	
	@; Construir valor combidano PIDz i actualitzar la variable _gd_pidz
	ldr r8, =_gd_pcbs		@; r8 = @PCB
	mov r10, #24			@; r10 = 24
	mla r10, r9, r10, r8	@; r10 = @_gd_pcbs = z*24 = numero de zocalos * estructura PCB (4 bytes * 6 elemets) + @Base PCB
	ldr r11, [r10]			@; r11 = PID de process actual
	mov r11, r11, lsl #4	@; PID desplasem 4 bits a l'esquerra
	orr r11, r9				@; PID + Zocalo
	str r11, [r6]			@; actualitzar _gd_pidz
	
	@; Recuperar PCB[z]->PC a r15
	ldr r11, [r10, #4]		@; r11 = PC
	mov r8, sp				@; r8 = @SP_irq
	str r11, [r8, #60]		@; guardem el PC de PCB al registre r15
	
	@; Reuperar CPSR
	ldr r11, [r10, #12]
	msr SPSR, r11			@; guardem a SPSRS_IRQ = CPSR recuperat des de PCB[z]->CPSR
	
	@; cambiar mod d'execucio
	mrs r11, CPSR
	orr r11, #0x1F			@; mascara mode sistema (11111b)
	msr CPSR, r11
	
	@; recuperar SP_irq des de PCB[z]->SP
	ldr r13, [r10, #8]
	
	@; Desapilar valors r0 - r12 + r14 i guardar a pila de mode IRQ
	pop {r11}				@; desapilar r0 
	str r11, [r8, #40]		@; guardar valor desapilat a la pila IRQ mode
	
	pop {r11}				@; desapilar r1
	str r11, [r8, #44]		 
	
	pop {r11}				@; desapilar r2
	str r11, [r8, #48]
	
	pop {r11}				@; desapilar r3
	str r11, [r8, #52]
	
	pop {r11}				@; desapilar r4
	str r11, [r8, #20]
	
	pop {r11}				@; desapilar r5
	str r11, [r8, #24]
	
	pop {r11}				@; desapilar r6
	str r11, [r8, #28]
	
	pop {r11}				@; desapilar r7
	str r11, [r8, #32]
	
	pop {r11}				@; desapilar r8
	str r11, [r8]
	
	pop {r11}				@; desapilar r9
	str r11, [r8, #4]
	
	pop {r11}				@; desapilar r10
	str r11, [r8, #8]
	
	pop {r11}				@; desapilar r11
	str r11, [r8, #12]
	
	pop {r11}				@; desapilar r12
	str r11, [r8, #56]
	
	pop {r14}				@; desapilar LR
	
	@; cabiem el mode de exuecucio a IRQ	
	mrs r11, CPSR
	bic r11, #0x1F			@; posem 5 bits baixos a 0
	orr r11, #0x12			@; cambiem ultims 5bits a mode IRQ (10010b)
	msr CPSR, r11

	pop {r8-r11, pc}


	@; Rutina para actualizar la cola de procesos retardados, poniendo en
	@; cola de READY aquellos cuyo número de tics de retardo sea 0
_gp_actualizarDelay:
	push {r0-r10, lr}
	@; carregem les adreçes
	ldr r0, =_gd_nDelay
	ldr r1, =_gd_qDelay
	
	ldr r2, =_gd_nReady
	ldr r3, =_gd_qReady
	
	mov r4, #0									@; i = 0
	
	ldr r5, [r0]								@; r5 = num processos retardats
	@; comprovem si la cua no es buida
													
	cmp r5, r4			
	beq .Lfi_gp_actualizarDelay
	
.L_actualizarDelay_fori:
	ldr r6, [r1, r4, lsl #2]					@; r6 = _gd_qDelay[i]
	sub r6, #1									@; decrementem numero de tics							
	lsl r7, r6, #16
	lsr r7, r7, #16								@; r7 = num de tics 
	
	@; comprovar si queden tics
	cmp r7, #0
	bne .L_actualizarDelay_noZeroTics
	
	@; Si tics = 0
	lsr r8, r6, #24								@; r8 = zocalo del process
	ldr r9, [r2]								@; r9 = num processos en Ready
	strb r8, [r3, r9]							@; guardem el zocalo a la cua Ready
	add r9, #1									@; incrementem nReady
	str r9, [r2]								@; guardem nReady
	
	@; Treiem el proces de la cua Delay
	sub r5, #1									@; decrement _gd_nDelay
	str r5, [r0]								@; guardem la variable 
	
	mov r8, r4									@; j = i
	
.L_actualizarDelay_forj:	
	cmp r8, r5
	bhs .L_actualizarDelay_fi_desp
	
	@; Desplaçem prox. word (zocalo + tics) a word actual
	add r9, r8, #1
	ldr r10, [r1, r9, lsl #2]					@; r10 = _gd_nDelay[j+1]
	str r10, [r1, r8, lsl #2]					@; _gd_nDelay[i] = r10
	add r8, #1									@; j++
	b .L_actualizarDelay_forj
	
	
.L_actualizarDelay_noZeroTics:
	str r6, [r1, r4, lsl #2]					@; actualizem el word a la cua _gd_qDelay[i]
	add r4, #1									@; i++
	
.L_actualizarDelay_fi_desp:
	cmp r4, r5									@; i < nDelay
	blo .L_actualizarDelay_fori					

.Lfi_gp_actualizarDelay:
	pop {r0-r10, pc}

	.global _gp_numProc
	@;Resultado
	@; R0: número de procesos total
_gp_numProc:
	push {r1-r2, lr}
	mov r0, #1				@; contar siempre 1 proceso en RUN
	ldr r1, =_gd_nReady
	ldr r2, [r1]			@; R2 = número de procesos en cola de READY
	add r0, r2				@; añadir procesos en READY
	ldr r1, =_gd_nDelay
	ldr r2, [r1]			@; R2 = número de procesos en cola de DELAY
	add r0, r2				@; añadir procesos retardados
	pop {r1-r2, pc}


	.global _gp_crearProc
	@; prepara un proceso para ser ejecutado, creando su entorno de ejecución y
	@; colocándolo en la cola de READY
	@;Parámetros
	@; R0: intFunc funcion,
	@; R1: int zocalo,
	@; R2: char *nombre
	@; R3: int arg
	@;Resultado
	@; R0: 0 si no hay problema, >0 si no se puede crear el proceso
_gp_crearProc:
	push {r4-r7,lr}
	@; comprovem si zocalo == 0 (per SO) i si no esta ocupat PID = 0
	cmp r1, #0					@; comprovem si z == 0
	beq .LcrearProc_err_so
	
	@; Calculem @PCB[z]->PID
	ldr r4, =_gd_pcbs
	mov r5, #24					@; r5 = 6pos * 4bytes = 24
	mla r5, r1, r5, r4			@; r5 = @PCB[z] -> Zocalo * 24(struct 6pos*4bytes) + @Base PCB			
	ldr r6, [r5]				@; r5 = carrgem el PID de z
	cmp r6, #0
	bne .LcrearProc_err_ocupat
	
	
	@; crear nou PID i guardem a PCB[z]->PC + incrementar pid count
	ldr r4, =_gd_pidCount
	ldr r6, [r4]				@; r6 = valor _gd_pidCount
	add r6, #1					@; incrementar _gd_pidCount
	str r6, [r4]				@; actualitzar _gd_pidCount
	str r6, [r5]				@; guardar valor a PCB[z]->PC
	
	@; guardem @func+4 a PCB[z]->PC
	add r0, #4					@; sumem 4 a la @base de la primera instruccio
	str r0, [r5, #4]			@; guardem @instr a PCB[z]->PC 
	
	@; CPSR -> sistema, I(IRQ)=0, T(tipo arm)=0, resta=0
	mov r6, #0x1F				@; r6 = (11111b)
	str r6, [r5, #12]			@; guardem CPSR construit a PCB[z]->Status
	
	@; guardem a PCB[z]->keyName primers 4 caractes (1 caracter = 1 byte) equival a un word 32bits
	ldr r6, [r2]				@; r6 = @nombre
	str r6, [r5, #16]			@; guardem a PCB[z]->keyName (32bits = 4bytes = 4caracters)
	
	@; inicialitzar workTics=0
	mov r6, #0					
	str r6, [r5, #20]			@; guardem 0 a PCB[z]->workTics
	
	@; calculem @pila per proces
	ldr r6, =_gd_stacks
	mov r4, #512
	mla r7, r1, r4, r6							@; calculem pos de la pila z*pila(128 pos * 4 bytes) = z*512
	
	@; guardem a r14 = @_gp_terminarProc
	sub r7, #4									@; pos TOP de la pila
	ldr r4, =_gp_terminarProc
	str r4, [r7]								@; guardem a r14 = @_gp_terminarProc
	
	@; guardem el valor 0 a r0-r12 
	mov r4, #0									@; valor per inicialitzar els registres a 0
	mov r6, #0									@; contador de registres i=0
	
.LcrearProc_fori:
	sub r7, #4									@; movem una pos a la pila
	str r4, [r7]								@; guardem un 0
	add r6, #1									@; i++
	cmp r6, #12									@; comprovem si estem dins de pila 0-12
	bne .LcrearProc_fori
	
	@; guardem SP a PCB[z]->SP
	sub r7, #4									@; movem una posicion de la pila
	str r3, [r7]								@; guardem el argument de la programa a R0
	str r7, [r5, #8]							@; guardem el valor de r13(SP) a PCB[z]->SP
	
	@;Seccio critica, inhibrim interupcions
	bl _gp_inhibirIRQs						
	
	@; guardem el num zocalo a ultima pos de la cola Ready
	ldr r4, =_gd_nReady
	ldr r5, [r4]			@; r5 = num de processos a la cola Ready
	ldr r6, =_gd_qReady
	strb r1, [r6, r5]		@; guardem zocalo (r1) a ultima pos de la cua Ready	
	add r5, #1				@; incrementem num de processos que estan en cua Ready
	str r5, [r4]			@; actualitzem num de processos a la cola Ready
	
	mov r0, #0				@; retornem un 0 -> el process s'ha creat correctament sense errors
	
	@;Fi seccio critica, desinhibrim interupcions
	bl _gp_desinhibirIRQs
	
	b .Lfi_crear_proc
	
.LcrearProc_err_so:
	mov r0, #1				@; error de crear proces 1 -> error zocalo ocupat per SO
	b .Lfi_crear_proc

.LcrearProc_err_ocupat:
	mov r0, #2				@; error de crear proces 2 -> error zocalo ocupat per altre proces
	
.Lfi_crear_proc:
	pop {r4-r7, pc}


	@; Rutina para terminar un proceso de usuario:
	@; pone a 0 el campo PID del PCB del zócalo actual, para indicar que esa
	@; entrada del vector _gd_pcbs está libre; también pone a 0 el PID de la
	@; variable _gd_pidz (sin modificar el número de zócalo), para que el código
	@; de multiplexación de procesos no salve el estado del proceso terminado.
_gp_terminarProc:
	ldr r0, =_gd_pidz
	ldr r1, [r0]			@; R1 = valor actual de PID + zócalo
	and r1, r1, #0xf		@; R1 = zócalo del proceso desbancado
	bl _gp_inhibirIRQs
	str r1, [r0]			@; guardar zócalo con PID = 0, para no salvar estado			
	ldr r2, =_gd_pcbs
	mov r10, #24
	mul r11, r1, r10
	add r2, r11				@; R2 = dirección base _gd_pcbs[zocalo]
	mov r3, #0
	str r3, [r2]			@; pone a 0 el campo PID del PCB del proceso
	str r3, [r2, #20]		@; borrar porcentaje de USO de la CPU
	ldr r0, =_gd_sincMain
	ldr r2, [r0]			@; R2 = valor actual de la variable de sincronismo
	mov r3, #1
	mov r3, r3, lsl r1		@; R3 = máscara con bit correspondiente al zócalo
	orr r2, r3
	str r2, [r0]			@; actualizar variable de sincronismo
	@; esborrar %CPU
	ldr r0, =espacioVacio4
	add r1, r1, #4 			@; r1 = fila
	mov r2, #28				@; r2 = col de pid = 5
	mov r3, #0				@; r3 = color
	bl _gs_escribirStringSub
	bl _gp_desinhibirIRQs
.LterminarProc_inf:
	bl _gp_WaitForVBlank	@; pausar procesador
	b .LterminarProc_inf	@; hasta asegurar el cambio de contexto


	.global _gp_matarProc
	@; Rutina para destruir un proceso de usuario:
	@; borra el PID del PCB del zócalo referenciado por parámetro, para indicar
	@; que esa entrada del vector _gd_pcbs está libre; elimina el índice de
	@; zócalo de la cola de READY o de la cola de DELAY, esté donde esté;
	@; Parámetros:
	@;	R0:	zócalo del proceso a matar (entre 1 y 15).
_gp_matarProc:
	push {r0-r7, lr} 
	
	@;Seccio critica, inhibirim les interupcions
	bl _gp_inhibirIRQs	
	
	@; posem al camp _gd_pcbs[z].PID a zero, per indicar que el zocalo z esta libre
	ldr r1, =_gd_pcbs
	mov r2, #24
	mla r3, r0, r2, r1				@; calculem adreça del PCB[z] = num zocalo * 24 + @base
	mov r2, #0		
	str r2, [r3]			 		@; guardem un 0 a PID  (PCB[z].PID = 0)
	str r2, [r3, #20]
	
	ldr r1, =_gd_nReady
	ldr r2, =_gd_qReady
	ldr r3, [r1]			 		@; r3 = num processos en Ready
	
	mov r5, #0				 		@; r5 = i = 0
.L_matarProc_incReady_i:
	cmp r3, r5
	beq .Lfi_matarProc_ready  
	
	@; Si nReady > 0
	ldrb r4, [r2, r5]		 		@; carrege primer z[i] en la cua Ready
	cmp r4, r0						@; comparem z[i] amb la z passada per parametre
	bne .L_matarProc_proxReady		@; si no son iguals passem a proxim
	
	@; si valor de Ready igual al valor passat per parrametre (z[i] == z)
	mov r6, r5						@; inicialitzem la j per desplaçament (j = i)
	
.L_matarProc_ready_forj:	
	add r7, r6, #1					@; r7 = j++
	cmp r7, r3						@; comprover si a la cua hi ha mes elements (j < nReady)
	bhs .L_matarProc_fiReady_desp	@; si j >= nReady 
	ldrb r4, [r2, r7]
	strb r4, [r2, r6]
	add r6, #1
	b .L_matarProc_ready_forj
	
	
.L_matarProc_fiReady_desp:			@; decrementem num proc en Ready
	sub r3, #1
	str r3, [r1]
	b .L_fi_matarProc

.L_matarProc_proxReady:				
	add r5, #1						@; i++
	b .L_matarProc_incReady_i		

	
.Lfi_matarProc_ready:
	@; Recorrem la cua Delay
	ldr r1, =_gd_nDelay
	ldr r2, =_gd_qDelay
	ldr r3, [r1]					@; r3 = num processos en la cua Delay
	
	mov r5, #0 						@; i = 0;
.L_matarProc_incDelay_i:
	cmp r3, r5						@; comprovem si (i == nDelay)
	beq .L_fi_matarProc  		
	
	ldr r4, [r2, r5, lsl #2]		@; carreguem el word 32bits (zocalo + tics) en la cua Delay
	mov r4, r4, lsr #24			@; r4 = zocalo de la cua _gd_qDelay[i]						
	cmp r4, r0						@; comparem z[i] amb la z passada per parametre
	bne .L_matarProc_proxDelay		@; si no son iguals passem a proxim
	
	@; si zocalo de Delay igual al zocalo passat per parrametre (z[i] == z)
	add r6, r5, #1					@; r6 = i + 1 = j
.L_matarProc_delay_forj:	
	cmp r6, r3						@; comprover si a la cua hi ha mes elements (j + 1 < nDelay)	
	beq .L_matarProc_fiDelay_desp
	ldr r4, [r2, r6, lsl #2]		@; carrgem word de la prox posicio qDelay
	str r4, [r2, r5, lsl #2]		@; guardem word a la posicio actual qDelay
	add r5, #4						@; prox posicio (4 bytes = 1 int)
	add r6, #1						@; j++
	b .L_matarProc_delay_forj
	
.L_matarProc_fiDelay_desp:			
	sub r3, #1						@; decrementem numero processos Delay
	str r3, [r1]
	b .L_fi_matarProc
	
.L_matarProc_proxDelay:
	add r5, #1						@; i++
	b .L_matarProc_incDelay_i		
	
.L_fi_matarProc:
	bl _gp_desinhibirIRQs
	@; esborrar %CPU
	mov r5, r0
	ldr r0, =espacioVacio4
	add r1, r5, #4 			@; r1 = fila
	mov r2, #28				@; r2 = col de pid = 28
	mov r3, #0				@; r3 = color
	@;Fi seccio critica, desinhibirim interupcions
	bl _gs_escribirStringSub
	pop {r0-r7, pc}


	
	.global _gp_retardarProc
	@; retarda la ejecución de un proceso durante cierto número de segundos,
	@; colocándolo en la cola de DELAY
	@;Parámetros
	@; R0: int nsec
_gp_retardarProc:
	push {r1-r6, lr}
	mov r1, #60					@; 1 sec = 60 tics 
	mul r1, r0					@; passem r0 (segons de retard) a tics
	
	ldr r2, =_gd_pidz
	ldr r3, [r2]				@; r3 = valor _gd_pidz
	cmp r3, #0					@; comprovem si es 
	beq .L_retardarProc_fi
	
		
	and r4, r3, #0xF			@; r4 = zocalo  
	lsl r4, #24
	orr r4, r1					@; r4 = construim un word (8 bits alts = zocalo, 16 bits baixos = tics)
								@; 16 bits => 600 * 60 = 36000; log2 36000 = 15,13 (necessitem 16 bits)	
								
	ldr r1, =_gd_nDelay
	ldr r2, [r1]				@; r2 = _gd_nDelay
	ldr r6, =_gd_qDelay
	@;ldr r5, [r3, r2]			@; r3 = @base _gd_qDelay + desplaçament per n elements a la cua
	str r4, [r6, r2, lsl #2]	@; guardem r4 a verctor _gd_qDelay
	
	add r2, #1
	str r2, [r1]				@; incrementem num de proc en la cola _gd_qDelay 
	
	orr r3, #0x80000000			@; posem 1 al bit mes alt de la variable _gd_pidz 	
	ldr r2, =_gd_pidz		
	str r3, [r2]				@; actualitzem _gd_pidz
	
	bl _gp_WaitForVBlank		@; forçem cessió de la CPU invocant la funció WaitForVBlank

.L_retardarProc_fi:
	pop {r1-r6, pc}



	.global _gp_inihibirIRQs
	@; pone el bit IME (Interrupt Master Enable) a 0, para inhibir todas
	@; las IRQs y evitar así posibles problemas debidos al cambio de contexto
_gp_inhibirIRQs:
	push {r0-r1, lr}
	
	ldr r0, =0x4000208			@; @REG_IME registre general de activacio de interupcions
	ldr r1, [r0]				@; carregem registre IME
	bic r1, #1					@; posem un 0
	str r1, [r0]				@; guardem registre
	
	pop {r0-r1, pc}


	.global _gp_desinihibirIRQs
	@; pone el bit IME (Interrupt Master Enable) a 1, para desinhibir todas
	@; las IRQs
_gp_desinhibirIRQs:
	push {r0-r1, lr}
	
	ldr r0, =0x4000208			@; @REG_IME registre general de activacio de interupcions
	ldr r1, [r0]				@; carregem registre IME
	orr r1, #1					@; posem un 0
	str r1, [r0]				@; guardem registre

	pop {r0-r1, pc}



	.global _gp_rsiTIMER0
	@; Rutina de Servicio de Interrupción (RSI) para contabilizar los tics
	@; de trabajo de cada proceso: suma los tics de todos los procesos y calcula
	@; el porcentaje de uso de la CPU, que se guarda en los 8 bits altos de la
	@; entrada _gd_pcbs[z].workTicks de cada proceso (z) y, si el procesador
	@; gráfico secundario está correctamente configurado, se imprime en la
	@; columna correspondiente de la tabla de procesos.
_gp_rsiTIMER0:
	push {r0-r10, lr}
	@; sumem tots workTicks de tots processos actius 
	ldr r10, =_gd_pcbs			@; r10 = @_gd_pcbs
	mov r9, #24					@; r9 = 6 pos * 4 bytes = 24 bytes
	
	ldr r1, [r10, #20]			@; r1 = workTics de process SO (32 bits)
	and r1, #0x00FFFFFF			@; r1 = totat_workTics
	mov r5, #1					@; i = 1 contador per recorre tots els PCBs
	
.L_rsiTIMER0_tics_fori:
	mla r3, r5, r9, r10			@; r3 = @_gd_pcbs[i].PID
	ldr r7, [r3]				@; r4 = _gd_pcbs[i].PID
	cmp r7, #0					@; comprovem si hi ha un process a PCB[i] (_gd_pcbs[i].PID != 0)
	beq .L_rsiTIMER0_tics_prox
	ldr r4, [r3, #20]			@; r4 = _gd_pcbs[i].workTics (32 bits = 8bits % + 24bits WorkTics)
	and r4, #0x00FFFFFF			@; r4 = workTics 
	add r1, r4					@; sumem workTics a valor total (tatal_workTics += _gd_pcbs[i].workTics)
	
.L_rsiTIMER0_tics_prox:	
	add r5, #1					@; i++
	cmp r5, #15					@; comprovem si estem al rang i < 15
	ble .L_rsiTIMER0_tics_fori


	@; r1 = total de worktics
	@; calculem el % de les tics respecte total 
	@; es posant el 0 a worktics i guardant el % en les 8 bits alts
	mov r6, #100
	add r2, r10, #20			@; r2 = @quo (@workTics per la fincio divmod)
	ldr r0, [r2]				@; r0 = workTics (% de SO + worktics)
	and r0, r0, #0x00FFFFFF			@; r0 = workTics SO
	mul r0, r6					@; r0 = workTics SO * 100
	ldr r3, =_gd_mod
	bl _ga_divmod				@; guardem resultat (%) a @workTics a 8 bits baixos
	
	mov r5, #0					@; i = 0, perque a pos 0 es SO
	mov r8, r1					@; r8 = tics total
	b .L_rsiTIMER0_print
	
.L_rsiTIMER0_print_fori:
	mla r3, r5, r9, r10
	ldr r7, [r3] 				@; r4 = PID[i] 
	cmp r7, #0					@; coprovem si pid esta ocupad
	beq .L_rsiTIMER0_print_prox
	add r2, r3, #20				@; r2 = @workTics
	ldr r0, [r3, #20]				@; r0 = valor de workTics
	and r0, r0, #0x00FFFFFF			@; r0 = workTics
	mul r0, r6					@; r0 = workTics * 100
	ldr r3, =_gd_mod			@; r3 = @_gd_mod
	mov r1, r8					@; r1 = tics total
	bl _ga_divmod				@; guardem resultat (%) a @workTics a 8 bits baixos
	
	
.L_rsiTIMER0_print:
	ldr r0, =_gd_percentString
	mov r1, #4					@; r1 = longitud String
	ldr r3, [r2]				@; r3 = valor workTics en % (8 bits baixos)
	lsl r4, r3, #24				@; r4 = valor workTics en % (8 bits alts)
	str r4, [r2]				@; guardem valor
	mov r2, r3					@; r2 = valor workTics en % (8 bits baixos)
	
	@; r0 = numString
	@; r1 = longitud
	@; r2 = numero a convertir
	bl _gs_num2str_dec			@; convertim valor de % a String
	
	ldr r0, =_gd_percentString	
	add r1, r5, #4				@; r1 = fila
	mov r2, #28					@; r2 = columna
	mov r3, #0					@; r3 = color
	bl _gs_escribirStringSub	@; escribim %CPU a la taula 
	
.L_rsiTIMER0_print_prox:	
	add r5, #1					@; incrementem i++
	cmp r5, #15			
	ble .L_rsiTIMER0_print_fori
	
	@; posem a 1 el bit 0 de la variable _gd_sincMain, per que el programa principal
	@; pugui detectar que ja disposa aquesta informacio
	ldr r0, =_gd_sincMain
	ldr r1, [r1]
	orr r1, #1
	str r1, [r0]
		
	pop {r0-r10, pc}

	
.end

