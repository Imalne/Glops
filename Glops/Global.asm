.386
.model flat,stdcall
option casemap:none

include windows.inc
include Global.inc
.data
	hInstance       DwoRD		?
	hWinMain        DWORD		?
	PageStatus		DWORD		?
	player1			Player		<>
	player2			Player		<>
	cursor			POINT		<>
	GroundHeight	DWORD		?
	BmpBackground	DWORD		?
	rePaintLabel	DWORD		?
	exChangeLabel	DWORD		0
	Board			Cell 144	DUP(<>)
	CellSelected1	POINT		<12,12>
	CellSelected2	POINT		<12,12>
	pieces			Piece 144	DUP(<>)

	rowSize			DWORD		?
	lineSize		DWORD		?
	

.code
end