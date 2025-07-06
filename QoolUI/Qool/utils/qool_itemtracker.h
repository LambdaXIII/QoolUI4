#ifndef QOOL_ITEMTRACKER_H
#define QOOL_ITEMTRACKER_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQuickItem>
#include <QWindow>

QOOL_NS_BEGIN

class ItemTracker: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit ItemTracker(QObject* parent = nullptr);

protected:
  Q_SLOT void update_item();
  Q_SLOT void update_window();

  Q_SLOT void setup_item();
  QList<QMetaObject::Connection> m_itemConnections;
  Q_SLOT void setup_window();
  QList<QMetaObject::Connection> m_windowConnections;

  Q_SLOT void update_item_properties();
  Q_SLOT void update_window_properties();

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    ItemTracker, QObject*, target)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    ItemTracker, QQuickItem*, item)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    ItemTracker, QWindow*, window)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    ItemTracker, bool, itemEnabled)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    ItemTracker, bool, windowActived)
};

QOOL_NS_END
#endif // QOOL_ITEMTRACKER_H
