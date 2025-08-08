#include "qool_smartobj.h"

#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

SmartObject::SmartObject(QObject* parent)
  : QObject{parent} {
  installEventFilter(this);
}

QBindable<QObject*> SmartObject::bindableParent() {
  return QBindable<QObject*>(this, "parent");
}

QQmlListProperty<QObject> SmartObject::smartItems() {
  return {
    this, nullptr, __appendFunction, __countFunction, __atFunction, nullptr};
}

void SmartObject::__appendFunction(
    QQmlListProperty<QObject>* property, QObject* item) {
  auto self = static_cast<SmartObject*>(property->object);
  self->appendChild(item);
}

qsizetype SmartObject::__countFunction(QQmlListProperty<QObject>* property) {
  auto self = static_cast<SmartObject*>(property->object);
  return self->m_items.length();
}

QObject* SmartObject::__atFunction(
    QQmlListProperty<QObject>* property, qsizetype index) {
  auto self = static_cast<SmartObject*>(property->object);
  return self->m_items.at(index);
}

void SmartObject::appendChild(QObject* child) {
  m_items.append(child);
  emit itemAppended(child);
}

void SmartObject::dumpProperties() const {
  if (! objectName().isEmpty()) xDebugQ << "Properties in" << objectName();
  auto metaObject = this->metaObject();
  for (int i = metaObject->propertyOffset(); i < metaObject->propertyCount();
      ++i) {
    auto property = metaObject->property(i);
    xDebugQ << xDBGBlue << i << ":" << xDBGYellow << property.name() << xDBGGrey
            << "=" << xDBGGreen << property.read(this) << xDBGReset;
  }
}

bool SmartObject::eventFilter(QObject* obj, QEvent* e) {
  if (obj == this && e->type() == QEvent::ParentChange) emit parentChanged();
  return false;
}

QOOL_NS_END
