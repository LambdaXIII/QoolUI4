#include "qool_crystal4containmentmask.h"

#include <cmath>

QOOL_NS_BEGIN

// 命中判定（曼哈顿距离 / L1 范数，O(1)）与变换顺序自 v3 逐字复用：
// |x - cx| + |y - cy| * (h / w) <= w / 2；y 预缩放与平移顺序不可调整
// （调序会改变命中域）。width/height 取 QQuickItem 自身几何（菱形外接框）。
// 完整说明见 docs/reference/Qool.Color/Crystal4ContainmentMask.md。
Crystal4ContainmentMask::Crystal4ContainmentMask(QQuickItem* parent)
  : QQuickItem(parent) {
}

QPointF Crystal4ContainmentMask::centerPoint() const {
  return m_centerPoint;
}

void Crystal4ContainmentMask::set_centerPoint(const QPointF& new_centerPoint) {
  if (m_centerPoint == new_centerPoint)
    return;
  m_centerPoint = new_centerPoint;
  emit centerPointChanged();
}

QPointF Crystal4ContainmentMask::__transform(QPointF p) const {
  static const QPointF ZERO_POINT { 0, 0 };
  if (width() != height()) {
    const qreal ratio = height() / width();
    p.ry() *= ratio;
  }
  if (centerPoint() != ZERO_POINT) {
    p -= centerPoint();
  }
  return p;
}

bool Crystal4ContainmentMask::contains(const QPointF& point) const {
  const QPointF vPoint = __transform(point);
  return std::abs(vPoint.x()) + std::abs(vPoint.y()) <= width() / 2;
}

QOOL_NS_END
