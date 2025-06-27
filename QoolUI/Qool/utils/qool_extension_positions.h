#ifndef QOOL_EXTENSION_POSITONS_H
#define QOOL_EXTENSION_POSITONS_H

#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QQuickItem>

QOOL_NS_BEGIN

class Extension_Positions: public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_ANONYMOUS
public:
  enum Positions {
    TopLeft,
    TopCenter,
    TopRight,
    LeftTop,
    LeftCenter,
    LeftBottom,
    BottomLeft,
    BottomCenter,
    BottomRight,
    RightTop,
    RightCenter,
    RightBottom,
    Center
  };
  Q_ENUM(Positions)

  explicit Extension_Positions(QObject* parent = nullptr);

  Q_INVOKABLE static qreal xPosFromWidth(
    qreal width, Positions position);
  Q_INVOKABLE static qreal yPosFromHeight(
    qreal height, Positions position);
  Q_INVOKABLE static QPointF posInRect(
    QQuickItem* item, Positions position);
  Q_INVOKABLE static QPointF posInRect(
    const QRectF& rect, Positions position);

  Q_INVOKABLE static qreal xOffsetToPos(
    qreal width, Positions position);
  Q_INVOKABLE static qreal yOffsetToPos(
    qreal height, Positions position);
  Q_INVOKABLE static QPointF offsetToPos(
    QQuickItem* item, Positions position);
  Q_INVOKABLE static QPointF offsetToPos(
    const QRectF& rect, Positions position);

#define POSCOLLECTION(NAME)                                            \
private:                                                               \
  Q_PROPERTY(QList<Positions> NAME READ NAME CONSTANT)                 \
public:                                                                \
  static const QList<Positions>& NAME();

  QOOL_FOREACH_10(POSCOLLECTION, leftSide, rightSide, topSide,
    bottomSide, leftEdge, rightEdge, topEdge, bottomEdge, hCenter,
    vCenter)

#undef POSCOLLECTION
};
QOOL_NS_END
#endif // QOOL_EXTENTION_POSITONS_H