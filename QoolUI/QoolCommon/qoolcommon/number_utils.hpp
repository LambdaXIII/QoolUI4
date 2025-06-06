#ifndef NUMBER_UTILS_HPP
#define NUMBER_UTILS_HPP

#include "qool_common.h"

namespace QOOL_NS::NumberUtils {

template <typename N>
inline N positive_gate(N number) {
  return number > 0 ? number : 0;
}

}; // namespace QOOL_NS::NumberUtils

#endif // NUMBER_UTILS_HPP
