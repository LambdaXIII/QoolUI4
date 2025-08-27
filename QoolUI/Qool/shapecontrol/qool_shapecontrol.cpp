#include "qool_shapecontrol.h"
#include "qool_shapecontrol_gadget.h"
#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

ShapeControl::ShapeControl(QObject* parent)
  : SmartObject(parent) {
  setup_properties();
}

void ShapeControl::dumpInfo() const {
  xDebugQ << "target: " << target();
  xDebugQ << "boundingRect: " << boundingRect();
}

bool ShapeControl::contains(const QPointF& point) const {
  if (m_target) return m_target->boundingRect().contains(point);
  return boundingRect().contains(point);
}

void ShapeControl::appendChild(QObject* child) {
  SmartObject::appendChild(child);
  if (auto p_child = qobject_cast<ShapeControlGadget*>(child); p_child) {
    if (p_child->control() == nullptr) p_child->set_control(this);
  } else {
    xInfoQ << xDBGRed << child << xDBGReset "is not a ShapeControlGadget";
  }
}

void ShapeControl::componentComplete() {
  SmartObject::componentComplete();
  set_target(qobject_cast<QQuickItem*>(parent()));
}

void ShapeControl::setup_properties() {
  // QBINDABLE_SET_BINDING(target, [&] {
  //   const auto p = bindableParent().value();
  //   return qobject_cast<QQuickItem*>(p);
  // });

  QBINDABLE_SET_BINDING(x, [&] {
    if (auto t = m_target.value(); t) return t->bindableX().value();
    return 0.0;
  });
  QBINDABLE_SET_BINDING(y, [&] {
    if (auto t = m_target.value(); t) return t->bindableY().value();
    return 0.0;
  });
  QBINDABLE_SET_BINDING(width, [&] {
    if (auto t = m_target.value(); t) return t->bindableWidth().value();
    return 0.0;
  });
  QBINDABLE_SET_BINDING(height, [&] {
    if (auto t = m_target.value(); t) return t->bindableHeight().value();
    return 0.0;
  });

  QBINDABLE_SET_BINDING(longEdge, [&] { return std::max(width(), height()); });
  QBINDABLE_SET_BINDING(shortEdge, [&] { return std::min(width(), height()); });
  QBINDABLE_SET_BINDING(aspectRatio, [&] {
    const qreal h = height();
    return h == 0 ? -1 : width() / height();
  });
  QBINDABLE_SET_BINDING(center,
      [&] { return QPointF(m_halfWidth.value(), m_halfHeight.value()); });
  QBINDABLE_SET_BINDING(halfWidth, [&] { return width() / 2; });
  QBINDABLE_SET_BINDING(halfHeight, [&] { return height() / 2; });
  QBINDABLE_SET_BINDING(
      boundingRect, [&] { return QRectF(x(), y(), width(), height()); });
}

QOOL_NS_END
