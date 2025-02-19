.386
.model flat,stdcall
option casemap:none

include         windows.inc
include			msvcrt.inc

include         gdi32.inc
includelib      gdi32.lib
include         user32.inc
includelib      user32.lib
include         kernel32.inc
includelib      kernel32.lib
includelib      msvcrt.lib
include			Global.inc

generateNewPieces PROTO
___test PROTO tt:DWORD
Hurt_By_Mov PROTO _Start:POINT,_End:POINT
Hurt_By_Detonate PROTO
.code


;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;工具函数
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
getPiece proc res:DWORD,X:DWORD,Y:DWORD
	pushad
	mov esi,offset pieces
	mov edi,res
	mov eax,X
	mov ebx,Y
	imul eax,lineSize
	imul ebx,type Piece
	add eax,ebx
	mov ecx,(Piece PTR [esi+eax]).pcolor
	mov (Piece PTR [edi]).pcolor,ecx
	mov ecx,(Piece PTR [esi+eax]).psize
	mov (Piece PTR [edi]).psize,ecx
	mov ecx,(Piece PTR [esi+eax]).LstX
	mov (Piece PTR [edi]).LstX,ecx
	mov ecx,(Piece PTR [esi+eax]).LstY
	mov (Piece PTR [edi]).LstY,ecx
	mov ecx,(Piece PTR [esi+eax]).Status
	mov (Piece PTR [edi]).Status,ecx
	popad
	ret
getPiece endp

setPiece proc X:DWORD,Y:DWORD,pcolor:DWORD,psize:DWORD
	pushad
	mov esi,offset pieces
	mov eax,X
	mov ebx,Y
	imul eax,lineSize
	imul ebx,type Piece
	add eax,ebx
	mov ecx,pcolor
	mov (Piece PTR [esi+eax]).pcolor,ecx
	mov ecx,psize
	mov (Piece PTR [esi+eax]).psize,ecx
	popad
	ret
setPiece endp

setPieceLstPos proc X:DWORD,Y:DWORD,lstx:DWORD,lsty:DWORD,status:DWORD
	pushad
	mov esi,offset pieces
	mov eax,X
	mov ebx,Y
	imul eax,lineSize
	imul ebx,type Piece
	add eax,ebx
	mov ecx,lstx
	mov (Piece PTR [esi+eax]).LstX,ecx
	mov ecx,lsty
	mov (Piece PTR [esi+eax]).LstY,ecx
	mov ecx,status
	mov (Piece PTR [esi+eax]).Status,ecx
	popad
	ret
setPieceLstPos endp

CleanPieceStatus proc USES edx ecx
	mov ecx,0
	.While ecx < BoardWidth
		mov edx,0
		.While edx < BoardWidth
		pushad
			invoke setPieceLstPos,ecx,edx,ecx,edx,0
		popad
		inc edx
		.ENDW
		inc ecx
	.ENDW
	ret
CleanPieceStatus endp



setNearbyPiece proc USES esi eax ebx ecx X:DWORD, Y:DWORD, offsetX:DWORD, offsetY:DWORD, pcolor:DWORD, psize:DWORD
	mov esi,offset pieces
	mov eax,X
	mov ebx,Y
	add eax, offsetX
	add ebx, offsetY
	mov ecx, BoardWidth
	.IF eax >= 0 && ebx >=0 && eax < ecx && ebx < ecx
		imul eax,lineSize
		imul ebx,type Piece
		add eax,ebx
		mov ecx,pcolor
		mov (Piece PTR [esi+eax]).pcolor, ecx
		mov ecx,psize
		mov (Piece PTR [esi+eax]).psize, ecx
	.ENDIF
	ret
setNearbyPiece endp

getNearbyPiece proc USES ecx piecePtr:DWORD, X:DWORD, Y:DWORD, offsetX:DWORD, offsetY:DWORD
	LOCAL @x
	LOCAL @y
	mov ecx, X
	mov @x, ecx
	mov ecx, Y
	mov @y, ecx 
	mov ecx, offsetX
	add @x, ecx
	mov ecx, offsetY
	add @y, ecx
	mov ecx, BoardWidth
	.IF @x >= 0 && @y >=0 && @x < ecx && @y < ecx
		invoke getPiece, piecePtr, @x, @y
	.ELSE
		mov ecx, piecePtr
		mov (Piece PTR [ecx]).psize, 0
		mov (Piece PTR [ecx]).pcolor, 0
	.ENDIF
	ret
getNearbyPiece endp

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;逻辑更新
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;设置重绘标签
resetSelect proc
	push eax
	mov eax,BoardWidth
	mov CellSelected1.x,eax
	mov CellSelected1.y,eax
	mov CellSelected2.y,eax
	mov CellSelected2.y,eax
	pop eax
	ret
resetSelect endp

Repaint proc
	mov rePaintLabel,1
	ret
Repaint endp

ExChange proc
	mov exChangeLabel,1
	ret
ExChange endp

changeSize proc
	.IF playerSize == 0
		mov playerSize,1
	.ELSE
		mov playerSize,0
	.ENDIF
	ret
changeSize endp


ResetExChange proc
	mov exChangeLabel,0
	ret
ResetExChange endp

checkPiece proc toUpdate:DWORD,hasBomb:DWORD,center:DWORD,_Start:DWORd,_End:DWord,X:DWORD,Y:DWORD
	LOCAL @vlen:DWORD
	LOCAL @hlen:DWORD
	LOCAL @res:Piece
	LOCAL @s1:Piece
	LOCAL @s2:Piece
	LOCAL @Start:POINT
	LOCAL @End:POINT
	LOCAL @Center:POINT
	LOCAL @existBomb:DWORD

	mov esi,hasBomb
	mov ebx,0
	mov [esi],ebx

	mov esi,toUpdate
	mov ebx,0
	mov [esi],ebx

	mov @existBomb,0

	mov @vlen,0
	mov @hlen,0
	
	invoke getPiece,addr @s1,X,Y

	mov eax,X
	mov ebx,@s1.pcolor
	.While eax >= 0
		push eax
		invoke getPiece,addr @res,eax,Y
		pop eax
		.IF @res.pcolor == ebx && @res.psize >= 1
			inc @hlen
			.IF @res.psize == 2 
				mov @existBomb,1
			.ENDIF
		.ELSE
			.break
		.ENDIF
		.IF eax == 0
			dec eax
			.break
		.ENDIF
		dec eax
	.EndW

	inc eax
	mov @Start.x,eax
	mov eax,Y
	mov @Start.y,eax

	mov esi,_Start
	mov (POINT PTR [esi]).y,eax
	mov eax,@Start.x
	mov (POINT PTR [esi]).x,eax

	mov eax,X
	inc eax
	.While eax < BoardWidth
		pushad
		invoke getPiece,addr @res,eax,Y
		popad
		.IF @res.pcolor == ebx && @res.psize >= 1
			inc @hlen
			.IF @res.psize == 2
				mov @existBomb,1
			.ENDIF
		.ELSE
			.break
		.ENDIF
		inc eax
	.EndW
	dec eax

	mov esi,_End
	mov (POINT PTR [esi]).x,eax
	mov eax,@Start.y
	mov (POINT PTR [esi]).y,eax

	.IF @hlen >= 3
		mov edx,0
		mov eax,@hlen
		mov ebx,2
		div ebx
		add @Start.x,eax
		mov esi,toUpdate
		mov ebx,1
		mov [esi],ebx
		mov esi,center
		mov eax,@Start.x
		mov (POINT PTR [esi]).x,eax
		mov eax,@Start.y
		mov (POINT PTR [esi]).y,eax
		.IF @existBomb == 1
			pushad
			mov esi,hasBomb
			mov ebx,1
			mov [esi],ebx
			popad
		.ENDIF
		ret
	.ELSEIF
		mov @existBomb,0
		mov eax,Y
		mov ebx,@s1.pcolor
		.While eax >= 0
			push eax
			invoke getPiece,addr @res,X,eax
			pop eax
			.IF @res.pcolor == ebx && @res.psize >= 1
				inc @vlen
				.IF @res.psize == 2 
					mov @existBomb,1
				.ENDIF
			.ELSE
				.break
			.ENDIF
			.IF eax == 0
				dec eax
				.break
			.ENDIF
			dec eax
		.EndW

		inc eax
		mov @Start.y,eax
		mov eax,X
		mov @Start.x,eax

		mov esi,_Start
		mov (POINT PTR [esi]).x,eax
		mov eax,@Start.y
		mov (POINT PTR [esi]).y,eax

		mov eax,Y
		inc eax
		.While eax < BoardWidth
			pushad
			invoke getPiece,addr @res,X,eax
			popad
			.IF @res.pcolor == ebx && @res.psize >= 1
				inc @vlen
				.IF @res.psize == 2 
					mov @existBomb,1
				.ENDIF
			.ELSE
				.break
			.ENDIF
			inc eax
		.EndW
		dec eax

		mov esi,_End
		mov (POINT PTR [esi]).y,eax
		mov eax,@Start.x
		mov (POINT PTR [esi]).x,eax

		.IF @vlen >= 3
			mov edx,0
			mov eax,@vlen
			mov ebx,2
			div ebx
			add @Start.y,eax
			
			mov esi,toUpdate
			mov ebx,1
			mov [esi],ebx
			mov esi,center
			mov eax,@Start.x
			mov (POINT PTR [esi]).x,eax
			mov eax,@Start.y
			mov (POINT PTR [esi]).y,eax
			.IF @existBomb == 1
				pushad
				mov esi,hasBomb
				mov ebx,1
				mov [esi],ebx
				popad
			.ENDIF
			ret
		.ENDIF
	.ENDIF
	ret
checkPiece endp

cleanPieces proc _Start:POINT,_End:POINT
	mov eax,_Start.x
	mov ebx,_End.x
	.IF eax == ebx
		mov eax,_Start.y
		mov ebx,_End.y
		.While eax<=ebx
			invoke setPiece,_Start.x,eax,0,0
			inc eax
		.EndW
	.ELSEIF
		.While eax<=ebx
			invoke setPiece,eax,_Start.y,0,0
			inc eax
		.EndW
	.ENDIF
	ret
cleanPieces endp


movPiece proc _Center:POINT,_Start:POINT,_End:POINT
	LOCAL @res:Piece
	LOCAl @LastPos:POINT

	invoke getPiece,addr @res,_Center.x,_Center.y
	invoke cleanPieces,_Start,_End
	invoke setPiece,_Center.x,_Center.y,@res.pcolor,@res.psize

	mov eax,_Start.x
	mov ebx,_End.x
	.IF eax == ebx
		mov eax,_Center.y
		sub eax,_Start.y
		mov ebx,_End.y
		sub ebx,_Center.y
		
		mov ecx,_Start.y
		.WHILE ecx>=0
			pushad
				pushad
					mov @LastPos.y,ecx
					mov ecx,_Start.x
					mov @LastPos.x,ecx
				popad
				push eax
				invoke getPiece,addr @res,_Start.x,ecx
				pop eax
				add ecx,eax
				push eax
				.IF ecx < _Center.y
						invoke setPiece,_Start.x,ecx,@res.pcolor,@res.psize
						invoke setPieceLstPos,_Start.x,ecx,@LastPos.x,@LastPos.y,1

				.ENDIF
				pop eax
				sub ecx,eax
				push eax
				invoke setPiece,_Start.x,ecx,@res.pcolor,0
				pop eax
			popad

			.IF ecx == 0
				.break
			.ENDIF
			dec ecx
		.ENDW


		mov ecx,_End.y
		.WHILE ecx<BoardWidth
			pushad
				pushad
					mov @LastPos.y,ecx
					mov ecx,_Start.x
					mov @LastPos.x,ecx
				popad
				push eax
				invoke getPiece,addr @res,_Start.x,ecx
				pop eax
				sub ecx,ebx
				push eax
					.IF ecx > _Center.y
						invoke setPiece,_Start.x,ecx,@res.pcolor,@res.psize
						invoke setPieceLstPos,_Start.x,ecx,@LastPos.x,@LastPos.y,1
				.ENDIF
				pop eax
				add ecx,ebx
				push eax
					invoke setPiece,_Start.x,ecx,@res.pcolor,0
				pop eax
			popad
			inc ecx
		.EndW
	.ELSEIF
		mov eax,_Center.x
		sub eax,_Start.x
		mov ebx,_End.x
		sub ebx,_Center.x

		mov ecx,_Start.x
		.While ecx >=0
			pushad
				pushad
					mov @LastPos.x,ecx
					mov ecx,_Start.y
					mov @LastPos.y,ecx
				popad
				push eax
				invoke getPiece,addr @res,ecx,_Start.y
				pop eax
				add ecx,eax
				push eax
				.IF ecx < _Center.x
						invoke setPiece,ecx,_Start.y,@res.pcolor,@res.psize
						invoke setPieceLstPos,ecx,_Start.y,@LastPos.x,@LastPos.y,1
				.ENDIF
				pop eax
				sub ecx,eax
				push eax
				invoke setPiece,ecx,_Start.y,@res.pcolor,0
				pop eax
			popad

			.IF ecx == 0
				.break
			.ENDIF
			dec ecx
		.ENDW

		mov ecx,_End.x
		.While ecx<BoardWidth
			pushad
				pushad
					mov @LastPos.x,ecx
					mov ecx,_Start.y
					mov @LastPos.y,ecx
				popad
				push eax
				invoke getPiece,addr @res,ecx,_Start.y
				pop eax
				sub ecx,eax
				push eax
				.IF ecx > _Center.x
						invoke setPiece,ecx,_Start.y,@res.pcolor,@res.psize
						invoke setPieceLstPos,ecx,_Start.y,@LastPos.x,@LastPos.y,1
				.ENDIF
				pop eax
				add ecx,eax
				push eax
				invoke setPiece,ecx,_Start.y,@res.pcolor,0
				pop eax
			popad
			inc ecx
		.ENDW
		
	.EndIF
	ret
movPiece endp

_detonate Proc proc X:DWORD,Y:DWORD
	LOCAl @res:Piece
	invoke Hurt_By_Detonate
	pushad
	invoke getPiece,addr @res,X,Y
	mov eax,X
	mov ebx,Y 
	
	.IF @res.psize <= 1
		push eax
			invoke setPiece,eax,Y,0,0
		pop eax	
		ret
	.ELSE
		push eax
			invoke setPiece,eax,Y,@res.pcolor,0
		pop eax	
	.ENDIF
	
	.IF eax != 0
		dec eax
		push eax
			invoke getPiece,addr @res,eax,Y
		pop eax
		mov ecx,2
		.IF @res.psize == ecx
			pushad
				invoke 	_detonate,eax,Y
			popad
		.ELSE
			push eax
				invoke setPiece,eax,Y,0,0
			pop eax	
		.ENDIF
		inc eax
	.ENDIF
	
	
	inc eax
	.IF eax<BoardWidth
		push eax
			invoke getPiece,addr @res,eax,Y
		pop eax
		mov ecx,2

		.IF @res.psize == ecx
			pushad
				invoke 	_detonate,eax,Y
			popad
		.ELSE
			push eax
				invoke setPiece,eax,Y,0,0
			pop eax
		.ENDIF
	.ENDIF
	dec eax


	.IF ebx != 0
		dec ebx
		push eax
			invoke getPiece,addr @res,X,ebx
		pop eax
		mov ecx,2

		.IF @res.psize == ecx
			pushad
				invoke _detonate,X,ebx
			popad
		.ELSE
			push eax
			invoke setPiece,X,ebx,0,0
			pop eax
		.ENDIF
		inc ebx
	.ENDIF


	inc ebx
	.IF ebx<BoardWidth
		push eax
			invoke getPiece,addr @res,X,ebx
		pop eax
		mov ecx,2
		
		.IF @res.psize == ecx
			pushad
				invoke _detonate,X,ebx
			popad
		.ELSE
			push eax
			invoke setPiece,X,ebx,0,0
			pop eax
		.ENDIF
	.ENDIF
	dec ebx

	;左上
	.IF eax!=0 && ebx != 0 
		dec eax
		dec ebx

		push eax
			invoke getPiece,addr @res,eax,ebx
		pop eax
		mov ecx,2

		.IF @res.psize == ecx
			pushad
				invoke _detonate,eax,ebx
			popad
		.ELSE
			push eax
			invoke setPiece,eax,ebx,0,0
			pop eax
		.ENDIF
		inc ebx
		inc eax
	.ENDIF

	;右上
	inc eax
	.IF eax<BoardWidth && ebx != 0
		dec ebx

		push eax
			invoke getPiece,addr @res,eax,ebx
		pop eax
		mov ecx,2

		.IF @res.psize == ecx
			pushad
				invoke _detonate,eax,ebx
			popad
		.ELSE
			push eax
				invoke setPiece,eax,ebx,0,0
			pop eax
		.ENDIF
		
		inc ebx
	.ENDIF
	dec eax


	;右下
	inc eax
	inc ebx
	.IF eax<BoardWidth && ebx <BoardWidth

		push eax
			invoke getPiece,addr @res,eax,ebx
		pop eax
		mov ecx,2

		.IF @res.psize == ecx
			pushad
				invoke _detonate,eax,ebx
			popad
		.ELSE
			push eax
				invoke setPiece,eax,ebx,0,0
			pop eax
		.ENDIF
	.ENDIF
	dec ebx
	dec eax

	;左下
	inc ebx
	.IF eax != 0 && ebx <BoardWidth
		dec eax

		push eax
			invoke getPiece,addr @res,eax,ebx
		pop eax
		mov ecx,2

		.IF @res.psize == ecx
			pushad
				invoke _detonate,eax,ebx
			popad
		.ELSE
			push eax
				invoke setPiece,eax,ebx,0,0
			pop eax
		.ENDIF
		inc eax
	.ENDIF
	dec ebx

	popad
	ret
_detonate endp

Detonate proc _Start:POINT,_End:POINT
	mov eax,_Start.x
	mov ebx,_End.x
	.IF eax ==ebx
		mov eax,_Start.y
		mov ebx,_End.y
		.While eax<=ebx
			pushad
				invoke _detonate,_Start.x,eax
			popad
			inc eax
		.ENDW
	.ELSEIF
		.While eax<=ebx
			pushad
				invoke _detonate,eax,_Start.y
			popad
			inc eax
		.ENDW
	.ENDIF
	ret
Detonate endp


updatePieces proc
	LOCAL @vlen:DWORD
	LOCAL @hlen:DWORD
	LOCAL @res:Piece
	LOCAL @s1:Piece
	LOCAL @s2:Piece
	LOCAL @Start:POINT
	LOCAL @End:POINT
	LOCAL @Center:POINT
	LOCAL @toUpdate:DWORD
	LOCAL @hasBomb:DWORD
	LOCAL @Change:DWORD
	LOCAL @got1:Piece
	LOCAL @got2:Piece
	.IF InAnima >= AnimateTime			;非移动状态
		invoke CleanPieceStatus
		invoke ___test,addr @Change
		.IF @Change == 1
			.IF exChangeLabel == 1
				mov glopping,1
			.ENDIF
			invoke resetSelect
			mov InAnima,0
			invoke ResetExChange
		.ELSE
			.IF glopping == 1
				mov glopping,0
				invoke changeSize
			.ENDIF
			.IF exChangeLabel == 1
				invoke getPiece,addr @got1,CellSelected1.x,CellSelected1.y
				invoke getPiece,addr @got2,CellSelected2.x,CellSelected2.y
				invoke setPiece,CellSelected1.x,CellSelected1.y,@got2.pcolor,@got2.psize
				invoke setPiece,CellSelected2.x,CellSelected2.y,@got1.pcolor,@got1.psize
				invoke setPieceLstPos,CellSelected1.x,CellSelected1.y,CellSelected2.x,CellSelected2.y,1
				invoke setPieceLstPos,CellSelected2.x,CellSelected2.y,CellSelected1.x,CellSelected1.y,1
				mov InAnima,0
				mov exChangeLabel,0
				invoke resetSelect
			.ENDIF
		.ENDIF
	.ELSE								;移动状态
	.ENDIF
	;invoke ResetExChange
 	ret
updatePieces endp

hasSolution proc USES ebx ecx
	LOCAL @leftTop:Piece
	LOCAL @leftBottom:Piece
	LOCAL @rightTop:Piece
	LOCAL @rightBottom:Piece
	LOCAL @x:DWORD
	LOCAL @y:DWORD
	LOCAL @centerPiece:Piece
	LOCAL @centerLeft:Piece
	LOCAL @centerRight:Piece
	LOCAL @centerUp:Piece
	LOCAL @centerDown:Piece

	mov eax, 0
	mov ecx, BoardWidth

	;考察单个棋子与其四个角的棋子

	mov @x, 0
	.WHILE @x < ecx
		mov @y, 0
		.WHILE @y < ecx
			invoke getPiece, addr @centerPiece, @x, @y
			invoke getNearbyPiece, addr @leftTop, @x, @y, -1, -1
			invoke getNearbyPiece, addr @leftBottom, @x, @y, -1, 1
			invoke getNearbyPiece, addr @rightTop, @x, @y, 1, -1
			invoke getNearbyPiece, addr @rightBottom, @x, @y, 1, 1

			;判断左下与左上与中间颜色是否相同
			.IF @leftTop.psize && @leftBottom.psize
				mov ebx, @leftTop.pcolor
				.IF @leftBottom.pcolor == ebx && @centerPiece.pcolor == ebx
					mov eax, 1
					ret
				.ENDIF
			.ENDIF

			;判断左上与右上与中间颜色是否相同
			.IF @leftTop.psize && @rightTop.psize
				mov ebx, @leftTop.pcolor
				.IF @rightTop.pcolor == ebx && @centerPiece.pcolor == ebx
					mov eax, 1
					ret
				.ENDIF
			.ENDIF

			;判断右上与右下与中间颜色是否相同
			.IF @rightTop.psize && @rightBottom.psize
				mov ebx, @rightTop.pcolor
				.IF @rightBottom.pcolor == ebx && @centerPiece.pcolor == ebx
					mov eax, 1
					ret
				.ENDIF
			.ENDIF

			;判断左下与右下与中间颜色是否相同
			.IF @leftBottom.psize && @rightBottom.psize
				mov ebx, @leftBottom.pcolor
				.IF @rightBottom.pcolor == ebx && @centerPiece.pcolor == ebx
					mov eax, 1
					ret
				.ENDIF
			.ENDIF

			inc @y
		.ENDW
		inc @x
	.ENDW

	;考察横向两个棋子与它们四个角的棋子
	mov @x, 1
	.WHILE @x < ecx
		mov @y, 0
		.WHILE @y < ecx
			invoke getPiece, addr @centerRight, @x, @y
			invoke getNearbyPiece, addr @centerLeft, @x, @y, -1, 0
			invoke getNearbyPiece, addr @leftTop, @x, @y, -2, -1
			invoke getNearbyPiece, addr @leftBottom, @x, @y, -2, 1
			invoke getNearbyPiece, addr @rightTop, @x, @y, 1, -1
			invoke getNearbyPiece, addr @rightBottom, @x, @y, 1, 1

			.IF @centerRight.psize && @centerLeft.psize
				mov ebx, @centerLeft.pcolor
				.IF @leftTop.pcolor==ebx || @leftBottom.pcolor==ebx || @rightTop.pcolor==ebx || @rightBottom.pcolor==ebx
					mov eax, 1
					ret
				.EndIF
			.ENDIF
			
			inc @y
		.ENDW
		inc @x
	.ENDW

	;考察纵向两个棋子与它们四个角的棋子
	mov @x, 0
	.WHILE @x < ecx
		mov @y, 1
		.WHILE @y < ecx
			invoke getPiece, addr @centerDown, @x, @y
			invoke getNearbyPiece, addr @centerUp, @x, @y, 0, -1
			invoke getNearbyPiece, addr @leftTop, @x, @y, -1, -2
			invoke getNearbyPiece, addr @leftBottom, @x, @y, -1, 1
			invoke getNearbyPiece, addr @rightTop, @x, @y, 1, -2
			invoke getNearbyPiece, addr @rightBottom, @x, @y, 1, 1

			.IF @centerUp.psize && @centerDown.psize
				mov ebx, @centerUp.pcolor
				.IF @leftTop.pcolor==ebx || @leftBottom.pcolor==ebx || @rightTop.pcolor==ebx || @rightBottom.pcolor==ebx
					mov eax, 1
					ret
				.EndIF
			.ENDIF
		.ENDW
	
	.ENDW
	ret
hasSolution endp

generateNewPieces proc USES ebx ecx edx esi
	;遍历使用
	LOCAL @singlePiece:Piece
	LOCAL @x:DWORD
	LOCAL @y:DWORD
	LOCAL @rightPiece:Piece
	LOCAL @leftMimicPiece:Piece
	LOCAL @rightMimicPiece:Piece
	LOCAl @upMimicPiece:Piece
	LOCAl @downMimicPiece:Piece
	LOCAL @leftUpPiece:Piece
	LOCAL @leftDownPiece:Piece
	LOCAl @rightUpPiece:Piece
	LOCAL @rightDownPiece:Piece
	LOCAL @helperPiece:Piece
	lea esi, pieces
	mov ecx, BoardWidth
	mov ebx, BoardWidth
	dec ebx
	;检查全局解
	invoke hasSolution    

	;如果存在全局解
L1:	.IF eax == 1          
		mov @x, 0
		.WHILE @x < ecx
			mov @y, 0
			.WHILE @y < ecx
				invoke getPiece, addr @singlePiece, @x, @y   
				.IF @singlePiece.psize == 0
					pushad
					invoke crt_rand
					div colorType
					invoke setPiece, @x, @y, edx, 1
					invoke setPieceLstPos,@x,@y,@x,@y,2
					popad
				.ENDIF
				inc @y
			.ENDW
			inc @x
		.ENDW

	;如果不存在全局解
	.ELSE
		mov @y, 0
		.WHILE @y < ecx
			mov @x, 0
			.WHILE @x < ecx
				invoke getPiece, addr @singlePiece, @x, @y
				invoke getNearbyPiece, addr @rightPiece, @x, @y, 1, 0
				.IF @singlePiece.psize == 0
					.IF @x!=ebx && @rightPiece.psize==0 ;连续两个空块
						invoke getNearbyPiece, addr @leftMimicPiece, @x, @y, -2, 0
						invoke getNearbyPiece, addr @rightMimicPiece, @x, @y, 3, 0
						.IF @leftMimicPiece.psize != 0
							mov edx, @leftMimicPiece.pcolor
						.ELSEIF @rightMimicPiece.psize != 0
							mov edx, @rightMimicPiece.pcolor
						.ELSE
							invoke crt_rand
							div colorType
						.ENDIF
						invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
						invoke setPieceLstPos,@x,@y,@x,@y,2
						invoke setNearbyPiece, @x, @y, 1, 0, edx, 1
						mov eax,@x
						add eax,1
						invoke setPieceLstPos,eax,@y,eax,@y,2
						mov eax, 1
						jmp L1; 此时已经有解，转到随机生成
					
					.ELSE
						.IF @x==0;最左边列
							invoke getNearbyPiece, addr @rightUpPiece, @x, @y, 1, -1
							invoke getNearbyPiece, addr @rightDownPiece, @x, @y, 1, 1
							invoke getNearbyPiece, addr @rightMimicPiece, @x, @y, 2, 0
							invoke getNearbyPiece, addr @upMimicPiece, @x, @y, 0, -2
							invoke getNearbyPiece, addr @downMimicPiece, @x, @y, 0, 2
							invoke getNearbyPiece, addr @helperPiece, @x, @y, 3, 0
							mov edx, @rightUpPiece.pcolor
							.IF	(@rightUpPiece.psize && @rightDownPiece.psize) && (@rightDownPiece.pcolor==edx);可向右平移插入两个空块
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							mov edx, @rightMimicPiece.pcolor
							.IF (@rightMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx;可向右平移连接两个连续块
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF

							invoke getNearbyPiece, addr @helperPiece, @x, @y, 2, -1
							mov edx, @rightUpPiece.pcolor
							.IF @helperPiece.pcolor==edx && (@rightUpPiece.psize && @helperPiece.psize);可向上平移连接两个连续块
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							invoke getNearbyPiece, addr @helperPiece, @x, @y, 0, -3
							mov edx, @upMimicPiece.pcolor
							.IF  (@upMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx;可向上平移连接两个连续块
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							
							invoke getNearbyPiece, addr @helperPiece, @x, @y, 2, 1
							mov edx, @rightDownPiece.pcolor
							.IF (@rightDownPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx;向下平移连接两个连续块
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							invoke getNearbyPiece, addr @helperPiece, @x, @y, 0, 3
							mov edx, @downMimicPiece.pcolor
							.IF  (@downMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx;可向下平移连接两个连续块
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
						.ELSEIF @x==ebx;最右边列
							invoke getNearbyPiece, addr @leftUpPiece, @x, @y, -1, -1
							invoke getNearbyPiece, addr @leftDownPiece, @x, @y, -1, 1
							invoke getNearbyPiece, addr @leftMimicPiece, @x, @y, -2, 0
							invoke getNearbyPiece, addr @upMimicPiece, @x, @y, 0, -2
							invoke getNearbyPiece, addr @downMimicPiece, @x, @y, 0, 2
							invoke getNearbyPiece, addr @helperPiece, @x, @y, -3, 0

							mov edx, @leftUpPiece.pcolor
							.IF	(@leftUpPiece.psize && @leftDownPiece.psize) && (@leftDownPiece.pcolor==edx)
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							mov edx, @leftMimicPiece.pcolor
							.IF (@leftMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							;向上平移有解
							invoke getNearbyPiece, addr @helperPiece, @x, @y, -2, -1
							mov edx, @leftUpPiece.pcolor
							.IF (@leftUpPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							invoke getNearbyPiece, addr @helperPiece, @x, @y, 0, -3
							mov edx, @upMimicPiece.pcolor
							.IF  (@upMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							;向下平移有解
							invoke getNearbyPiece, addr @helperPiece, @x, @y, -2, 1
							mov edx, @leftDownPiece.pcolor
							.IF (@leftDownPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							invoke getNearbyPiece, addr @helperPiece, @x, @y, 0, 3
							mov edx, @upMimicPiece.pcolor
							.IF  (@downMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx;可向上平移连接两个连续块
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF

						.ELSEIF @y==0;最上边列
							invoke getNearbyPiece, addr @leftDownPiece, @x, @y, -1, 1
							invoke getNearbyPiece, addr @rightDownPiece, @x, @y, 1, 1
							invoke getNearbyPiece, addr @downMimicPiece, @x, @y, 0, 2
							invoke getNearbyPiece, addr @leftMimicPiece, @x, @y, -2, 0
							invoke getNearbyPiece, addr @rightMimicPiece, @x, @y, 2, 0
							invoke getNearbyPiece, addr @helperPiece,  @x, @y, 0, 3
							mov edx, @leftDownPiece.pcolor
							.IF	(@leftDownPiece.psize && @rightDownPiece.psize) && (@rightDownPiece.pcolor==edx)
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							mov edx, @downMimicPiece.pcolor
							.IF (@downMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							;向左平移有解
							invoke getNearbyPiece, addr @helperPiece, @x, @y, -1, 2
							mov edx, @leftDownPiece.pcolor
							.IF (@leftDownPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							invoke getNearbyPiece, addr @helperPiece, @x, @y, -3, 0
							mov edx, @leftMimicPiece.pcolor
							.IF  (@leftMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							;向右平移有解
							invoke getNearbyPiece, addr @helperPiece, @x, @y, 1, 2
							mov edx, @rightDownPiece.pcolor
							.IF (@rightDownPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							invoke getNearbyPiece, addr @helperPiece, @x, @y, 3, 0
							mov edx, @rightMimicPiece.pcolor
							.IF  (@rightMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF

						.ELSEIF @y==ebx;最下边列
							invoke getNearbyPiece, addr @leftUpPiece, @x, @y, -1, -1
							invoke getNearbyPiece, addr @rightUpPiece, @x, @y, 1, -1
							invoke getNearbyPiece, addr @upMimicPiece, @x, @y, 0, -2
							invoke getNearbyPiece, addr @leftMimicPiece, @x, @y, -2, 0
							invoke getNearbyPiece, addr @rightMimicPiece, @x, @y, 2, 0
							invoke getNearbyPiece, addr @helperPiece,  @x, @y, 0, -3
							mov edx, @leftUpPiece.pcolor
							.IF	(@leftUpPiece.psize && @rightUpPiece.psize) && (@rightUpPiece.pcolor==edx)
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							mov edx, @upMimicPiece.pcolor
							.IF (@upMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							;向左平移有解
							invoke getNearbyPiece, addr @helperPiece, @x, @y, -1, -2
							mov edx, @leftUpPiece.pcolor
							.IF (@leftUpPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							invoke getNearbyPiece, addr @helperPiece, @x, @y, -3, 0
							mov edx, @leftMimicPiece.pcolor
							.IF  (@leftMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx;可向上平移连接两个连续块
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							;向右平移有解
							invoke getNearbyPiece, addr @helperPiece, @x, @y, 1, -2
							mov edx, @rightUpPiece.pcolor
							.IF (@rightMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF
							invoke getNearbyPiece, addr @helperPiece, @x, @y, 3, 0
							mov edx, @rightMimicPiece.pcolor
							.IF  (@rightMimicPiece.psize && @helperPiece.psize) && @helperPiece.pcolor==edx
								invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
								invoke setPieceLstPos,@x,@y,@x,@y,2
								mov eax, 1
								jmp L1
							.ENDIF

						.ENDIF
						;没办法只能随机
						invoke crt_rand
						div colorType
						invoke setNearbyPiece, @x, @y, 0, 0, edx, 1
						invoke setPieceLstPos,@x,@y,@x,@y,2
					.ENDIF
				.ENDIF
				inc @x
			.ENDW
			inc @y
		.ENDW
	.ENDIF

	;mov @x, 0
	;.WHILE @x < ecx
		;mov @y, 0
		;.WHILE @y < ecx
			;mov ebx, @x
			;mov CellSelected1.x, ebx
			;mov ebx, @y 
			;mov CellSelected1.y, ebx
			;invoke updatePieces
			;inc @y
		;.ENDW
		;inc @x
	;.ENDW
	ret
generateNewPieces endp

___test proc tt:DWORD
	LOCAL @Start:POINT
	LOCAL @End:POINT
	LOCAL @Center:POINT
	LOCAL @toUpdate:DWORD
	LOCAL @hasBomb:DWORD
	LOCAL @res:Piece
	mov eax,0
	mov ebx,0

	mov esi,tt
	mov ebx,0
	mov [esi],ebx

	.While eax<BoardWidth
		push eax
		.WHILE ebx<BoardWidth
			pushad
				invoke checkPiece,addr @toUpdate,addr @hasBomb,addr @Center,addr @Start,addr @End,eax,ebx
			popad
			pushad
			.IF @toUpdate == 1
				.IF @hasBomb == 0
					invoke getPiece,addr @res,@Center.x,@Center.y
					invoke setPiece,@Center.x,@Center.y,@res.pcolor,2
					invoke movPiece,@Center,@Start,@End
					invoke Hurt_By_Mov,@Start,@End
				.ELSE
					invoke Detonate,@Start,@End
				.ENDIF
				invoke generateNewPieces
				mov esi,tt
				mov ebx,1
				mov [esi],ebx
				ret
			.ENDIF
			popad
			inc ebx
		.ENDW
		mov ebx,0
		pop eax
		inc eax
	.ENDW
	ret
___test endp



;更新玩家信息
updatePlayer proc
	.IF (player1.HP == 0) || (player2.HP == 0)
		mov PageStatus,2
	.ENDIF
	ret
updatePlayer endp

;更行游戏数据
update proc
	.IF PageStatus == 0											;在开始界面
		ret
	.ELSEIF PageStatus == 1										;在游戏界面
		invoke updatePlayer
		;.IF exChangeLabel == 1
			invoke updatePieces
		;.ENDIF
	.ENDIF
	ret
update endp

Hurt_By_Mov proc uses eax ebx _Start:POINT,_End:POINT
	mov ebx,_Start.x
	mov eax,_End.x

	.IF eax == ebx
		mov eax,_End.y
		sub eax,_Start.y
		imul eax,10
		.IF playerSize == 1
			mov ebx,player1.HP
			.IF ebx>eax
				sub ebx,eax
			.ELSE
				mov ebx,0
			.ENDIF
			mov player1.HP,ebx
		.ELSE
			mov ebx,player2.HP
			.IF ebx>eax
				sub ebx,eax
			.ELSE
				mov ebx,0
			.ENDIF
			mov player2.HP,ebx
		.ENDIF
	.ELSE
		sub eax,ebx
		imul eax,10
		.IF playerSize == 1
			mov ebx,player1.HP
			.IF ebx>eax
				sub ebx,eax
			.ELSE
				mov ebx,0
			.ENDIF
			mov player1.HP,ebx
		.ELSE
			mov ebx,player2.HP
			.IF ebx>eax
				sub ebx,eax
			.ELSE
				mov ebx,0
			.ENDIF
			mov player2.HP,ebx
		.ENDIF
	.ENDIF
	ret
Hurt_By_Mov endp

Hurt_By_Detonate proc uses eax ebx
	.IF playerSize == 1
		mov eax,9
		imul eax,3
		mov ebx,player1.HP
		.IF ebx>eax
				sub ebx,eax
			.ELSE
				mov ebx,0
			.ENDIF
		mov player1.HP,ebx
	.ELSE
		mov eax,9
		imul eax,3
		mov ebx,player2.HP
		.IF ebx>eax
				sub ebx,eax
			.ELSE
				mov ebx,0
			.ENDIF
		mov player2.HP,ebx
	.ENDIF
	ret
Hurt_By_Detonate endp


;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;棋子生成
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;生成整个棋盘
initPieces proc
	Local @index:POINT
	invoke crt_srand
	mov ecx,BoardWidth
	mov esi,offset pieces
	mov eax,esi
	mov @index.x,0
	mov @index.y,0

	.WHILE ecx > 0																						;循环生成每一棋子（垃圾loop不能用）
		push ecx
			mov edi,0
			mov ecx,BoardWidth
			mov @index.x,0
			.While ecx>0
				push ecx
				mov edx,0
				invoke crt_rand
				div colorType
				.IF @index.x>1																			;生成的棋子横向不能连着相同颜色三个以上
					mov ebx,(Piece PTR [esi+edi-(type Piece)]).pcolor
					.IF ebx == edx
						mov ebx,(Piece PTR [esi+edi-(type Piece)*2]).pcolor
						.IF ebx == edx
							.IF edx < 5
								inc edx
							.ELSE
								mov edx,0
							.ENDIF
						.ENDIF
					.ENDIF
				.ENDIF
				.IF @index.y>1																			;生成的棋子竖向不能连着相同颜色三个以上
					mov ebx,(Piece PTR [esi+edi-(type Piece)*9]).pcolor
					.IF ebx == edx
						mov ebx,(Piece PTR [esi+edi-(type Piece)*18]).pcolor
						.IF ebx == edx
							.IF edx < 5
								inc edx
							.ELSE
								mov edx,0
							.ENDIF
						.ENDIF
					.ENDIF
				.ENDIF

				mov (Piece PTR [esi+edi]).pcolor,edx
				mov (Piece PTR [esi+edi]).psize,1
				
				mov eax,@index.x
				mov (Piece PTR [esi+edi]).LstY,eax
				mov eax,@index.y
				mov (Piece PTR [esi+edi]).LstX,eax
				mov eax,0
				mov (Piece PTR [esi+edi]).Status,eax

				add edi,type Piece
				inc @index.x
				pop ecx
				dec ecx
			.ENDW
			add esi,lineSize
			inc @index.y
		pop ecx
		dec ecx
		.ENDW

	ret
initPieces endp


;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;游戏初始化
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
initGame proc
	push eax
	mov eax,0
	mov PageStatus,0
	mov eax,type Cell
	mul BoardWidth
	mov rowSize,eax
	mov eax,type Piece
	mul BoardWidth
	mov lineSize,eax
	pop eax
	ret
initGame endp

;初始化整个棋盘的棋子
startAGame proc
	mov edx,0
	invoke crt_rand
	mov ebx,2
	div ebx
	mov playerSize,edx
	;invoke initGame
	invoke initPieces
	mov eax,HPLimit
	mov player1.HP,eax
	mov player2.HP,eax
	mov ecx,BoardWidth
	mov eax,0
	mov ebx,0
	mov glopping,0
	mov InAnima,AnimateTime
	mov edx,BoardWidth
	mov esi,offset  Board
	L1:
		push ecx
		mov ecx,BoardWidth
		mov ebx,0
		L2:
			mov	(Cell PTR [esi]).x,eax
			mov (Cell PTR [esi]).y,ebx
			add ebx,CellSize
			add esi,type Cell
			loop L2
		pop ecx
		add eax,CellSize
		loop L1
	ret
startAGame endp



;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;鼠标响应事件
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ButtonClicked proc USES ebx ecx edx button:GameButton, clickedPos:POINT
	mov eax, clickedPos.x
	mov ebx, clickedPos.y
	mov ecx, button.posX
	add ecx, button.bmpWidth
	mov edx, button.posY
	add edx, button.bmpHeight
	.IF (eax>=button.posX && eax<=ecx)&&(ebx>=button.posY && ebx<=edx)
		mov eax, 1
	.ELSE
		mov eax, 0
	.ENDIF
	ret
ButtonClicked endp

pressAtStartPage proc po:POINT
	pushad
		invoke ButtonClicked, startButton, po
		.IF eax == 1			;点击了开始游戏按钮
			mov PageStatus,1
			invoke startAGame	;更改游戏状态为游戏状态
			invoke Repaint
		.ENDIF
	popad
	ret
pressAtStartPage endp

pressAtOverPage proc po:POINT
pushad
		invoke ButtonClicked, restartButton, po
		.IF eax == 1			;点击了重新游戏按钮
			mov PageStatus,1
			invoke startAGame	;更改游戏状态为游戏状态
			invoke Repaint
		.ENDIF
	popad
	ret
pressAtOverPage endp

;游戏界面下的点击事件
lMouseInGame proc pos:POINT
	LOCAL @posOnBoard:POINT
	LOCAL @index:POINT
	LOCAL @got1:Piece
	LOCAL @got2:Piece
	.IF InAnima >= AnimateTime
		pushad
		mov eax,pos.x
		mov ebx,pos.y
		.IF (eax<startX||eax>endX || ebx<startY || ebx>endY)										;如果点击棋盘以外的位置
			ret
		.ENDIF


		mov edx, 0   
		mov eax,pos.x
		sub eax,startX
		mov @posOnBoard.x,eax
		mov ebx,CellSize
		idiv ebx
		mov edx, 0;
		mov @index.x,eax
		mov eax,pos.y
		sub eax,startY
		mov @posOnBoard.y,eax
		mov ebx,CellSize
		idiv ebx
		mov @index.y,eax

		;invoke getPiece,@index.x,@index.y,addr @got
		mov eax,BoardWidth
		.IF CellSelected1.x >= eax 
			mov eax,@index.y
			mov CellSelected1.y,eax
			mov eax,@index.x
			mov CellSelected1.x,eax
		.ELSE
			mov eax,CellSelected1.x
			mov ebx,CellSelected1.y
			.IF (@index.x == eax)&&(@index.y == ebx)
				ret
			.ENDIF

			mov ecx,CellSelected1.y
			inc ebx
			dec ecx
			.IF ((@index.x == eax) && (@index.y == ecx || @index.y == ebx))
				mov eax,CellSelected1.x
				mov CellSelected2.x,eax
				mov eax,CellSelected1.y
				mov CellSelected2.y,eax
				mov eax,@index.y
				mov CellSelected1.y,eax
				mov eax,@index.x
				mov CellSelected1.x,eax
				invoke getPiece,addr @got1,CellSelected1.x,CellSelected1.y
				invoke getPiece,addr @got2,CellSelected2.x,CellSelected2.y
				invoke setPiece,CellSelected1.x,CellSelected1.y,@got2.pcolor,@got2.psize
				invoke setPiece,CellSelected2.x,CellSelected2.y,@got1.pcolor,@got1.psize
				invoke setPieceLstPos,CellSelected1.x,CellSelected1.y,CellSelected2.x,CellSelected2.y,1
				invoke setPieceLstPos,CellSelected2.x,CellSelected2.y,CellSelected1.x,CellSelected1.y,1
				mov InAnima,0
				; resetSelect
				invoke ExChange
				invoke Repaint
			.ELSE
				mov eax,CellSelected1.x
				mov ebx,CellSelected1.x
				mov ecx,CellSelected1.y
				inc eax
				dec ebx
				.IF ((@index.y == ecx) && (@index.x == eax || @index.x == ebx))
					mov eax,CellSelected1.x
					mov CellSelected2.x,eax
					mov eax,CellSelected1.y
					mov CellSelected2.y,eax
					mov eax,@index.y
					mov CellSelected1.y,eax
					mov eax,@index.x
					mov CellSelected1.x,eax
					invoke getPiece,addr @got1,CellSelected1.x,CellSelected1.y
					invoke getPiece,addr @got2,CellSelected2.x,CellSelected2.y
					invoke setPiece,CellSelected1.x,CellSelected1.y,@got2.pcolor,@got2.psize
					invoke setPiece,CellSelected2.x,CellSelected2.y,@got1.pcolor,@got1.psize
					invoke setPieceLstPos,CellSelected1.x,CellSelected1.y,CellSelected2.x,CellSelected2.y,1
					invoke setPieceLstPos,CellSelected2.x,CellSelected2.y,CellSelected1.x,CellSelected1.y,1
					mov InAnima,0
					;invoke resetSelect
					invoke ExChange
					invoke Repaint
				.ELSE
					mov eax,@index.y
					mov CellSelected1.y,eax
					mov eax,@index.x
					mov CellSelected1.x,eax
					mov eax,BoardWidth
					mov CellSelected2.x,eax
					mov CellSelected2.y,eax
				.ENDIF
			.ENDIF
		.ENDIF
		popad
		invoke Repaint
	.ENDIF
	ret
lMouseInGame endp


;根据游戏状态，处理左键点击
leftMouseHandler proc
	LOCAL	@stPos:POINT
	LOCAL   @scrPos:RECT
	LOCAL   @test:RECT
	invoke GetCursorPos,addr @stPos											;左键点击的屏幕位子
	invoke ScreenToClient,hWinMain,addr @stPos								;
	.IF PageStatus == 0
		invoke pressAtStartPage,@stPos
	.ELSEIF PageStatus == 1
		invoke lMouseInGame,@stPos
	.ELSEIF PageStatus == 2
		invoke pressAtOverPage, @stPos
	.ENDIF
	ret
leftMouseHandler endp


;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;绘图
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;绘制棋盘
paintGrounds proc _hWnd,_hDC
	LOCAL @OldPen
	LOCAL @OldBrush
	invoke  CreatePen,PS_SOLID,3,0DBDBDBH
	invoke  SelectObject,_hDC,eax
	mov @OldPen,eax
	
	mov ecx,BoardWidth
	inc ecx
	mov eax,startX
	mov ebx,startY
	mov edx,CellSize
	imul edx,BoardWidth
	add ebx,edx
	L1:
		pushad
		invoke  MoveToEx,_hDC,eax,startY,NULL
		popad
		pushad
		invoke  LineTo,_hDC,eax,ebx
		popad
		add eax,CellSize
		loop L1
	invoke  SelectObject,_hDC,@OldPen
	invoke 	DeleteObject,eax

	invoke  CreatePen,PS_SOLID,3,0DBDBDBH
	invoke  SelectObject,_hDC,eax
	mov @OldPen,eax
	
	mov ecx,BoardWidth
	inc ecx
	mov eax,startX
	mov edx,CellSize
	imul edx,BoardWidth
	add eax,edx
	mov ebx,startY
	
	L2:
		pushad
		invoke  MoveToEx,_hDC,startX,ebx,NULL
		popad
		pushad
		invoke  LineTo,_hDC,eax,ebx
		popad
		add ebx,CellSize
		loop L2
	invoke  SelectObject,_hDC,@OldPen
	invoke 	DeleteObject,eax
	ret
paintGrounds endp


;绘制血条
paintHP proc  _hWnd,_hDC
	LOCAL @OldBrush
	LOCAL @OldPen
	
	ret
paintHP endp

;绘制玩家信息
paintPlayer proc _hWnd,_hDC,_hdcBmp
	LOCAL @OldBrush
	LOCAL @OldPen
	LOCAL @newBrush

	invoke  CreateSolidBrush,0cc7a00H
	invoke  SelectObject,_hDC,eax
	mov @OldBrush,eax
		.IF playerSize == 0
			invoke Rectangle,_hDC,player1ING.left,player1ING.top,player1ING.right,player1ING.bottom
		.ELSE
			invoke Rectangle,_hDC,player2ING.left,player2ING.top,player2ING.right,player2ING.bottom
		.ENDIF
	invoke  SelectObject,_hDC,@OldBrush
	invoke 	DeleteObject,eax


	invoke  CreateSolidBrush,0eeee00H
	invoke  SelectObject,_hDC,eax
	mov @OldBrush,eax

	invoke SelectObject, _hdcBmp, player1Bmp
	invoke BitBlt, _hDC, P1IconPos.x, P1IconPos.y, WWidth, WHeight, _hdcBmp, 0, 0, SRCCOPY
	
	invoke SelectObject, _hdcBmp, player2Bmp
	invoke BitBlt, _hDC, P2IconPos.x, P2IconPos.y, WWidth, WHeight, _hdcBmp, 0, 0, SRCCOPY

	invoke  SelectObject,_hDC,@OldBrush
	invoke 	DeleteObject,eax

	invoke  CreateSolidBrush,0ee0000H
	invoke  SelectObject,_hDC,eax
	mov eax,P1HPStripPos.x
	mov ebx,P1HPStripPos.x
	mov ecx,P1HPStripPos.y
	mov edx,P1HPStripPos.y
	add ebx,HPStripWidth
	add edx,HPStripLength
	add ebx,HPGap
	add ebx,HPGap
	add edx,HPGap
	add edx,HPGap
	invoke RoundRect,_hDC,eax,ecx,ebx,edx,HPStripWidth,HPStripWidth

	mov eax,P2HPStripPos.x
	mov ebx,P2HPStripPos.x
	mov ecx,P2HPStripPos.y
	mov edx,P2HPStripPos.y
	add ebx,HPStripWidth
	add edx,HPStripLength
	sub eax,HPGap
	sub eax,HPGap
	add edx,HPGap
	add edx,HPGap
	invoke RoundRect,_hDC,eax,ecx,ebx,edx,HPStripWidth,HPStripWidth

	invoke  SelectObject,_hDC,@OldBrush
	invoke 	DeleteObject,eax

	invoke  CreateSolidBrush,00000eeH
	invoke  SelectObject,_hDC,eax
	mov eax,P1HPStripPos.x
	mov ebx,P1HPStripPos.x
	mov ecx,P1HPStripPos.y
	mov edx,P1HPStripPos.y
	add ebx,HPStripWidth
	add edx,player1.HP
	add eax,HPGap
	add ecx,HPGap
	add ebx,HPGap
	add edx,HPGap
	invoke RoundRect,_hDC,eax,ecx,ebx,edx,HPStripWidth,HPStripWidth

	mov eax,P2HPStripPos.x
	mov ebx,P2HPStripPos.x
	mov ecx,P2HPStripPos.y
	mov edx,P2HPStripPos.y
	add ebx,HPStripWidth
	add edx,player2.HP
	sub eax,HPGap
	add ecx,HPGap
	sub ebx,HPGap
	add edx,HPGap
	invoke RoundRect,_hDC,eax,ecx,ebx,edx,HPStripWidth,HPStripWidth

	


	invoke  SelectObject,_hDC,@OldBrush
	invoke 	DeleteObject,eax
	ret
paintPlayer endp



;绘制开始界面，按钮
paintStartPage proc _hWnd,_hDC,_hdcBmp
	invoke SelectObject, _hdcBmp, backgroundBmp
	invoke BitBlt, _hDC, 0, 0, WWidth, WHeight, _hdcBmp, 0, 0, SRCCOPY
	invoke SelectObject, _hdcBmp, startButton.hBmp
	invoke BitBlt, _hDC, startButton.posX, startButton.posY, WWidth, WHeight, _hdcBmp, 0, 0, SRCCOPY
	ret
paintStartPage endp

;绘制结束界面
paintEndPage proc _hWnd,_hDC,_hdcBmp
	invoke SelectObject, _hdcBmp, backgroundOverBmp
	invoke BitBlt, _hDC, 0, 0, WWidth, WHeight, _hdcBmp, 0, 0, SRCCOPY
	invoke SelectObject, _hdcBmp, restartButton.hBmp
	invoke BitBlt, _hDC, restartButton.posX, restartButton.posY, WWidth, WHeight, _hdcBmp, 0, 0, SRCCOPY
	ret
paintEndPage endp


;绘制单个棋子
paintCell proc _hWnd:DWORD,_hDC:DWORD,pos:Cell,color:DWORD,_size:DWORD,piece:DWORD
	LOCAL @OldBrush
	LOCAL @OldPen
	LOCAL @color
	LOCAL @index:POINT
	LOCAL @res:Piece
	LOCAL @des:DWORD
	pushad
	mov eax,color
	imul eax,4
	mov @color,eax
	invoke  CreateSolidBrush,Colors[eax]
	invoke  SelectObject,_hDC,eax
	mov @OldBrush,eax
	mov eax,@color
	invoke  CreatePen,PS_SOLID,3,Colors[eax]
	invoke  SelectObject,_hDC,eax
	mov @OldPen,eax
	

	pushad
		mov edx,0
		mov eax,pos.x
		mov ebx,CellSize
		div ebx
		mov @index.x,eax
		mov edx,0
		mov eax,pos.y
		mov ebx,CellSize
		div ebx
		mov @index.y,eax
		invoke getPiece,addr @res,@index.x,@index.y
	popad

	mov eax,pos.x
	mov ebx,pos.y
	add eax,startX
	add ebx,startY
	mov ecx,eax
	mov edx,ebx
	add ecx,CellSize
	add edx,CellSize
	add eax,5
	add ebx,11
	sub ecx,5
	sub edx,5
	push ecx
	push edx
	.IF InAnima < AnimateTime && @res.Status>0
		mov ecx,AnimateTime
		sub ecx,InAnima
		mov @des,ecx

		mov ecx,@index.x
		mov edx,@index.y
		sub ecx,@res.LstX
		sub edx,@res.LstY
		imul ecx,Speed
		imul ecx,@des
		imul edx,Speed
		imul edx,@des
		sub eax,ecx
		sub ebx,edx
	.ENDIF
	pop edx
	pop ecx
		pushad
		invoke SetViewportOrgEx,_hDC, eax, ebx, NULL
		.IF _size == 1
			.IF @res.Status == 2
				.IF InAnima > 40
					invoke Polygon,_hDC, offset testRect,7
				.ENDIF
			.ELSE
				invoke Polygon,_hDC, offset testRect,7
			.ENDIF
		.ELSEIF _size == 2
			.IF @res.Status == 2
				.IF InAnima > 40
					invoke Polygon,_hDC, offset testRectSM,5
				.ENDIF
			.ELSE
				invoke Polygon,_hDC, offset testRectSM,5
			.ENDIF
		.ENDIF
		invoke SetViewportOrgEx,_hDC, 0, 0, NULL

		invoke  SelectObject,_hDC,@OldBrush
		invoke 	DeleteObject,eax
		invoke  SelectObject,_hDC,@OldPen
		invoke 	DeleteObject,eax
		popad
	popad
	ret
paintCell endp


;绘制所有棋子
paintPieces proc _hWnd:DWORD,_hDC:DWORD
	mov ecx,BoardWidth
	mov esi,offset pieces
	mov edi,offset Board
	L1:
		push ecx
		mov ecx,BoardWidth
		L2:
			push ecx
			mov eax,(Piece PTR [esi]).pcolor
			mov ebx,(Piece PTR [esi]).psize
			invoke paintCell,_hWnd,_hDC,Cell PTR [edi],eax,ebx,esi
			pop ecx
			add edi,type Cell
			add esi,type Piece
			loop L2
		pop ecx
		loop L1
	.IF InAnima < AnimateTime
		inc InAnima
	.ENDIF
	ret
paintPieces endp


;绘制选中单元格
paintSelected proc _hWnd:DWORD,_hDC:DWORD
	LOCAL @OldPen
	invoke  CreatePen,PS_SOLID,3,0ff00ffH
	invoke  SelectObject,_hDC,eax
	mov @OldPen,eax
	mov eax,BoardWidth
	.IF CellSelected1.x<eax	&& CellSelected1.y<eax										;存在选中单元格
		mov eax,CellSelected1.x
		mov ebx,CellSelected1.y
		imul eax,CellSize
		imul ebx,CellSize
		add eax,startX
		add ebx,startY
		mov ecx,eax
		mov edx,ebx
		add ecx,CellSize
		add edx,CellSize
		invoke RoundRect,_hDC,eax,ebx,ecx,edx,20,20

		invoke  SelectObject,_hDC,@OldPen
		invoke 	DeleteObject,eax
		invoke  CreatePen,PS_SOLID,3,000ffffH
		invoke  SelectObject,_hDC,eax
		mov eax,BoardWidth
		
		.IF CellSelected2.x<eax	&& CellSelected2.y<eax										;存在两个选中格
		mov eax,CellSelected2.x
		mov ebx,CellSelected2.y
		imul eax,CellSize
		imul ebx,CellSize
		add eax,startX
		add ebx,startY
		mov ecx,eax
		mov edx,ebx
		add ecx,CellSize
		add edx,CellSize
		invoke RoundRect,_hDC,eax,ebx,ecx,edx,20,20
		.ENDIF
	.ENDIF
	invoke  SelectObject,_hDC,@OldPen
	invoke 	DeleteObject,eax
	ret
paintSelected endp


Paint proc _hWnd,_hDC
	LOCAL @hdcBuffer:DWORD
	LOCAL @cptBmp:DWORD
	LOCAL @oldBmp:DWORD
	LOCAL @hdcBmp:DWORD

	invoke CreateCompatibleDC, _hDC
	mov @hdcBuffer, eax
	invoke CreateCompatibleBitmap, _hDC, WWidth, WHeight
	mov @cptBmp, eax
	invoke SelectObject, @hdcBuffer, @cptBmp
	mov @oldBmp, eax
	invoke PatBlt, @hdcBuffer, 0, 0, WWidth, WHeight, WHITENESS
	invoke CreateCompatibleDC, _hDC
	mov @hdcBmp, eax


	.IF PageStatus == 0
		invoke paintStartPage,_hWnd, @hdcBuffer, @hdcBmp
	.ELSEIF PageStatus == 1
		invoke paintGrounds,_hWnd,@hdcBuffer
		invoke paintPlayer,_hWnd,@hdcBuffer, @hdcBmp
		invoke paintSelected,_hWnd,@hdcBuffer
		invoke paintPieces,_hWnd,@hdcBuffer	
	.ELSEIF PageStatus == 2
		invoke paintEndPage, _hWnd, @hdcBuffer, @hdcBmp
	.ENDIF
	; mov rePaintLabel,0

	invoke BitBlt, _hDC, 0, 0, WWidth, WHeight, @hdcBuffer, 0, 0, SRCCOPY
	invoke SelectObject, @hdcBuffer, @oldBmp
	invoke DeleteDC, @hdcBuffer
	invoke DeleteObject, @cptBmp
	invoke DeleteObject, @hdcBmp
	ret
Paint endp

CreateGameButton proc USES eax button:DWORD, _hBmp:DWORD, _posX:DWORD, _posY:DWORD, _bmpWidth:DWORD, _bmpHeight:DWORD
	mov esi, button
	mov eax, _hBmp
	mov (GameButton PTR [esi]).hBmp, eax
	mov eax, _posX
	mov (GameButton PTR [esi]).posX, eax
	mov eax, _posY
	mov (GameButton PTR [esi]).posY, eax
	mov eax, _bmpWidth
	mov (GameButton PTR [esi]).bmpWidth, eax
	mov eax, _bmpHeight
	mov (GameButton PTR [esi]).bmpHeight, eax
	ret
CreateGameButton endp

Init proc hWnd:DWORD, wParam:DWORD, lParam:DWORD
	invoke LoadBitmap, hInstance, 101
	invoke CreateGameButton, addr startButton, eax, 760, 650, 128, 64
	invoke LoadBitmap, hInstance, 104
	invoke CreateGameButton, addr restartButton, eax, 760, 650, 128, 64

	invoke LoadBitmap, hInstance, 102
	mov backgroundBmp, eax
	invoke LoadBitmap, hInstance, 103
	mov backgroundOverBmp, eax
	invoke LoadBitmap, hInstance, 105
	mov player1Bmp, eax
	invoke LoadBitmap, hInstance, 106
	mov player2Bmp, eax
	ret
Init endp

end