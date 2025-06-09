#ifndef QOOL_OCTAGONSHAPEHELPER_H
#define QOOL_OCTAGONSHAPEHELPER_H

#include "qool_abstractshapehelper.h"
#include "qool_octagonsettings.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/qoolns.hpp"

#include <QObject>
#include <QPointF>
#include <QQmlEngine>
#include <QRectF>

QOOL_NS_BEGIN

class OctagonShapeHelper: public AbstractShapeHelper {
  Q_OBJECT
  QML_ELEMENT

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    OctagonShapeHelper, OctagonSettings*, settings)

public:
  explicit OctagonShapeHelper(QObject* parent = nullptr);
  Q_INVOKABLE void dumpPoints() const;

protected:
  QList<QPointF> externalPoints() const;
  QList<QPointF> internalPoints() const;

  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, qreal, safeBorderWidth)
  QOOL_BINDABLE_MEMBER(
    OctagonShapeHelper, qreal, safeInternalLeftBorder)
  QOOL_BINDABLE_MEMBER(
    OctagonShapeHelper, qreal, safeInternalRightBorder)
  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, qreal, safeInternalTopBorder)
  QOOL_BINDABLE_MEMBER(
    OctagonShapeHelper, qreal, safeInternalBottomBorder)
  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, qreal, shortEdgeLength)
  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, qreal, safeCutSizeTL)
  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, qreal, safeCutSizeTR)
  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, qreal, safeCutSizeBL)
  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, qreal, safeCutSizeBR)

#define DECL_POINT(_N_)                                                \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    OctagonShapeHelper, QPointF, internal##_N_)                        \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    OctagonShapeHelper, qreal, internal##_N_##x)                       \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    OctagonShapeHelper, qreal, internal##_N_##y)                       \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    OctagonShapeHelper, QPointF, external##_N_)                        \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    OctagonShapeHelper, qreal, external##_N_##x)                       \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    OctagonShapeHelper, qreal, external##_N_##y)

  DECL_POINT(TL)
  DECL_POINT(TR)
  DECL_POINT(LT)
  DECL_POINT(LB)
  DECL_POINT(RT)
  DECL_POINT(RB)
  DECL_POINT(BL)
  DECL_POINT(BR)

#undef DECL_POINT

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    OctagonShapeHelper, QPolygonF, internalPolygon)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    OctagonShapeHelper, QPolygonF, externalPolygon)
};

QOOL_NS_END

#endif // QOOL_OCTAGONSHAPEHELPER_H
