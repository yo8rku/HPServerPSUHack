;*********************************************************************
;                                                                    *
;                       Software License Agreement                   *
;                                                                    *
;   The software supplied herewith by Microchip Technology           *
;   Incorporated (the "Company") for its dsPIC controller            *
;   is intended and supplied to you, the Company's customer,         *
;   for use solely and exclusively on Microchip dsPIC                *
;   products. The software is owned by the Company and/or its        *
;   supplier, and is protected under applicable copyright laws. All  *
;   rights are reserved. Any use in violation of the foregoing       *
;   restrictions may subject the user to criminal sanctions under    *
;   applicable laws, as well as to civil liability for the breach of *
;   the terms and conditions of this license.                        *
;                                                                    *
;   THIS SOFTWARE IS PROVIDED IN AN "AS IS" CONDITION.  NO           *
;   WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING,    *
;   BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND    *
;   FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE     *
;   COMPANY SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL,  *
;   INCIDENTAL OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.  *
;                                                                    *
;   (c) Copyright 2007 Microchip Technology, All rights reserved.    *
;*********************************************************************


	; Local inclusions.
	.nolist
	.include	"dspcommon.inc"		; MODCON, XBREV
	.list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.section .libdsp, code

	.global _realiFft32bIP


	.equ	TF_FFT_SIZE,1024			; 10stage, 1024 point complex FFT
	.equ	TF_FFT_STG, 10


;*********************************************************************
;                                                                    *
;                       Software License Agreement                   *
;                                                                    *
;   The software supplied herewith by Microchip Technology           *
;   Incorporated (the "Company") for its dsPIC controller            *
;   is intended and supplied to you, the Company's customer,         *
;   for use solely and exclusively on Microchip dsPIC                *
;   products. The software is owned by the Company and/or its        *
;   supplier, and is protected under applicable copyright laws. All  *
;   rights are reserved. Any use in violation of the foregoing       *
;   restrictions may subject the user to criminal sanctions under    *
;   applicable laws, as well as to civil liability for the breach of *
;   the terms and conditions of this license.                        *
;                                                                    *
;   THIS SOFTWARE IS PROVIDED IN AN "AS IS" CONDITION.  NO           *
;   WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING,    *
;   BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND    *
;   FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE     *
;   COMPANY SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL,  *
;   INCIDENTAL OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.  *
;                                                                    *
;   (c) Copyright 2007 Microchip Technology, All rights reserved.    *
;*********************************************************************

	; Local inclusions.
	.nolist
	.include	"dspcommon.inc"		; MODCON, XBREV
	.list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.section .libdsp, code

	.global _realiFft32bIP


	.equ	TF_FFT_SIZE,1024			; 10stage, 1024 point complex FFT
	.equ	TF_FFT_STG, 10


	.text

;............................................................................
; MERGE ODD/EVEN FFT RESULTS
; W8->(Radd,Isub)
; W9->(Rsub,Iadd)
; W10-> Wr
; W11-> Wi

; W12 -> ACCA
; W13 -> ACCB
; W14 -> FP, First two location used for TEMP

; Equations for Butterfly Computation
; Gr(k)=Radd - (Wr*Iadd + Wi*Rsub)  
; Gi(k)=Isub + (Wr*Rsub-Wi*Iadd)
; Gr(N-k)=Radd + (Wr*Iadd + Wi*Rsub)  
; Gi(N-k)=-Isub + (Wr*Rsub-Wi*Iadd)        
;............................................................................


		.macro MERGE_BFLY_MACRO


; Iadd*Wi 32-bit multiplication
			MOV.D	[w11],W6				; (w6,w7)=Wi=(y0,y1)
											; (w9,w9+1)=Iadd=(x0,x1)

			MUL.SU	w7,[w9],w0				; y1*x0
			MUL.US 	w6,[++w9],w2			; y0*x1
			MUL.SS	w7,[w9--],w4			; y1*x1

			LAC		w3,B
			ADD		w1,B					
			SFTAC	B,#16					; B=(y1*x0 + y0*x1)>>16

			ADD		w4,[w13++],[w14++]
			ADDC	w5,[w13--],[w14--]		; TEMP=Iadd*Wi=y1*x1 + (y1*x0 + y0*x1)>>16	


; Rsub*Wi 32-bit multiplication
											; (w9-2,w9-1)=Rsub=(x0,x1)
											; (w6,w7)=Wi=(x0,x1)								
			MUL.US 	w6,[--w9],w2			; y0*x1
			MUL.SS	w7,[w9--],w4			; y1*x1
			MUL.SU	w7,[w9++],w0			; y1*x0

			LAC		w3,B
			ADD		w1,B					
			SFTAC	B,#16					; B=(y1*x0 + y0*x1)>>16
		
			ADD 	w4,[w13],[w13++]
			ADDC	w5,[w13],[w13--]		; B=Rsub*Wi=y1*x1 + (y1*x0 + y0*x1)>>16	


; Iadd*Wr 32-bit multiplication			
			MOV.D	[w10],W6				; (w6,w7)=Wr=(y0,y1)
											; (w9+1,w9+2)=Rsub=(x0,x1)	

			MUL.SU	w7,[++w9],w0			; y1*x0
			MUL.US 	w6,[++w9],w2			; y0*x1
			MUL.SS	w7,[w9--],w4			; y1*x1

			LAC		w3,A
			ADD		w1,A					
			SFTAC	A,#16					; A=(y1*x0 + y0*x1)>>16
		
			ADD 	w4,[w12],[w12++]
			ADDC	w5,[w12],[w12--]		; A=Iadd*Wr=y1*x1 + (y1*x0 + y0*x1)>>16	

; Gr(k)=Radd-(Wr*Iadd + Wi*Rsub)  
; Gr(N-k)=Radd+(Wr*Iadd + Wi*Rsub)  	
			ADD		B						; B=Iadd*Wr+Rsub*Wi	
			SFTAC	B,#-1	
			LAC		[++W8],A				; A=Radd	
			MOV		[--w8],[w12]
			SUB		A						; A=Radd-(Iadd*Wr+Rsub*Wi)
			
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gr(k)=Radd+(Iadd*Wr+Rsub*Wi)  
			
			ADD		A
			ADD		B						; B=Radd+(Iadd*Wr+Rsub*Wi)
	
; Rsub*Wr 32-bit multiplication
											; (w6,w7)=Wr=(y0,y1)
											; (w9-2,w9-1)=Rsub=(x0,x1)
			MUL.US 	w6,[--w9],w2			; y0*x1
			MUL.SS	w7,[w9--],w4			; y1*x1
			MUL.SU	w7,[w9],w0				; y1*x0

			LAC		w3,A
			ADD		w1,A					
			SFTAC	A,#16					; A=(y1*x0 + y0*x1)>>16
		
			ADD 	w4,[w12],[w12++]
			ADDC	w5,[w12],[w12--]		; A=Rsub*Wr=y1*x1 + (y1*x0 + y0*x1)>>16	

			MOV		[w13++],[W9++]
			MOV		[w13--],[w9++]			; Gr(N-k)=(Radd - (Iadd*Wr-Rsub*Wi))/2 	

									
; Gi(k)=Isub - (Wr*Rsub + Wi*Iadd)
; Gi(N-k)=-Isub - (Wr*Rsub + Wi*Iadd)
			LAC		[++W14],B					
			MOV		[--w14],[w13]			; B=Wi*Iadd
		
			SUB		A						; A=Rsub*Wr-Wi*Iadd
			SFTAC	A,#-1
			LAC		[++W8],B				; B=Isub	
			MOV		[--w8],[w13]
			ADD		A						; A=Isub+(Rsub*Wr-Wi*Iadd)
				
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gi(k)=Isub+(Rsub*Wr-Wi*Iadd)
		
			SUB		A
			SUB		A						; B=-Isub+(Rsub*Wr-Wi*Iadd)
					
			MOV		[w12++],[W9++]
			MOV		[w12--],[w9++]			; Gi(N-k)=-Isub+(Rsub*Wr-Wi*Iadd)	
			SUB		w9,#16

		.endm

		.macro MERGE_BFLY_MACRO_PSV


; Iadd*Wi 32-bit multiplication
			POP		DSRPAG
			MOV.D	[w11],W6				; (w6,w7)=Wi=(y0,y1)
											; (w9,w9+1)=Iadd=(x0,x1)
			PUSH	DSRPAG
			MOVPAG  #0x01,DSRPAG

			MUL.SU	w7,[w9],w0				; y1*x0
			MUL.US 	w6,[++w9],w2			; y0*x1
			MUL.SS	w7,[w9--],w4			; y1*x1

			LAC		w3,B
			ADD		w1,B					
			SFTAC	B,#16					; B=(y1*x0 + y0*x1)>>16

			ADD		w4,[w13++],[w14++]
			ADDC	w5,[w13--],[w14--]		; TEMP=Iadd*Wi=y1*x1 + (y1*x0 + y0*x1)>>16	


; Rsub*Wi 32-bit multiplication
											; (w9-2,w9-1)=Rsub=(x0,x1)
											; (w6,w7)=Wi=(x0,x1)								
			MUL.US 	w6,[--w9],w2			; y0*x1
			MUL.SS	w7,[w9--],w4			; y1*x1
			MUL.SU	w7,[w9++],w0			; y1*x0

			LAC		w3,B
			ADD		w1,B					
			SFTAC	B,#16					; B=(y1*x0 + y0*x1)>>16
		
			ADD 	w4,[w13],[w13++]
			ADDC	w5,[w13],[w13--]		; B=Rsub*Wi=y1*x1 + (y1*x0 + y0*x1)>>16	


; Iadd*Wr 32-bit multiplication			
			POP		DSRPAG					
			MOV.D	[w10],W6				; (w6,w7)=Wr=(y0,y1)
											; (w9+1,w9+2)=Rsub=(x0,x1)	
			PUSH	DSRPAG
			MOVPAG  #0x01,DSRPAG

			MUL.SU	w7,[++w9],w0			; y1*x0
			MUL.US 	w6,[++w9],w2			; y0*x1
			MUL.SS	w7,[w9--],w4			; y1*x1

			LAC		w3,A
			ADD		w1,A					
			SFTAC	A,#16					; A=(y1*x0 + y0*x1)>>16
		
			ADD 	w4,[w12],[w12++]
			ADDC	w5,[w12],[w12--]		; A=Iadd*Wr=y1*x1 + (y1*x0 + y0*x1)>>16	

; Gr(k)=Radd-(Wr*Iadd + Wi*Rsub)  
; Gr(N-k)=Radd+(Wr*Iadd + Wi*Rsub)  	
			ADD		B						; B=Iadd*Wr+Rsub*Wi	
			SFTAC	B,#-1	
			LAC		[++W8],A				; A=Radd	
			MOV		[--w8],[w12]
			SUB		A						; A=Radd-(Iadd*Wr+Rsub*Wi)
			
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gr(k)=Radd+(Iadd*Wr+Rsub*Wi)  
			
			ADD		A
			ADD		B						; B=Radd+(Iadd*Wr+Rsub*Wi)
	
; Rsub*Wr 32-bit multiplication
											; (w6,w7)=Wr=(y0,y1)
											; (w9-2,w9-1)=Rsub=(x0,x1)
			MUL.US 	w6,[--w9],w2			; y0*x1
			MUL.SS	w7,[w9--],w4			; y1*x1
			MUL.SU	w7,[w9],w0				; y1*x0

			LAC		w3,A
			ADD		w1,A					
			SFTAC	A,#16					; A=(y1*x0 + y0*x1)>>16
		
			ADD 	w4,[w12],[w12++]
			ADDC	w5,[w12],[w12--]		; A=Rsub*Wr=y1*x1 + (y1*x0 + y0*x1)>>16	

			MOV		[w13++],[W9++]
			MOV		[w13--],[w9++]			; Gr(N-k)=(Radd - (Iadd*Wr-Rsub*Wi))/2 	

									
; Gi(k)=Isub - (Wr*Rsub + Wi*Iadd)
; Gi(N-k)=-Isub - (Wr*Rsub + Wi*Iadd)
			LAC		[++W14],B					
			MOV		[--w14],[w13]			; B=Wi*Iadd
		
			SUB		A						; A=Rsub*Wr-Wi*Iadd
			SFTAC	A,#-1
			LAC		[++W8],B				; B=Isub	
			MOV		[--w8],[w13]
			ADD		A						; A=Isub+(Rsub*Wr-Wi*Iadd)
				
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gi(k)=Isub+(Rsub*Wr-Wi*Iadd)
		
			SUB		A
			SUB		A						; B=-Isub+(Rsub*Wr-Wi*Iadd)
					
			MOV		[w12++],[W9++]
			MOV		[w12--],[w9++]			; Gi(N-k)=-Isub+(Rsub*Wr-Wi*Iadd)	
			SUB		w9,#16

		.endm		
;............................................................................


; Local Stack Frame
;............................................................................
;   |_______|
;   |_______|<- Stack Pointer                          	SP 
;   |_______|<- Stack Pointer Return                   	SP+6
;   |_______|<- Twiddle Factor INDEX	       			FP+4
;   |_______|<- Temp                               		FP                                              
;............................................................................

    .equ    SP_RET,     6
	.equ	TF_INDX,  	4
	.equ	TEMP,		0
 

;............................................................................
; Real FFT Calculation
;............................................................................
_realiFft32bIP:
;............................................................................
; Context Save
			PUSH.D	w8						; {w8,w9} to TOS
			PUSH.D	w10						; {w10,w11} to TOS
			PUSH.D	w12						; {w12,w13} to TOS
			PUSH	CORCON
.ifndef PSV_ON
			PUSH 	DSRPAG
	.else
			PUSH	PSVPAG
	.endif
			LNK     #8
;............................................................................
;;	PSVPAG = __builtin_psvpage(&twiddleFactor);
;;	CORCONbits.PSV = 1;	
.ifndef PSV_ON

        	MOV	    #COEFFS_IN_DATA,W7	; W7 = COEFFS_IN_DATA
	        CP	    W7,W3				; W7 - W3
	        BRA	    Z,_NOPSV            ; IF W4 = COEFFS_IN_DATA
            NOP

        	; TWIDDLES IN FLASH
            MOVPAG W3,DSRPAG            ; SET DSRPAG TO PSV PAGE

         	; CHECK IF SUFFICIENT SPACE IS AVAILABLE IN STACK
        	; CONDITION (SP + TABLE SIZE + STACK_GUARD) < SPLIM
	        MOV    SPLIM,W5             ; LOAD STACK POINTER LIMIT
          	MOV    _STACK_GUARD,W13     ; STACK GUARD SPACE FOR INTERRUPTS ETC ...
	                            ; NOTE: THIS IS USER-DEFINABLE
        	MOV	   #TF_FFT_SIZE,W9		; 
          	SL     W9,W12               ; 
          	ADD    W9,W12,W9            ; TABLE_SIZE IN BYTES
          	ADD    W9,W13,W9            ; ADD _STACK_GUARD
           	BRA    C,_RUNFROMFLASH
	        ADD    W9,W15,W9            ; ADD SP
         	BRA    C,_RUNFROMFLASH

        	SUB    W9,W5,W13            ; CHECK AGAINST SPLIM
        	BRA    LTU,_COPYTOSTACK

_RUNFROMFLASH:
			PUSH	DSRPAG
			MOVPAG	#0x01,DSRPAG

; Store Input Parameters
			MOV		w2,w11					; w11 ---> Wi = SIN(*)
	
			MOV		#TF_FFT_SIZE,W8
			ADD		w2,w8,w2
			MOV		w2,W10					; w10 ---> Wr = COS(*)


			MOV		w1,w8					; W8  ---> Pr[0], first bin
			MOV		#8,w2
			SL		w2,w0,w2
			ADD		w1,w2,w9				; w9 ---> Pr[N], last bin

			LSR		w2,#4,w6				; N/2
			SUB		w6,#2,w6				; w6 = BIN_CNTR = (N/2)-2


			SUBR	w0,#TF_FFT_STG,w1
			MOV		#2,w2								
			SL		w2,w1,w2				; TF_INDX=TF_FFT_SIZE/FFT_SIZE
			MOV		w2,[w14+TF_INDX]


			ADD		w10,w2,w10				; Next Twiddle Factor (Wr)
			ADD		w11,w2,w11				; Next Twiddle Factor (Wi)

			MOV		#ACCAL,w12				; w12 ---> A
			MOV		#ACCBL,w13				; W13 ---> B
			


; DC and Nyquist Bin
			LAC		[++w8],A				; A=Pr[0]	
			MOV		[--w8],[w12]	

			LAC		[++w9],B				; B=Pr[N]	
			MOV		[--w9],[w13]
			

			ADD		A
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gr[0]=(Pr[0]+Pr[N]
			
			SUB		A		
			SUB		A					
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gi[0]=(Pr[0]-Pr[N])						
			
			CLR		[w9++]								
			CLR		[w9++]					; Gr[N]=0
			CLR		[w9++]								
			CLR		[w9++]					; Gi[N]=0

			SUB		w9,#16					; w9---> Gr[N-1], w8---> Gr[1]


; Bin 1 to N-1, k=1:(N/2-1)
			DO 		w6,BIN_END_PSV
BIN_START_PSV:
			LAC		[++w9],A				; A=Pr[N-k]	
			MOV		[--w9],[w12]	
			LAC		[++w8],B				; B=Pr[k]	
			MOV		[--w8],[w13]
			ADD		A						; A=(Pr[k]+Pr[N-k])/2
			SFTAC	A,#1	
			SUB		B						; Gr[N]=(Pr[k]-Pr[N-k])/2

			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Radd[k]=(Pr[k]+Pr[N-k])/2


			MOV		[w13++],[W9++]
			MOV		[w13--],[w9++]			; Rsub[k]=(Pr[k]-Pr[N-k])/2
	

			LAC		[++w9],A				; A=Pi[N-k]	
			MOV		[--w9],[w12]	
			LAC		[++w8],B				; B=Pi[k]	
			MOV		[--w8],[w13]
			ADD		A						; A=(Pi[k]+Pi[N-k])/2
			SFTAC	A,#1	
			SUB		B						; Gr[N]=(Pi[k]-Pi[N-k])/2


			MOV		[w12++],[W9++]
			MOV		[w12--],[w9--]			; Iadd[k]=(Pi[k]+Pi[N-k])/2


			MOV		[w13++],[W8++]
			MOV		[w13--],[w8++]			; Isub[k]=(Pi[k]-Pi[N-k])/2

											; w9---> Gi[N-k],
			SUB		w8,#8					; w8---> Gr[k]

			MERGE_BFLY_MACRO_PSV
		
			MOV		[w14+TF_INDX],w0
			ADD		w10,w0,w10				; Next Twiddle Factor (Wr)
BIN_END_PSV:	ADD		w11,w0,w11				; Next Twiddle Factor (Wi)


			LAC		[++W8],A				; B=Pr(N/2)	
			MOV		[--w8],[w12]
			SFTAC	A,#1					
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gr(N/2)=Pr(N/2)/2

			LAC		[++W8],A				; B=Pi(N/2)	
			MOV		[--w8],[w12]
			SFTAC	A,#1					
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gi(N/2)=Pi(N/2)/2

		    BRA     _DONEREALIFFT

_COPYTOSTACK:
			MOV     W15,W7
			
        	MOV	   #TF_FFT_SIZE,W9		; 
	        SL     W9,W12               ; 
         	ADD    W9,W12,W9            ; TABLE_SIZE IN WORDS
			
        	; COPY ENTIRE TWIDDLE TABLE TO STACK
	        DEC    W9,W13           ; REPEAT COUNT
	        REPEAT W13              ; SET REPEAT COUNT
	        MOV    [W2++],[w15++]   ; copy from PSV to stack
	
; Store Input Parameters
			MOV		w7,w11					; w11 ---> Wi = SIN(*)
	
			MOV		#TF_FFT_SIZE,W8
			ADD		w7,w8,w7
			MOV		w7,W10					; w10 ---> Wr = COS(*)

			MOVPAG	#0x01,DSRPAG
			NOP
			BRA     _INPUTPARAMSSTORED

_NOPSV:
			MOVPAG	#0x01,DSRPAG
			NOP

.else	
			MOV		w3,PSVPAG		
			BSET	CORCON,#2
.endif

; Store Input Parameters
			MOV		w2,w11					; w11 ---> Wi = SIN(*)
	
			MOV		#TF_FFT_SIZE,W8
			ADD		w2,w8,w2
			MOV		w2,W10					; w10 ---> Wr = COS(*)

_INPUTPARAMSSTORED:
			MOV		w1,w8					; W8  ---> Pr[0], first bin
			MOV		#8,w2
			SL		w2,w0,w2
			ADD		w1,w2,w9				; w9 ---> Pr[N], last bin

			LSR		w2,#4,w6				; N/2
			SUB		w6,#2,w6				; w6 = BIN_CNTR = (N/2)-2


			SUBR	w0,#TF_FFT_STG,w1
			MOV		#2,w2								
			SL		w2,w1,w2				; TF_INDX=TF_FFT_SIZE/FFT_SIZE
			MOV		w2,[w14+TF_INDX]


			ADD		w10,w2,w10				; Next Twiddle Factor (Wr)
			ADD		w11,w2,w11				; Next Twiddle Factor (Wi)

			MOV		#ACCAL,w12				; w12 ---> A
			MOV		#ACCBL,w13				; W13 ---> B
			


; DC and Nyquist Bin
			LAC		[++w8],A				; A=Pr[0]	
			MOV		[--w8],[w12]	

			LAC		[++w9],B				; B=Pr[N]	
			MOV		[--w9],[w13]
			

			ADD		A
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gr[0]=(Pr[0]+Pr[N]
			
			SUB		A		
			SUB		A					
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gi[0]=(Pr[0]-Pr[N])						
			
			CLR		[w9++]								
			CLR		[w9++]					; Gr[N]=0
			CLR		[w9++]								
			CLR		[w9++]					; Gi[N]=0

			SUB		w9,#16					; w9---> Gr[N-1], w8---> Gr[1]


; Bin 1 to N-1, k=1:(N/2-1)
			DO 		w6,BIN_END
BIN_START:
			LAC		[++w9],A				; A=Pr[N-k]	
			MOV		[--w9],[w12]	
			LAC		[++w8],B				; B=Pr[k]	
			MOV		[--w8],[w13]
			ADD		A						; A=(Pr[k]+Pr[N-k])/2
			SFTAC	A,#1	
			SUB		B						; Gr[N]=(Pr[k]-Pr[N-k])/2

			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Radd[k]=(Pr[k]+Pr[N-k])/2


			MOV		[w13++],[W9++]
			MOV		[w13--],[w9++]			; Rsub[k]=(Pr[k]-Pr[N-k])/2
	

			LAC		[++w9],A				; A=Pi[N-k]	
			MOV		[--w9],[w12]	
			LAC		[++w8],B				; B=Pi[k]	
			MOV		[--w8],[w13]
			ADD		A						; A=(Pi[k]+Pi[N-k])/2
			SFTAC	A,#1	
			SUB		B						; Gr[N]=(Pi[k]-Pi[N-k])/2


			MOV		[w12++],[W9++]
			MOV		[w12--],[w9--]			; Iadd[k]=(Pi[k]+Pi[N-k])/2


			MOV		[w13++],[W8++]
			MOV		[w13--],[w8++]			; Isub[k]=(Pi[k]-Pi[N-k])/2

											; w9---> Gi[N-k],
			SUB		w8,#8					; w8---> Gr[k]

			MERGE_BFLY_MACRO
		
			MOV		[w14+TF_INDX],w0
			ADD		w10,w0,w10				; Next Twiddle Factor (Wr)
BIN_END:	ADD		w11,w0,w11				; Next Twiddle Factor (Wi)


			LAC		[++W8],A				; B=Pr(N/2)	
			MOV		[--w8],[w12]
			SFTAC	A,#1					
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gr(N/2)=Pr(N/2)/2

			LAC		[++W8],A				; B=Pi(N/2)	
			MOV		[--w8],[w12]
			SFTAC	A,#1					
			MOV		[w12++],[W8++]
			MOV		[w12--],[w8++]			; Gi(N/2)=Pi(N/2)/2
		
_DONEREALIFFT:

;............................................................................
; Context Restore
			ULNK
.ifndef PSV_ON
			POP 	DSRPAG
	.else
			POP		PSVPAG
	.endif	
			POP		CORCON
			POP.D	w12					; {w12,w13} from TOS
			POP.D	w10					; {w10,w11} from TOS
			POP.D	w8					; {w8,w9} from TOS
;............................................................................
			RETURN	

