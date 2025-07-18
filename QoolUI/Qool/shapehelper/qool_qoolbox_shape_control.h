#ifndef QOOL_QOOLBOX_SHAPE_CONTROL_H
#define QOOL_QOOLBOX_SHAPE_CONTROL_H

#include "qool_abstractshapehelper.h"
#include "qool_qoolbox_settings.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QPointF>
#include <QQmlEngine>
#include <QRectF>

QOOL_NS_BEGIN

class QoolBoxShapeControl: public AbstractShapeHelper {
  Q_OBJECT
  QML_ELEMENT

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, QoolBoxSettings*, settings)

public:
  explicit QoolBoxShapeControl(QObject* parent = nullptr);
  Q_INVOKABLE void dumpInfo() const override;
  Q_INVOKABLE bool contains(const QPointF& point) const override;

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, qreal, safeTR)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, qreal, safeTL)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, qreal, safeBL)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, qreal, safeBR)

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, qreal, borderShrinkSize)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, qreal, safeBorderWidth)

#define DECL_POINT(_N_)                                                \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    QoolBoxShapeControl, QPointF, _N_)                                 \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    QoolBoxShapeControl, qreal, _N_##x)                                \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    QoolBoxShapeControl, qreal, _N_##y)

  QOOL_FOREACH_8(
    DECL_POINT, intTL, intTR, intLT, intLB, intRT, intRB, intBL, intBR)
  QOOL_FOREACH_8(
    DECL_POINT, extTL, extTR, extLT, extLB, extRT, extRB, extBL, extBR)

#undef DECL_POINT

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, qreal, offsetX)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, qreal, offsetY)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, qreal, intOffsetX)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, qreal, intOffsetY)

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, QPolygonF, intPolygon)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    QoolBoxShapeControl, QPolygonF, extPolygon)

protected:
  // QOOL_BINDABLE_MEMBER(QoolBoxShapeControl, qreal, safeBorderWidth)
  // QOOL_BINDABLE_MEMBER(QoolBoxShapeControl, qreal, borderShrinkSize)
  QOOL_BINDABLE_MEMBER(QoolBoxShapeControl, QList<QPointF>, intPoints)
  QOOL_BINDABLE_MEMBER(QoolBoxShapeControl, QList<QPointF>, extPoints)

private:
  void __setup_reference_values();
  void __connect_points();
  void __setup_ext_points();
  void __setup_int_points();
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_SHAPE_CONTROL_H
