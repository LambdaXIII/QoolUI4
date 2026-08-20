#ifndef MATH_UTILS_HPP
#define MATH_UTILS_HPP

#include "numbers.hpp"
#include "qoolns.hpp"

#include <algorithm>
#include <cmath>
#include <concepts>
#include <numeric>

QOOL_NS_BEGIN

namespace math {

template<typename T>
concept Arithmetic = std::integral<T> || std::floating_point<T>;

template<Arithmetic N>
constexpr bool is_equal(N a, N b, float epsilon = M_FUZZY_EPSILON) {
  const auto aa = std::abs(a);
  const auto ab = std::abs(b);
  if (aa < epsilon && ab < epsilon) return true;
  return std::abs(a - b) / std::max(aa, ab) < epsilon;
}

template<Arithmetic N>
constexpr bool is_zero(N a, float epsilon = M_EPSILON) {
  return std::abs(a) < epsilon;
}

template<Arithmetic N>
constexpr N auto_bound(N left, N x, N right) {
  const auto min = std::min(left, right);
  const auto max = std::max(left, right);
  return std::min(std::max(x, min), max);
}

template<Arithmetic N, Arithmetic P>
constexpr N set_precision(N number, P precision) {
  const double p = static_cast<double>(std::abs(precision));
  if (is_zero(p)) return std::round(number);

  const long double factor = std::pow(10.0, p);
  const auto rounded =
      std::round(static_cast<long double>(number) * factor) / factor;
  return static_cast<N>(rounded);
}

/**
 * 将输入值从输入范围线性映射到目标范围。支持任意数值类型的输入与输出
 * 范围；使用浮点中间计算以确保精度，最终结果转换为目标类型（整型/浮点
 * 型等）。输入范围端点相等时返回目标范围最小值（避免除以零）。
 */
template<Arithmetic T, Arithmetic U>
constexpr U remap(T input, T in_min, T in_max, U out_min, U out_max) noexcept {
  if (in_min == in_max) { return out_min; }

  // 统一用 double 做中间计算
  const double ratio =
      (static_cast<double>(input) - static_cast<double>(in_min))
      / (static_cast<double>(in_max) - static_cast<double>(in_min));
  const double result =
      static_cast<double>(out_min)
      + ratio * (static_cast<double>(out_max) - static_cast<double>(out_min));

  return static_cast<U>(result);
}

/// @brief  将数值循环映射到 [min, max) 左闭右开区间
/// @tparam N 算术类型（整型 / 浮点型）
/// @param min 区间下界
/// @param value 待映射值
/// @param max 区间上界
/// @return 循环映射后落在 [min, max) 内的结果
template<Arithmetic N>
constexpr N cycle_in_range(N min, N value, N max) noexcept {
  const N left = std::min(min, max);
  const N right = std::max(min, max);

  // 区间退化为单点
  if (left == right) { return left; }

  // 快速路径：值已在目标区间内
  if (left <= value && value < right) { return value; }

  if constexpr (std::integral<N>) {
    using unsigned_N = std::make_unsigned_t<N>;
    // 无符号计算区间长度，彻底规避有符号整型溢出
    const unsigned_N range =
        static_cast<unsigned_N>(right) - static_cast<unsigned_N>(left);

    if constexpr (std::signed_integral<N>) {
      const N distance = value - left;
      N mod = distance % static_cast<N>(range);
      if (mod < 0) { mod += static_cast<N>(range); }
      return left + mod;
    } else {
      // 无符号整型：利用无符号算术的模特性处理下溢
      const unsigned_N distance =
          static_cast<unsigned_N>(value) - static_cast<unsigned_N>(left);
      return left + static_cast<N>(distance % range);
    }
  } else {
    const N range = right - left;
    const N distance = value - left;
    N mod = std::fmod(distance, range);
    if (mod < 0) { mod += range; }
    return left + mod;
  }
}

template<Arithmetic N>
  requires std::integral<N> || std::floating_point<N>
constexpr N average(std::initializer_list<N> numbers) {
  // 空列表显式返回 N(0)：0/0 在整型下为未定义行为、浮点下为 NaN，
  // "空集均值 = 0"是调用方依赖的自洽约定。
  if (numbers.size() == 0) return N(0);
  // 累加器初始值必须是 N：字面量 0 是 int，浮点列表会因整数除法截断结果。
  return std::accumulate(numbers.begin(), numbers.end(), N(0)) / numbers.size();
}

} // namespace math

QOOL_NS_END
#endif // MATH_UTILS_HPP
