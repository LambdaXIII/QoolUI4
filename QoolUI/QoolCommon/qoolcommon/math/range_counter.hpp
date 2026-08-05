#ifndef MATH_RANGE_COUNTER_HPP
#define MATH_RANGE_COUNTER_HPP

#include "qoolns.hpp"

#include <utility>

QOOL_NS_BEGIN

namespace math {

/**
 * 整数步进计数器（UI 等宽覆盖场景：以 step 为最小刻度的离散计数）。
 *
 * 语义约定：
 * - first()/last() 为区间端点（含端点），count() = (last-first)/step 为
 *   整数步数（C++ 整数除法，向下取整）；区间跨度为 step 的非整数倍时，
 *   步数 ≠ 覆盖元素数（如 [0,10) step=3 → count=3，元素 0/3/6/9 共 4 个）。
 * - contained_last() = last - step：最后一个完整步的起点（"步内包含的
 *   末元素"），用于等宽分格时计算末格位置。
 * - fromSteps(start, steps)：以 start 为起点、步数推导终点（end = start
 *   + steps*step，含端点的区间为 [start, end]）。
 * - 构造时端点乱序自动交换（first ≤ last）。
 *
 * 刻意设计：count 的整数截断与 contained_last 的 last-step 语义是
 * "等宽步进覆盖"的原始意图（UI 分格），非缺陷，勿按"元素数"修改。
 */
template <typename N, N step_length = 1>
class RangeCounter {
  N m_first;
  N m_last;
  const N m_step = step_length;

public:
  RangeCounter(N first, N last) {
    m_first = std::min(first, last);
    m_last = std::max(first, last);
  }

  static RangeCounter<N, step_length> fromSteps(N start, int steps) {
    N end = start + steps * step_length;
    return { start, end };
  }

  N first() const { return m_first; }
  N last() const { return m_last; }
  N contained_last() const { return m_last - m_step; }
  N step() const { return m_step; }
  int count() const { return (m_last - m_first) / m_step; }
};

} // namespace math

QOOL_NS_END

#endif // MATH_RANGE_COUNTER_HPP
