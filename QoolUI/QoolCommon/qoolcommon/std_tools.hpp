#ifndef STD_TOOLS_HPP
#define STD_TOOLS_HPP

#include "qoolns.hpp"

#include <chrono>
#include <optional>
#include <random>
#include <string>

QOOL_NS_BEGIN

namespace tools {

inline std::string generate_random_string(size_t length = 5,
  std::optional<unsigned> seed = {},
  std::optional<std::string> chars = {}) {
  static const std::string default_charset { "0123456789"
                                             "ABCDEFGHJKMNPQRSTWXYZ"
                                             "abcdefghjkmnpqrstwxyz" };

  const std::string charset = chars.value_or(default_charset);
  // 空字符集无法取样：直接返回空串，避免分布上下界倒置（UB）
  if (charset.empty())
    return {};

  const unsigned random_seed = seed.value_or(
    std::chrono::system_clock::now().time_since_epoch().count());
  std::mt19937 generator(random_seed);
  // 取样上限必须是字符数（charset.size()-1），不能用 sizeof(charset)：
  // sizeof(std::string) 是对象大小而非字符串长度，会越界读对象内存
  std::uniform_int_distribution<> distribution(
    0, static_cast<int>(charset.size()) - 1);

  std::string result;
  result.reserve(length);

  for (int i = 0; i < length; ++i) {
    const auto c = charset[distribution(generator)];
    result.append({ c });
  }

  return result;
}

} // namespace tools

QOOL_NS_END

#endif // STD_TOOLS_HPP
