#ifndef QOOL_OCTAGONSHAPEHELPER_H
#define QOOL_OCTAGONSHAPEHELPER_H

#include "qool_shapehelperbasic.h"
#include "qoolcommon/qool_bindable_property.hpp"
#include "qoolcommon/qool_common.h"

#include <QObject>
#include <QObjectBindableProperty>
#include <QPolygonF>
#include <QQmlEngine>
#include <QQuickItem>

QOOL_NS_BEGIN

class OctagonShapeHelper: public ShapeHelperBasic {
  Q_OBJECT
  QML_ELEMENT

  QOOL_BINDABLE_PROPERTY(OctagonShapeHelper, qreal, cutSizeTL)
  QOOL_BINDABLE_PROPERTY(OctagonShapeHelper, qreal, cutSizeTR)
  QOOL_BINDABLE_PROPERTY(OctagonShapeHelper, qreal, cutSizeBL)
  QOOL_BINDABLE_PROPERTY(OctagonShapeHelper, qreal, cutSizeBR)

#define POINT_DECL(_N_)                                                \
  QOOL_BINDABLE_PROPERTY_READONLY(                                     \
    OctagonShapeHelper, QPointF, ext##_N_)                             \
  QOOL_BINDABLE_PROPERTY_READONLY(                                     \
    OctagonShapeHelper, qreal, ext##_N_##x)                            \
  QOOL_BINDABLE_PROPERTY_READONLY(                                     \
    OctagonShapeHelper, qreal, ext##_N_##y)                            \
  QOOL_BINDABLE_PROPERTY_READONLY(                                     \
    OctagonShapeHelper, QPointF, int##_N_)                             \
  QOOL_BINDABLE_PROPERTY_READONLY(                                     \
    OctagonShapeHelper, qreal, int##_N_##x)                            \
  QOOL_BINDABLE_PROPERTY_READONLY(                                     \
    OctagonShapeHelper, qreal, int##_N_##y)

  POINT_DECL(TL)
  POINT_DECL(LT)
  POINT_DECL(TR)
  POINT_DECL(RT)
  POINT_DECL(BL)
  POINT_DECL(LB)
  POINT_DECL(BR)
  POINT_DECL(RB)

#undef POINT_DECL

  QOOL_BINDABLE_PROPERTY(OctagonShapeHelper, qreal, borderWidth)

  QOOL_BINDABLE_PROPERTY_READONLY(
    OctagonShapeHelper, QPolygonF, polygon)
  QOOL_BINDABLE_PROPERTY_READONLY(
    OctagonShapeHelper, QPolygonF, intPolygon)

private:
  Q_SLOT void updateTLCorner();
  Q_SLOT void updateTRCorner();
  Q_SLOT void updateBLCorner();
  Q_SLOT void updateBRCorner();

public:
  explicit OctagonShapeHelper(QObject* parent = nullptr);
};

QOOL_NS_END
#endif // QOOL_OCTAGONSHAPEHELPER_H
