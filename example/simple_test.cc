#include <cassert>
#include <iostream>
#include <string>

void test_assert() {
  constexpr int compile_time_value = 42;
  static_assert(compile_time_value == 42, "Compile-time assertion failed");
}

int main() {
  test_assert();

  std::string message =
      "Hello from the hermetic clang toolchain!\n"
      "This toolchain is self-contained and does not rely on external "
      "system libraries.\n"
      "You can inspect the compiler used to build this binary by using:\n"
      "\treadelf -p .comment bazel-bin/example/simple_test\n"
      "\tfile bazel-bin/example/simple_test\n";
  std::cout << message << std::endl;
  return 0;
}
