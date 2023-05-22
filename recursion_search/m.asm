.386

option casemap :none

include \masm32\include\masm32rt.inc
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\shell32.lib

.data
    inputFile db "D:\masm32\thuchanh\input.txt",0
    outputFileName db "D:\masm32\thuchanh\output.txt",0
	error db "ERRORRRRRRRRRRRRRRRRR!",0
    bufferSize equ 256
    buffer db bufferSize dup (?)
    findData WIN32_FIND_DATA <>
    handle dd ?
	xxx dd ?
    outputFileHandle dd ?
    line_break db 13,10,0
    byteWrite dd ?
    byteRead dd ?
    x db "\*",0
	y db ".",0
	z db "..",0
	a db "\",0
.code

SearchDirectory proc directoryPath:LPSTR
    local searchPath[512]:BYTE
    local fileFound:BYTE
    local anoPath[512]:BYTE
    
    invoke lstrcpy, addr searchPath, directoryPath
    invoke lstrcat, addr searchPath, addr x
    invoke lstrcpy, addr anoPath, directoryPath
    invoke StdOut, addr anoPath
    invoke FindFirstFile, addr searchPath, addr findData
    mov handle, eax
	push eax
    .while handle != INVALID_HANDLE_VALUE
        
        invoke lstrcmp, addr findData.cFileName, addr y
        cmp eax, 0
        je nextFile
        invoke lstrcmp, addr findData.cFileName, addr z
        cmp eax, 0
        je nextFile
        
        test findData.dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY
        jnz isDirectory

        invoke lstrlen, addr findData.cFileName
        invoke WriteFile, outputFileHandle, addr findData.cFileName, eax, addr byteWrite, 0
        invoke WriteFile, outputFileHandle, addr line_break, 2, addr byteWrite, 0
        jmp nextFile
        alo:
			mov  handle, INVALID_HANDLE_VALUE
			jmp the_end
        isDirectory:
        invoke lstrlen, addr findData.cFileName
        invoke WriteFile, outputFileHandle, addr findData.cFileName, eax, addr byteWrite, 0
        invoke WriteFile, outputFileHandle, addr line_break, 2, addr byteWrite, 0
		
        invoke lstrcpy, addr searchPath, directoryPath
        invoke lstrcat, addr searchPath, addr a
        invoke lstrcat, addr searchPath, addr findData.cFileName
		invoke SearchDirectory, addr searchPath
        pop ebx
		mov handle, ebx
        nextFile:
        invoke FindNextFile, handle, addr findData
		cmp eax, 0 
		je alo
	the_end:	
    .endw
	invoke FindClose, handle

    ret
SearchDirectory endp

main proc
     invoke CreateFile, ADDR inputFile, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    cmp eax, INVALID_HANDLE_VALUE 
    je fileError
    
    invoke ReadFile, eax, ADDR buffer, sizeof buffer, ADDR byteRead, NULL
	mov ebx, byteRead
    test ebx,ebx
    jz fileError
	
    invoke CreateFile, addr outputFileName, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    cmp eax, INVALID_HANDLE_VALUE
    je fileError
    mov outputFileHandle, eax

    
	
    invoke SearchDirectory, addr buffer

	invoke CloseHandle, outputFileHandle
    invoke ExitProcess, 0

fileError:
    
    invoke StdOut, offset error
    invoke ExitProcess, 1

main endp
end main