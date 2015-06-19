SECTION .text
	extern A, b, X, X_old
	extern pthread_barrier_wait
	global thread_func_sse

; never returns
thread_func_sse:
	push rbp
	mov rbp, rsp
	
	push rdi ; save arg structure pointer on stack
	mov rdi, [rdi+16] ; wait for "start" signal
	call pthread_barrier_wait
	pop rdi
	
	xor rcx, rcx
	mov ecx, [rdi] ; i = arg.start

loop_i:
	xorpd xmm0, xmm0
	mov rdx, 0 ; j
	mov rsi, [A]
	mov rbx, [rsi+8*rcx] ; A[i]

loop_j:
	; first, check if i==j or i==j+1
	cmp ecx, edx
	je single_last
	inc edx
	cmp ecx, edx
	je single_first
	dec edx

	movupd xmm1, [rbx+8*rdx];
	mov rsi, [X_old]
	movupd xmm2, [rsi+8*rdx];

	mulpd xmm1, xmm2
	addpd xmm0, xmm1

next_j:
	add edx, 2
	cmp edx, [rdi+8]
	jl loop_j

	; sum the "half-sums" in xmm0
	movhlps xmm1, xmm0
	addsd xmm0, xmm1

	; compute and update X
	mov rsi, [b]
	movsd xmm1, [rsi+8*rcx]
	subsd xmm1, xmm0
	movsd xmm0, [rbx+8*rcx]
	divsd xmm1, xmm0
	mov rsi, [X]
	movsd [rsi+8*rcx], xmm1

	inc ecx
	cmp ecx, [rdi+4]
	jne loop_i

	push rdi ; save arg structure pointer on stack
	mov rdi, [rdi+24] ; signal that the thread is finished
	call pthread_barrier_wait
	pop rdi

	jmp thread_func_sse

single_last:
	; i==j, so we only use the last value
	xorpd xmm1, xmm1
	movsd xmm1, [rbx+8*rdx+8]
	xorpd xmm2, xmm2
	mov rsi, [X_old]
	movsd xmm2, [rsi+8*rdx+8]

	mulpd xmm1, xmm2
	addpd xmm0, xmm1
	jmp next_j

single_first:
	; i==j+1, so we only use the first value
	
	dec edx ; since we incremented it beforehand
	xorpd xmm1, xmm1
	movsd xmm1, [rbx+8*rdx]
	xorpd xmm2, xmm2
	mov rsi, [X_old]
	movsd xmm2, [rsi+8*rdx]

	mulpd xmm1, xmm2
	addpd xmm0, xmm1
	jmp next_j
