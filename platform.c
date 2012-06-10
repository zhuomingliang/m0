#define M0_SOURCE
#include "m0.h"

#include <stdio.h>
#include <stdlib.h>

#define close_file(FP) do { \
	FILE *fp_ = FP; if(!fp_) break; \
	int status_ = fclose(fp_); assert(status_ == 0); \
} while(0)

void *m0_platform_mmap_file_private(const char *name)
{
	FILE *file = NULL;
	void *buffer = NULL;

	file = fopen(name, "rb");
	if(!file || fseek(file, 0, SEEK_END))
		goto FAIL;

	long pos = ftell(file);
	if(pos < 0)
		goto FAIL;

	size_t size = (size_t)pos;
	buffer = malloc(size);
	if(!buffer)
		goto FAIL;

	if(!fread(buffer, size, 1, file))
		goto FAIL;

	close_file(file);
	return buffer;

FAIL:
	close_file(file);
	free(buffer);
	return NULL;
}

bool m0_platform_munmap(void *block, size_t size)
{
	(void)size;
	free(block);
	return 1;
}
