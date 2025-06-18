#include "qool_smartobj.h"

QOOL_NS_BEGIN

SmartObject::SmartObject(QObject* parent)
  : QObject(parent) {
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

QOOL_NS_END