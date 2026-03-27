#include "stdio.h"
#include <stdarg.h>
// gcc -no-pie stdprintf.c myprintf.o -o new
union prm {
    int i;
    char* str;
};

extern int fakeprintf(char*, union prm*, ...);

int main()
{
    fakeprintf("%d %x %b", 'g', 'y', 'y');
    // char a[10] = {};
    // scanf("%s", &a);
    printf("%d %x %b", 'g', 'y', 'y');
}