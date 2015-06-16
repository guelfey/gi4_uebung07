SECTION .text
	extern sqrt
	global vect_dist_sse

vect_dist_sse:
	push rbp
	mov rbp, rsp

	push rcx
	push rbx
	mov rcx, 0 ; loop counter
	xorpd xmm0, xmm0 ; init sum with 0

loop:
	mov rbx, [rbp+16]
	movapd xmm1, [rdi+8*rcx]
	mov rbx, [rbp+24]
	movapd xmm2, [rsi+8*rcx]

	subpd xmm1, xmm2
	mulpd xmm1, xmm1
	addpd xmm0, xmm1

	add ecx, 2
	cmp ecx, edx
	jne loop

	; xmm0 contains two "half-sums" as packed doubles. add them and return the
	; square root.

	movhlps xmm1, xmm0
	addsd xmm0, xmm1 ; add first element of xmm0 and xmm1 (second elemtn doesnt
	;matter

	sqrtsd xmm0, xmm0

	pop rbx
	pop rcx
	pop rbp
	ret
