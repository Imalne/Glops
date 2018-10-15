.386
.model flat,stdcall
option casemap:none

include         windows.inc
include         gdi32.inc
includelib      gdi32.lib
include         user32.inc
includelib      user32.lib
include         kernel32.inc
includelib      kernel32.lib
include			Global.inc

.code



;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;逻辑更新
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Repaint proc
	mov rePaintLabel,1
	ret
Repaint endp

updatePlayer proc

	ret
updatePlayer endp

update proc
	.IF PageStatus == 0
		ret
	.ELSEIF PageStatus == 1
		invoke updatePlayer
	.ENDIF
	ret
update endp



;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;游戏初始化
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
initGame proc
	push eax
	mov eax,0
	mov PageStatus,0
	pop eax
	ret
initGame endp

startAGame proc
	invoke initGame
	mov player1.HP,800
	mov player2.HP,800
	mov ecx,12
	mov eax,0
	mov ebx,0
	mov edx,12
	mov esi,offset  Board
	L1:
		push ecx
		mov ecx,12
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
		.IF (eax>=StartBtnLT.x && eax<=StartBtnRB.x)&&(ebx>=StartBtnLT.y && ebx<=StartBtnRB.y)
			mov PageStatus,1
			invoke Repaint
		.ENDIF
	popad
	ret
pressAtStartPage endp

lMouseInGame proc pos:POINT
	LOCAL @posOnBoard:POINT
	LOCAL @index:POINT
	mov eax,pos.x
	mov ebx,pos.y
	.IF (eax<startX||eax>endX || ebx<startY || ebx>endY)
		ret
	.ENDIF
	mov edx, 0   
	mov eax,pos.x
	sub eax,startX
	mov @posOnBoard.x,eax
	mov ebx,70
	idiv ebx
	mov edx, 0   ;
	mov @index.x,eax
	mov eax,pos.y
	sub eax,startY
	mov @posOnBoard.y,eax
	mov ebx,70
	idiv ebx
	mov @index.y,eax
	ret
lMouseInGame endp


leftMouseHandler proc
	LOCAL	@stPos:POINT
	LOCAL   @scrPos:RECT
	LOCAL   @test:RECT
	invoke GetCursorPos,addr @stPos
	invoke ScreenToClient,hWinMain,addr @stPos
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
paintGrounds proc _hWnd,_hDC
	LOCAL @OldPen
	LOCAL @OldBrush

	pushad
	invoke  CreatePen,PS_SOLID,3,0ff0000H
	invoke  SelectObject,_hDC,eax
	mov @OldPen,eax
	
	mov ecx,BoardWidth
	inc ecx
	mov eax,startX
	mov ebx,startY
	mov edx,CellSize
	imul edx,BoardLength
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

	invoke  CreatePen,PS_SOLID,3,0ff0000H
	invoke  SelectObject,_hDC,eax
	mov @OldPen,eax
	
	mov ecx,BoardLength
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
	popad
	ret
paintGrounds endp

paintHP proc  _hWnd,_hDC
	LOCAL @OldBrush
	LOCAL @OldPen
	
	ret
paintHP endp


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
	Paint proc _hWnd,_hDC
	.IF PageStatus == 0
		invoke paintStartPage,_hWnd,_hDC
	.ELSEIF PageStatus == 1
		invoke paintGrounds,_hWnd,_hDC
		invoke paintPlayer,_hWnd,_hDC
	.ENDIF
	mov rePaintLabel,0
	ret
	Paint endp



end