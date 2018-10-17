IFNDEF GLOBAL_INC
	GLOBAL_INC		equ			1
	IDI_ICON1       equ			101
	ID_TIMER        equ			1
	
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;结构体定义
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	Player STRUCT
	HP		DWORD	?
	Player ENDS

	Cell STRUCT
		x DWORD	?
		y DWORD ?
	Cell ENDS

	Piece STRUCT
		pcolor	DWORD ?
		psize	DWORD ?
		;pindex	POINT <>
	Piece ENDS

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
				Board:Cell,
				rowSize:DWORD,
				pieces:Piece,
				CellSelected1:POINT,
				CellSelected2:POINT

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;常量
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	.data
	szClassName     Byte		'Game',0
	repaintFreq     DWORD		17
	WWidth			DWORD		1620
	WHeight			DWORD		1000
	GroundHeight1	DWORD		600
	GroundHeight2	DWORD		300
	Gravity			DWORD		2
	StartBtnLT		POINT		<390,400>
	StartBtnRB		POINT		<690,450>
	StartBtnRect	RECT		<390,400,690,450>
	StartStr		Byte		"Start Game",0
	CellSize		DWORD		90
	BoardWidth		DWORD		9
	;BoardLength		DWORD		12
	startX			DWORD		380
	startY			DWORD		50
	endX			DWORD		1220
	endY			DWORD		870
	HPLimit			DWORD		800
	P1IconPos		POINT		<0,0>
	P2IconPos		POINT		<1530,0>
	P1HPStripPos	POINT		<0,90>
	P2HPStripPos	POINT		<1550,90>
	IconSize		DWORD		70
	HPStripLength	DWORD		800
	HPStripWidth	DWORD		50
	HPGap			DWORD		10
	colorType		DWORD       6
	Colors			DWORD		0EE3B3BH,0CD661DH,09F79EEH,09ACD32H,000EEEEH,0CD00CDH;红色，橙色，蓝色，绿色，黄色，紫色
	testRect		POINT		<20,0>,<60,0>,<80,34>,<60,68>,<20,68>,<0,34>,<20,0>



;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;过程externdef
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	.code
	leftMouseHandler PROTO
	update PROTO
	startAGame PROTO
	Paint PROTO _hWnd:DWORD,_hDC:DWORD


ELSE
echo -----------------------------------------
echo WARNING Duplicate include file window.inc
echo -----------------------------------------
ENDIF