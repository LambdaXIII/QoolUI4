#include "qool_smartobj.h"

#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

SmartObject::SmartObject(QObject* parent)
  : QObject { parent } {
  installEventFilter(this);
}

QBindable<QObject*> SmartObject::bindableParent() {
  return QBindable<QObject*>(this, "parent");
}

QQmlListProperty<QObject> SmartObject::smartItems() {
  // return { this, nullptr, _append_item, nullptr, nullptr, nullptr };
  return { this, &m_items };
}

void SmartObject::dumpProperties() const {
  if (! objectName().isEmpty())
    xDebugQ << "Properties in" << objectName();
  auto metaObject = this->metaObject();
  for (int i = metaObject->propertyOffset();
    i < metaObject->propertyCount();
    ++i) {
    auto property = metaObject->property(i);
    xDebugQ << xDBGBlue << i << ":" << xDBGYellow << property.name()
            << xDBGGrey << "=" << xDBGGreen << property.read(this)
            << xDBGReset;
  }
}

bool SmartObject::eventFilter(QObject* obj, QEvent* e) {
  if (obj == this && e->type() == QEvent::ParentChange)
    emit parentChanged();
  return false;
}

QOOL_NS_END
