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

	shufpd xmm1, xmm0, 0x1 ; move second element of xmm0 to first elemtn of
	addpd xmm0, xmm1 ; add first element of xmm0 and xmm1 (second elemtn doesnt
	;matter

	; when calling sqrt, both the parameter and the return value are in xmm0
	call sqrt

	pop rbx
	pop rcx
	pop rbp
	ret
