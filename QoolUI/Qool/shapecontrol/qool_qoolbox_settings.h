#ifndef QOOL_QOOLBOX_SETTINGS_H
#define QOOL_QOOLBOX_SETTINGS_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QObjectBindableProperty>
#include <QQmlEngine>

QOOL_NS_BEGIN

// QoolBox 外观设置（QML 类型，QML_ELEMENT 注册、可实例化）：四角切角/
// 边框/填充/偏移/圆角开关——QoolBox 形状与外观统一配置入口，
// `QoolBoxShapeControl::settings` 属性类型直接为本类。
//
// 类型默认值为 C++ 常量（无 Style 默认——C++ 构造时无 engine 上下文）：
// 主题联动由消费方（QoolBox/QoolBGBox 等）在实例化处显式绑定 Style 字段
// 实现（现状模式
// `settings: QoolBoxSettings { borderWidth: Style.controlBorderWidth; ... }`）。
//
// 引用语义（文档契约）：QObject 引用——`qbox1.settings: qbox2.settings`
// 共享同一实例（字段绑定/动画作用于共享对象）；独立副本 = 新建实例赋值。
class QoolBoxSettings : public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit QoolBoxSettings(QObject* parent = nullptr);

  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, cutSizeTL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, cutSizeTR)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, cutSizeBL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, cutSizeBR)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, borderWidth)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, QColor, borderColor)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, QColor, fillColor)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, offsetX)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, offsetY)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, bool, curved)
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_SETTINGS_H
