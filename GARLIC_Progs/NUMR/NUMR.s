	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"NUMR.c"
	.text
	.align	2
	.global	revertir_numero
	.syntax unified
	.arm
	.fpu softvfp
	.type	revertir_numero, %function
revertir_numero:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #20
	str	r0, [sp, #4]
	mov	r3, #0
	str	r3, [sp, #12]
	b	.L2
.L3:
	ldr	r0, [sp, #4]
	add	r3, sp, #8
	add	r2, sp, #4
	mov	r1, #10
	bl	GARLIC_divmod
	ldr	r2, [sp, #12]
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	mov	r2, r3
	ldr	r3, [sp, #8]
	add	r3, r2, r3
	str	r3, [sp, #12]
.L2:
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bne	.L3
	ldr	r3, [sp, #12]
	mov	r0, r3
	add	sp, sp, #20
	@ sp needed
	ldr	pc, [sp], #4
	.size	revertir_numero, .-revertir_numero
	.align	2
	.global	cuenta_digitos
	.syntax unified
	.arm
	.fpu softvfp
	.type	cuenta_digitos, %function
cuenta_digitos:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #20
	str	r0, [sp, #4]
	mov	r3, #0
	str	r3, [sp, #12]
	b	.L6
.L7:
	ldr	r0, [sp, #4]
	add	r3, sp, #8
	add	r2, sp, #4
	mov	r1, #10
	bl	GARLIC_divmod
	ldr	r3, [sp, #12]
	add	r3, r3, #1
	str	r3, [sp, #12]
.L6:
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bne	.L7
	ldr	r3, [sp, #12]
	mov	r0, r3
	add	sp, sp, #20
	@ sp needed
	ldr	pc, [sp], #4
	.size	cuenta_digitos, .-cuenta_digitos
	.align	2
	.global	son_digitos_impares
	.syntax unified
	.arm
	.fpu softvfp
	.type	son_digitos_impares, %function
son_digitos_impares:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #20
	str	r0, [sp, #4]
	mov	r3, #1
	strb	r3, [sp, #15]
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bne	.L11
	mov	r3, #0
	strb	r3, [sp, #15]
	b	.L11
.L13:
	ldr	r0, [sp, #4]
	add	r3, sp, #8
	add	r2, sp, #4
	mov	r1, #10
	bl	GARLIC_divmod
	ldr	r3, [sp, #8]
	and	r3, r3, #255
	and	r3, r3, #1
	strb	r3, [sp, #15]
.L11:
	ldr	r3, [sp, #4]
	cmp	r3, #0
	beq	.L12
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L13
.L12:
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, sp, #20
	@ sp needed
	ldr	pc, [sp], #4
	.size	son_digitos_impares, .-son_digitos_impares
	.section	.rodata
	.align	2
.LC0:
	.ascii	"-Numeros reversibles- PID (%d)-\012\000"
	.align	2
.LC1:
	.ascii	"\012%0Numeros originales: %3 \012\000"
	.align	2
.LC2:
	.ascii	"%d \011\000"
	.align	2
.LC3:
	.ascii	" \012\000"
	.align	2
.LC4:
	.ascii	"\012%0Numeros invertidos: %1\012\000"
	.align	2
.LC5:
	.ascii	"\012%0Numeros que son reversibles:%2\012\000"
	.align	2
.LC6:
	.ascii	"\012No hay ninguno!\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 88
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{r4, r5, r6, r7, r8, r9, r10, fp, lr}
	add	fp, sp, #32
	sub	sp, sp, #92
	str	r0, [fp, #-96]
	mov	r3, sp
	mov	r10, r3
	ldr	r3, [fp, #-96]
	cmp	r3, #0
	bge	.L16
	mov	r3, #0
	str	r3, [fp, #-96]
	b	.L17
.L16:
	ldr	r3, [fp, #-96]
	cmp	r3, #3
	ble	.L17
	mov	r3, #3
	str	r3, [fp, #-96]
.L17:
	ldr	r3, [fp, #-96]
	add	r2, r3, #1
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	mov	r1, r3
	sub	r3, r1, #1
	str	r3, [fp, #-48]
	mov	r3, r1
	mov	r2, r3
	mov	r3, #0
	lsl	r0, r3, #5
	str	r0, [fp, #-104]
	ldr	r0, [fp, #-104]
	orr	r0, r0, r2, lsr #27
	str	r0, [fp, #-104]
	lsl	r3, r2, #5
	str	r3, [fp, #-108]
	mov	r3, r1
	mov	r2, r3
	mov	r3, #0
	lsl	r0, r3, #5
	str	r0, [fp, #-112]
	ldr	r0, [fp, #-112]
	orr	r0, r0, r2, lsr #27
	str	r0, [fp, #-112]
	lsl	r3, r2, #5
	str	r3, [fp, #-116]
	mov	r3, r1
	lsl	r3, r3, #2
	add	r3, r3, #3
	add	r3, r3, #7
	lsr	r3, r3, #3
	lsl	r3, r3, #3
	sub	sp, sp, r3
	mov	r3, sp
	add	r3, r3, #3
	lsr	r3, r3, #2
	lsl	r3, r3, #2
	str	r3, [fp, #-52]
	ldr	r3, [fp, #-96]
	add	r2, r3, #1
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	mov	r1, r3
	sub	r3, r1, #1
	str	r3, [fp, #-56]
	mov	r3, r1
	mov	r2, r3
	mov	r3, #0
	lsl	r0, r3, #5
	str	r0, [fp, #-120]
	ldr	r0, [fp, #-120]
	orr	r0, r0, r2, lsr #27
	str	r0, [fp, #-120]
	lsl	r3, r2, #5
	str	r3, [fp, #-124]
	mov	r3, r1
	mov	r2, r3
	mov	r3, #0
	lsl	r9, r3, #5
	orr	r9, r9, r2, lsr #27
	lsl	r8, r2, #5
	mov	r3, r1
	lsl	r3, r3, #2
	add	r3, r3, #3
	add	r3, r3, #7
	lsr	r3, r3, #3
	lsl	r3, r3, #3
	sub	sp, sp, r3
	mov	r3, sp
	add	r3, r3, #3
	lsr	r3, r3, #2
	lsl	r3, r3, #2
	str	r3, [fp, #-60]
	ldr	r3, [fp, #-96]
	add	r2, r3, #1
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	mov	r1, r3
	sub	r3, r1, #1
	str	r3, [fp, #-64]
	mov	r3, r1
	mov	r2, r3
	mov	r3, #0
	lsl	r7, r3, #5
	orr	r7, r7, r2, lsr #27
	lsl	r6, r2, #5
	mov	r3, r1
	mov	r2, r3
	mov	r3, #0
	lsl	r5, r3, #5
	orr	r5, r5, r2, lsr #27
	lsl	r4, r2, #5
	mov	r3, r1
	lsl	r3, r3, #2
	add	r3, r3, #3
	add	r3, r3, #7
	lsr	r3, r3, #3
	lsl	r3, r3, #3
	sub	sp, sp, r3
	mov	r3, sp
	add	r3, r3, #3
	lsr	r3, r3, #2
	lsl	r3, r3, #2
	str	r3, [fp, #-68]
	mov	r3, #0
	str	r3, [fp, #-44]
	ldr	r3, [fp, #-96]
	add	r2, r3, #1
	mov	r3, r2
	lsl	r3, r3, #1
	add	r3, r3, r2
	lsl	r3, r3, #1
	mov	r2, r3
	mov	r3, #1
	lsl	r3, r3, r2
	str	r3, [fp, #-72]
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L31
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [fp, #-40]
	b	.L18
.L21:
	bl	GARLIC_random
	mov	r3, r0
	mov	r0, r3
	sub	r3, fp, #84
	sub	r2, fp, #88
	ldr	r1, [fp, #-72]
	bl	GARLIC_divmod
	ldr	r3, [fp, #-84]
	cmp	r3, #9
	bhi	.L19
	ldr	r3, [fp, #-96]
	add	r2, r3, #1
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	mov	r2, r3
	ldr	r3, [fp, #-84]
	add	r3, r2, r3
	str	r3, [fp, #-84]
.L19:
	ldr	r1, [fp, #-84]
	ldr	r3, [fp, #-52]
	ldr	r2, [fp, #-40]
	str	r1, [r3, r2, lsl #2]
	ldr	r3, [fp, #-84]
	mov	r0, r3
	bl	revertir_numero
	mov	r3, r0
	str	r3, [fp, #-88]
	ldr	r3, [fp, #-84]
	mov	r0, r3
	bl	cuenta_digitos
	str	r0, [fp, #-76]
	ldr	r3, [fp, #-88]
	mov	r0, r3
	bl	cuenta_digitos
	str	r0, [fp, #-80]
	ldr	r2, [fp, #-76]
	ldr	r3, [fp, #-80]
	cmp	r2, r3
	bne	.L20
	ldr	r2, [fp, #-84]
	ldr	r3, [fp, #-88]
	add	r3, r2, r3
	mov	r0, r3
	bl	son_digitos_impares
	mov	r3, r0
	cmp	r3, #0
	beq	.L20
	ldr	r3, [fp, #-44]
	add	r2, r3, #1
	str	r2, [fp, #-44]
	ldr	r1, [fp, #-84]
	ldr	r2, [fp, #-68]
	str	r1, [r2, r3, lsl #2]
.L20:
	ldr	r1, [fp, #-88]
	ldr	r3, [fp, #-60]
	ldr	r2, [fp, #-40]
	str	r1, [r3, r2, lsl #2]
	ldr	r3, [fp, #-40]
	add	r3, r3, #1
	str	r3, [fp, #-40]
.L18:
	ldr	r3, [fp, #-96]
	add	r2, r3, #1
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	mov	r2, r3
	ldr	r3, [fp, #-40]
	cmp	r2, r3
	bhi	.L21
	ldr	r0, .L31+4
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [fp, #-40]
	b	.L22
.L23:
	ldr	r3, [fp, #-52]
	ldr	r2, [fp, #-40]
	ldr	r3, [r3, r2, lsl #2]
	mov	r1, r3
	ldr	r0, .L31+8
	bl	GARLIC_printf
	ldr	r3, [fp, #-40]
	add	r3, r3, #1
	str	r3, [fp, #-40]
.L22:
	ldr	r3, [fp, #-96]
	add	r2, r3, #1
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	mov	r2, r3
	ldr	r3, [fp, #-40]
	cmp	r2, r3
	bhi	.L23
	ldr	r0, .L31+12
	bl	GARLIC_printf
	ldr	r0, .L31+16
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [fp, #-40]
	b	.L24
.L25:
	ldr	r3, [fp, #-60]
	ldr	r2, [fp, #-40]
	ldr	r3, [r3, r2, lsl #2]
	mov	r1, r3
	ldr	r0, .L31+8
	bl	GARLIC_printf
	ldr	r3, [fp, #-40]
	add	r3, r3, #1
	str	r3, [fp, #-40]
.L24:
	ldr	r3, [fp, #-96]
	add	r2, r3, #1
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	mov	r2, r3
	ldr	r3, [fp, #-40]
	cmp	r2, r3
	bhi	.L25
	ldr	r0, .L31+12
	bl	GARLIC_printf
	ldr	r0, .L31+20
	bl	GARLIC_printf
	ldr	r3, [fp, #-44]
	cmp	r3, #0
	beq	.L26
	mov	r3, #0
	str	r3, [fp, #-40]
	b	.L27
.L28:
	ldr	r3, [fp, #-68]
	ldr	r2, [fp, #-40]
	ldr	r3, [r3, r2, lsl #2]
	mov	r1, r3
	ldr	r0, .L31+8
	bl	GARLIC_printf
	ldr	r3, [fp, #-40]
	add	r3, r3, #1
	str	r3, [fp, #-40]
.L27:
	ldr	r2, [fp, #-40]
	ldr	r3, [fp, #-44]
	cmp	r2, r3
	bcc	.L28
	ldr	r0, .L31+12
	bl	GARLIC_printf
	b	.L29
.L26:
	ldr	r0, .L31+24
	bl	GARLIC_printf
.L29:
	mov	r3, #0
	mov	sp, r10
	mov	r0, r3
	sub	sp, fp, #32
	@ sp needed
	pop	{r4, r5, r6, r7, r8, r9, r10, fp, pc}
.L32:
	.align	2
.L31:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.word	.LC5
	.word	.LC6
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
