#ifndef QOOL_OCTAGONSHAPEHELPER_H
#define QOOL_OCTAGONSHAPEHELPER_H

#include "qool_abstractshapehelper.h"
#include "qool_octagonsettings.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolns.hpp"

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
  Q_INVOKABLE void dumpInfo() const override;
  Q_INVOKABLE bool contains(const QPointF& point) const override;

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    OctagonShapeHelper, qreal, safeTR)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    OctagonShapeHelper, qreal, safeTL)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    OctagonShapeHelper, qreal, safeBL)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    OctagonShapeHelper, qreal, safeBR)

#define DECL_POINT(_N_)                                                \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    OctagonShapeHelper, QPointF, _N_)                                  \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    OctagonShapeHelper, qreal, _N_##x)                                 \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(                         \
    OctagonShapeHelper, qreal, _N_##y)

  QOOL_FOREACH_8(
    DECL_POINT, intTL, intTR, intLT, intLB, intRT, intRB, intBL, intBR)
  QOOL_FOREACH_8(
    DECL_POINT, extTL, extTR, extLT, extLB, extRT, extRB, extBL, extBR)

#undef DECL_POINT

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    OctagonShapeHelper, QPolygonF, intPolygon)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    OctagonShapeHelper, QPolygonF, extPolygon)

protected:
  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, qreal, safeBorderWidth)
  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, qreal, borderShrinkSize)
  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, QList<QPointF>, intPoints)
  QOOL_BINDABLE_MEMBER(OctagonShapeHelper, QList<QPointF>, extPoints)

private:
  void __setup_reference_values();
  void __connect_points();
  void __setup_ext_points();
  void __setup_int_points();
};

QOOL_NS_END

#endif // QOOL_OCTAGONSHAPEHELPER_H
