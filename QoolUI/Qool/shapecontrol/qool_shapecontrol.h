#ifndef QOOL_SHAPECONTROL_H
#define QOOL_SHAPECONTROL_H

#include "qool_smartobj.h"

#include "qoolcommon/qbindable_property_macros.hpp"
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

protected:
  void appendChild(QObject* child) override;
  void componentComplete() override;

private:
  void setup_properties();

  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, QQuickItem*, target, FINAL)
  // xy仅为target属性的绑定，不代表target内部状态！
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, x, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, y, FINAL)

  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, width, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(ShapeControl, qreal, height, FINAL)

  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, longEdge, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, shortEdge, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, aspectRatio, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, QPointF, center, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, halfWidth, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, qreal, halfHeight, FINAL)
  QBINDABLE_READONLY_PROPERTY(ShapeControl, QRectF, boundingRect, FINAL)
};

QOOL_NS_END

#endif // QOOL_SHAPECONTROL_H
