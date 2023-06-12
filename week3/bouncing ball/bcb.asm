.386    
.model flat,stdcall 
option casemap:none

include D:\masm32\include\windows.inc   
include D:\masm32\include\user32.inc
includelib D:\masm32\lib\user32.lib 
include D:\masm32\include\kernel32.inc
includelib D:\masm32\lib\kernel32.lib  
include D:\masm32\include\masm32.inc
includelib D:\masm32\lib\masm32.lib
include D:\masm32\include\gdi32.inc
includelib D:\masm32\lib\gdi32.lib

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
.CONST
DRAWING equ 1
WAITING equ 0
PEN_COLOR equ 000000ffh 
PEN_SIZE equ 20
BALL_SIZE equ 30
BALL_SPEED equ 10

.DATA
ClassName db 'SimpleWinClass',0
AppName db 'Ball',0

state db WAITING

vectorX dd 8
vectorY dd -8

WIN_WIDTH dd 700
WIN_HEIGHT dd 500

.DATA?
hBrush HBRUSH ?
hInstance HINSTANCE ?
tlpoint POINT <>
brpoint POINT <>
wc WNDCLASSEX <?>
msg MSG <?> 
hwnd HWND ? 
hdc HDC ?
ps PAINTSTRUCT <?>
time SYSTEMTIME <?>
hPen HPEN ?

.CODE
start:
    
    invoke GetModuleHandle,NULL 
    mov hInstance, eax 

    invoke WinMain, hInstance,NULL,NULL,SW_SHOW
	
    invoke ExitProcess, eax

   
    WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
	
        invoke LoadIcon, NULL, IDI_APPLICATION
        mov wc.hIcon, eax
        mov wc.hIconSm, eax
		invoke LoadCursor, NULL, IDC_ARROW
        mov wc.hCursor, eax
		mov wc.cbSize, SIZEOF WNDCLASSEX    
        mov wc.style, CS_HREDRAW or CS_VREDRAW  
        mov wc.lpfnWndProc, OFFSET WndProc  
        mov wc.cbClsExtra, NULL
        mov wc.cbWndExtra, NULL
        push hInstance
        pop wc.hInstance
        mov wc.hbrBackground, COLOR_WINDOW+1   
        mov wc.lpszMenuName, NULL
        mov wc.lpszClassName, OFFSET ClassName

        invoke RegisterClassEx, addr wc
        invoke CreateWindowEx, WS_EX_CLIENTEDGE, addr ClassName, addr AppName, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,CW_USEDEFAULT, WIN_WIDTH,WIN_HEIGHT,\
		NULL,NULL,hInstance,NULL
		mov hwnd, eax  

        invoke ShowWindow, hwnd,CmdShow
        invoke UpdateWindow,hwnd

        .WHILE TRUE
                invoke GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
		.ENDW
		mov     eax,msg.wParam
		ret
	WinMain endp
    
	TimerProc PROC thwnd:HWND, uMsg:UINT, idEvent:UINT, dwTime:DWORD
            invoke InvalidateRect,TRUE
            ret
    TimerProc ENDP

    WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

        .IF uMsg==WM_DESTROY
            invoke PostQuitMessage, NULL
            
		.ELSEIF uMsg==WM_CREATE
            invoke CreatePen, PS_SOLID, PEN_SIZE, PEN_COLOR
            mov hPen, eax
			invoke CreateSolidBrush, PEN_COLOR
			mov hBrush, eax
        .ELSEIF uMsg==WM_LBUTTONDOWN
            cmp [state], DRAWING
            je EXIT
            push lParam
            call updateXY
            mov [state], DRAWING
			invoke SetTimer,hwnd,1,20,addr TimerProc

        .ELSEIF uMsg==WM_PAINT
            mov dword ptr[time.wMilliseconds], 0

            invoke BeginPaint,hwnd, addr ps
            mov hdc, eax
            
            invoke SelectObject,hdc,hPen
			invoke SelectObject,hdc,hBrush
            call createEllipse

            invoke EndPaint, hWnd, addr ps

        .ELSE
            
            invoke DefWindowProc,hWnd,uMsg,wParam,lParam
            ret
		.ENDIF
        EXIT:
            ret
    WndProc endp

    createEllipse proc
        invoke Ellipse,hdc, tlpoint.x,tlpoint.y,brpoint.x,brpoint.y

        call moveEllipse

        mov eax, WIN_WIDTH
        cmp brpoint.x, eax
        jg MEET_RIGHT_LEFT

        mov eax, WIN_HEIGHT
        cmp brpoint.y, eax
        jg MEET_BOTTOM_TOP

        cmp tlpoint.x, 0
        jl MEET_RIGHT_LEFT

        cmp tlpoint.y, 0
        jl MEET_BOTTOM_TOP

        jmp MEET_NONE

        MEET_RIGHT_LEFT:
            neg vectorX
            jmp MEET_NONE

        MEET_BOTTOM_TOP:
            neg vectorY
            jmp MEET_NONE

        MEET_NONE:

        ret
    createEllipse endp

    moveEllipse proc
        mov eax, dword ptr[vectorX]
        mov ecx, dword ptr[vectorY]

        add tlpoint.x, eax
        add tlpoint.y, ecx
        add brpoint.x, eax
        add brpoint.y, ecx

        ret
    moveEllipse endp

    updateXY proc lParam:LPARAM
        mov eax, lParam

		xor ebx, ebx
        mov bx, ax

        mov tlpoint.x, ebx
        mov brpoint.x, ebx
        add brpoint.x, BALL_SIZE

        mov eax, lParam
        shr eax, 16

        mov tlpoint.y, eax
        mov brpoint.y, eax
        add brpoint.y, BALL_SIZE

        ret
        updateXY endp

end start