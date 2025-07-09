#ifndef QOOL_SMARTOBJ_H
#define QOOL_SMARTOBJ_H

#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QQmlListProperty>
#include <QQuickItem>
#include <QQuickWindow>
#include <QVariant>

QOOL_NS_BEGIN

class SmartObject: public QObject {
  Q_OBJECT
  QML_ELEMENT

  Q_CLASSINFO("DefaultProperty", "smartItems")
  QML_LIST_PROPERTY_ASSIGN_BEHAVIOR_APPEND

  Q_PROPERTY(
    QQmlListProperty<QObject> smartItems READ smartItems CONSTANT FINAL)
  Q_PROPERTY(
    QObject* parent READ parent WRITE setParent NOTIFY parentChanged)

public:
  explicit SmartObject(QObject* parent = nullptr);
  virtual ~SmartObject() = default;

  QBindable<QObject*> bindableParent();

  Q_SIGNAL void parentChanged();
  Q_INVOKABLE void dumpProperties() const;

protected:
  bool eventFilter(QObject* obj, QEvent* e) override;

private:
  QObjectList m_items;
  QQmlListProperty<QObject> smartItems();
};

// TODO: 拆分父对象追踪功能

QOOL_NS_END

#endif // QOOL_SMARTOBJ_H
