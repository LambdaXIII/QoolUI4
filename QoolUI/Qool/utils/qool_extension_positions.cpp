#include "qool_extension_positions.h"

#include "qoolcommon/debug.hpp"
QOOL_NS_BEGIN

Extension_Positions::Extension_Positions(QObject* parent)
  : QObject(parent) {
  xInfoQ << "initialized.";
}

using POS = Extension_Positions::Positions;

#define IMPL_COLLECTION(NAME, ...)                                     \
  const QList<POS>& Extension_Positions::NAME() {                      \
    static const QList<POS> value { __VA_ARGS__ };                     \
    return value;                                                      \
  }

IMPL_COLLECTION(leftSide, POS::TopLeft, POS::LeftTop, POS::LeftCenter,
  POS::LeftBottom, POS::BottomLeft)
IMPL_COLLECTION(rightSide, POS::TopRight, POS::RightTop,
  POS::RightCenter, POS::RightBottom, POS::BottomRight)
IMPL_COLLECTION(topSide, POS::LeftTop, POS::TopLeft, POS::TopCenter,
  POS::TopRight, POS::RightTop)
IMPL_COLLECTION(bottomSide, POS::LeftBottom, POS::BottomLeft,
  POS::BottomCenter, POS::BottomRight, POS::RightBottom)

IMPL_COLLECTION(
  leftEdge, POS::LeftTop, POS::LeftCenter, POS::LeftBottom)
IMPL_COLLECTION(
  rightEdge, POS::RightTop, POS::RightCenter, POS::RightBottom)
IMPL_COLLECTION(topEdge, POS::TopLeft, POS::TopCenter, POS::TopRight)
IMPL_COLLECTION(
  bottomEdge, POS::BottomLeft, POS::BottomCenter, POS::BottomRight)

IMPL_COLLECTION(hCenter, POS::LeftCenter, POS::RightCenter, POS::Center)
IMPL_COLLECTION(vCenter, POS::TopCenter, POS::BottomCenter, POS::Center)

#undef IMPL_COLLECTION

qreal Extension_Positions::xPosFromWidth(
  qreal width, Positions position) {
  if (leftSide().contains(position))
    return 0;
  if (rightSide().contains(position))
    return width;
  if (hCenter().contains(position))
    return width / 2;
  return 0;
}

qreal Extension_Positions::yPosFromHeight(
  qreal height, Positions position) {
  if (topSide().contains(position))
    return 0;
  if (bottomSide().contains(position))
    return height;
  if (vCenter().contains(position))
    return height / 2;
  return 0;
}

QPointF Extension_Positions::posInRect(
  QQuickItem* item, Positions position) {
  const auto x = xPosFromWidth(item->width(), position);
  const auto y = yPosFromHeight(item->height(), position);
  return QPointF(x, y);
}

QPointF Extension_Positions::posInRect(
  const QRectF& rect, Positions position) {
  const auto x = xPosFromWidth(rect.width(), position);
  const auto y = yPosFromHeight(rect.height(), position);
  return QPointF(x, y);
}

qreal Extension_Positions::xOffsetToPos(
  qreal width, Positions position) {
  return xPosFromWidth(width, position) * -1;
}

qreal Extension_Positions::yOffsetToPos(
  qreal height, Positions position) {
  return yPosFromHeight(height, position) * -1;
}

QPointF Extension_Positions::offsetToPos(
  QQuickItem* item, Positions position) {
  const auto x = xOffsetToPos(item->width(), position);
  const auto y = yOffsetToPos(item->height(), position);
  return QPointF(x, y);
}

QPointF Extension_Positions::offsetToPos(
  const QRectF& rect, Positions position) {
  const auto x = xOffsetToPos(rect.width(), position);
  const auto y = yOffsetToPos(rect.height(), position);
  return QPointF(x, y);
}

QOOL_NS_END