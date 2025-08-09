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

class SmartObject : public QObject {
  Q_OBJECT
  QML_ELEMENT

  Q_CLASSINFO("DefaultProperty", "smartItems")
  QML_LIST_PROPERTY_ASSIGN_BEHAVIOR_APPEND

  Q_PROPERTY(
      QQmlListProperty<QObject> smartItems READ smartItems CONSTANT FINAL)
  Q_PROPERTY(QObject* parent READ parent WRITE setParent NOTIFY parentChanged)

public:
  explicit SmartObject(QObject* parent = nullptr);
  virtual ~SmartObject() = default;

  QBindable<QObject*> bindableParent();

  Q_SIGNAL void parentChanged(QObject*);
  Q_SIGNAL void itemAppended(QObject* child);

  Q_INVOKABLE void dumpProperties() const;

protected:
  virtual bool eventFilter(QObject* obj, QEvent* e) override;
  virtual void appendChild(QObject* child);

private:
  QObjectList m_items;
  QQmlListProperty<QObject> smartItems();
  static void __appendFunction(
      QQmlListProperty<QObject>* property, QObject* item);
  static qsizetype __countFunction(QQmlListProperty<QObject>* property);
  static QObject* __atFunction(
      QQmlListProperty<QObject>* property, qsizetype index);
};

QOOL_NS_END

#endif // QOOL_SMARTOBJ_H
