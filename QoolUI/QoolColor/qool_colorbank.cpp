#include "qool_colorbank.h"

#include <algorithm>

QOOL_NS_BEGIN

// 稀疏语义与持久化三接法见 docs/reference/Qool.Color/ColorBank.md。
ColorBank::ColorBank(QObject* parent)
  : QObject { parent } {
}

// color：未设置过的索引返回默认白（Qt::white）——"未设置"与"显式设置为白"
// 无法从返回值区分，需区分时用 filledIndexes()。
QColor ColorBank::color(int n) const {
  return m_colors.value(n, Qt::white);
}

// setColor：带相等守卫——与当前值相等时不写入、不发 colorChanged。
// n 可为任意非负整数（无上界）；写入不创建中间索引（稀疏）。
void ColorBank::setColor(int n, const QColor& color) {
  const auto old = m_colors.value(n, Qt::white);
  if (old == color)
    return;
  m_colors.insert(n, color);
  emit colorChanged(n);
}

// filledIndexes：已设置索引升序、无重复；宿主持久化读面（配合 color() 批量导出）。
QList<int> ColorBank::filledIndexes() const {
  QList<int> result;
  result.reserve(m_colors.size());
  for (auto it = m_colors.cbegin(); it != m_colors.cend(); ++it)
    result.append(it.key());
  std::sort(result.begin(), result.end());
  return result;
}

QOOL_NS_END
