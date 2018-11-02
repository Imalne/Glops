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

.data

.code
_ProcWinMain    proc    uses ebx edi esi hWnd,uMsg,wParam,lParam
                LOCAL   @stPS:PAINTSTRUCT
				LOCAL   @char
				LOCAL   @test:RECT

                mov     eax,uMsg
                .if     eax == WM_TIMER
					; .IF rePaintLabel > 0
					; .ENDIF
					invoke update
					invoke InvalidateRect,hWnd,NULL,FALSE
                .elseif eax == WM_PAINT
					invoke BeginPaint,hWnd,addr @stPS
					invoke Paint,hWnd,eax
					invoke EndPaint,hWnd,addr @stPS
                .elseif eax == WM_CREATE
					invoke Init, hWnd, wParam, lParam
                    invoke SetTimer,hWnd,ID_TIMER,repaintFreq,NULL
				.elseif eax == WM_LBUTTONDOWN
					invoke leftMouseHandler
				.elseif uMsg==WM_CHAR
					push wParam
					pop  @char
                .elseif eax == WM_CLOSE
					invoke KillTimer,hWnd,ID_TIMER
					invoke DestroyWindow,hWinMain
					invoke PostQuitMessage,NULL
                .else   
                    invoke DefWindowProc,hWnd,uMsg,wParam,lParam
					ret
                .endif
                xor     eax,eax
                ret
_ProcWinMain    endp
 
 
_WinMain        proc    
 
	LOCAL   @stWndClass:WNDCLASSEX
	LOCAL   @stMsg:MSG
       
	   
	invoke  GetModuleHandle,NULL
	mov     hInstance,eax
	invoke  RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
	invoke  LoadIcon,hInstance,IDI_ICON1
	mov     @stWndClass.hIcon,eax
	mov     @stWndClass.hIconSm,eax
	invoke  LoadCursor,0,IDC_ARROW
	mov     @stWndClass.hCursor,eax
	push    hInstance
	pop     @stWndClass.hInstance
	mov     @stWndClass.cbSize,sizeof WNDCLASSEX
	mov     @stWndClass.style,CS_HREDRAW or CS_VREDRAW
	mov     @stWndClass.lpfnWndProc,offset _ProcWinMain
	mov     @stWndClass.hbrBackground,COLOR_WINDOW + 1
	mov     @stWndClass.lpszClassName,offset szClassName
	invoke  RegisterClassEx,addr @stWndClass
	invoke  CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szClassName,\
			WS_OVERLAPPEDWINDOW,160,90,WWidth,WHeight,NULL,NULL,hInstance,NULL
	mov     hWinMain,eax
	invoke  ShowWindow,hWinMain,SW_SHOWNORMAL
	invoke  UpdateWindow,hWinMain
	invoke initGame
	.while  TRUE
		invoke  GetMessage,addr @stMsg,NULL,0,0
		.break  .if eax ==0
		invoke  TranslateMessage,addr @stMsg
		invoke  DispatchMessage,addr @stMsg 
	.endw
	ret
_WinMain        endp
 
 
start:
    call    _WinMain
    invoke  ExitProcess,NULL
    end     start




