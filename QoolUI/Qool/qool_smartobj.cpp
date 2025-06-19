#include "qool_smartobj.h"

#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

SmartObject::SmartObject(QObject* parent)
  : QObject {} {
  this->setParent(parent);
}

QQmlListProperty<QObject> SmartObject::smartItems() {
  return { this, nullptr, _append_item, nullptr, nullptr, nullptr };
}

void SmartObject::_append_item(
  QQmlListProperty<QObject>* list, QObject* item) {
  SmartObject* self = qobject_cast<SmartObject*>(list->object);
  self->m_items.append(item);
  if (item->parent() == nullptr)
    item->setParent(self);
}

void SmartObject::setParent(QObject* parent) {
  QObject* old_parent = this->parent();
  if (parent == old_parent)
    return;
  QObject::setParent(parent);
  emit parentChanged();
  QQuickItem* pItem = qobject_cast<QQuickItem*>(parent);
  if (pItem != m_parentItem) {
    m_parentItem = pItem;
    emit parentItemChanged();
  }
}

QVariant SmartObject::parentItem() const {
  return QVariant::fromValue(m_parentItem);
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

QOOL_NS_END
