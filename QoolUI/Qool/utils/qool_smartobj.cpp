#include "qool_smartobj.h"

#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

SmartObject::SmartObject(QObject* parent)
  : QObject { parent } {
  m_enabled.setValue(true);
  connect(this, SIGNAL(parentChanged()), this, SLOT(update_parent()));
  update_parent();
}

QVariant SmartObject::parentItem() const {
  if (m_parentQuickItem)
    return QVariant::fromValue(m_parentQuickItem);
  if (m_parentWindow)
    return QVariant::fromValue(m_parentWindow);
  return {};
}

QQuickItem* SmartObject::parentQuickItem() const {
  return m_parentQuickItem;
}

QQuickWindow* SmartObject::parentWindow() const {
  return m_parentWindow;
}

QQmlListProperty<QObject> SmartObject::smartItems() {
  // return { this, nullptr, _append_item, nullptr, nullptr, nullptr };
  return { this, &m_items };
}

void SmartObject::update_parent() {
  disconnect(m_parentQuickItem);
  disconnect(m_parentWindow);

  m_parentQuickItem = qobject_cast<QQuickItem*>(parent());
  if (m_parentQuickItem)
    m_parentWindow = m_parentQuickItem->window();
  else
    m_parentWindow = qobject_cast<QQuickWindow*>(parent());

  if (m_parentQuickItem) {
    connect(m_parentQuickItem,
      SIGNAL(enabledChanged()),
      this,
      SLOT(update_item_properties()));
  }

  if (m_parentWindow) {
    connect(m_parentWindow,
      SIGNAL(activeChanged()),
      this,
      SLOT(update_window_properties()));
  }

  update_item_properties();
  update_window_properties();
}

void SmartObject::update_item_properties() {
  if (! m_parentQuickItem) {
    set_parentEnabled(true);
    return;
  }
  set_parentEnabled(m_parentQuickItem->isEnabled());
}

void SmartObject::update_window_properties() {
  if (! m_parentWindow) {
    set_windowActived(true);
    return;
  }
  set_windowActived(m_parentWindow->isActive());
}

// void SmartObject::_append_item(
//   QQmlListProperty<QObject>* list, QObject* item) {
//   SmartObject* self = qobject_cast<SmartObject*>(list->object);
//   self->m_items.append(item);
//   if (item->parent() == nullptr)
//     item->setParent(self);
// }

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

bool SmartObject::event(QEvent* e) {
  if (e->type() == QEvent::ParentChange)
    emit parentChanged();

  return QObject::event(e);
}

QOOL_NS_END
