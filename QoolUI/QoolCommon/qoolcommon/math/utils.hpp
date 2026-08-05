#ifndef MATH_UTILS_HPP
#define MATH_UTILS_HPP

#include "numbers.hpp"
#include "qoolns.hpp"

#include <algorithm>
#include <cmath>
#include <numeric>

QOOL_NS_BEGIN

namespace math {

template <typename N>
inline bool is_equal(N a, N b, float epsilon = M_FUZZY_EPSILON) {
  const auto aa = std::abs(a);
  const auto ab = std::abs(b);
  if (aa < epsilon && ab < epsilon)
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

/**
 * @brief 将输入值从输入范围线性映射到目标范围。
 *    * 支持任意数值类型的输入和输出范围。该函数使用浮点中间计算以确保精度，
 * 最终结果转换为目标类型。适用于整型、浮点型等多种类型组合。
 *    * @tparam T 输入值和输入范围的类型
 * @tparam U 输出范围的类型
 * @param input 输入值
 * @param in_min 输入范围的最小值
 * @param in_max 输入范围的最大值
 * @param out_min 目标范围的最小值
 * @param out_max 目标范围的最大值
 * @return 映射后的结果，类型为 U
 */
template<typename T, typename U>
U remap(T input, T in_min, T in_max, U out_min, U out_max) {
  if (in_min == in_max) {
    return out_min; // 避免除以零，返回目标范围最小值
  }

  // 转换为 double 进行浮点运算，避免整数除法误差
  double input_diff = static_cast<double>(input) - static_cast<double>(in_min);
  double in_range = static_cast<double>(in_max) - static_cast<double>(in_min);
  double out_range =
      static_cast<double>(out_max) - static_cast<double>(out_min);
  double scaled = (input_diff / in_range) * out_range;

  return static_cast<U>(scaled + static_cast<double>(out_min));
}

/**
 * 将 \c value 循环折返约束到 [min, max] 区间（模数回绕，非钳制）。
 *
 * 与 auto_bound（超界钳制在边界）不同，本函数把区间视为环：
 * value 超出区间时按模数折回——从 max 一侧继续向外走会绕回 min。
 * 典型用途：角度归一化（任意角度折返到 [-180°, 180°]）、循环索引
 * （末位 +1 绕回开头，如 12 点制时钟 12 时 +1 → 1 时）。
 *
 * 端点乱序（min > max）时自动取小大为界，语义与 auto_bound 一致，
 * 区间定义为 [min(min,max), max(min,max)]。
 *
 * 算法：① 端点排序得 left/right；② value 落在 [left, right] 内原样
 * 返回（含两端点）；③ 区间外对 range = right - left 取模折返，
 * fmod 负余数加 range 修正，保证结果落在 [left, right)。
 *
 * 示例（min=0, max=10）：5 → 5；12 → 2；-3 → 7；10 → 10。
 *
 * \note N 应为有符号整型或浮点类型：无符号类型下区间外取值与
 * 负余数修正路径依赖 fmod 的负返回值，为未定义行为。
 */
template <typename N>
inline N cycle_in_range(N min, N value, N max) {
  const N left = std::min(min, max);
  const N right = std::max(min, max);
  if (left == right)
    return left;
  if (left <= value && value <= right) // 端点已排序，区间内判定须用 right
    return value;

  const N range = right - left;
  const N distance = value - left;
  N mod = std::fmod(distance, range);
  if (mod < 0)
    mod += range;
  return left + mod;
}

template<typename N> inline N average(std::initializer_list<N> numbers) {
  return std::accumulate(numbers.begin(), numbers.end(), 0) / numbers.size();
}

} // namespace math

QOOL_NS_END
#endif // MATH_UTILS_HPP
