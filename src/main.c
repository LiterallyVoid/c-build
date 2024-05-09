#include <stdio.h>

int main(void) {
	int uninitialized;

	// If `compile-commands.json` is being generated and is found by `clangd`, this
	// should be a warning.
	if (uninitialized) {}

	printf("Hello, world!\n");

	// This should crash if the undefined behavior sanitizer is working.
	char arr[40];
	printf("%c", arr[40]);
}
