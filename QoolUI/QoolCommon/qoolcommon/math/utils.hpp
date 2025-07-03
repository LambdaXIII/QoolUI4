#ifndef MATH_UTILS_HPP
#define MATH_UTILS_HPP

#include "numbers.hpp"
#include "qoolns.hpp"

#include <algorithm>
#include <cmath>

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

template <typename N, typename P>
inline N set_precision(N number, P precision) {
  const double p = static_cast<double>(std::abs(precision));
  if (is_zero(p))
    return std::round(number);

  const long double factor = std::pow(10.0, p);
  const auto rounded =
    std::round(static_cast<long double>(number) * factor) / factor;
  return static_cast<N>(rounded);
}

} // namespace math

QOOL_NS_END
#endif // MATH_UTILS_HPP
