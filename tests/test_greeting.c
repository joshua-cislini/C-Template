#include <string.h>

#include "greeting.h"
#include "test_framework.h"

static void test_greets_given_name(void) {
	char buffer[64];
	int length = greeting_format(buffer, sizeof buffer, "Ada");

	CHECK_EQ_STR("Hello, Ada!", buffer);
	CHECK_EQ_INT(strlen("Hello, Ada!"), length);
}

static void test_defaults_to_world(void) {
	char buffer[64];

	greeting_format(buffer, sizeof buffer, NULL);
	CHECK_EQ_STR("Hello, World!", buffer);

	greeting_format(buffer, sizeof buffer, "");
	CHECK_EQ_STR("Hello, World!", buffer);
}

static void test_truncates_safely(void) {
	char buffer[6];
	int length = greeting_format(buffer, sizeof buffer, "Ada");

	CHECK_EQ_STR("Hello", buffer);
	CHECK(length >= (int)sizeof buffer);
}

static void test_rejects_null_buffer(void) {
	CHECK_EQ_INT(-1, greeting_format(NULL, 0, "Ada"));
}

int main(void) {
	RUN_TEST(test_greets_given_name);
	RUN_TEST(test_defaults_to_world);
	RUN_TEST(test_truncates_safely);
	RUN_TEST(test_rejects_null_buffer);
	return TEST_REPORT();
}
