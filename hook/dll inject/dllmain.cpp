/* Replace "dll.h" with the name of your header */
#include "dll.h"
#include <windows.h>

BOOL APIENTRY DllMain(HMODULE hModule,  DWORD  nReason, LPVOID lpReserved) {
  switch (nReason) {
  case DLL_PROCESS_ATTACH:
    break;
  case DLL_PROCESS_DETACH:
    break;
  case DLL_THREAD_ATTACH:
    break;
  case DLL_THREAD_DETACH:
    break;
  }
  return TRUE;
}

extern "C" __declspec(dllexport) int Mal() {
  MessageBox(
    NULL,
    "injected",
    "=^..^=",
    MB_OK
  );
  return 0;
}

