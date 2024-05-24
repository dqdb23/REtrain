#include <iostream>
#include <string>
#include <windows.h>
#include <pthread.h>
#include <tlhelp32.h>
using namespace std;

#define BUFSIZE MAX_PATH

void countWords(void* arg) {
    LARGE_INTEGER frequency;
    LARGE_INTEGER t1, t2;
    double elapsedTime;
    QueryPerformanceFrequency(&frequency);
    QueryPerformanceCounter(&t1);

    FILE* file = fopen("C:\\Users\\84824\\Desktop\\RE\\thread, process\\1.txt", "r");
    if (file == NULL) {
        cout << "Khong the mo file." << endl;
        return;
    }

    int count = 0;
    char c;
    while ((c = fgetc(file)) != EOF) {
        count++;
    }

    fclose(file);
    QueryPerformanceCounter(&t2);
    elapsedTime = (double)(t2.QuadPart - t1.QuadPart) / frequency.QuadPart;
   
    double* timeTaken = (double*)arg;
    *timeTaken = elapsedTime;
}

void countFiles(void* arg) {
    LARGE_INTEGER frequency;
    LARGE_INTEGER t1, t2;
    double elapsedTime;
    QueryPerformanceFrequency(&frequency);
    QueryPerformanceCounter(&t1);

    TCHAR basePath[BUFSIZE];
    DWORD dwRet;
    dwRet = GetCurrentDirectory(BUFSIZE, basePath);

    WIN32_FILE_ATTRIBUTE_DATA Info;
    WIN32_FIND_DATA fileData;
    HANDLE hFind = FindFirstFile(basePath, &fileData);

    if (hFind != INVALID_HANDLE_VALUE) {
        int counts = 0;
        do {
            if (fileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
                counts++;
            }
        } while (FindNextFile(hFind, &fileData) != 0);
        FindClose(hFind);

        QueryPerformanceCounter(&t2);
        elapsedTime = (double)(t2.QuadPart - t1.QuadPart) / frequency.QuadPart;
        

        double* timeTaken = (double*)arg;
        *timeTaken = elapsedTime;
    } else {
        cout << "Khong the mo thu muc hien tai." << endl;
    }
}

void countThreads(void* arg){
	LARGE_INTEGER frequency;
    LARGE_INTEGER t1, t2;
    double elapsedTime;
    QueryPerformanceFrequency(&frequency);
    QueryPerformanceCounter(&t1);
	HANDLE hProcessSnap;
    PROCESSENTRY32 pe32;
	int count=0;
    hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hProcessSnap == INVALID_HANDLE_VALUE) {
        printf("ERROR: Khong the tao snapshot cua cac tien trinh.\n");
        return ;
    }

    pe32.dwSize = sizeof(PROCESSENTRY32);

    if (!Process32First(hProcessSnap, &pe32)) {
        printf("ERROR: khong the lay thong tin cua tien trinh dau tien.\n");
        CloseHandle(hProcessSnap);
        return ;
    }

    do {
        if(strcmp(pe32.szExeFile, "explorer.exe") == 0){
            count = pe32.cntThreads;
        }
    } while (Process32Next(hProcessSnap, &pe32));

    CloseHandle(hProcessSnap);
    QueryPerformanceCounter(&t2);
    elapsedTime = (double)(t2.QuadPart - t1.QuadPart) / frequency.QuadPart;
   
    double* timeTaken = (double*)arg;
    *timeTaken = elapsedTime;
	
}

int main() {
    double timeTaken1 = 0, timeTaken2 = 0, timeTaken3 = 0;
    pthread_t thread1, thread2, thread3;

    pthread_create(&thread1, NULL, (void* (*)(void*))countWords, (void*)&timeTaken1);
    pthread_create(&thread2, NULL, (void* (*)(void*))countFiles, (void*)&timeTaken2);
    pthread_create(&thread3, NULL, (void* (*)(void*))countThreads, (void*)&timeTaken3);

    pthread_join(thread1, NULL);
    pthread_join(thread2, NULL);
    pthread_join(thread3, NULL);

    printf("Thread 1: %.6f s\n", timeTaken1);
    printf("Thread 2: %.6f s\n", timeTaken2);
    printf("Thread 3: %.6f s\n", timeTaken3);
    
	if( timeTaken1 >= timeTaken2){
		if (timeTaken1 >= timeTaken3){
			printf("Thread 1: Giai nhat\n");
			if(timeTaken3 >= timeTaken2){
				printf("Thread 3: Giai nhi\n");
				printf("Thread 2: Giai ba\n");
			}else{
				printf("Thread 2: Giai nhi\n");
				printf("Thread 3: Giai ba\n");
			}
		}
		else{
			printf("Thread 3: Giai nhat\n");
			printf("Thread 1: Giai nhi\n");
			printf("Thread 2: Giai ba\n");
		}
	}else{
		if(timeTaken2 >= timeTaken3){
			printf("Thread 2: Giai nhat\n");
				if(timeTaken1 >= timeTaken3){
				printf("Thread 1: Giai nhi\n");
				printf("Thread 3: Giai ba\n");
			}else{
				printf("Thread 3: Giai nhi\n");
				printf("Thread 1: Giai ba\n");
			}
		}
		else{
			printf("Thread 3: Giai nhat\n");
			printf("Thread 2: Giai nhi\n");
			printf("Thread 1: Giai ba\n");
		}
		
	}
    system("pause");

    return 0;
}
