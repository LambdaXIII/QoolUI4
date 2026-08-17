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
// 单一类型定案（ADR-0005 修订 + spec D2 执行修正的再修正）：最初双类型
// 结构（C++ Base 属性定义处 + QML 派生类绑 Style 默认）被 Qt 6.11 实证
// 否定——QML 文件以 QML_UNCREATABLE 类型为根继承被引擎拒绝（组件根
// creatable 检查，"Type unavailable ... is a probe base type"），"QML 类型
// 继承 Base"不可行；Base 的唯一派生场景死亡后抽象层失去存在意义，故
// 删除 Base、收敛为单一 C++ 类（本类）。无 Base 后 `settings` 属性类型
// 直接为本类（已注册 QML 类型），内联赋值
// （`settings: QoolBoxSettings {...}`）与引用赋值
// （`settings: otherBox.settings`）类型完全匹配，无需 QML_UNCREATABLE
// 基类做属性类型解析——Base 不再出现在 QML 类型系统。
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
