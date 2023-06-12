.386
.model flat, stdcall
include \masm32\include\masm32rt.inc	
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib

addC	proto
addI proto,row: DWORD, lFind: DWORD
cut proto, str1:ptr byte , str2 :ptr byte 
SearchDir proto, temp: ptr byte
del proto, strD : ptr byte
rmv proto , rm:ptr byte
.const 
butS				equ 1
butP				equ 2
WM_FINISH 			equ WM_USER+100h
ID_Edit				equ 1000
ID_ButS 			equ 200
ID_ButST 			equ 201
ID_KillThreat		equ 202
ID_CreateThreat 	equ 203
ID_NewList			equ 204
.data
classname	db			"Win32",0
wndname		db			"Scan",0
ListClass 	db 			"SysListView32",0
butClass	db			"Button",0
editClass	db			"Edit",0
staticClass	db			"Static",0
butSc		db			"Scan",0
butST		db			"Stop",0
head		db			"FilePath",0
cc			db			"Path",0
dot     	db      	".",0
dotDot  	db      	"..",0	
path		DB			10000 dup(0)
slashS		DB			"\*",0
sao			DB			"*",0
Path 		DB			5000 dup(0)
Path2		DB			5000 dup(0)
msg			MSG			<>
wc			WNDCLASSEX	<>

.data?
hWnd1		DWORD 	?
hIns		DWORD	?	
hEdit		DWORD	?
hList		DWORD	?
button1 	HWND	?
button2 	HWND	?
ThreadID 	DWORD 	?
hThread		DWORD	?
ExitCode	DWORD 	?

.code
Start:
	invoke GetModuleHandle,NULL
	mov hIns, eax
	mov wc.hInstance, eax
	mov	wc.cbClsExtra , 0
	mov	wc.cbSize , sizeof WNDCLASSEX
	mov wc.cbWndExtra , 0
	mov wc.hbrBackground, COLOR_WINDOW + 1
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov wc.hIcon, eax
	mov wc.hIconSm, eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov	wc.hCursor,eax
	mov wc.lpfnWndProc,offset WndProc
	mov wc.lpszClassName, offset classname
	mov wc.lpszMenuName, NULL
	mov wc.style, CS_HREDRAW OR CS_VREDRAW
	invoke RegisterClassEx,addr wc
	invoke CreateWindowEx,NULL,addr classname, addr wndname, WS_OVERLAPPEDWINDOW, 500, 250 , 700 , 500 , NULL,NULL, hIns, NULL
	mov hWnd1, eax
	invoke CreateWindowEx, NULL, ADDR editClass, ADDR cc, WS_CHILD or WS_VISIBLE, 12, 15, 40, 30, hWnd1, NULL, hIns, NULL
	invoke CreateWindowEx,WS_EX_CLIENTEDGE, addr editClass,NULL,WS_CHILD+ WS_VISIBLE+ ES_AUTOHSCROLL, 60,10,550,30,hWnd1,ID_Edit,hIns,NULL
	mov hEdit, eax
	invoke CreateWindowEx,WS_EX_CLIENTEDGE, addr butClass, addr butSc, WS_CHILD or WS_VISIBLE,620,10,60,30,hWnd1,butS,hIns,NULL
	mov button1 , eax
	
	invoke ShowWindow,hWnd1,SW_SHOW
	invoke UpdateWindow,hWnd1
	
	MessageLoop:
		invoke GetMessage,addr msg, NULL,NULL,NULL
		.if eax == 0
			jmp quit
		.endif
		invoke TranslateMessage,addr msg
		invoke DispatchMessage,addr msg	
		loop MessageLoop
	quit:
	invoke ExitProcess,NULL 
	
	WndProc proc hWnd : HWND , uMsg:UINT , wParam: WPARAM , lParam: LPARAM
		.if uMsg == WM_COMMAND
			mov eax,wParam  
			.if lParam == 0
				.if ax == ID_ButS
					invoke DestroyWindow,button1
					invoke CreateWindowEx,WS_EX_CLIENTEDGE, addr butClass, addr butSc, WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,620,10,60,30,hWnd,butS,hIns,NULL
					mov button1, eax
				.elseif ax == ID_ButST
					invoke GetWindowText,hEdit,addr path,sizeof path	
					invoke DestroyWindow,button1
					invoke CreateWindowEx,WS_EX_CLIENTEDGE, addr butClass, addr butST, WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,620,10,60,30,hWnd, butP, hIns,NULL
					mov button1, eax
					
				.elseif ax == ID_NewList
					invoke DestroyWindow,hList
					invoke CreateWindowEx,WS_EX_CLIENTEDGE, addr ListClass, NULL, LVS_REPORT+WS_CHILD+WS_VISIBLE, 10,60,670,390,hWnd, NULL, hIns, NULL
					mov hList, eax
					invoke SetFocus, hList
					invoke addC
				.elseif ax == ID_CreateThreat
					
					mov eax, offset ThreadProc
					invoke CreateThread,NULL,NULL,eax,0,NULL, addr ThreadID
					mov hThread, eax
					
				.elseif ax == ID_KillThreat
					invoke GetExitCodeThread,hThread,addr ExitCode
					.if ExitCode == STILL_ACTIVE
						invoke TerminateThread,hThread, 0
					.else 
						invoke CloseHandle,hThread
					.endif
				.endif
			.else
				.if ax == butS
					invoke SendMessage,hWnd,WM_COMMAND, ID_NewList,0
					invoke SendMessage,hWnd,WM_COMMAND, ID_ButST,0
					invoke SendMessage,hWnd,WM_COMMAND, ID_CreateThreat,0
				.elseif ax == butP
					invoke SendMessage,hWnd,WM_COMMAND, ID_KillThreat,0
					invoke SendMessage,hWnd,WM_COMMAND, ID_ButS,0
				.endif
			.endif
		.elseif uMsg==WM_FINISH
        	
        	invoke SendMessage,hWnd,WM_COMMAND, ID_ButS, 0
			
		.elseif uMsg==WM_CREATE
			invoke SendMessage,hWnd,WM_COMMAND, ID_NewList,0
			
		.elseif	uMsg == WM_DESTROY
			invoke PostQuitMessage,NULL
			xor eax , eax
			.else 
				invoke DefWindowProc,hWnd,uMsg, wParam, lParam
				
		.endif
		outp:
		ret

	WndProc endp

	ThreadProc PROC USES ecx Param:DWORD
		invoke SearchDir,addr path
        invoke PostMessage,hWnd1,WM_FINISH,NULL,NULL
        ret
	ThreadProc ENDP


SearchDir proc dir : ptr byte
local finddata: WIN32_FIND_DATA
local FHandle : DWORD 

	invoke del,addr Path
	invoke lstrcat, addr Path,dir
	invoke lstrcat, addr Path,addr slashS
	
	invoke FindFirstFile, addr Path, addr finddata
	.if eax != INVALID_HANDLE_VALUE
		mov FHandle , eax
		xor edi,edi
		invoke cut,addr sao,addr Path
		.while eax != 0
			invoke lstrcmp,addr finddata.cFileName, addr dot
			cmp eax, 0
			je next
			invoke lstrcmp, addr finddata.cFileName, addr dotDot
			cmp eax, 0
			je next
			invoke lstrcat , addr Path,addr finddata.cFileName
			invoke addI,edi,addr Path
			inc edi
			invoke del,addr Path2
			invoke lstrcpy, addr Path2,addr Path
			invoke SearchDir,addr Path2
			invoke cut,addr slashS , addr Path
			invoke rmv,addr Path
			next:
			invoke FindNextFile,FHandle,addr finddata
		.endw
		invoke FindClose,FHandle
	.endif
	outF:
	ret
SearchDir endp

addC	proc 
		local lvc : LV_COLUMN
		local rect: RECT
				
		mov lvc.imask, LVCF_TEXT or LVCF_WIDTH or LVCF_FMT
		mov lvc.lx,600
		mov lvc.pszText, offset head
		mov lvc.fmt,LVCFMT_FILL
		invoke SendMessage,hList,LVM_INSERTCOLUMN,0,addr lvc	
		ret

	addC endp
	
addI proc ,row: DWORD, lFind: DWORD
		local lvi: LV_ITEM
		invoke SetFocus,hList
		mov edi, lFind
		assume edi: ptr WIN32_FIND_DATA
		mov lvi.imask, LVIF_TEXT or LVIF_PARAM 
		push row
		pop lvi.iItem
		mov lvi.iSubItem,0
		lea eax, Path
		mov lvi.pszText,eax	
		push row
		pop lvi.lParam	
		invoke SendMessage,hList,LVM_INSERTITEM, 0 ,addr lvi
		invoke SendMessage,hList,LVM_SCROLL,0,20
		invoke SendMessage,hList,LVM_ENSUREVISIBLE,row,FALSE
		invoke Sleep,1
		ret

addI endp

del proc , strD : ptr byte
	mov ecx , 5000
	xor ebx, ebx
	mov edi,strD
	LD:
		mov [edi], bl
		inc edi
		loop LD
	ret

del endp
	

cut proc , str1:ptr byte , str2 :ptr byte
	mov edi , str2
	invoke lstrlen,str2
	add edi , eax
	invoke lstrlen,str1
	mov ecx , eax
	inc ecx
	xor ebx , ebx
	L3:
		mov [edi], bl
		dec edi
		loop L3
	ret

cut endp
rmv proc , rm:ptr byte
	mov edi , rm
	invoke lstrlen,rm
	mov ecx , eax
	add edi,eax
	xor eax, eax
	LR:
		mov ah,[edi]
		cmp ah,'\'
		jz ut
		mov [edi],al
		dec edi
		loop LR
	ut:
	ret

rmv endp


end Start