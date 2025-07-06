#ifndef QOOL_SMARTOBJ_H
#define QOOL_SMARTOBJ_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
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
  Q_PROPERTY(QVariant parentItem READ parentItem NOTIFY parentChanged)
  Q_PROPERTY(QQuickItem* parentQuickItem READ parentQuickItem NOTIFY
      parentChanged)
  Q_PROPERTY(
    QQuickWindow* parentWindow READ parentWindow NOTIFY parentChanged)

public:
  explicit SmartObject(QObject* parent = nullptr);
  virtual ~SmartObject() = default;

  QVariant parentItem() const;
  QBindable<QVariant> bindable_parentItem();

  QQuickItem* parentQuickItem() const;
  QBindable<QQuickItem*> bindable_parentQuickItem();

  QQuickWindow* parentWindow() const;
  QBindable<QQuickWindow*> bindable_parentWindow();

  Q_SIGNAL void parentChanged();
  Q_INVOKABLE void dumpProperties() const;

protected:
  bool event(QEvent* e) override;

private:
  QObjectList m_items;
  QQuickItem* m_parentQuickItem { nullptr };
  QQuickWindow* m_parentWindow { nullptr };
  QQmlListProperty<QObject> smartItems();

  Q_SLOT void update_parent();
  Q_SLOT void update_item_properties();
  Q_SLOT void update_window_properties();

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SmartObject, bool, enabled)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SmartObject, bool, parentEnabled)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SmartObject, bool, windowActived)
};

// TODO: 拆分父对象追踪功能

QOOL_NS_END

#endif // QOOL_SMARTOBJ_H
