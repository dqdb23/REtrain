#include <stdio.h>
#include <windows.h>
#include <tlhelp32.h>
#include <psapi.h>
#include <tchar.h>

int main() {
    HANDLE hProcessSnap;
    PROCESSENTRY32 pe32;
    HANDLE hProcessToken;

    
    BOOL isElevated = FALSE;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hProcessToken)) {
        printf("ERROR: Khong the mo token cua tien trinh hien tai.\n");
        return 1;
    }

    TOKEN_ELEVATION Elevation;
    DWORD cbSize = sizeof(TOKEN_ELEVATION);
    if (GetTokenInformation(hProcessToken, TokenElevation, &Elevation, sizeof(Elevation), &cbSize)) {
        isElevated = Elevation.TokenIsElevated;
    }

    CloseHandle(hProcessToken);

    if (!isElevated) {
        printf("Chuong trinh can duoc chay voi quyen Administrator de doc duoc thong tin bo nho cua tat ca cac tien trinh.\n");
        return 1;
    }

    hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hProcessSnap == INVALID_HANDLE_VALUE) {
        printf("ERROR: Khong the tao snapshot cua cac tien trinh.\n");
        return 1;
    }

    pe32.dwSize = sizeof(PROCESSENTRY32);
    if (!Process32First(hProcessSnap, &pe32)) {
        printf("ERROR: khong the lay thong tin cua tien trinh dau tien.\n");
        CloseHandle(hProcessSnap);
        return 1;
    }

    printf("%-30s %25s %20s %20s\n", "Image Name", "PID", "Count Threads", "Memory Usage (KB)");

    do {
        _tprintf(TEXT(" %-30s"), pe32.szExeFile);
        HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pe32.th32ProcessID);
        if (hProcess != NULL) {
            DWORD dwAccessDenied = 0;
            if (!GetExitCodeProcess(hProcess, &dwAccessDenied) && GetLastError() == ERROR_ACCESS_DENIED) {
                printf("%25d %20d %20s (Access Denied)\n", pe32.th32ProcessID, pe32.cntThreads, "N/A");
            }
            else {
                PROCESS_MEMORY_COUNTERS pmc;
                if (GetProcessMemoryInfo(hProcess, &pmc, sizeof(pmc))) {
                    printf("%25d %20d %20d\n", pe32.th32ProcessID, pe32.cntThreads, (int)(pmc.WorkingSetSize / 1024));
                }
                else {
                    DWORD dwError = GetLastError();
                    printf("%25d %20d %20s (Error: %lu)\n", pe32.th32ProcessID, pe32.cntThreads, "N/A", dwError);
                }
            }
            CloseHandle(hProcess);
        }
        else {
            DWORD dwError = GetLastError();
            printf("%25d %20d %20s (Error: %lu)\n", pe32.th32ProcessID, pe32.cntThreads, "N/A", dwError);
        }
    } while (Process32Next(hProcessSnap, &pe32));

    CloseHandle(hProcessSnap);
    system("pause");
    return 0;
}
