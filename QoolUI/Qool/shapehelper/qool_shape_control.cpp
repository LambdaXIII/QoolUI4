#include "qool_shape_control.h"

QOOL_NS_BEGIN

ShapeControl::ShapeControl(QObject* parent)
  : SmartObject(parent) {
  auto parentItem = qobject_cast<QQuickItem*>(parent);
  if (parentItem) set_target(parentItem);
}

bool ShapeControl::contains(const QPointF& point) const {
  if (target()) return target()->contains(point);
  return boundingRect().contains(point);
}

QQuickItem* ShapeControl::target() const { return m_target; }

void ShapeControl::set_target(QQuickItem* newTarget) {
  if (m_target == newTarget) return;
  if (m_target) {
#define __HANDLE__(N) m_##N.takeBinding();
    QOOL_FOREACH_9(__HANDLE__, x, y, width, height, aspectRatio, longEdge,
        shortEdge, halfWidth, halfHeight)
#undef __HANDLE__
  }
  m_target = newTarget;

  if (m_target) {
#define BIND(N, P) m_##N.setBinding([&] { return m_target->P().value(); });
    BIND(x, bindableX)
    BIND(y, bindableY)
    BIND(width, bindableWidth)
    BIND(height, bindableHeight)
#undef BIND
  }
  emit targetChanged();
}

QOOL_NS_END
