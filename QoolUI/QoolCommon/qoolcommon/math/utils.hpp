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

template <typename N>
inline N remap(
  N value, N sourceMin, N sourceMax, N targetMin, N targetMax) {
  const N s_left = std::min(sourceMin, sourceMax);
  const N s_right = std::max(sourceMin, sourceMax);
  const N t_left = std::min(targetMin, targetMax);
  const N t_right = std::max(targetMin, targetMax);

  if (s_left == t_left && s_right == t_right)
    return value;

  const N s_total = s_right - s_left;
  const N t_total = t_right - t_left;
  value = auto_bound(s_left, value, s_right);
  const N s_vdistance = value - s_left;

  N t_vdistance;
  if (s_total == t_total)
    t_vdistance = s_vdistance;
  else if (s_vdistance == 0)
    t_vdistance = 0;
  else if (s_vdistance == s_total)
    t_vdistance = t_total;
  else {
    const N ratio = t_total / s_total;
    t_vdistance = s_vdistance * ratio;
  }
  return t_left + t_vdistance;
}

} // namespace math

QOOL_NS_END
#endif // MATH_UTILS_HPP
