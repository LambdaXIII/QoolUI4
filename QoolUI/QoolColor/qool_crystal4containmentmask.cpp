#include "qool_crystal4containmentmask.h"

#include <cmath>

QOOL_NS_BEGIN

/*!
    \qmltype Crystal4ContainmentMask
    \inqmlmodule Qool.Color
    \nativetype qoolui::Crystal4ContainmentMask
    \brief 水晶4（菱形）形态的 containmentMask：QQuickItem 派生，O(1) 数值命中判定。

    供 ColorCrystal / ColorCursor 等水晶4形态组件的 \c containmentMask 使用；
    宿主一般不需要直接实例化。

    \section2 v4 模式（QQuickItem containmentMask）

    QQuickItem 的 \c containmentMask 属性要求 QQuickItem 派生类型。v3 中本掩码是
    QObject 派生（当时由宿主组件自行桥接判定），v4 按 \l ShapeContainmentMask
    模式改写为 QQuickItem 派生：重写 \l {QQuickItem::contains()}{contains()}，
    可直接赋值给 \c containmentMask 属性，坐标变换由 Qt 自动完成。

    \c contains() 收到的点位于掩码自身局部坐标系。掩码作为宿主子项置于 (0,0)
    且尺寸与宿主一致时，掩码局部坐标与宿主局部坐标重合——ColorCrystal /
    ColorCursor 均按此方式使用。

    \section2 命中判定（数学公式，自 v3 逐字复用）

    命中判定是纯数值不等式（曼哈顿距离 / L1 范数），不依赖路径填充，O(1) 性能稳定：

    \badcode
    |x - cx| + |y - cy| * (h / w) <= w / 2
    \endcode

    其中 \c{x}/\c{y} 为判定点（掩码局部坐标），\c{cx}/\c{cy} 为 \l centerPoint，
    \c{w}/\c{h} 为掩码自身 \c width / \c height（即菱形外接框，取 QQuickItem
    几何属性）。该公式与变换顺序自 v3 qool_crystal4containmentmask.cpp 逐字
    复用，未做任何改动：

    \list 1
        \li 当 \c{w != h} 时，\c{y} 先按 \c{h / w} 比例预缩放（仿射变换）；
        \li 当 \c{centerPoint != (0, 0)} 时，点平移到以菱形中心为原点的坐标；
        \li 曼哈顿距离 \c{|x| + |y| <= w / 2} 判命中，边界含等号。
    \endlist

    几何形状：\c{w == h} 时为正菱形，四顶点 (\c{±w/2}, 0)、(0, \c{±h/2})；
    \c{w != h} 时为仿射缩放菱形——水平半宽恒为 \c{w/2}，垂直半长恒为
    \c{w²/(2h)}（y 预缩放的结果，并非 \c{h/2}，勿按直觉修改）。

    \\qmlproperty QPointF centerPoint
    菱形中心（掩码局部坐标系），默认 \c{(0, 0)}。默认值下掩码判定跳过平移
    分支，菱形中心落在掩码坐标原点——ColorCrystal 即以此默认使用（其菱形
    绘制于自身原点周围，掩码与图形天然重合）；ColorCursor 传入自身中心点。
    注意该点是掩码局部坐标而非宿主坐标：掩码随宿主移动时其局部原点跟随，
    \c centerPoint 无需跟随宿主位移更新。

    \section2 易误解点

    \list
        \li \c width / \c height 直接取 QQuickItem 自身几何（菱形外接框），
            不再像 v3 那样作为掩码独立属性——这是 v4 containmentMask 模式的
            架构裁定（掩码即 QQuickItem），并非 API 丢失；QML 用法
            \c {width: parent.width} 与 v3 一致。
        \li \c centerPoint 默认 (0,0) 使菱形中心位于掩码原点，是 v3 既有语义，
            非缺陷（ColorCrystal 依赖此默认）。
        \li 判定公式的 y 预缩放与平移顺序不可调整（v3 保真，调序会改变命中域）。
    \endlist
*/
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
