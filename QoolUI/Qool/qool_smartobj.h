#ifndef QOOL_SMARTOBJ_H
#define QOOL_SMARTOBJ_H

#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolcommon/qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QQmlListProperty>
#include <QQuickItem>

QOOL_NS_BEGIN

class SmartObject: public QObject {
  Q_OBJECT
  QML_ELEMENT

  Q_CLASSINFO("DefaultProperty", "smartItems")
  QML_LIST_PROPERTY_ASSIGN_BEHAVIOR_APPEND

  Q_PROPERTY(
    QQmlListProperty<QObject> smartItems READ smartItems CONSTANT)
  Q_PROPERTY(QQuickItem* parentItem READ parentItem WRITE setParent
      NOTIFY parentItemChanged)
  Q_PROPERTY(
    QObject* parent READ parent WRITE setParent NOTIFY parentChanged)

public:
  explicit SmartObject(QObject* parent = nullptr);
  virtual ~SmartObject() = default;

  void setParent(QObject* parent = nullptr);
  QQuickItem* parentItem() const;
  Q_SIGNAL void parentChanged();
  Q_SIGNAL void parentItemChanged();

private:
  QObjectList m_items;
  QQuickItem* m_parentItem { nullptr };
  QQmlListProperty<QObject> smartItems();
  static void _append_item(
    QQmlListProperty<QObject>* list, QObject* item);

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(bool, enabled, true)
};

QOOL_NS_END

#endif // QOOL_SMARTOBJ_H