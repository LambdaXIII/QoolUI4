#include "qool_shapecontrol.h"
#include "qoolcommon/debug.hpp"
QOOL_NS_BEGIN

ShapeControl::ShapeControl(QObject* parent)
  : SmartObject(parent) {
  auto parentItem = qobject_cast<QQuickItem*>(parent);
  if (parentItem) set_target(parentItem);
  setup_properties();
}

void ShapeControl::dumpInfo() const {
  xDebugQ << "target: " << target();
  xDebugQ << "boundingRect: " << boundingRect();
}

bool ShapeControl::contains(const QPointF& point) const {
  if (m_target) return m_target->boundingRect().contains(point);
  return boundingRect().contains(point);
  // if (point.x() < x()) return false;
  // if (point.y() < y()) return false;
  // if (point.x() > x() + width()) return false;
  // if (point.y() > y() + height()) return false;
  // return true;
}

QBindable<QQuickItem*> ShapeControl::bindable_target() {
  return QBindable<QQuickItem*>(this, "target");
}

void ShapeControl::setup_properties() {
  QBINDABLE_SET_BINDING(longEdge, [&] { return std::max(width(), height()); });
  QBINDABLE_SET_BINDING(shortEdge, [&] { return std::min(width(), height()); });
  QBINDABLE_SET_BINDING(aspectRatio, [&] {
    const qreal h = height();
    return h == 0 ? -1 : width() / height();
  });
  QBINDABLE_SET_BINDING(halfWidth, [&] { return width() / 2; });
  QBINDABLE_SET_BINDING(halfHeight, [&] { return height() / 2; });
  QBINDABLE_SET_BINDING(
      boundingRect, [&] { return QRectF(x(), y(), width(), height()); });
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
