#include <stdio.h>
#include <windows.h>
#include <tlhelp32.h>
#include <string.h>

int terminatePID(DWORD pid) {
    HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, pid);
    if (hProcess != NULL) {
        TerminateProcess(hProcess, 0);
        CloseHandle(hProcess);
        
        return 0;
    } 
}

int terminatePS(const char* ps) {
    HANDLE hProcessSnap;
    PROCESSENTRY32 pe32;

    hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hProcessSnap == INVALID_HANDLE_VALUE) {
        printf("ERROR: Khong the tao snapshot.\n");
        return 1;
    }

    pe32.dwSize = sizeof(PROCESSENTRY32);

    if (!Process32First(hProcessSnap, &pe32)) {
        printf("ERROR: Khong the lay thong tin tien trinh dau tien.\n");
        CloseHandle(hProcessSnap);
        return 1;
    }

    do {
        if (strcmp(pe32.szExeFile, ps) == 0) {
            if(terminatePID(pe32.th32ProcessID)==0){
                 return 0;
            }
            break;
        }
    } while (Process32Next(hProcessSnap, &pe32));

    CloseHandle(hProcessSnap);
}

int main() {
    char ps[100];
    printf("Nhap ten Process:");
    if (scanf("%s", ps) != 1) {
        printf("ERROR: Khong doc duoc ten Process.\n");
        return 1;
    }

    if (strlen(ps) == 0) {
        printf("ERROR: Ten Process khong hop le.\n");
        return 1;
    }

    DWORD pid;
    printf("Nhap PID:");
    if (scanf("%lu", &pid) != 1) {
        printf("ERROR: Khong doc duoc PID.\n");
        return 1;
    }

    if (pid != 0) {
        if(terminatePID(pid)==0){
        	printf("Da ket thuc tien trinh PID %lu thanh cong.\n", pid);
		}
    } else {
        if(terminatePS(ps)==0){
        	printf("Da ket thuc tien trinh %s thanh cong.\n", ps);
		}
    }

    return 0;
}
