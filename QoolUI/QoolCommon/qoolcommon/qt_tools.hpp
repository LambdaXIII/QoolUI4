#ifndef QT_UTILS_HPP
#define QT_UTILS_HPP

#include "qoolns.hpp"

QOOL_NS_BEGIN

namespace tools {

template <typename T>
inline T* find_parent(QObject* x) {
  while (x != nullptr) {
    T* res = qobject_cast<T*>(x);
    if (res != nullptr)
      return res;
    x = x->parent();
  }
  return nullptr;
}

} // namespace tools

QOOL_NS_END

#endif // QT_UTILS_HPP
