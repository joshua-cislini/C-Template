/**
 * @file greeting.h
 * @brief Example module - replace it with your own code.
 *
 * Shows the intended layout: public declarations in include/, the
 * implementation in src/, and unit tests in tests/.
 */
#ifndef GREETING_H
#define GREETING_H

#include <stddef.h>

/**
 * @brief Writes "Hello, <name>!" into @p buffer.
 *
 * @param buffer Destination buffer (always null-terminated when @p size > 0).
 * @param size   Size of @p buffer in bytes.
 * @param name   Name to greet; NULL or "" greets "World".
 * @return The length of the full greeting (like snprintf: if it is >= @p size
 *         the output was truncated), or -1 if @p buffer is NULL.
 */
int greeting_format(char *buffer, size_t size, const char *name);

#endif /* GREETING_H */
