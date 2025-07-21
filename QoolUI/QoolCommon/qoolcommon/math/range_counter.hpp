#ifndef MATH_RANGE_COUNTER_HPP
#define MATH_RANGE_COUNTER_HPP

#include "qoolns.hpp"

#include <utility>

QOOL_NS_BEGIN

namespace math {

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
