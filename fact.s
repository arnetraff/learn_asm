.section .data
.section .text

.globl _start
.globl fact
_start:
	pushl $4
	call fact
	addl $4, %esp

	movl %eax, %ebx
	movl $1, %eax
	
	int $0x80

fact:
	pushl %ebp
	movl %esp, %ebp
	movl 8(%ebp), %eax
	
	cmpl $1, %eax
	
	je end_fact

	decl %eax
	pushl %eax
	call fact
	movl 8(%ebp), %ebx
	
	imull %ebx, %eax
	
	end_fact:
		movl %ebp, %esp
		popl %ebp
		
		ret

