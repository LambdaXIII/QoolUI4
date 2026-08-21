#ifndef QOOL_SHAPECONTROL_GADGET_H
#define QOOL_SHAPECONTROL_GADGET_H

#include "qool_smartobj.h"
#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"
#include <QObject>
#include <QQuickItem>

#include "qool_shapecontrol.h"

QOOL_NS_BEGIN

class ShapeControlGadget : public SmartObject {
  Q_OBJECT
  QML_ELEMENT
  QML_UNCREATABLE(
      "This is a virtual class for gadgets, can not instantiate alone.")
  Q_CLASSINFO("ShapeControlGadgetName", "Unnamed Gadget")
public:
  explicit ShapeControlGadget(QObject* parent = nullptr);
  virtual ~ShapeControlGadget() = default;
  Q_INVOKABLE virtual QString gadgetName() const;

  Q_INVOKABLE virtual bool contains(const QPointF& point) const;

  QBINDABLE_WRITABLE_PROPERTY(ShapeControlGadget, ShapeControl*, control)
  QBINDABLE_WRITABLE_PROPERTY(ShapeControlGadget, QQuickItem*, target)
};

QOOL_NS_END

#endif // QOOL_SHAPECONTROL_GADGET_H
