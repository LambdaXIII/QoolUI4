#ifndef QT_UTILS_HPP
#define QT_UTILS_HPP

#include "qoolns.hpp"

#include <QList>
#include <QObject>
#include <functional>

QOOL_NS_BEGIN

namespace tools {

template <typename T>
inline T* find_parent(QObject* x) {
  // 刻意包含自身：从 x 本身开始向上搜索（ItemTracker 等场景需要
  // "target 就是所需类型"的命中）。若要跳过自身，先 x = x->parent()。
  while (x != nullptr) {
    T* res = qobject_cast<T*>(x);
    if (res != nullptr)
      return res;
    x = x->parent();
  }
  return nullptr;
}

template <typename T, typename List = QList<T>>
inline QList<qsizetype> find_all_indexes(
  const T& element, const List& list) {
  if (list.isEmpty())
    return {};
  QList<qsizetype> indexes;
  qsizetype last_pos = 0;
  while (last_pos >= 0) {
    last_pos = list.indexOf(element, last_pos);
    if (last_pos >= 0) {
      indexes << last_pos;
      // indexOf 的 from 参数包含自身：不 +1 会在同一位置反复命中（死循环）
      ++last_pos;
    }
  }
  return indexes;
}

template <typename T, typename List = QList<T>,
  typename Pred = std::function<bool(const T&)>>
inline QList<qsizetype> find_all_indexes_if(
  Pred pred, const List& list) {
  QList<qsizetype> indexes;
  for (qsizetype i = 0; i < list.length(); i++) {
    if (pred(list.at(i)))
      indexes << i;
  }
  return indexes;
}

} // namespace tools

QOOL_NS_END

#endif // QT_UTILS_HPP
