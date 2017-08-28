.filenamespace psykoz2017
:BasicUpstart2(mainStartup)

//----------------------------------------------------------
//				Variables
//----------------------------------------------------------
.var			debug = false
.var 			music = LoadSid("acid_jazz.sid")
.var			musicEnabled = false
.const 			irqpointer = $0314

//----------------------------------------------------------

//----------------------------------------------------------
//				Main Startup Code
//----------------------------------------------------------
mainStartup:
* = mainStartup "Main Startup"
				lda #$00
				sta $d020
				sta $d021
				jsr examplePart.partInit
				sei
		:SetupIRQ(examplePart.partIrqStart, examplePart.partIrqStartLine, false)
		:FillScreen($0400,$20,$d800,BLACK)
				cli
				jmp examplePart.partJump
//----------------------------------------------------------
examplePart: {
.pc = $0b00 "ExamplePart"
//----------------------------------------------------------
.var 			rastertimeMarker = debug ? $d020 : $d024
.label			partIrqStartLine = $14
//----------------------------------------------------------
partInit:
// init music
				ldx #0
				ldy #0
				lda #music.startSong-1
				jsr music.init

// init sprites
				lda #0

				.for (var i = 0; i < 7; i++) {
					sta $d000 + i
					sta $d001 + i
				}

				lda #%01111111 // set sprites 0-7 on
				sta $d015

				.for (var i=0; i<7; i++) {
					lda #$C0 + i
					sta $07F8 + i
				}

				lda #$30
				sta $cf
				lda #$10
				sta $ce

				rts
//----------------------------------------------------------
partIrqStart: {
			.for(var j=0; j<7; j++) {
				nop
			}				
				ldx #$00
!:
				lda colors1,x
				sta $d020
				sta $d021
			.for(var j=0; j<22; j++) {
				nop
			}				
				inx
				cpx #colorend-colors1
				bne !-


				lda #01
				sta $d020
				sta $d021
				jsr music.play 

				inc $cf

				inc $ce
				inc $ce

				lda #03
				sta $d020
				sta $d021

			.for (var j=0; j<7; j++) {
				lda $cf
				adc #23 * j
				tax
				lda sinTblX, x
				adc #40
				sta $d000 + j * 2 

				lda $ce
				adc #17 * j
				tax
				lda sinTblY, x
				sta $d001  + j * 2 
			}
				lda #0
				sta $d020
				sta $d021
		:EndIRQ(partIrqStart,partIrqStartLine,false)
}

colors1:
				.text "fncmagolk@fncmagolk@fncmagolk@fncmagolk@"
colorend:

scrollText:
				.text "abcdefghijklmnopqrstuvxyz ABCEDFGHIJKLMNOPQRSTUVXYZ 01234567890asdasdasdjadsljkadsl kads ljk"
scrollTextEnd:

sinTblX: 		.byte 100,102,104,107,109,112,114,117,119,121,124,126,129,131,133,135,138,140,142,144,147,149,151,153,155,157,159,161,163,165,167,168,170,172,174,175,177,178,180,181,183,184,185,187,188,189,190,191,192,193,194,194,195,196,197,197,198,198,198,199,199,199,199,199,200,199,199,199,199,199,198,198,198,197,197,196,195,194,194,193,192,191,190,189,188,187,185,184,183,181,180,178,177,175,174,172,170,168,167,165,163,161,159,157,155,153,151,149,147,144,142,140,138,135,133,131,129,126,124,121,119,117,114,112,109,107,104,102,100,97,95,92,90,87,85,82,80,78,75,73,70,68,66,64,61,59,57,55,52,50,48,46,44,42,40,38,36,34,32,31,29,27,25,24,22,21,19,18,16,15,14,12,11,10,9,8,7,6,5,5,4,3,2,2,1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,2,3,4,5,5,6,7,8,9,10,11,12,14,15,16,18,19,21,22,24,25,27,29,31,32,34,36,38,40,42,44,46,48,50,52,55,57,59,61,64,66,68,70,73,75,78,80,82,85,87,90,92,95,97
sinTblY: 		.byte 64,65,67,68,70,71,73,74,76,78,79,81,82,84,85,87,88,89,91,92,94,95,96,98,99,100,102,103,104,105,106,108,109,110,111,112,113,114,115,116,117,118,118,119,120,121,121,122,123,123,124,124,125,125,126,126,126,127,127,127,127,127,127,127,128,127,127,127,127,127,127,127,126,126,126,125,125,124,124,123,123,122,121,121,120,119,118,118,117,116,115,114,113,112,111,110,109,108,106,105,104,103,102,100,99,98,96,95,94,92,91,89,88,87,85,84,82,81,79,78,76,74,73,71,70,68,67,65,64,62,60,59,57,56,54,53,51,49,48,46,45,43,42,40,39,38,36,35,33,32,31,29,28,27,25,24,23,22,21,19,18,17,16,15,14,13,12,11,10,9,9,8,7,6,6,5,4,4,3,3,2,2,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,2,3,3,4,4,5,6,6,7,8,9,9,10,11,12,13,14,15,16,17,18,19,21,22,23,24,25,27,28,29,31,32,33,35,36,38,39,40,42,43,45,46,48,49,51,53,54,56,57,59,60,62
//

//----------------------------------------------------------
partJump:
				jmp *
//----------------------------------------------------------
}
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
//----------------------------------------------------------
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
//----------------------------------------------------------

*=music.location "Music"
.fill music.size, music.getData(i)

*=$3000
.var sprites = LoadPicture("damones_sprite.png")
.for (var s = 0; s < 7; s++) {

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


