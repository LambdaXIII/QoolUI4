#include "qool_shapegadget_halfcrystal.h"
#include "qool_literals.h"

QOOL_NS_BEGIN

/*!
    \qmltype HalfCrystalGadget
    \inqmlmodule Qool
    \nativetype qoolui::HalfCrystalGadget
    \brief HalfCrystal 精确命中掩码 Gadget：以 \l {Qool::RectGadget}
    {RectGadget} 画布几何（\c geometrySource）+ \c direction 判定命中。

    \c contains 为 C++ 覆写（Q_INVOKABLE——containmentMask 要求掩码对象
    metaObject 上有 \c contains(QPointF) 方法，QML function 不满足，故不走
    QtObject 包装路径）。算法与 QoolBoxGadget::contains 同族（矩形粗判 +
    角域排除）：

    \list 1
        \li shapeRect 粗判（含边界）——direction 为 N/S/W/E 时取
            \c geometrySource 对应半区矩形（topHalfRect/bottomHalfRect/
            leftHalfRect/rightHalfRect），其余值取 maxInnerSquareRect
            （菱形形态）；
        \li 内部正方形四角域统一排除（直角边 = shortEdge/2、斜边
            \c{dx+dy < halfS}——开集语义：斜边/直角边上的点命中；无
            direction 分支——半区粗判已剪枝，不相邻角域因 dx/dy 负向
            自然不命中）。
    \endlist

    坐标基准 = \c geometrySource 的本地画布坐标（HalfCrystal 中 gB 四元
    绑定为组件本地——掩码收到的 point 同为组件本地，引擎已逆变换），
    组件平移/父变换后判定仍准确。引用瞬时几何（绑定驱动，不跟动画层）
    ——方向切换动画期间命中域即当前形状语义。
*/
HalfCrystalGadget::HalfCrystalGadget(QObject* parent)
  : ShapeControlGadget(parent) {
}

/*!
    \qmlmethod bool HalfCrystalGadget::contains(point point)
    \brief 精确命中判定：shapeRect 粗判 + 内部正方形四角域排除。
*/
bool HalfCrystalGadget::contains(const QPointF& point) const {
  const auto src = m_geometrySource.value();
  if (!src)
    return false; // 几何源未就绪——不命中（组件初始化期无交互）

  // ① shapeRect 粗判（含边界）——direction 决定半区/整正方形
  QRectF r;
  switch (m_direction.value()) {
  case QoolLiterals::N: r = src->topHalfRect(); break;
  case QoolLiterals::S: r = src->bottomHalfRect(); break;
  case QoolLiterals::W: r = src->leftHalfRect(); break;
  case QoolLiterals::E: r = src->rightHalfRect(); break;
  default: r = src->maxInnerSquareRect(); break; // 菱形形态
  }
  if (!r.contains(point))
    return false;

  // ② 四角域统一排除（内部正方形四角各一直角等腰三角形——直角顶点在
  //    正方形角、直角边沿坐标轴、斜边斜率 -1）
  const qreal halfS = src->shortEdge() / 2;
  const qreal cx = src->centerX();
  const qreal cy = src->centerY();
  const qreal l = cx - halfS;
  const qreal t = cy - halfS;
  const qreal rr = cx + halfS;
  const qreal b = cy + halfS;

  // 左上角域：原点 (l, t)
  if (point.x() - l >= 0 && point.y() - t >= 0
      && (point.x() - l) + (point.y() - t) < halfS)
    return false;
  // 右上角域：原点 (rr, t)
  if (rr - point.x() >= 0 && point.y() - t >= 0
      && (rr - point.x()) + (point.y() - t) < halfS)
    return false;
  // 右下角域：原点 (rr, b)
  if (rr - point.x() >= 0 && b - point.y() >= 0
      && (rr - point.x()) + (b - point.y()) < halfS)
    return false;
  // 左下角域：原点 (l, b)
  if (point.x() - l >= 0 && b - point.y() >= 0
      && (point.x() - l) + (b - point.y()) < halfS)
    return false;

  return true;
}

QOOL_NS_END
