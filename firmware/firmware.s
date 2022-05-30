	.file	"firmware.c"
	.option nopic
	.text
	.align	2
	.globl	putchar
	.type	putchar, @function
putchar:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	mv	a5,a0
	sb	a5,-17(s0)
	lbu	a4,-17(s0)
	li	a5,10
	bne	a4,a5,.L2
	li	a0,13
	call	putchar
.L2:
	li	a5,33554432
	addi	a5,a5,8
	lbu	a4,-17(s0)
	sw	a4,0(a5)
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	putchar, .-putchar
	.align	2
	.globl	print
	.type	print, @function
print:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	j	.L4
.L5:
	lw	a5,-20(s0)
	addi	a4,a5,1
	sw	a4,-20(s0)
	lbu	a5,0(a5)
	mv	a0,a5
	call	putchar
.L4:
	lw	a5,-20(s0)
	lbu	a5,0(a5)
	bnez	a5,.L5
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	print, .-print
	.section	.rodata
	.align	2
.LC0:
	.string	"0123456789abcdef"
	.text
	.align	2
	.globl	print_hex
	.type	print_hex, @function
print_hex:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	li	a5,7
	sw	a5,-20(s0)
	j	.L7
.L10:
	lw	a5,-20(s0)
	slli	a5,a5,2
	lw	a4,-36(s0)
	srl	a5,a4,a5
	andi	a4,a5,15
	lui	a5,%hi(.LC0)
	addi	a5,a5,%lo(.LC0)
	add	a5,a4,a5
	lbu	a5,0(a5)
	sb	a5,-21(s0)
	lbu	a4,-21(s0)
	li	a5,48
	bne	a4,a5,.L8
	lw	a4,-20(s0)
	lw	a5,-40(s0)
	bge	a4,a5,.L11
.L8:
	lbu	a5,-21(s0)
	mv	a0,a5
	call	putchar
	lw	a5,-20(s0)
	sw	a5,-40(s0)
	j	.L9
.L11:
	nop
.L9:
	lw	a5,-20(s0)
	addi	a5,a5,-1
	sw	a5,-20(s0)
.L7:
	lw	a5,-20(s0)
	bgez	a5,.L10
	nop
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	print_hex, .-print_hex
	.section	.rodata
	.align	2
.LC1:
	.string	">=100"
	.text
	.align	2
	.globl	print_dec
	.type	print_dec, @function
print_dec:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	lw	a4,-20(s0)
	li	a5,99
	bleu	a4,a5,.L13
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1)
	call	print
	j	.L12
.L13:
	lw	a4,-20(s0)
	li	a5,89
	bleu	a4,a5,.L15
	li	a0,57
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-90
	sw	a5,-20(s0)
	j	.L16
.L15:
	lw	a4,-20(s0)
	li	a5,79
	bleu	a4,a5,.L17
	li	a0,56
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-80
	sw	a5,-20(s0)
	j	.L16
.L17:
	lw	a4,-20(s0)
	li	a5,69
	bleu	a4,a5,.L18
	li	a0,55
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-70
	sw	a5,-20(s0)
	j	.L16
.L18:
	lw	a4,-20(s0)
	li	a5,59
	bleu	a4,a5,.L19
	li	a0,54
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-60
	sw	a5,-20(s0)
	j	.L16
.L19:
	lw	a4,-20(s0)
	li	a5,49
	bleu	a4,a5,.L20
	li	a0,53
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-50
	sw	a5,-20(s0)
	j	.L16
.L20:
	lw	a4,-20(s0)
	li	a5,39
	bleu	a4,a5,.L21
	li	a0,52
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-40
	sw	a5,-20(s0)
	j	.L16
.L21:
	lw	a4,-20(s0)
	li	a5,29
	bleu	a4,a5,.L22
	li	a0,51
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-30
	sw	a5,-20(s0)
	j	.L16
.L22:
	lw	a4,-20(s0)
	li	a5,19
	bleu	a4,a5,.L23
	li	a0,50
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-20
	sw	a5,-20(s0)
	j	.L16
.L23:
	lw	a4,-20(s0)
	li	a5,9
	bleu	a4,a5,.L16
	li	a0,49
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-10
	sw	a5,-20(s0)
.L16:
	lw	a4,-20(s0)
	li	a5,8
	bleu	a4,a5,.L24
	li	a0,57
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-9
	sw	a5,-20(s0)
	j	.L12
.L24:
	lw	a4,-20(s0)
	li	a5,7
	bleu	a4,a5,.L25
	li	a0,56
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-8
	sw	a5,-20(s0)
	j	.L12
.L25:
	lw	a4,-20(s0)
	li	a5,6
	bleu	a4,a5,.L26
	li	a0,55
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-7
	sw	a5,-20(s0)
	j	.L12
.L26:
	lw	a4,-20(s0)
	li	a5,5
	bleu	a4,a5,.L27
	li	a0,54
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-6
	sw	a5,-20(s0)
	j	.L12
.L27:
	lw	a4,-20(s0)
	li	a5,4
	bleu	a4,a5,.L28
	li	a0,53
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-5
	sw	a5,-20(s0)
	j	.L12
.L28:
	lw	a4,-20(s0)
	li	a5,3
	bleu	a4,a5,.L29
	li	a0,52
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-4
	sw	a5,-20(s0)
	j	.L12
.L29:
	lw	a4,-20(s0)
	li	a5,2
	bleu	a4,a5,.L30
	li	a0,51
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-3
	sw	a5,-20(s0)
	j	.L12
.L30:
	lw	a4,-20(s0)
	li	a5,1
	bleu	a4,a5,.L31
	li	a0,50
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-2
	sw	a5,-20(s0)
	j	.L12
.L31:
	lw	a5,-20(s0)
	beqz	a5,.L32
	li	a0,49
	call	putchar
	lw	a5,-20(s0)
	addi	a5,a5,-1
	sw	a5,-20(s0)
	j	.L12
.L32:
	li	a0,48
	call	putchar
.L12:
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	print_dec, .-print_dec
	.align	2
	.globl	getchar_prompt
	.type	getchar_prompt, @function
getchar_prompt:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	li	a5,-1
	sw	a5,-20(s0)
 #APP
# 98 "firmware.c" 1
	rdcycle a5
# 0 "" 2
 #NO_APP
	sw	a5,-24(s0)
	li	a5,50331648
	li	a4,-1
	sw	a4,0(a5)
	lw	a5,-36(s0)
	beqz	a5,.L35
	lw	a0,-36(s0)
	call	print
	j	.L35
.L38:
 #APP
# 106 "firmware.c" 1
	rdcycle a5
# 0 "" 2
 #NO_APP
	sw	a5,-28(s0)
	lw	a4,-28(s0)
	lw	a5,-24(s0)
	sub	a5,a4,a5
	sw	a5,-32(s0)
	lw	a4,-32(s0)
	li	a5,12001280
	addi	a5,a5,-1280
	bleu	a4,a5,.L36
	lw	a5,-36(s0)
	beqz	a5,.L37
	lw	a0,-36(s0)
	call	print
.L37:
	lw	a5,-28(s0)
	sw	a5,-24(s0)
	li	a5,50331648
	lw	a4,0(a5)
	li	a5,50331648
	not	a4,a4
	sw	a4,0(a5)
.L36:
	li	a5,33554432
	addi	a5,a5,8
	lw	a5,0(a5)
	sw	a5,-20(s0)
.L35:
	lw	a4,-20(s0)
	li	a5,-1
	beq	a4,a5,.L38
	li	a5,50331648
	sw	zero,0(a5)
	lw	a5,-20(s0)
	andi	a5,a5,0xff
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	getchar_prompt, .-getchar_prompt
	.align	2
	.globl	getchar
	.type	getchar, @function
getchar:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
	li	a0,0
	call	getchar_prompt
	mv	a5,a0
	mv	a0,a5
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
	.size	getchar, .-getchar
	.section	.rodata
	.align	2
.LC2:
	.string	"Cycles: 0x"
	.align	2
.LC3:
	.string	"Instns: 0x"
	.align	2
.LC4:
	.string	"Chksum: 0x"
	.text
	.align	2
	.globl	cmd_benchmark
	.type	cmd_benchmark, @function
cmd_benchmark:
	addi	sp,sp,-336
	sw	ra,332(sp)
	sw	s0,328(sp)
	addi	s0,sp,336
	mv	a5,a0
	sw	a1,-328(s0)
	sb	a5,-321(s0)
	addi	a5,s0,-320
	sw	a5,-44(s0)
	li	a5,314159104
	addi	a5,a5,161
	sw	a5,-20(s0)
 #APP
# 140 "firmware.c" 1
	rdcycle a5
# 0 "" 2
 #NO_APP
	sw	a5,-48(s0)
 #APP
# 141 "firmware.c" 1
	rdinstret a5
# 0 "" 2
 #NO_APP
	sw	a5,-52(s0)
	sw	zero,-24(s0)
	j	.L43
.L51:
	sw	zero,-28(s0)
	j	.L44
.L45:
	lw	a5,-20(s0)
	slli	a5,a5,13
	lw	a4,-20(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	srli	a5,a5,17
	lw	a4,-20(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	slli	a5,a5,5
	lw	a4,-20(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	andi	a4,a5,0xff
	lw	a5,-28(s0)
	addi	a3,s0,-16
	add	a5,a3,a5
	sb	a4,-304(a5)
	lw	a5,-28(s0)
	addi	a5,a5,1
	sw	a5,-28(s0)
.L44:
	lw	a4,-28(s0)
	li	a5,255
	ble	a4,a5,.L45
	sw	zero,-32(s0)
	sw	zero,-36(s0)
	j	.L46
.L48:
	lw	a5,-32(s0)
	addi	a4,s0,-16
	add	a5,a4,a5
	lbu	a5,-304(a5)
	beqz	a5,.L47
	lw	a5,-36(s0)
	addi	a4,a5,1
	sw	a4,-36(s0)
	lw	a4,-32(s0)
	andi	a4,a4,0xff
	addi	a3,s0,-16
	add	a5,a3,a5
	sb	a4,-304(a5)
.L47:
	lw	a5,-32(s0)
	addi	a5,a5,1
	sw	a5,-32(s0)
.L46:
	lw	a4,-32(s0)
	li	a5,255
	ble	a4,a5,.L48
	sw	zero,-40(s0)
	sw	zero,-56(s0)
	j	.L49
.L50:
	lw	a5,-40(s0)
	slli	a5,a5,2
	lw	a4,-44(s0)
	add	a5,a4,a5
	lw	a5,0(a5)
	lw	a4,-20(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-40(s0)
	addi	a5,a5,1
	sw	a5,-40(s0)
.L49:
	lw	a4,-40(s0)
	li	a5,63
	ble	a4,a5,.L50
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L43:
	lw	a4,-24(s0)
	li	a5,19
	ble	a4,a5,.L51
 #APP
# 165 "firmware.c" 1
	rdcycle a5
# 0 "" 2
 #NO_APP
	sw	a5,-60(s0)
 #APP
# 166 "firmware.c" 1
	rdinstret a5
# 0 "" 2
 #NO_APP
	sw	a5,-64(s0)
	lbu	a5,-321(s0)
	beqz	a5,.L52
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	print
	lw	a4,-60(s0)
	lw	a5,-48(s0)
	sub	a5,a4,a5
	li	a1,8
	mv	a0,a5
	call	print_hex
	li	a0,10
	call	putchar
	lui	a5,%hi(.LC3)
	addi	a0,a5,%lo(.LC3)
	call	print
	lw	a4,-64(s0)
	lw	a5,-52(s0)
	sub	a5,a4,a5
	li	a1,8
	mv	a0,a5
	call	print_hex
	li	a0,10
	call	putchar
	lui	a5,%hi(.LC4)
	addi	a0,a5,%lo(.LC4)
	call	print
	li	a1,8
	lw	a0,-20(s0)
	call	print_hex
	li	a0,10
	call	putchar
.L52:
	lw	a5,-328(s0)
	beqz	a5,.L53
	lw	a4,-64(s0)
	lw	a5,-52(s0)
	sub	a4,a4,a5
	lw	a5,-328(s0)
	sw	a4,0(a5)
.L53:
	lw	a4,-60(s0)
	lw	a5,-48(s0)
	sub	a5,a4,a5
	mv	a0,a5
	lw	ra,332(sp)
	lw	s0,328(sp)
	addi	sp,sp,336
	jr	ra
	.size	cmd_benchmark, .-cmd_benchmark
	.align	2
	.globl	delay
	.type	delay, @function
delay:
	addi	sp,sp,-48
	sw	s0,44(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	zero,-20(s0)
 #APP
# 195 "firmware.c" 1
	rdcycle a5
# 0 "" 2
 #NO_APP
	sw	a5,-24(s0)
	j	.L56
.L58:
 #APP
# 198 "firmware.c" 1
	rdcycle a5
# 0 "" 2
 #NO_APP
	sw	a5,-28(s0)
	lw	a4,-28(s0)
	lw	a5,-24(s0)
	sub	a5,a4,a5
	sw	a5,-32(s0)
	lw	a4,-32(s0)
	li	a5,500
	bleu	a4,a5,.L57
	lw	a5,-28(s0)
	sw	a5,-24(s0)
.L57:
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L56:
	lw	a4,-20(s0)
	lw	a5,-36(s0)
	blt	a4,a5,.L58
	nop
	lw	s0,44(sp)
	addi	sp,sp,48
	jr	ra
	.size	delay, .-delay
	.section	.rodata
	.align	2
.LC5:
	.string	"Booting..\n"
	.align	2
.LC6:
	.string	"Press ENTER to continue..\n"
	.align	2
.LC7:
	.string	"\n"
	.align	2
.LC8:
	.string	"PicoSoC\n"
	.align	2
.LC9:
	.string	"   [9] Run simplistic benchmark\n"
	.align	2
.LC10:
	.string	"Command> "
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	li	a5,50331648
	li	a4,31
	sw	a4,0(a5)
	li	a5,33554432
	addi	a5,a5,4
	li	a4,434
	sw	a4,0(a5)
	li	a0,1000
	call	delay
	lui	a5,%hi(.LC5)
	addi	a0,a5,%lo(.LC5)
	call	print
	li	a5,50331648
	li	a4,63
	sw	a4,0(a5)
	li	a0,1000
	call	delay
	li	a5,50331648
	li	a4,127
	sw	a4,0(a5)
	li	a0,1000
	call	delay
	nop
.L60:
	lui	a5,%hi(.LC6)
	addi	a0,a5,%lo(.LC6)
	call	getchar_prompt
	mv	a5,a0
	mv	a4,a5
	li	a5,13
	bne	a4,a5,.L60
	lui	a5,%hi(.LC7)
	addi	a0,a5,%lo(.LC7)
	call	print
	lui	a5,%hi(.LC8)
	addi	a0,a5,%lo(.LC8)
	call	print
.L67:
	lui	a5,%hi(.LC7)
	addi	a0,a5,%lo(.LC7)
	call	print
	lui	a5,%hi(.LC7)
	addi	a0,a5,%lo(.LC7)
	call	print
	lui	a5,%hi(.LC9)
	addi	a0,a5,%lo(.LC9)
	call	print
	lui	a5,%hi(.LC7)
	addi	a0,a5,%lo(.LC7)
	call	print
	li	a5,10
	sw	a5,-20(s0)
	j	.L61
.L66:
	lui	a5,%hi(.LC10)
	addi	a0,a5,%lo(.LC10)
	call	print
	call	getchar
	mv	a5,a0
	sb	a5,-21(s0)
	lbu	a4,-21(s0)
	li	a5,32
	bleu	a4,a5,.L62
	lbu	a4,-21(s0)
	li	a5,126
	bgtu	a4,a5,.L62
	lbu	a5,-21(s0)
	mv	a0,a5
	call	putchar
.L62:
	lui	a5,%hi(.LC7)
	addi	a0,a5,%lo(.LC7)
	call	print
	lbu	a4,-21(s0)
	li	a5,57
	bne	a4,a5,.L63
	li	a1,0
	li	a0,1
	call	cmd_benchmark
	nop
	j	.L65
.L63:
	lw	a5,-20(s0)
	addi	a5,a5,-1
	sw	a5,-20(s0)
.L61:
	lw	a5,-20(s0)
	bgtz	a5,.L66
.L65:
	j	.L67
	.size	main, .-main
	.ident	"GCC: (GNU) 8.2.0"
