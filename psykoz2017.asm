.filenamespace psykoz2017
:BasicUpstart2(mainStartup)

//----------------------------------------------------------
//				Variables
//----------------------------------------------------------
.const			D = 0
.const 			A = 1
.const 			M = 2
.const 			O = 3
.const 			N = 4
.const 			EE = 5
.const 			S = 6
.const			Sp = 7

.var			debug = true
.var 			music = LoadSid("Nevernever201708230d.sid")
.const 			irqpointer = $0314
.const			scrollLine = 24

//----------------------------------------------------------

//----------------------------------------------------------
//				Main Startup Code
//----------------------------------------------------------
mainStartup:
* = mainStartup "Main Startup"
				sei
		:SetupIRQ(examplePart.partIrqStart, examplePart.partIrqStartLine, false)

		:FillScreen($0400,$20,$d800,BLACK)
		:CopyLogo(logo, logo + $300, $d800, $e800)
				jsr examplePart.partInit

				cli
				jmp examplePart.partJump


examplePart: {
.pc = $0b00 "ExamplePart"
//----------------------------------------------------------
.var 			rastertimeMarker = debug ? $d020 : $d024
.label			partIrqStartLine = $14
.label			spriteIrqStartLine = $20 - 4
.label			scrollIrqStartLine = $96
.label			musicIrqStartLine = $A9
.label			scrollTopSpritesStartLine = $bf
.label			openBordersLine = $fa
//----------------------------------------------------------
partInit:
// init music
				ldx #0
				ldy #0
				lda #music.startSong-1
				jsr music.init

// init sprites
				lda #%01111111 // set sprites 0-7 on
				sta $d015

				.for (var i = 0; i < 7; i++) {
					lda #$C0 + i
					sta $07F8 + i
				}

				lda #$ff // stretch sprite x
				sta $d01d


				lda #0
				sta spriteXPtr // sprite x ptr
				sta spriteYPtr // sprite y ptr
				sta spriteXLocPtr // sprite x loc ptr

// init scroll
				sta scrollTextSmooth

				lda #<scrollText
				sta scrollTextPtr

				lda #>scrollText
				sta scrollTextPtr + 1

				ldx #0
				
!:
				lda (scrollPalette), x
				sta $d800 + (40 * scrollLine), x
				inx
				cpx #40
				bne !-

				lda $d016
				and #%11110111
				sta $d016

				rts
//----------------------------------------------------------
partIrqStart: {
// reset smooth scroll...
				lda #$1b
				sta $d011
				lda #0
				sta $d015
				DebugRaster(1)

				lda $d016
				and #%11111000
				sta $d016

			.for (var i = 0; i < 8; i++) {
				lda #$C0 + i
				sta $07F8 + i
			}

				lda #0
				sta $d020
				sta $d021

		:EndIRQ(SpriteIrqStart,spriteIrqStartLine,false)
}

SpriteIrqStart: {
				DebugRaster(2)
				lda #$ff
				sta $d015

				dec spriteXPtr // sprite x ptr

				dec spriteYPtr // sprite y ptr
				dec spriteYPtr

				dec spriteXLocPtr // sprite x loc ptr
				dec spriteXLocPtr
				dec spriteXLocPtr

				ldy #0
				sty spriteHiLoTmp

			.for (var j=0; j<7; j++) {
				lda spriteXPtr
				adc #23 * j
				tax
				lda sinTblX, x
				ldx spriteXLocPtr
				adc sinTblY, x
				sta $d000 + j * 2 

				bcc no_overflow
				tya 
				ora #1 << j
				tay
no_overflow:				

				lda spriteYPtr
				adc #17 * j
				tax
				lda sinTblY, x
				adc #40
				sta $d001  + j * 2

				txa 
				ror
				clc
				ror
				clc
				tax

				lda spritePalette, x
				sta $d027 + j

				lda spriteHiLo, x
				cmp #1
				bne !+

				lda spriteHiLoTmp
				ora #1 << j
				sta spriteHiLoTmp
!:				

			}

				tya
				sta $d010

				lda spriteHiLoTmp
				sta $d01B

				DebugRaster(0)
		:EndIRQ(scrollIrqStart,scrollIrqStartLine,false)

}

scrollIrqStart: {
				DebugRaster(1)

				dec scrollTextSmooth
				lda scrollTextSmooth
				and #%00000111
				tax

				lda $d016
				and #%11111000
				sta $d016
				
				txa
				ora $d016
				sta $d016

				txa
				cmp #7
				bne onlysmooth

				lda scrollTextPtr
				adc #0
				sta scrollTextPtr

				bcc !+

				lda scrollTextPtr + 1
				adc #0
				sta scrollTextPtr + 1
!:
				
onlysmooth:
				ldy #0
				ldx #40

!:
				lda (scrollTextPtr), y
				sta $0400 + (40 * scrollLine), y

				iny

				dex
				bne !-

				lda (scrollTextPtr), y
				cmp #0
				bne !+

				lda #<scrollText
				sta scrollTextPtr

				lda #>scrollText
				sta scrollTextPtr + 1
!:

				DebugRaster(0)
		:EndIRQ(musicIrqStart,musicIrqStartLine,false)


}

musicIrqStart: {
				DebugRaster(4)
				jsr music.play 
				DebugRaster(0)

		:EndIRQ(scrollTopSprites,scrollTopSpritesStartLine,false)
}


openBorders: {
				lda #0
				sta $d015

				lda #0
				sta $d011
	:EndIRQ(partIrqStart,partIrqStartLine,false)

}


partJump:
				jmp *
}

colors1:
//				.text "fncmagolk@fncmagolk@fncmagolk@fncmagolk@"
colorend:



* = $4000 "scrollText"
sinTblX: 		.byte 100,102,104,107,109,112,114,117,119,121,124,126,129,131,133,135,138,140,142,144,147,149,151,153,155,157,159,161,163,165,167,168,170,172,174,175,177,178,180,181,183,184,185,187,188,189,190,191,192,193,194,194,195,196,197,197,198,198,198,199,199,199,199,199,200,199,199,199,199,199,198,198,198,197,197,196,195,194,194,193,192,191,190,189,188,187,185,184,183,181,180,178,177,175,174,172,170,168,167,165,163,161,159,157,155,153,151,149,147,144,142,140,138,135,133,131,129,126,124,121,119,117,114,112,109,107,104,102,100,97,95,92,90,87,85,82,80,78,75,73,70,68,66,64,61,59,57,55,52,50,48,46,44,42,40,38,36,34,32,31,29,27,25,24,22,21,19,18,16,15,14,12,11,10,9,8,7,6,5,5,4,3,2,2,1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,2,3,4,5,5,6,7,8,9,10,11,12,14,15,16,18,19,21,22,24,25,27,29,31,32,34,36,38,40,42,44,46,48,50,52,55,57,59,61,64,66,68,70,73,75,78,80,82,85,87,90,92,95,97
sinTblY: 		.byte 64,65,67,68,70,71,73,74,76,78,79,81,82,84,85,87,88,89,91,92,94,95,96,98,99,100,102,103,104,105,106,108,109,110,111,112,113,114,115,116,117,118,118,119,120,121,121,122,123,123,124,124,125,125,126,126,126,127,127,127,127,127,127,127,128,127,127,127,127,127,127,127,126,126,126,125,125,124,124,123,123,122,121,121,120,119,118,118,117,116,115,114,113,112,111,110,109,108,106,105,104,103,102,100,99,98,96,95,94,92,91,89,88,87,85,84,82,81,79,78,76,74,73,71,70,68,67,65,64,62,60,59,57,56,54,53,51,49,48,46,45,43,42,40,39,38,36,35,33,32,31,29,28,27,25,24,23,22,21,19,18,17,16,15,14,13,12,11,10,9,9,8,7,6,6,5,4,4,3,3,2,2,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,2,3,3,4,4,5,6,6,7,8,9,9,10,11,12,13,14,15,16,17,18,19,21,22,23,24,25,27,28,29,31,32,33,35,36,38,39,40,42,43,45,46,48,49,51,53,54,56,57,59,60,62

sinTblTextX: 	
				.byte 0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,6,6,6,6,6,6,6,6,6,5,5,5,5,5,5,5,4,4,4,4,4,4,3,3,3,3,3,3,2,2,2,2,2,1,1,1,1,1,0,0,0,0,0,0,-1,-1,-1,-1,-1,-2,-2,-2,-2,-2,-3,-3,-3,-3,-3,-4,-4,-4,-4,-4,-4,-5,-5,-5,-5,-5,-5,-6,-6,-6,-6,-6,-6,-6,-7,-7,-7,-7,-7,-7,-7,-7,-7,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-7,-7,-7,-7,-7,-7,-7,-7,-7,-6,-6,-6,-6,-6,-6,-6,-5,-5,-5,-5,-5,-5,-4,-4,-4,-4,-4,-4,-3,-3,-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1
				.byte 0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,6,6,6,6,6,6,6,6,6,5,5,5,5,5,5,5,4,4,4,4,4,4,3,3,3,3,3,3,2,2,2,2,2,1,1,1,1,1,0,0,0,0,0,0,-1,-1,-1,-1,-1,-2,-2,-2,-2,-2,-3,-3,-3,-3,-3,-4,-4,-4,-4,-4,-4,-5,-5,-5,-5,-5,-5,-6,-6,-6,-6,-6,-6,-6,-7,-7,-7,-7,-7,-7,-7,-7,-7,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-7,-7,-7,-7,-7,-7,-7,-7,-7,-6,-6,-6,-6,-6,-6,-6,-5,-5,-5,-5,-5,-5,-4,-4,-4,-4,-4,-4,-3,-3,-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1

spritePalette:	.byte  1, 1, 1, 1, 1, 1, 1, 1
				.byte  1, 1, 1, 1, 3, 3, 3,14
				.byte 14,14, 6, 6, 6,11,11,11
				.byte  0, 0, 0, 0, 0, 0, 0, 0
				.byte  0, 0, 0, 0, 0, 0, 0, 0
				.byte 11,11,11, 6, 6, 6,14,14
				.byte 14, 3, 3, 3, 1, 1, 1, 1
				.byte  1, 1, 1, 1, 1, 1, 1, 1

spriteHiLo: 	
				.byte  0, 0, 0, 0, 0, 0, 0, 0
				.byte  0, 0, 0, 0, 0, 0, 0, 0
				.byte  1, 1, 1, 1, 1, 1, 1, 1
				.byte  1, 1, 1, 1, 1, 1, 1, 1
				.byte  1, 1, 1, 1, 1, 1, 1, 1
				.byte  1, 1, 1, 1, 1, 1, 1, 1
				.byte  0, 0, 0, 0, 0, 0, 0, 0
				.byte  0, 0, 0, 0, 0, 0, 0, 0

textSpriteArr:
				.byte 7,7,7,7,7,7,7,7
				.byte Sp,S,A,N,D,Sp,Sp,Sp
				.byte Sp,M,EE,S,A,Sp,Sp,Sp
				.byte Sp,M,A,D,EE,Sp,Sp,Sp

				.byte Sp,A,Sp,D,A,M,Sp,Sp
				.byte 7,7,7,7,7,7,7,7
				.byte 7,7,7,7,7,7,7,7
				.byte Sp,Sp,S,O,N,EE,Sp,Sp

				.byte Sp,Sp,M,O,D,EE,Sp,Sp
				.byte Sp,Sp,N,O,D,Sp,Sp,Sp
				.byte Sp,Sp,M,EE,N,Sp,Sp,Sp
				.byte 7,7,7,7,7,7,7,7

				.byte 7,7,7,7,7,7,7,7
				.byte S,EE,M,EE,N,Sp,Sp,Sp
				.byte Sp,M,EE,A,D,Sp,Sp,Sp
				.byte A,M,EE,N,D,S,Sp,Sp

				.byte D,A,M,EE,S,Sp,Sp,Sp
				.byte 7,7,7,7,7,7,7,7
				.byte 7,7,7,7,7,7,7,7
				.byte N,O,M,A,D,S,Sp,Sp,Sp

				.byte Sp,M,O,A,N,Sp,Sp,Sp
				.byte Sp,A,M,EE,N,Sp,Sp,Sp
				.byte 7,7,7,7,7,7,7,7
				.byte 7,7,7,7,7,7,7,7

				.byte D,EE,M,O,N,S,Sp,Sp
				.byte Sp,M,A,D,EE,Sp,Sp,Sp
				.byte Sp,Sp,M,EE,Sp,Sp,Sp,Sp
				.byte Sp,Sp,D,O,Sp,Sp,Sp,Sp

				.byte A,Sp,D,EE,M,O,Sp,Sp
				.byte 7,7,7,7,7,7,7,7
				.byte 7,7,7,7,7,7,7,7
				.byte 7,7,7,7,7,7,7,7




spriteKerning:	
				.byte 4, 2, 4, 2, -4, 10, 4, 4
				.byte 4, 0, 4, 4, 3, 2, 8, 8

scrollText:
				.text "                                        hello! my name is zados of damones, the true founder of it with irwin the magnificent boozer. damones was a joke, still is but still standing, so no worries about that... i love c64 bcos it was my first compuke, not forgetting amiga but i lost them both over 20 years ago. you know, emulating them is mastubating. no more c64, no more amiga. only personal cerebral compuking nowadays. once upon a time there was mhz, now ghz and tomorrow thz but you only need 1 mhz to prove you are living. pixelate your brains. be brave and drunk. this scroll shall be in a product / demo i have never heard of, but i am forced to write some words of wastedom. madness! at this point i would love to send my regards to lamers. scream your dreams, whisk your creams. fuck, i am tired of writing and thinking... too many beers. too drunk to fuck et cetera. a new start tomorrow... i thank you for the years, 26 years... i don't know why but grab a brew for it. and tomorrow i shan't drink never again ever! common thread is lost, totally. damones makes sense. suck my cucumber, rabbits! this is the end, finally. zados says goofoo!                                 demons made me do a demo -- a quick and dirty hack for psykoz 2017 -- code: kakka -- music: zardax / ald -- gfx: h7 -- text: zados                     special greetings fly to spaceman x :)                                                   "
scrollTextEnd:
				.byte 0

scrollPalette:	.byte 11, 6, 14, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 14, 6, 11, 11

* = $2000 "Logo"
logo:
				.byte 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
				.byte 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
				.byte 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
				.byte 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
				.byte 32,32,32,32,85,255,32,32,32,32,32,32,32,32,86,123,32,32,32,32,32,32,32,32,32,108,86,104,98,98,98,85,98,98,123,32,32,32,32,32,32,32,32,32,74,224,98,98,123,104,32,32,32,32,32,251,123,32,32,32,32,32,32,32,108,236,32,224,224,236,226,105,224,224,92,32,32,32,32,32,111,111,111,111,108,98,124,226,251,224,252,98,98,111,225,255,224,123,111,111,111,111,111,108,224,97,252,98,224,98,111,124,226,251,32,111,111,111,111,111,111,111,111,111,32,224,224,92,111,111,95,236,224,224,97,224,254,224,123,111,111,111,108,224,127,224,104,124,226,251,224,252,123,32,111,111,111,111,111,111,111,32,32,111,111,251,224,97,111,111,32,95,234,224,97,251,244,224,224,123,32,108,224,224,224,224,222,224,105,123,124,224,224,252,123,111,32,32,111,111,32,77,32,77,77,225,224,92,67,32,77,106,224,224,97,251,224,234,124,224,98,224,105,244,224,224,244,224,236,67,67,225,163,224,251,32,77,32,77,77,111,111,77,78,78,124,224,224,223,32,108,233,224,105,116,225,224,224,123,124,224,105,108,224,224,97,224,163,252,32,32,254,224,224,97,111,111,77,78,78,67,67,67,67,67,67,224,224,224,252,224,224,105,126,67,225,224,226,126,67,67,67,225,236,126,67,74,224,224,252,224,224,224,236,67,67,67,67,67,67,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,14,14,14,14,14,6,5,5,5,14,14,14,14,10,6,6,6,14,14,14,14,14,14,6,6,6,6,6,6,3,6,14,3,14,6,14,14,14,14,14,14,14,14,14,6,14,14,14,6,6,14,14,14,14,10,14,6,14,14,14,14,14,14,14,6,6,5,14,3,3,14,14,3,14,6,14,14,14,14,14,11,11,11,11,6,6,6,14,14,3,3,6,6,6,6,14,1,14,11,12,1,12,11,6,1,6,6,14,14,14,6,6,14,6,14,11,11,12,15,1,12,12,1,15,14,14,3,14,11,12,14,3,1,3,6,14,1,14,6,11,12,11,6,3,3,14,6,6,14,14,14,6,6,5,11,15,15,12,12,11,1,1,14,11,11,14,3,14,11,12,14,14,1,14,6,14,1,14,14,6,12,6,14,14,3,14,3,1,14,6,6,3,3,6,6,11,12,14,15,11,12,1,12,11,11,6,14,14,11,12,12,6,3,14,6,6,3,14,6,14,14,14,14,14,14,14,14,1,6,11,11,14,3,14,6,14,12,15,1,11,11,11,15,11,11,6,14,14,14,14,6,14,14,14,6,6,14,14,6,6,14,14,6,14,14,6,14,3,6,14,14,14,14,14,6,11,11,15,1,11,11,11,11,11,11,11,6,14,14,14,14,14,14,6,11,6,3,14,6,11,11,11,6,6,14,11,14,14,14,6,14,14,14,6,11,11,11,11,11,11,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,10,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,10,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,10,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,10,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,10,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
logoEnd:

scrollTopSprites: {
				DebugRaster(7)

				lda textSpriteXPtr
				adc #1
				sta textSpriteXPtr

				clc
				lda textSpriteSlow
				adc #1
				clc
				sta textSpriteSlow
				cmp #15
				bne !+
				lda #0
				sta textSpriteSlow

				clc
				lda textSpritePtr
				adc #1
				sta textSpritePtr

!:				
				lda textSpritePtr

				clc
				ror

				clc
				ror

				clc
				ror

				clc

				rol
				rol
				rol
				tax

				lda #0
				sta textSpriteHiXPos


				sta textSpritestartPos

				lda #0
				sta textSpritestartPos + 1

			.for (var i = 0; i < 8; i++) {
				lda #218
				sta $D001 + i * 2

				clc
				lda textSpriteArr, x
				adc #$C0
				clc
				sta $07F8 + i


				lda textSpriteArr, x
				rol
				tay

				txa
				pha

				lda i * 11
				adc textSpriteXPtr
				tax
				ldx textSpriteXPtr
				lda #36
				adc sinTblTextX + i * 17, x
				clc
				sta textSpriteXJemma

				pla
				tax
				lda textSpriteXJemma

				sbc spriteKerning, y
				clc

				adc textSpritestartPos + 1
				sta textSpritestartPos + 1

				bcc !+
				lda textSpritestartPos
				adc #1
				sta textSpritestartPos
				clc

				lda #1 <<  i
				ora textSpriteHiXPos
				sta textSpriteHiXPos

!:
				lda textSpritestartPos + 1
				sta $d000 + i * 2

				adc spriteKerning + 1, y
				sta textSpritestartPos + 1

				bcc !+
				lda textSpritestartPos
				adc #1
				sta textSpritestartPos
				clc
!:

				lda spritePalette,y
				sta $d027 + i

				inx
			}

			lda textSpriteHiXPos
			sta $d010

/*
				lda #%00000000
				sta $d010
*/
				DebugRaster(0)

		:EndIRQ(examplePart.openBorders,examplePart.openBordersLine,false)

}

* = $10 "Zeropage" virtual
.zp {
	spriteXPtr: .byte 0
	spriteYPtr: .byte 0
	spriteXLocPtr: .byte 0
	spriteHiLoTmp: .byte 0
	textSpriteHiXPos: .byte 0
	textSpritePtr: .byte 0
	textSpritestartPos: .word 0
	textSpriteXPtr: .byte 0
	textSpriteXJemma: .byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte 0

	textSpriteSlow: .byte 0
}

scrollTextSmooth: .byte 0
scrollTextPtr: .byte 0,0


//

//----------------------------------------------------------
//----------------------------------------------------------
//	Macros
//----------------------------------------------------------
.macro SetupIRQ(IRQaddr,IRQline,IRQlineHi) {
				lda #<IRQaddr
				sta irqpointer
				lda #>IRQaddr
				sta irqpointer+1
				lda #$1f
				sta $dc0d
				sta $dd0d
				lda #$81
				sta $d01a
				sta $d019
		.if(IRQlineHi) {
				lda #$9b
		} else {
				lda #$1b
		}
				sta $d011
				lda #IRQline
				sta $d012
}
//----------------------------------------------------------
.macro EndIRQ(nextIRQaddr,nextIRQline,IRQlineHi) {
				asl $d019
				lda #<nextIRQaddr
				sta irqpointer
				lda #>nextIRQaddr
				sta irqpointer+1
				lda #nextIRQline
				sta $d012
		.if(IRQlineHi) {
				lda $d011
				ora #$80
				sta $d011
		}	
				jmp $febc
}

.macro FillScreen(screen,char,colorbuff,color) {
				ldx #$00
loop:
		.for(var i=0; i<3; i++) {
				lda #char
				sta screen+[i*$100],x
				lda #color
				sta colorbuff+[i*$100],x
		}
				lda #char
				sta screen+[$2e8],x
				lda #color
				sta colorbuff+[$2e8],x
				inx
				bne loop
}

.macro CopyLogo(charStart, colorStart, charTargetStart, colorTargetStart) {

				lda #>charStart
				sta $fc
				lda #<charStart
				sta $fd

				lda #$04
				sta $fe

				lda #>colorTargetStart
				sta $f9

				lda #>colorStart
				sta $fa
				lda #<colorStart
				sta $fb

				lda #>charTargetStart
				sta $f8
				lda #<charTargetStart
				sta $f7

				ldx #$00
				ldy #$00
loop:
				lda ($fb),y
				sta ($fd),y
				lda ($f9),y
				sta ($f7),y
				iny
				bne loop

				inc $fc
				inc $fe
				inc $fa
				inc $f8

				inx
				cpx #$02
				bne loop
}


.macro DebugRaster(color) {
	.if (debug) {
		pha
		lda #0 + color
		sta $d020
		sta $d021
		pla
	}
}

*=music.location "Music"
.fill music.size, music.getData(i)

* = $3000 "Sprites"
.var sprites = LoadPicture("damones_sprite.png")
.for (var s = 0; s < 8; s++) {

	.for (var y=0; y<21; y++) {
		.for (var x=0; x<3; x++)
				.byte sprites.getSinglecolorByte(x, y + (s * 21))
	}

	.byte 0 // padding
}

.print ""
.print "SID Data"
.print "--------"
.print "location=$"+toHexString(music.location)
.print "init=$"+toHexString(music.init)
.print "play=$"+toHexString(music.play)
.print "songs="+music.songs
.print "startSong="+music.startSong
.print "size=$"+toHexString(music.size)
.print "name="+music.name
.print "author="+music.author
.print "copyright="+music.copyright
.print ""
.print "Additional tech data"
.print "--------------------"
.print "header="+music.header
.print "header version="+music.version
.print "flags="+toBinaryString(music.flags)
.print "speed="+toBinaryString(music.speed)
.print "startpage="+music.startpage
.print "pagelength="+music.pagelength


