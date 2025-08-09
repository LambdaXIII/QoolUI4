#ifndef QOOL_QOOLBOX_SHAPE_CONTROL_H
#define QOOL_QOOLBOX_SHAPE_CONTROL_H

#include "qool_abstractshapehelper.h"
#include "qool_qoolbox_settings.h"
#include "qool_shapecontrol.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QPointF>
#include <QQmlEngine>
#include <QRectF>

QOOL_NS_BEGIN

class QoolBoxShapeControl : public ShapeControl {
  Q_OBJECT
  QML_ELEMENT

  QBINDABLE_WRITABLE_PROPERTY(QoolBoxShapeControl, QoolBoxSettings*, settings)

public:
  explicit QoolBoxShapeControl(QObject* parent = nullptr);
  Q_INVOKABLE void dumpInfo() const override;
  Q_INVOKABLE bool contains(const QPointF& point) const override;

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
  void __setup_helper_properties();

  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, safeTR)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, safeTL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, safeBL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, safeBR)

  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, borderShrinkSize)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, safeBorderWidth)

#define DECL_POINT(_N_)                                           \
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, QPointF, _N_)  \
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, _N_##x) \
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, _N_##y)

  QOOL_FOREACH_8(
      DECL_POINT, intTL, intTR, intLT, intLB, intRT, intRB, intBL, intBR)
  QOOL_FOREACH_8(
      DECL_POINT, extTL, extTR, extLT, extLB, extRT, extRB, extBL, extBR)

#undef DECL_POINT

  QBINDABLE_WRITABLE_PROPERTY(QoolBoxShapeControl, qreal, offsetX)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxShapeControl, qreal, offsetY)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxShapeControl, qreal, intOffsetX)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxShapeControl, qreal, intOffsetY)

  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, QPolygonF, intPolygon)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, QPolygonF, extPolygon)

  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, topSpace)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, bottomSpace)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, leftSpace)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, rightSpace)
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_SHAPE_CONTROL_H
