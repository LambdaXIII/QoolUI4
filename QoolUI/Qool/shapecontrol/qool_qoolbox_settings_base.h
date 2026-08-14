#ifndef QOOL_QOOLBOX_SETTINGS_BASE_H
#define QOOL_QOOLBOX_SETTINGS_BASE_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QObjectBindableProperty>
#include <QQmlEngine>

QOOL_NS_BEGIN

// QoolBox 外观设置基类（属性定义处；QML_UNCREATABLE 注册——属性类型解析用）。
//
// 双类型结构（ADR-0005 + spec D2 fallback 定案）：Base 承载全部 9 属性的
// 定义与默认值；QML 面经派生类 QoolBoxSettings（QML_ELEMENT 注册、可实例化）
// 暴露。设计背景：QML 文件以 QML_UNCREATABLE 类型为根继承被 Qt 6.11 引擎
// 拒绝（组件根元素 creatable 检查——01 票实证），故"QML 类型继承 Base"
// 不可行；Base 注册 QML_UNCREATABLE（QML 中可见、不可实例化）是为了
// **属性类型解析**：`QoolBoxShapeControl::settings` 属性类型 Base* 若指向
// 未注册 QML 的类型，QML 引擎对内联对象字面量赋值
// （`settings: QoolBoxSettings {...}`）报 "Cannot assign to property of
// unknown type"（引擎需按 qmltypes 解析属性类型并做子类检查）；注册后
// 内联赋值与引用赋值（`settings: otherBox.settings`）均正常，多态完整。
// 直接实例化 Base 报错（uncreatable，提示使用 QoolBoxSettings）。
//
// 属性宏体系：QBINDABLE_WRITABLE_PROPERTY（可绑定、相等守卫 + 信号）。
class QoolBoxSettingsBase : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_UNCREATABLE(
      "QoolBoxSettingsBase is the abstract base of QoolBoxSettings; instantiate QoolBoxSettings instead.")

public:
  explicit QoolBoxSettingsBase(QObject* parent = nullptr);

  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettingsBase, qreal, cutSizeTL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettingsBase, qreal, cutSizeTR)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettingsBase, qreal, cutSizeBL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettingsBase, qreal, cutSizeBR)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettingsBase, qreal, borderWidth)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettingsBase, QColor, borderColor)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettingsBase, QColor, fillColor)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettingsBase, qreal, offsetX)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettingsBase, qreal, offsetY)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettingsBase, bool, curved)
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_SETTINGS_BASE_H
