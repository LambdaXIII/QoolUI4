#ifndef QOOL_ITEMTRACKER_H
#define QOOL_ITEMTRACKER_H

#include "qoolcommon/qbindable_property_macros.hpp"
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

  QBINDABLE_WRITABLE_PROPERTY(
    ItemTracker, QObject*, target)
  QBINDABLE_READONLY_PROPERTY(
    ItemTracker, QQuickItem*, item)
  QBINDABLE_READONLY_PROPERTY(
    ItemTracker, QWindow*, window)
  QBINDABLE_READONLY_PROPERTY(
    ItemTracker, bool, itemEnabled)
  QBINDABLE_READONLY_PROPERTY(
    ItemTracker, bool, windowActived)
};

QOOL_NS_END
#endif // QOOL_ITEMTRACKER_H
