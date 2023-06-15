.386    
.model flat,stdcall 
option casemap:none

include \masm32\include\windows.inc   
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib 
include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib  
include \masm32\include\masm32.inc
includelib \masm32\lib\masm32.lib
include \masm32\include\gdi32.inc
includelib \masm32\lib\gdi32.lib

move proto right: DWORD, bottom: DWORD
WndProc proto hWnd:HWND, uMsg: UINT,wParam: WPARAM, lParam: LPARAM

.const 
PEN_COLOR equ 000000ffh 
PEN_SIZE  equ 20
BALL_SIZE equ 30
.data?
hIns 	DWORD	?
hWnd1	DWORD 	?
hPen 	HPEN 	?
hBrush  HBRUSH  ?
.data
classname	db		"BB",0
appname		db		"BouncingBall",0

wc			WNDCLASSEX	<>
msg			MSG			<>

cons	dd	8

x1		dd	?
x2		dd	?
y1		dd	?
y2		dd	?


mx		dd	8
my		dd	8

.code
start:
	invoke GetModuleHandle,NULL
	mov hIns, eax
	mov wc.hInstance, eax
	
	mov wc.cbSize, sizeof WNDCLASSEX
	mov wc.style, CS_HREDRAW OR CS_VREDRAW
	
	mov wc.lpfnWndProc,offset WndProc
	mov wc.cbClsExtra,0
	mov wc.cbWndExtra,0
	
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov wc.hIcon, eax
	mov wc.hIconSm, eax
	
	invoke LoadCursor,NULL,IDC_ARROW
	mov wc.hCursor,eax
	
	mov wc.hbrBackground, COLOR_WINDOW + 1
	mov wc.lpszMenuName, NULL
	mov wc.lpszClassName, offset classname
	
	invoke RegisterClassEx,addr wc
	invoke CreateWindowEx,WS_EX_WINDOWEDGE,addr classname, addr appname, WS_OVERLAPPEDWINDOW, 500,250,500,500,NULL,NULL,hIns,NULL
	mov hWnd1, eax
	invoke ShowWindow,hWnd1,SW_SHOW
	invoke UpdateWindow,hWnd1
	
	Message:
		invoke GetMessage,addr msg,NULL,NULL,NULL
		.if eax == 0
			jmp quit
		.endif
		invoke TranslateMessage,addr msg
		invoke DispatchMessage,addr msg
		loop Message
	quit:
	invoke ExitProcess,NULL
	
	WndProc proc hWnd:HWND, uMsg: UINT,wParam: WPARAM, lParam: LPARAM
	LOCAL hdc: DWORD
	LOCAL rect: RECT
	LOCAL hbr : DWORD
		
		mov eax, x1
		add eax, BALL_SIZE
		mov x2, eax
		
		mov eax, y1
		add eax, BALL_SIZE
		mov y2, eax
	 
		.if uMsg == WM_DESTROY
			invoke PostQuitMessage,NULL
			xor eax, eax
		.elseif uMsg == WM_CREATE
			 invoke CreatePen, PS_SOLID, PEN_SIZE, PEN_COLOR
            mov hPen, eax
			invoke CreateSolidBrush, PEN_COLOR
			mov hBrush, eax
			invoke SetTimer,hWnd, 1, 20,NULL
		
		.elseif uMsg == WM_TIMER
			invoke GetDC,hWnd
			mov hdc, eax
			
			invoke GetStockObject,0
			mov hbr, eax
			
			invoke GetClientRect,hWnd, addr rect
			invoke FillRect,hdc,addr rect, hbr
			invoke SelectObject,hdc,hPen
			invoke SelectObject,hdc,hBrush
			invoke Ellipse,hdc,x1,y1,x2,y2
			invoke move, rect.right , rect.bottom
			invoke ReleaseDC,hWnd,hdc
		.else 
			invoke DefWindowProc,hWnd,uMsg,wParam,lParam
		.endif
		EXIT:
		ret

	WndProc endp
	
move proc right: DWORD, bottom: DWORD
	mov ecx, cons
	
		mov eax, my
		add y1, eax
		mov edx, bottom
		.if y1 > edx
			sub edx, BALL_SIZE
			mov y1, edx
		.endif

		mov eax, y2
		add eax, my			

		mov ebx, mx
		add x1, ebx	
		mov edx, right
		.if x1 > edx
			sub edx, BALL_SIZE
			mov x1, edx
		.endif
		
		mov ebx, x2
		add ebx, mx
		
		.if y1 < ecx
			.if my > ecx				
				neg my
			.endif
		.elseif eax > bottom
			neg my		
		.endif
		
		.if x1 < ecx
			.if mx > ecx				
				neg mx
			.endif
		.elseif ebx > right
			neg mx
		.endif
		
	ret

move endp

end start