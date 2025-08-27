#ifndef QOOL_SHAPEGADGET_TRIANGLE_H
#define QOOL_SHAPEGADGET_TRIANGLE_H

#include "qool_shape_macros.hpp"
#include "qool_shapecontrol_gadget.h"
#include "qoolcommon/qbindable_property_macros.hpp"
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class TriangleGadget : public ShapeControlGadget {
  Q_OBJECT
  QML_ELEMENT
  Q_CLASSINFO("ShapeControlGadgetName", "Triangle")

  QOOL_DECL_POINT(pointA, FINAL)
  QOOL_DECL_POINT(pointB, FINAL)
  QOOL_DECL_POINT(pointC, FINAL)

public:
  explicit TriangleGadget(QObject* parent = nullptr);
  Q_INVOKABLE bool contains(const QPointF& point) const override;

  QBINDABLE_READONLY_PROPERTY(TriangleGadget, bool, isTriangle)
  QBINDABLE_READONLY_PROPERTY(TriangleGadget, qreal, area)
  QBINDABLE_READONLY_PROPERTY(TriangleGadget, QPointF, centroid)
};

QOOL_NS_END

#endif // QOOL_SHAPEGADGET_TRIANGLE_H
