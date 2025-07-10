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

  const unsigned random_seed = seed.value_or(
    std::chrono::system_clock::now().time_since_epoch().count());
  std::mt19937 generator(seed);
  std::uniform_int_distribution<> distribution(0, sizeof(charset) - 2);

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
