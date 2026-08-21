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

// PropertyProxy：无状态属性代理（Qool 模块，C++ QML 类型）。
// 类名 = 文件名的去前缀名（AGENTS 惯例——Qool 前缀会导出为
// "QoolPropertyProxy" 导致 QML 引用失败）。
//
// 定位：target（对象）+ property（字符串）桥接任意对象属性，暴露 value
// 作为该属性的代理。value 是**无状态代理**——getter 现读 target.property、
// setter 直写（可写时），无内部存储、数据源唯一 → 无同步竞态、无"回滚"概念
// （ADR 0012）。
//
// 双路径同步（读方向）：观测建立（target/property 设置或变更）时立即 read()
// 一次（通用前置，常量即终值）；有 NOTIFY → 事件驱动（连 notify 发
// valueChanged）；无 NOTIFY → 轮询，interval 语义：<0 不轮询（默认 -1，
// busy polling opt-in）/ =0 事件循环周期（零定时器）/ >0 固定间隔。轮询
// 判变快照（上次采样值）仅用于比较变化、不参与读写。
//
// 净化可写性：isWritable = 元对象可写且非常量（isWritable() && !isConstant()）
// ——写方向守卫单一条件；isConstant 独立透传。五能力（isReadable/isWritable/
// isConstant/isResettable/isBindable）只读、随观测刷新。
//
// 无效态：target null / 属性无效 / 不可读 → value 无效（QML undefined）、
// 能力全 false、不连信号、不启动定时器。
//
// 写方向：可写（净化 isWritable）→ 写回 target.property；不可写 → 忽略 +
// xWarningQ（显化组件名）。不做 on value 语法（QQmlPropertyValueSource 写
// 值源语义与代理方向冲突）。
class PropertyProxy : public QObject {
  Q_OBJECT
  QML_ELEMENT

  // value 属无状态非标准场景：手工 Q_PROPERTY（无 m_ 成员），勿用 QBINDABLE
  // 宏（宏带 m_ 成员破坏无状态契约）。
  Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged FINAL)
  Q_PROPERTY(bool isReadable READ isReadable NOTIFY isReadableChanged FINAL)
  Q_PROPERTY(bool isWritable READ isWritable NOTIFY isWritableChanged FINAL)
  Q_PROPERTY(bool isConstant READ isConstant NOTIFY isConstantChanged FINAL)
  Q_PROPERTY(bool isResettable READ isResettable NOTIFY isResettableChanged FINAL)
  Q_PROPERTY(bool isBindable READ isBindable NOTIFY isBindableChanged FINAL)

public:
  explicit PropertyProxy(QObject* parent = nullptr);

  QVariant value() const;
  void setValue(const QVariant& new_value);

  bool isReadable() const;
  bool isWritable() const;
  bool isConstant() const;
  bool isResettable() const;
  bool isBindable() const;

  // target/property/interval 为普通可写属性（非无状态约束范围），用宏。
  QBINDABLE_WRITABLE_PROPERTY(PropertyProxy, QObject*, target, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(PropertyProxy, QString, property, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(PropertyProxy, int, interval, FINAL)

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
  QTimer* m_timer = nullptr;
  QMetaObject::Connection m_notifyConnection;
  QMetaObject::Connection m_destroyedConnection;
  bool m_hasLast = false;
  QVariant m_lastValue;
};

QOOL_NS_END

#endif // QOOL_PROPERTYPROXY_H
