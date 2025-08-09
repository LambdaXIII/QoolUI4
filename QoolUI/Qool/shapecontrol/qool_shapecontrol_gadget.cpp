#include "qool_shapecontrol_gadget.h"

// #include "qool_shapecontrol.h"

QOOL_NS_BEGIN

ShapeControlGadget::ShapeControlGadget(QObject* parent)
  : SmartObject(parent) {
  QBINDABLE_SET_BINDING(control, [&] {
    QObject* p = bindableParent().value();
    return qobject_cast<ShapeControl*>(p);
  });

  QBINDABLE_SET_BINDING(target, [&] {
    ShapeControl* control = m_control.value();
    if (control) return control->bindable_target().value();

    QObject* p = bindableParent().value();
    return qobject_cast<QQuickItem*>(p);
  });
}

QString ShapeControlGadget::gadgetName() const {
  int index = metaObject()->indexOfClassInfo("ShapeControlGadgetName");
  if (index >= 0) return {metaObject()->classInfo(index).value()};
  return metaObject()->className();
}

bool ShapeControlGadget::contains(const QPointF& point) const {
  if (auto c = control(); c) return c->contains(point);
  return false;
}

QOOL_NS_END
