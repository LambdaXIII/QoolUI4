#ifndef QOOL_QOOLBOX_SETTINGS_H
#define QOOL_QOOLBOX_SETTINGS_H

#include "qool_qoolbox_settings_base.h"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

// QoolBox 外观设置（QML 面类型，QML_ELEMENT 注册、可实例化）。
//
// 双类型结构（ADR-0005 + spec D2 fallback 定案）：全部 9 属性定义与默认值
// 在基类 QoolBoxSettingsBase（QML_UNCREATABLE 注册——QML 中类型名可见但
// 不可实例化，供 `settings` 属性类型解析；见 base 头注释）；本类仅承载
// QML 注册（可实例化）与继承暴露。类型默认值为 C++ 常量（fallback：无
// Style 默认）——主题联动由消费方（QoolBox/QoolBGBox 等）在实例化处显式
// 绑定 Style 字段实现（现状模式
// `settings: QoolBoxSettings { borderWidth: Style.controlBorderWidth; ... }`）。
//
// 引用语义（QDoc 契约）：QObject 引用——`qbox1.settings: qbox2.settings`
// 共享同一实例（字段绑定/动画作用于共享对象）；独立副本 = 新建实例赋值。
class QoolBoxSettings : public QoolBoxSettingsBase {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit QoolBoxSettings(QObject* parent = nullptr);
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_SETTINGS_H
