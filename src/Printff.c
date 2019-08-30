
#include <stdio.h>
#include "Printff.h"

void _printff(char* str)
{
    // Prints the string pointed to by str
    // Explicitly flushes stdout b/c otherwise the board seems to buffer
    printf(str);
    fflush(stdout);
    return;
}