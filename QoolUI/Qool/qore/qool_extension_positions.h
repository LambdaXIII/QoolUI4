#ifndef QOOL_EXTENSION_POSITONS_H
#define QOOL_EXTENSION_POSITONS_H

#include "qool_literals.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QQuickItem>

QOOL_NS_BEGIN

class Extension_Positions: public QObject {
  Q_OBJECT
  // QML_ELEMENT
  QML_ANONYMOUS
public:
  explicit Extension_Positions(QObject* parent = nullptr);

  Q_INVOKABLE static qreal xPosFromWidth(
    qreal width, QoolLiterals::Positions position);
  Q_INVOKABLE static qreal yPosFromHeight(
    qreal height, QoolLiterals::Positions position);
  Q_INVOKABLE static QPointF posInRect(
    QQuickItem* item, QoolLiterals::Positions position);
  Q_INVOKABLE static QPointF posInRect(
    const QRectF& rect, QoolLiterals::Positions position);

  Q_INVOKABLE static qreal xOffsetToPos(
    qreal width, QoolLiterals::Positions position);
  Q_INVOKABLE static qreal yOffsetToPos(
    qreal height, QoolLiterals::Positions position);
  Q_INVOKABLE static QPointF offsetToPos(
    QQuickItem* item, QoolLiterals::Positions position);
  Q_INVOKABLE static QPointF offsetToPos(
    const QRectF& rect, QoolLiterals::Positions position);

#define POSCOLLECTION(NAME)                                            \
private:                                                               \
  Q_PROPERTY(QList<QoolLiterals::Positions> NAME READ NAME CONSTANT)   \
public:                                                                \
  static const QList<QoolLiterals::Positions>& NAME();

  QOOL_FOREACH_10(POSCOLLECTION, leftSide, rightSide, topSide,
    bottomSide, leftEdge, rightEdge, topEdge, bottomEdge, hCenter,
    vCenter)

#undef POSCOLLECTION
};
QOOL_NS_END
#endif // QOOL_EXTENTION_POSITONS_H
