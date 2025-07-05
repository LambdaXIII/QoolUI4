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

QBindable<QVariant> SmartObject::bindable_parentItem() {
  return QBindable<QVariant>(this, "parentItem");
}

QQuickItem* SmartObject::parentQuickItem() const {
  return m_parentQuickItem;
}

QBindable<QQuickItem*> SmartObject::bindable_parentQuickItem() {
  return QBindable<QQuickItem*> { this, "parentQuickItem" };
}

QQuickWindow* SmartObject::parentWindow() const {
  return m_parentWindow;
}

QBindable<QQuickWindow*> SmartObject::bindable_parentWindow() {
  return QBindable<QQuickWindow*> { this, "parentWindow" };
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
    m_parentEnabled = true;
    return;
  }
  m_parentEnabled = m_parentQuickItem->isEnabled();
}

void SmartObject::update_window_properties() {
  if (! m_parentWindow) {
    m_windowActived = true;
    return;
  }
  m_windowActived = m_parentWindow->isActive();
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

bool SmartObject::event(QEvent* e) {
  if (e->type() == QEvent::ParentChange)
    emit parentChanged();

  return QObject::event(e);
}

QOOL_NS_END
