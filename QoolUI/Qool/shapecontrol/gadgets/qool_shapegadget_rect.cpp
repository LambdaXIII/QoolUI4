#include "qool_shapegadget_rect.h"

QOOL_NS_BEGIN

/*!
    \qmltype RectGadget
    \inqmlmodule Qool
    \nativetype qoolui::RectGadget
    \brief 矩形几何 Gadget：挂载于标准 \l ShapeControl 之下，提供九点、
    半区矩形、内部最大正方形等派生几何与精确命中判定。

    \c width/\c height 默认绑定 target 尺寸（经由 \c bindable_target）；
    \c x/\c y 默认 0（不随 target 位置——派生几何一律本地画布坐标，
    与渲染同基准）。\b 显式设置 \c rect（经 \c set_rect → setValue）
    或 QML 中直接绑定 \c x/\c y/\c width/\c height 会移除对应构造绑定，
    几何独立为设置值、不再跟随 target——这是刻意设计，供画布串联
    场景（如 \c{gB.rect = gA.maxInnerSquareRect} 后 gB 成为独立画布
    几何源，HalfCrystal 即此用法），非缺陷。

    \note \c topHalfRect/\c bottomHalfRect/\c leftHalfRect/
    \c rightHalfRect 与 \c maxInnerSquareRect 派生自 \c rect（派生几何
    统一基于 rect 单一数据源——无外部绑定时 rect 即 x/y/width/height
    拼装，结果等价；rect 被外部绑定时派生量跟随绑定值，与
    \l {contains()}{contains()} 判定域同源），坐标基准 = 本 Gadget 本地
    （x/y 起，默认 0 时即 target 内部坐标系）——画布串联时掩码坐标与
    渲染同基准。

    派生量：九点 \c topLeft..\c bottomRight（每点含 \c X/\c Y 分量）、
    \c halfWidth/\c halfHeight/\c shortEdge/\c longEdge/\c isSquare、
    四半区矩形、\c maxInnerSquareRect/\c minOutterSquareRect、
    \l {contains()}{contains()}。
*/
RectGadget::RectGadget(QObject* parent)
  : ShapeControlGadget(parent) {
  // setBinding 激活时立即求值一次——此时 target 尚未设置（componentComplete
  // 才 set_target）——必须守卫 null（target 建立后经 bindable 依赖自动重求值）
  // QBINDABLE_SET_BINDING(x, [&] {
  //   const auto t = bindable_target().value();
  //   return t ? t->bindableX().value() : 0.0;
  // });
  // QBINDABLE_SET_BINDING(y, [&] {
  //   const auto t = bindable_target().value();
  //   return t ? t->bindableY().value() : 0.0;
  // });

  QBINDABLE_SET_VALUE(x, 0)
  QBINDABLE_SET_VALUE(y, 0)

  QBINDABLE_SET_BINDING(width, [&] {
    const auto t = bindable_target().value();
    return t ? t->bindableWidth().value() : 0.0;
  });
  QBINDABLE_SET_BINDING(height, [&] {
    const auto t = bindable_target().value();
    return t ? t->bindableHeight().value() : 0.0;
  });
  QBINDABLE_SET_BINDING(rect, [&] {
    const auto x = bindable_x().value();
    const auto y = bindable_y().value();
    const auto w = bindable_width().value();
    const auto h = bindable_height().value();
    return QRectF(x, y, w, h);
  });

  // —— 派生几何统一基于 rect（m_rect 为唯一数据源契约——九点/半区/
  // 方块全部从 rect 读，rect 被外部绑定（QML 绑定）时派生量跟随绑定值，
  // 与 contains 判定域同源，不依赖 x/y/w/h 残留值）——
  // 九点分量绑定直接读 rect（无中间量层——依赖一跳）：
#define TT bindable_rect().value().top();
#define LL bindable_rect().value().left();
#define RR bindable_rect().value().right();
#define BB bindable_rect().value().bottom();
#define HC bindable_rect().value().center().x();
#define VC bindable_rect().value().center().y();

  QBINDABLE_SET_BINDING(topLeftX, [&] { return LL; });
  QBINDABLE_SET_BINDING(topLeftY, [&] { return TT; });
  QBINDABLE_SET_BINDING(topCenterX, [&] { return HC; });
  QBINDABLE_SET_BINDING(topCenterY, [&] { return TT; });
  QBINDABLE_SET_BINDING(topRightX, [&] { return RR; });
  QBINDABLE_SET_BINDING(topRightY, [&] { return TT; });

  QBINDABLE_SET_BINDING(leftCenterX, [&] { return LL; });
  QBINDABLE_SET_BINDING(leftCenterY, [&] { return VC; });
  QBINDABLE_SET_BINDING(centerX, [&] { return HC; });
  QBINDABLE_SET_BINDING(centerY, [&] { return VC; });
  QBINDABLE_SET_BINDING(rightCenterX, [&] { return RR; });
  QBINDABLE_SET_BINDING(rightCenterY, [&] { return VC; });

  QBINDABLE_SET_BINDING(bottomLeftX, [&] { return LL; });
  QBINDABLE_SET_BINDING(bottomLeftY, [&] { return BB; });
  QBINDABLE_SET_BINDING(bottomCenterX, [&] { return HC; });
  QBINDABLE_SET_BINDING(bottomCenterY, [&] { return BB; });
  QBINDABLE_SET_BINDING(bottomRightX, [&] { return RR; });
  QBINDABLE_SET_BINDING(bottomRightY, [&] { return BB; });

#undef TT
#undef LL
#undef RR
#undef BB
#undef HC
#undef VC

#define SETUP(NAME)                                                       \
  QBINDABLE_SET_BINDING(NAME,                                             \
      [&] { return QPointF(m_##NAME##X.value(), m_##NAME##Y.value()); });
  QOOL_FOREACH_9(SETUP, topLeft, topCenter, topRight, leftCenter, center,
      rightCenter, bottomLeft, bottomCenter, bottomRight)
#undef SETUP

  // 半宽/半高 = 边长一半（对齐基类 ShapeControl 语义——基类同为 width/2；
  // 曾误绑 m_hcenter/m_vcenter（= x+width/2 中心坐标），x/y 非零时半区
  // 矩形全部错误——RectGadget 零使用者从未暴露）
  QBINDABLE_SET_BINDING(
      halfWidth, [&] { return bindable_rect().value().width() / 2; });
  QBINDABLE_SET_BINDING(
      halfHeight, [&] { return bindable_rect().value().height() / 2; });
  QBINDABLE_SET_BINDING(topHalfRect, [&] {
    const auto r = bindable_rect().value();
    return QRectF(r.x(), r.y(), r.width(), r.height() / 2);
  });
  QBINDABLE_SET_BINDING(bottomHalfRect, [&] {
    const auto r = bindable_rect().value();
    return QRectF(r.x(), r.y() + r.height() / 2, r.width(), r.height() / 2);
  });
  QBINDABLE_SET_BINDING(leftHalfRect, [&] {
    const auto r = bindable_rect().value();
    return QRectF(r.x(), r.y(), r.width() / 2, r.height());
  });
  QBINDABLE_SET_BINDING(rightHalfRect, [&] {
    const auto r = bindable_rect().value();
    // 曾误写 QRectF(w, y, w, h)——x 位置用了半宽（恰在 x=0 时碰巧正确）；
    // 半区矩形 x 应为右半区起点 rect.x + 半宽
    return QRectF(r.x() + r.width() / 2, r.y(), r.width() / 2, r.height());
  });

  QBINDABLE_SET_BINDING(shortEdge, [&] {
    const auto r = bindable_rect().value();
    return std::min(r.width(), r.height());
  });
  QBINDABLE_SET_BINDING(longEdge, [&] {
    const auto r = bindable_rect().value();
    return std::max(r.width(), r.height());
  });
  QBINDABLE_SET_BINDING(isSquare, [&] {
    const auto r = bindable_rect().value();
    return r.width() == r.height();
  });

  QBINDABLE_SET_BINDING(maxInnerSquareRect, [&] {
    const auto r = bindable_rect().value();
    const auto edge = std::min(r.width(), r.height());
    const auto delta = edge / 2;
    const auto c = r.center();

    const auto x = c.x() - delta;
    const auto y = c.y() - delta;
    return QRectF(x, y, edge, edge);
  });
  QBINDABLE_SET_BINDING(minOutterSquareRect, [&] {
    const auto r = bindable_rect().value();
    const auto edge = std::max(r.width(), r.height());
    const auto delta = edge / 2;
    const auto c = r.center();

    const auto x = c.x() - delta;
    const auto y = c.y() - delta;
    return QRectF(x, y, edge, edge);
  });
}

bool RectGadget::contains(const QPointF& p) const {
  return m_rect.value().contains(p);
}

QRectF RectGadget::rect() const { return m_rect.value(); }

void RectGadget::set_rect(const QRectF& newRect) {
  Qt::beginPropertyUpdateGroup();
  set_x(newRect.x());
  set_y(newRect.y());
  set_width(newRect.width());
  set_height(newRect.height());
  Qt::endPropertyUpdateGroup();
}

QOOL_NS_END
