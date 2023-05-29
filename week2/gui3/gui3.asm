.386
.model flat,stdcall
option casemap:none
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\comctl32.inc
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\shell32.lib
includelib \masm32\lib\comctl32.lib

.data
ClassName db "SimpleWinClass",0
AppName  db "reverse text",0
ButtonText db "Show",0
EditClassName db "edit",0
ReadonlyClassName db "edit",0
len dd ?
.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?
hwndButton HWND ?
hwndEdit HWND ?
hwndReadOnly HWND ?
buffer db 512 dup(?)
cac db 512 dup(?)
.const
readonlyID equ 101
EditID equ 100
IDM_HELLO equ 1
IDM_CLEAR equ 2
IDM_GETTEXT equ 3
IDM_EXIT equ 4

.code
start:
	invoke GetModuleHandle, NULL
	mov    hInstance,eax
	invoke GetCommandLine
	mov CommandLine,eax
	invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess,eax
WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	mov   wc.cbSize,SIZEOF WNDCLASSEX
	mov   wc.style, CS_HREDRAW or CS_VREDRAW
	mov   wc.lpfnWndProc, OFFSET WndProc
	mov   wc.cbClsExtra,NULL
	mov   wc.cbWndExtra,NULL
	push  hInst
	pop   wc.hInstance
	mov   wc.hbrBackground,COLOR_BTNFACE+1
	
	mov   wc.lpszClassName,OFFSET ClassName
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov   wc.hIcon,eax
	mov   wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov   wc.hCursor,eax
	invoke RegisterClassEx, addr wc
	INVOKE CreateWindowEx,WS_EX_CLIENTEDGE,ADDR ClassName,ADDR AppName,\
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
           CW_USEDEFAULT,300,200,NULL,NULL,\
           hInst,NULL
	mov   hwnd,eax
	
	INVOKE ShowWindow, hwnd,SW_SHOWNORMAL
	INVOKE UpdateWindow, hwnd
	.WHILE TRUE
                INVOKE GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                INVOKE TranslateMessage, ADDR msg
                INVOKE DispatchMessage, ADDR msg
	.ENDW
	mov     eax,msg.wParam
	ret
WinMain endp
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	.IF uMsg==WM_DESTROY
		invoke PostQuitMessage,0
		
	.ELSEIF uMsg==WM_CREATE
		invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR EditClassName,NULL,\
                        WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or\
                        ES_AUTOHSCROLL or ES_MULTILINE,\
                        50,35,200,25,hWnd,EditID,hInstance,NULL
	    mov  hwndEdit,eax
		invoke SetFocus, hwndEdit
		invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ReadonlyClassName,NULL, \
                    WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or \
                    ES_AUTOHSCROLL or ES_MULTILINE or ES_READONLY, \
                    50, 70, 200, 25, hWnd, readonlyID, hInstance, NULL
		mov hwndReadOnly, eax
	
	.ELSEIF uMsg==WM_COMMAND
		
		mov eax,wParam
			
				
				.IF lParam==0
					.IF ax == IDM_GETTEXT
				
						invoke SendMessage, hwndEdit, WM_GETTEXT, 512, ADDR buffer
						invoke lstrlen, ADDR buffer
						dec eax
						mov ecx, 0
						.WHILE ecx < eax
							mov dl, buffer[ecx]
							mov dh, buffer[eax]
							mov buffer[ecx], dh
							mov buffer[eax], dl
							inc ecx
							dec eax
						.ENDW
					    invoke SendMessage, hwndReadOnly, WM_SETTEXT, NULL, ADDR buffer
					.ENDIF
				.ELSE
					.IF ax == EditID
						shr eax, 16
						.IF ax == EN_CHANGE
							invoke SendMessage, hWnd,WM_COMMAND	,IDM_GETTEXT,0
						.ENDIF	
					.ENDIF
				.ENDIF	
				
	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam
		ret
	.ENDIF
	xor    eax,eax
	ret
WndProc endp


end start
