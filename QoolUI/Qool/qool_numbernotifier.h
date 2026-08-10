#ifndef QOOL_NUMBERNOTIFIER_H
#define QOOL_NUMBERNOTIFIER_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlProperty>
#include <QtQml/qqmlpropertyvaluesource.h>
#include <QtQml/qqmlregistration.h>

class QTimer;

QOOL_NS_BEGIN

// NumberNotifier：数值属性观测器（Qool 模块，C++ QML 类型）。
// 类名 = 文件名的去前缀名（AGENTS 惯例：qool_类名.h ↔ 类名——QML_ELEMENT
// 默认导出类名；Qool 前缀会导出为 "QoolNumberNotifier" 导致 QML 引用失败）。
//
// 定位：挂在单个数值属性上做**持续化动态监测**——拉取式采样循环，不是事件
// 驱动（不连接属性的 notify 信号）：
//   - 每 interval（默认 200ms）主动 read() 属性值，与上次采样值求差
//   - velocity = 差值 / (interval/1000)——值/秒，**有向**（增大正、减小负）
//   - 属性骤停 → 下次采样差值为 0 → velocity 自然归零（"转速表"语义——
//     当前速率，而非"最后变化速度"）
//   - 差值非零（采样检测到变化）→ 发 valueUpdated(newValue, oldValue)
//     ——采样快照对（相邻两次采样值，非真实变化瞬间值）：延迟 ≤ interval、
//     可能漏掉采样间的往返变化——**区别于原属性自身的 Changed 通知**
//     （事件精确；宿主需要精确通知应直接监听原属性）——QDoc 必须说明
//
// 双模式（统一到同一采样循环）：
//   - `NumberNotifier on value` 语法：引擎属性赋值失败时调 setTarget()，
//     提供被挂属性的引用（读方向观测——本类型从不写值）
//   - 普通对象用法：target + property 属性（写路径重建观测）
// 两模式互斥使用；setup_property 语义：target/property 均设置时优先。
//
// 特化 real：read().toReal()（int 兼容）。边界：target 为 null / 属性无效 /
// 读值非有限数——基准重置、velocity 归零（不报错，注释见 sample）。
class NumberNotifier : public QObject, public QQmlPropertyValueSource {
  Q_OBJECT
  Q_INTERFACES(QQmlPropertyValueSource)
  QML_ELEMENT

public:
  explicit NumberNotifier(QObject* parent = nullptr);

  // QQmlPropertyValueSource：on 语法路径（引擎在属性赋值失败时调用——
  // 文档契约"正常赋值优先"；本类型只读方向，从不 write）
  void setTarget(const QQmlProperty& property) override;

  // 属性声明优先 Bindable 系列宏（仓库规范——bindable 由宏自动实现；
  // 本类无需手动 setter 逻辑，重建观测走 Changed 信号连接）
  QBINDABLE_WRITABLE_PROPERTY(NumberNotifier, QObject*, target, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(NumberNotifier, QString, property, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(NumberNotifier, int, interval, FINAL)

  // 采样检测事件（新值在前——Qt 惯例 + 单参 handler 自动降级为新值、
  // 旧值丢弃）。命名：单属性变化通知携带新旧值数据 → xxxUpdated（AGENTS
  // 信号命名规范——区别于宏生成的无参 xxxChanged 属性通知）
  Q_SIGNAL void valueUpdated(qreal newValue, qreal oldValue);
  QBINDABLE_READONLY_PROPERTY(NumberNotifier, qreal, velocity, FINAL)

private:
  void sample();
  void rebuild_observation();
  void when_targetChanged();
  void when_propertyChanged();
  void when_intervalChanged();

  QQmlProperty m_observed;
  QTimer* m_timer = nullptr;
  bool m_hasLast = false;
  qreal m_lastValue = 0;
};

QOOL_NS_END

#endif // QOOL_NUMBERNOTIFIER_H
