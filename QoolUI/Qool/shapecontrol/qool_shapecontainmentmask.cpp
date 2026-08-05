#include "qool_shapecontainmentmask.h"

QOOL_NS_BEGIN

/*!
    \qmltype ShapeContainmentMask
    \inqmlmodule Qool
    \nativetype qoolui::ShapeContainmentMask
    \brief 将形状命中判定委托给 ShapeControl 的 containmentMask 包装器。

    QQuickItem 的 containmentMask 要求 QQuickItem 派生类型，而
    \l ShapeControl 是 QObject 派生——本类型作为桥接：重写
    QQuickItem::contains()，将局部坐标点直接委托给
    \\l {control}{control} 的数值判定（O(1) 线性不等式），
    避免 Shape 的路径填充判定开销。

    \\qmlproperty ShapeControl control
    命中判定委托对象（八边形形态传 QoolBoxShapeControl）。
    未设置时退化为 QQuickItem 默认判定（矩形）。

    供 \l QoolBox / \l OctagonShape 的 containmentMask 使用；
    宿主一般不需要直接实例化。
*/
ShapeContainmentMask::ShapeContainmentMask(QQuickItem* parent)
  : QQuickItem(parent) {
}

ShapeControl* ShapeContainmentMask::control() const {
  return m_control;
}

void ShapeContainmentMask::set_control(ShapeControl* new_control) {
  if (m_control == new_control)
    return;
  m_control = new_control;
  emit controlChanged();
}

bool ShapeContainmentMask::contains(const QPointF& point) const {
  if (m_control)
    return m_control->contains(point);
  return QQuickItem::contains(point);
}

QOOL_NS_END
