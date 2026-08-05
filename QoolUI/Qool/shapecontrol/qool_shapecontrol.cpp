#include "qool_shapecontrol.h"
#include "qool_shapecontrol_gadget.h"
#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

/*!
    \qmltype ShapeControl
    \inqmlmodule Qool
    \nativetype qoolui::ShapeControl
    \brief 形状控制点计算器基类：以 target 的几何为输入派生形状数据。

    绑定 target（QQuickItem）的 x/y/width/height，派生长边、短边、
    宽高比、中心、半宽半高与外接矩形等基础几何量。具体形状
    （如 QoolBoxShapeControl 的八边形）在子类中由设置计算控制点。

    \l {contains()}{contains()} 是命中判定的扩展点：基类按外接矩形
    判定，子类覆写为形状精确判定（数值算法，不依赖路径填充）。
    C++ 侧扩展通过子类化本类（或 ShapeControlGadget）实现。
*/
ShapeControl::ShapeControl(QObject* parent)
  : SmartObject(parent) {
  setup_properties();
}

void ShapeControl::dumpInfo() const {
  xDebugQ << "target: " << target();
  xDebugQ << "boundingRect: " << boundingRect();
}

/*!
    \qmlmethod bool ShapeControl::contains(point)
    判断 \c point（局部坐标）是否落在形状内。

    基类实现按外接矩形判定；形状子类覆写为精确判定
    （如 QoolBoxShapeControl 的八边形线性不等式）。
*/
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
