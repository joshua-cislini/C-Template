/**
 * @file test_framework.h
 * @brief Minimal, dependency-free unit test helpers.
 *
 * Each tests/test_<name>.c file is built into its own executable by
 * `make test`; a non-zero exit code marks it as failed.
 *
 * @code
 * #include "test_framework.h"
 *
 * static void test_addition(void) {
 *     CHECK(1 + 1 == 2);
 *     CHECK_EQ_INT(4, 2 * 2);
 *     CHECK_EQ_STR("abc", "abc");
 * }
 *
 * int main(void) {
 *     RUN_TEST(test_addition);
 *     return TEST_REPORT();
 * }
 * @endcode
 *
 * Swap it for Unity, cmocka, greatest, ... if you need more.
 */
#ifndef TEST_FRAMEWORK_H
#define TEST_FRAMEWORK_H

#include <stdio.h>

static int tf_checks_run;
static int tf_checks_failed;
static int tf_tests_run;
static int tf_tests_failed;

#define TF_FAIL_(...)                            \
	do {                                         \
		++tf_checks_failed;                      \
		printf("  %s:%d: ", __FILE__, __LINE__); \
		printf(__VA_ARGS__);                     \
		putchar('\n');                           \
	} while(0)

/** Fails the current test if @p cond is false (the test keeps running). */
#define CHECK(cond)                              \
	do {                                         \
		++tf_checks_run;                         \
		if(!(cond)) {                            \
			TF_FAIL_("CHECK(%s) failed", #cond); \
		}                                        \
	} while(0)

/** Compares two integers. */
#define CHECK_EQ_INT(expected, actual)                                      \
	do {                                                                    \
		long long tf_e_ = (long long)(expected);                            \
		long long tf_a_ = (long long)(actual);                              \
		++tf_checks_run;                                                    \
		if(tf_e_ != tf_a_) {                                                \
			TF_FAIL_("%s == %s failed: expected %lld, got %lld", #expected, \
					 #actual, tf_e_, tf_a_);                                \
		}                                                                   \
	} while(0)

/** Compares two C strings (NULL-safe). */
#define CHECK_EQ_STR(expected, actual)                                          \
	do {                                                                        \
		const char *tf_e_ = (expected);                                         \
		const char *tf_a_ = (actual);                                           \
		++tf_checks_run;                                                        \
		if(tf_e_ != tf_a_ && (!tf_e_ || !tf_a_ || strcmp(tf_e_, tf_a_) != 0)) { \
			TF_FAIL_("%s == %s failed: expected \"%s\", got \"%s\"", #expected, \
					 #actual, tf_e_ ? tf_e_ : "(null)",                         \
					 tf_a_ ? tf_a_ : "(null)");                                 \
		}                                                                       \
	} while(0)

/** Runs a `void fn(void)` test function and reports PASS/FAIL. */
#define RUN_TEST(fn)                         \
	do {                                     \
		int tf_before_ = tf_checks_failed;   \
		++tf_tests_run;                      \
		fn();                                \
		if(tf_checks_failed == tf_before_) { \
			printf("  PASS  %s\n", #fn);     \
		} else {                             \
			++tf_tests_failed;               \
			printf("  FAIL  %s\n", #fn);     \
		}                                    \
	} while(0)

/** Prints a summary; use as `return TEST_REPORT();` at the end of main(). */
#define TEST_REPORT()                                                    \
	(printf("  %d/%d tests passed (%d checks, %d failed)\n",             \
			tf_tests_run - tf_tests_failed, tf_tests_run, tf_checks_run, \
			tf_checks_failed),                                           \
	 fflush(stdout), tf_tests_failed == 0 ? 0 : 1)

#endif /* TEST_FRAMEWORK_H */
