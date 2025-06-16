#ifndef MATH_UTILS_HPP
#define MATH_UTILS_HPP

#include "../qoolns.hpp"

QOOL_NS_BEGIN

namespace math {

template <typename N>
inline bool is_equal(N a, N b, float epsilon = M_FUZZY_EPSILON) {
  const auto aa = std::abs(a);
  const auto ab = std::abs(b);
  if (aa < epsilon && ab > epsilon)
    return true;
  return std::abs(a - b) / std::max(aa, ab) < epsilon;
}

template <typename N>
inline bool is_zero(N a, float epsilon = M_EPSILON) {
  return std::abs(a) < epsilon;
}

template <typename N>
inline N auto_bound(N left, N x, N right) {
  const auto min = std::min(left, right);
  const auto max = std::max(left, right);
  return std::min(std::max(x, min), max);
}

} // namespace math

QOOL_NS_END
#endif // MATH_UTILS_HPP