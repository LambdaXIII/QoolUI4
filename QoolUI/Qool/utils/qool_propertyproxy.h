#ifndef QOOL_PROPERTYPROXY_H
#define QOOL_PROPERTYPROXY_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"

#include <QQmlProperty>
#include <QtQml/qqmlregistration.h>
#include <QObject>
#include <QVariant>

class QTimer;

QOOL_NS_BEGIN

// PropertyProxy 契约见 docs/reference/Qool/PropertyProxy.md。
class PropertyProxy : public QObject {
  Q_OBJECT
  QML_ELEMENT

  // value 无状态非标准场景：手工 Q_PROPERTY（无 m_ 成员）；QBINDABLE 宏带
  // m_ 成员，破坏无状态契约。
  Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged)
  Q_PROPERTY(bool isReadable READ isReadable NOTIFY isReadableChanged)
  Q_PROPERTY(bool isWritable READ isWritable NOTIFY isWritableChanged)
  Q_PROPERTY(bool isConstant READ isConstant NOTIFY isConstantChanged)
  Q_PROPERTY(bool isResettable READ isResettable NOTIFY isResettableChanged)
  Q_PROPERTY(bool isBindable READ isBindable NOTIFY isBindableChanged)

public:
  explicit PropertyProxy(QObject* parent = nullptr);

  QVariant value() const;
  void setValue(const QVariant& new_value);

  bool isReadable() const;
  bool isWritable() const;
  bool isConstant() const;
  bool isResettable() const;
  bool isBindable() const;

  // target/property/interval 为普通可写属性，用宏。
  QBINDABLE_WRITABLE_PROPERTY(PropertyProxy, QObject*, target)
  QBINDABLE_WRITABLE_PROPERTY(PropertyProxy, QString, property)
  QBINDABLE_WRITABLE_PROPERTY(PropertyProxy, int, interval)

public:
  Q_SIGNAL void valueChanged();
  Q_SIGNAL void isReadableChanged();
  Q_SIGNAL void isWritableChanged();
  Q_SIGNAL void isConstantChanged();
  Q_SIGNAL void isResettableChanged();
  Q_SIGNAL void isBindableChanged();

private:
  bool valid_readable() const;
  void rebuild_observation();
  void configure_polling();
  void when_targetChanged();
  void when_propertyChanged();
  void when_intervalChanged();
  Q_SLOT void whenTargetNotify();
  Q_SLOT void when_targetDestroyed();
  Q_SLOT void sample();

  QQmlProperty m_observed;
  QTimer* m_timer{nullptr};
  QMetaObject::Connection m_notifyConnection;
  QMetaObject::Connection m_destroyedConnection;
  bool m_hasLast{false};
  QVariant m_lastValue;
};

QOOL_NS_END

#endif // QOOL_PROPERTYPROXY_H
