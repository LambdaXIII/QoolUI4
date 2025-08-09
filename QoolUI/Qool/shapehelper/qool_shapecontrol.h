#ifndef QOOL_SHAPECONTROL_H
#define QOOL_SHAPECONTROL_H

#include "qool_smartobj.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolcommon/qobject_property_macros.hpp"
#include <QObject>

#include "qoolns.hpp"
#include <QBindable>
#include <QQmlEngine>
#include <QQuickItem>

QOOL_NS_BEGIN

class ShapeControl : public SmartObject {
  Q_OBJECT
  QML_ELEMENT
public:
  ShapeControl(QObject* parent = nullptr);
  virtual ~ShapeControl() = default;
  Q_INVOKABLE virtual void dumpInfo() const;
  Q_INVOKABLE virtual bool contains(const QPointF& point) const;

  QBindable<QQuickItem*> bindable_target();

private:
  QQuickItem* m_target{nullptr};
  void setup_properties();

  QOBJECT_WRITABLE_PROPERTY_DECLARE(QQuickItem*, target, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, x, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, y, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, width, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, height, FINAL)

  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, longEdge, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, shortEdge, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, aspectRatio, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, halfWidth, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, halfHeight, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, QRectF, boundingRect, FINAL)
};

QOOL_NS_END

#endif // QOOL_SHAPECONTROL_H
