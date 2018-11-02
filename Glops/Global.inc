IFNDEF GLOBAL_INC
	GLOBAL_INC		equ			1
	IDI_ICON1       equ			101
	ID_TIMER        equ			1
	
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;结构体定义
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	;玩家
	Player STRUCT
	HP		DWORD	?
	Player ENDS

	;棋盘上的棋子位置
	Cell STRUCT
		x DWORD	?
		y DWORD ?
	Cell ENDS

	;逻辑棋子
	Piece STRUCT
		pcolor	DWORD ?
		psize	DWORD ?
		LstX	DWORD ?
		LstY	DWORD ?
		Status  DWORD ?
	Piece ENDS

	;按钮
	GameButton STRUCT
		hBmp 	  DWORD ?
		posX 	  DWORD ?
		posY 	  DWORD ?
		bmpWidth  DWORD ?
		bmpHeight DWORD ?
	GameButton ENDS

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;全局变量
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	externdef	hWinMain:DWORD,
				hInstance:DwoRD,
				PageStatus:DWORD,
				player1:Player,
				player2:Player,
				cursor:POINT,
				GroundHeight:DWORD,
				GameStatus:DWORD,
				BmpBackground:DWORD,
				rePaintLabel:DWORD,
				exChangeLabel:DWORD,
				Board:Cell,
				rowSize:DWORD,
				lineSize:DWORD,
				pieces:Piece,
				CellSelected1:POINT,
				CellSelected2:POINT,
				InAnima:DWORD,
				playerSize:DWORD,
				glopping:DWORD

	externdef   backgroundBmp:DWORD,
				backgroundOverBmp:DWORD,
				player1Bmp:DWORD,
				player2Bmp:DWORD,
				startButton:GameButton,
				restartButton:GameButton

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;常量
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	.data
	szClassName     Byte		'Glops',0																		;窗口名
	repaintFreq     DWORD		5																				
	WWidth			DWORD		1620																			;窗口宽度
	WHeight			DWORD		1000																			;窗口宽度
	CellSize		DWORD		90																				;单元格大小
	BoardWidth		DWORD		9																				;棋盘单行或单列上单元格的数量
	;BoardLength		DWORD		12
	startX			DWORD		380																				;棋盘左上角坐标
	startY			DWORD		50
	endX			DWORD		1220																			;窗口右下角坐标
	endY			DWORD		870
	HPLimit			DWORD		800																				;HP上线
	P1IconPos		POINT		<105,15>																			;玩家一头像左上角
	P2IconPos		POINT		<1425,15>																		;玩家二头像左上角
	P1HPStripPos	POINT		<105,120>																		;玩家一血条左上角
	P2HPStripPos	POINT		<1445,120>																		;玩家二血条左上角
	IconSize		DWORD		70																				;玩家头像大小
	HPStripLength	DWORD		800																				;血条框长度
	HPStripWidth	DWORD		50																				;血条框宽度
	HPGap			DWORD		10																				;血条与框的间隔
	colorType		DWORD       6
	Colors			DWORD		00000FFH,04071FFH,0FF0000H,00FF00H,000FFFFH,07400CDH;红色，橙色，蓝色，绿色，黄色，紫色
	testRect		POINT		<20,0>,<60,0>,<80,34>,<60,68>,<20,68>,<0,34>,<20,0>								;单个棋子的六个顶点的相对位置
	testRectSM		POINT		<20,20>,<60,20>,<60,60>,<20,60>,<20,20>								;单个棋子的六个顶点的相对位置
	AnimateTime		EQU			45
	Speed			EQU			2
	player1ING		RECT		<100,10,180,90>
	player2ING		RECT		<1420,10,1500,90>



;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;过程externdef
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	.code
	leftMouseHandler PROTO
	update PROTO
	startAGame PROTO
	initGame PROTO
	Paint PROTO _hWnd:DWORD,_hDC:DWORD
	Init PROTO hWnd:DWORD, wParam:DWORD, lParam:DWORD


ELSE
echo -----------------------------------------
echo WARNING Duplicate include file window.inc
echo -----------------------------------------
ENDIF