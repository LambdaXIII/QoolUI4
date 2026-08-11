#include "qool_shapegadget_rect.h"

QOOL_NS_BEGIN

RectGadget::RectGadget(QObject* parent)
  : ShapeControlGadget(parent) {
  QBINDABLE_SET_BINDING(
      x, [&] { return bindable_target().value()->bindableX().value(); });
  QBINDABLE_SET_BINDING(
      y, [&] { return bindable_target().value()->bindableY().value(); });
  QBINDABLE_SET_BINDING(width,
      [&] { return bindable_target().value()->bindableWidth().value(); });
  QBINDABLE_SET_BINDING(height,
      [&] { return bindable_target().value()->bindableHeight().value(); });
  QBINDABLE_SET_BINDING(rect, [&] {
    const auto x = bindable_x().value();
    const auto y = bindable_y().value();
    const auto w = bindable_width().value();
    const auto h = bindable_height().value();
    return QRectF(x, y, w, h);
  });

  m_left.setBinding([&] { return bindable_x().value(); });
  m_top.setBinding([&] { return bindable_y().value(); });
  m_right.setBinding(
      [&] { return bindable_x().value() + bindable_width().value(); });
  m_bottom.setBinding(
      [&] { return bindable_y().value() + bindable_height().value(); });
  m_hcenter.setBinding(
      [&] { return bindable_x().value() + (bindable_width().value() / 2); });
  m_vcenter.setBinding(
      [&] { return bindable_y().value() + (bindable_height().value() / 2); });

#define TT m_top.value();
#define LL m_left.value();
#define RR m_right.value();
#define BB m_bottom.value();
#define HC m_hcenter.value();
#define VC m_vcenter.value();

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

  QBINDABLE_SET_BINDING(halfWidth, [&] { return m_hcenter.value(); });
  QBINDABLE_SET_BINDING(halfHeight, [&] { return m_vcenter.value(); });
  QBINDABLE_SET_BINDING(topHalfRect, [&] {
    const auto x = bindable_x().value();
    const auto y = bindable_y().value();
    const auto w = bindable_width().value();
    const auto h = bindable_halfHeight().value();
    return QRectF(x, y, w, h);
  });
  QBINDABLE_SET_BINDING(bottomHalfRect, [&] {
    const auto x = bindable_x().value();
    const auto y = bindable_leftCenterY().value();
    const auto w = bindable_width().value();
    const auto h = bindable_halfHeight().value();
    return QRectF(x, y, w, h);
  });
  QBINDABLE_SET_BINDING(leftHalfRect, [&] {
    const auto x = bindable_x().value();
    const auto y = bindable_y().value();
    const auto w = bindable_halfWidth().value();
    const auto h = bindable_height().value();
    return QRectF(x, y, w, h);
  });
  QBINDABLE_SET_BINDING(rightHalfRect, [&] {
    const auto x = bindable_topCenterX();
    const auto y = bindable_y().value();
    const auto w = bindable_halfWidth().value();
    const auto h = bindable_height().value();
    return QRectF(w, y, w, h);
  });

  QBINDABLE_SET_BINDING(shortEdge, [&] {
    return std::min(bindable_width().value(), bindable_height().value());
  });
  QBINDABLE_SET_BINDING(longEdge, [&] {
    return std::max(bindable_width().value(), bindable_height().value());
  });
  QBINDABLE_SET_BINDING(isSquare,
      [&] { return bindable_width().value() == bindable_height().value(); });

  QBINDABLE_SET_BINDING(maxInnerSquareRect, [&] {
    const auto edge = bindable_shortEdge().value();
    const auto delta = edge / 2;
    const auto cx = bindable_centerX().value();
    const auto cy = bindable_centerY().value();

    const auto x = cx - delta;
    const auto y = cy - delta;
    return QRectF(x, y, edge, edge);
  });
  QBINDABLE_SET_BINDING(minOutterSquareRect, [&] {
    const auto edge = bindable_longEdge().value();
    const auto delta = edge / 2;
    const auto cx = bindable_centerX().value();
    const auto cy = bindable_centerY().value();

    const auto x = cx - delta;
    const auto y = cy - delta;
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
