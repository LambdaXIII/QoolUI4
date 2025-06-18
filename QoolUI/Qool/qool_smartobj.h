#ifndef QOOL_SMARTOBJ_H
#define QOOL_SMARTOBJ_H

#include "qoolcommon/qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QQmlListProperty>

QOOL_NS_BEGIN

class SmartObject: public QObject {
  Q_OBJECT
  QML_ELEMENT

  Q_CLASSINFO("DefaultProperty", "smartItems")
  QML_LIST_PROPERTY_ASSIGN_BEHAVIOR_APPEND

  Q_PROPERTY(
    QQmlListProperty<QObject> smartItems READ smartItems CONSTANT)

public:
  explicit SmartObject(QObject* parent = nullptr);

private:
  QObjectList m_items;
  QQmlListProperty<QObject> smartItems();
  static void _append_item(
    QQmlListProperty<QObject>* list, QObject* item);
};

QOOL_NS_END

#endif // QOOL_SMARTOBJ_H