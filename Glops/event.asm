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

ResetExChange proc
	mov exChangeLabel,0
	ret
ResetExChange endp

checkPiece proc  X:DWORD,Y:DWORD,toUpdate:DWORD
	LOCAL @vlen:DWORD
	LOCAL @hlen:DWORD
	LOCAL @res:Piece
	LOCAL @s1:Piece
	LOCAL @s2:Piece
	LOCAL @Start:POINT
	LOCAL @End:POINT
	LOCAL @Center:POINT

	mov @vlen,0
	mov @hlen,0
	
	invoke getPiece,addr @s1,X,Y

	mov eax,X
	mov ebx,@s1.pcolor
	.While eax >= 0
		push eax
		invoke getPiece,addr @res,eax,Y
		pop eax
		.IF @res.pcolor == ebx
			inc @hlen
		.ELSE
			.break
		.ENDIF
		dec eax
	.EndW

	inc eax
	mov @Start.x,eax
	mov eax,Y
	mov @Start.y,eax

	mov eax,X
	inc eax
	.While eax < BoardWidth
		pushad
		invoke getPiece,addr @res,eax,Y
		popad
		.IF @res.pcolor == ebx
			inc @hlen
		.ELSE
			.break
		.ENDIF
		inc eax
	.EndW
	dec eax

	.IF @hlen >= 3
		mov edx,0
		mov eax,@hlen
		mov ebx,2
		div ebx
		add @Start.x,eax
		invoke getPiece,addr @res,@Start.x,@Start.y
		invoke setPiece,@Start.x,@Start.y,@res.pcolor,2
		mov esi,toUpdate
		;mov ebx,1
		;mov [esi],ebx
		invoke ResetExChange
		invoke resetSelect
		ret
	.ELSEIF
		mov eax,Y
		mov ebx,@s1.pcolor
		.While eax >= 0
			push eax
			invoke getPiece,addr @res,X,eax
			pop eax
			.IF @res.pcolor == ebx
				inc @vlen
			.ELSE
				.break
			.ENDIF
			dec eax
		.EndW

		inc eax
		mov @Start.y,eax
		mov eax,X
		mov @Start.x,eax

		mov eax,Y
		inc eax
		.While eax < BoardWidth
			pushad
			invoke getPiece,addr @res,X,eax
			popad
			.IF @res.pcolor == ebx
				inc @vlen
			.ELSE
				.break
			.ENDIF
			inc eax
		.EndW
		dec eax

		.IF @vlen >= 3
			mov edx,0
			mov eax,@vlen
			mov ebx,2
			div ebx
			add @Start.y,eax
			invoke getPiece,addr @res,@Start.x,@Start.y
			invoke setPiece,@Start.x,@Start.y,@res.pcolor,2
			mov esi,toUpdate
			;mov ebx,1
			;mov [esi],ebx
			invoke ResetExChange
			invoke resetSelect
			ret
		.ENDIF
	.ENDIF
	ret
checkPiece endp


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
	invoke checkPiece,CellSelected1.x,CellSelected1.y,addr @toUpdate
	invoke checkPiece,CellSelected2.x,CellSelected2.y,addr @toUpdate
	
	
		
	ret
updatePieces endp





;更新玩家信息
updatePlayer proc

	ret
updatePlayer endp

;更行游戏数据
update proc
	.IF PageStatus == 0											;在开始界面
		ret
	.ELSEIF PageStatus == 1										;在游戏界面
		invoke updatePlayer
		.IF exChangeLabel == 1
			invoke updatePieces
		.ENDIF
	.ENDIF
	ret
update endp

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
			L2:
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
				add edi,type Piece
				inc @index.x
				pop ecx
				loop L2
			add esi,rowSize
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
	invoke initGame
	invoke initPieces
	mov eax,HPLimit
	mov player1.HP,eax
	mov player2.HP,eax
	mov ecx,BoardWidth
	mov eax,0
	mov ebx,0
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
pressAtStartPage proc po:POINT
	pushad
		mov eax,po.x
		mov ebx,po.y
		.IF (eax>=StartBtnLT.x && eax<=StartBtnRB.x)&&(ebx>=StartBtnLT.y && ebx<=StartBtnRB.y)			;点击了开始游戏按钮
			mov PageStatus,1																			;更改游戏状态为游戏状态
			invoke Repaint
		.ENDIF
	popad
	ret
pressAtStartPage endp

;游戏界面下的点击事件
lMouseInGame proc pos:POINT
	LOCAL @posOnBoard:POINT
	LOCAL @index:POINT
	LOCAL @got1:Piece
	LOCAL @got2:Piece
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
	ret
paintGrounds endp


;绘制血条
paintHP proc  _hWnd,_hDC
	LOCAL @OldBrush
	LOCAL @OldPen
	
	ret
paintHP endp

;绘制玩家信息
paintPlayer proc _hWnd,_hDC
	LOCAL @OldBrush
	LOCAL @OldPen
	invoke  CreateSolidBrush,0eeee00H
	invoke  SelectObject,_hDC,eax
	mov @OldBrush,eax

	mov eax,P1IconPos.x
	mov ebx,P1IconPos.x
	mov ecx,P1IconPos.y
	mov edx,P1IconPos.y
	add ebx,IconSize
	add edx,IconSize
	invoke Rectangle,_hDC,eax,ecx,ebx,edx
	
	mov eax,P2IconPos.x
	mov ebx,P2IconPos.x
	mov ecx,P2IconPos.y
	mov edx,P2IconPos.y
	add ebx,IconSize
	add edx,IconSize
	invoke Rectangle,_hDC,eax,ecx,ebx,edx

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
	invoke Rectangle,_hDC,eax,ecx,ebx,edx

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
	invoke Rectangle,_hDC,eax,ecx,ebx,edx

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
	invoke Rectangle,_hDC,eax,ecx,ebx,edx

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
	invoke Rectangle,_hDC,eax,ecx,ebx,edx

	invoke  SelectObject,_hDC,@OldBrush
	ret
paintPlayer endp



;绘制开始界面，按钮
paintStartPage proc _hWnd,_hDC
	LOCAL @OldBrush
	invoke  GetStockObject,BLACK_BRUSH
	invoke  SelectObject,_hDC,eax
	mov @OldBrush,eax
	invoke RoundRect,_hDC,StartBtnLT.x,StartBtnLT.y,StartBtnRB.x,StartBtnRB.y,20,20
	INVOKE DrawText, _hDC, ADDR StartStr,-1, ADDR StartBtnRect, DT_CENTER 

	invoke  SelectObject,_hDC,@OldBrush
	invoke  MoveToEx,_hDC,0,0,NULL
	invoke  LineTo,_hDC,WWidth,0
	ret
paintStartPage endp


;绘制单个棋子
paintCell proc _hWnd:DWORD,_hDC:DWORD,pos:Cell,color:DWORD,_size:DWORD
	LOCAL @OldBrush
	LOCAL @OldPen
	LOCAL @color
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
	pushad
	invoke SetViewportOrgEx,_hDC, eax, ebx, NULL
	.IF _size == 1
		invoke Polygon,_hDC, offset testRect,7
	.ELSEIF _size == 2
		invoke Polygon,_hDC, offset testRectSM,5
	.ENDIF
	invoke SetViewportOrgEx,_hDC, 0, 0, NULL

	invoke  SelectObject,_hDC,@OldBrush
	invoke  SelectObject,_hDC,@OldPen
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
			invoke paintCell,_hWnd,_hDC,Cell PTR [edi],eax,ebx
			pop ecx
			add edi,type Cell
			add esi,type Piece
			loop L2
		pop ecx
		loop L1
	ret
paintPieces endp


;绘制选中单元格
paintSelected proc _hWnd:DWORD,_hDC:DWORD
	LOCAL @OldPen
	invoke  CreatePen,PS_SOLID,3,0ff00ffH
	invoke  SelectObject,_hDC,eax
	mov @OldPen,eax
	mov eax,BoardWidth
	.IF CellSelected1.x<eax												;存在选中单元格
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

		invoke  CreatePen,PS_SOLID,3,000ffffH
		invoke  SelectObject,_hDC,eax
		mov eax,BoardWidth
		
		.IF CellSelected2.x<eax											;存在两个选中格
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
	ret
paintSelected endp


Paint proc _hWnd,_hDC
.IF PageStatus == 0
	invoke paintStartPage,_hWnd,_hDC
.ELSEIF PageStatus == 1
	invoke paintGrounds,_hWnd,_hDC
	invoke paintPlayer,_hWnd,_hDC
	invoke paintSelected,_hWnd,_hDC
	invoke paintPieces,_hWnd,_hDC
	
.ENDIF
mov rePaintLabel,0
ret
Paint endp



end