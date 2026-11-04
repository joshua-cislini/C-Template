#include "greeting.h"

#include <stdio.h>

int greeting_format(char *buffer, size_t size, const char *name) {
	if(buffer == NULL) {
		return -1;
	}
	if(name == NULL || name[0] == '\0') {
		name = "World";
	}
	return snprintf(buffer, size, "Hello, %s!", name);
}
