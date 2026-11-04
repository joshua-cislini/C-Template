#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "greeting.h"

/* Injected by the Makefile from config.mk; fallbacks keep other tools happy. */
#ifndef PROJECT_NAME
#define PROJECT_NAME "program"
#endif
#ifndef PROJECT_VERSION
#define PROJECT_VERSION "0.0.0"
#endif

int main(int argc, char *argv[]) {
	if(argc > 1 && strcmp(argv[1], "--version") == 0) {
		printf("%s %s\n", PROJECT_NAME, PROJECT_VERSION);
		return EXIT_SUCCESS;
	}

	char message[128];
	const char *name = (argc > 1) ? argv[1] : NULL;

	if(greeting_format(message, sizeof message, name) < 0) {
		fprintf(stderr, "error: could not format the greeting\n");
		return EXIT_FAILURE;
	}

	puts(message);
	return EXIT_SUCCESS;
}
