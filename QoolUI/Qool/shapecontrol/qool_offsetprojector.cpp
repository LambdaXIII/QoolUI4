#include "qool_offsetprojector.h"

QOOL_NS_BEGIN

/*!
    \qmltype OffsetProjector
    \inqmlmodule Qool
    \nativetype qoolui::OffsetProjector
    \brief 位移映射节点：位移方向与距离度量方向的几何折算。

    输入位移方向（\c direction）、距离的度量方向（\c refDirection）与
    沿度量方向的移动距离（\c refDistance），输出实际位移向量
    \c offset——满足 \c{offset ∥ direction_unit} 且
    \c{offset·refDirection_unit == refDistance}：

    \code
    offset = direction_unit * refDistance / (direction_unit · refDirection_unit)
    \endcode

    典型场景是凸多边形内描边：内点 = 外点 + offset（描边宽度沿边法线
    度量，\c refDistance 直接绑定描边宽度——零系数接入）；减法即反向
    运动（扩张）。\c direction/\c refDirection 方向对数据由形状特征
    提供，节点本身形状无关。

    \section2 默认值自洽

    独立使用（不设任何属性）时 \c refDistance = 0，\c offset 恒为零向量。

    \section2 退化契约

    \list
    \li 任一输入向量为零向量 → offset 零向量；
    \li \c refDistance == 0 → offset 零向量；
    \li 两方向正交（点积 ≈ 0）→ offset 零向量（含浮点噪声容差）。
    \endlist

    \section2 通知语义

    输入变化但实际结果不变时不发出 \c offsetChanged（输出值相等守卫）——
    如 \c refDistance == 0 时改变方向不会传播下游；恢复非零后链条自动
    恢复。

    \section2 符号规则（调试指引）

    \c direction 与 \c refDirection 的点积必须 \e 大于 0（同侧、指向
    内部），节点不校验。方向对配错（点积 ≤ 0）的可观察症状是
    \c offset 反向——描边向几何外扩张；近正交（错误配置）则
    \c offset 为零向量。
*/
OffsetProjector::OffsetProjector(QObject* parent)
  : QObject{parent} {
  // 单绑定链：归一化 → 点积 → 退化短路 → 数乘。结果经 QObjectBindableProperty
  // 内置相等守卫——实际值未变不发 offsetChanged（refDistance==0 时方向输入
  // 变化仍重算但恒零向量 → 不传播；恢复非零自动恢复链条）。
  QBINDABLE_SET_BINDING(offset, [&] {
    const QVector2D m = bindable_direction().value().normalized();
    const QVector2D r = bindable_refDirection().value().normalized();
    const qreal d = bindable_refDistance().value();
    if (d == 0)
      return QVector2D();
    const float proj = QVector2D::dotProduct(m, r);
    if (qFuzzyIsNull(proj))
      return QVector2D();
    return m * (float(d) / proj);
  });
}

QBindable<QVector2D> OffsetProjector::bindable_direction() {
  return QBindable<QVector2D>(this, "direction");
}

QBindable<QVector2D> OffsetProjector::bindable_refDirection() {
  return QBindable<QVector2D>(this, "refDirection");
}

QBindable<qreal> OffsetProjector::bindable_refDistance() {
  return QBindable<qreal>(this, "refDistance");
}

QOOL_NS_END
