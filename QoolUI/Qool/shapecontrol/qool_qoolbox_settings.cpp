/*!
    \qmltype QoolBoxSettings
    \inqmlmodule Qool
    \nativetype qoolui::QoolBoxSettings
    \brief 八边形外观设置（四角切角/边框/填充/偏移/圆角开关）。

    QoolBox 的形状与外观统一配置入口。属性定义在 C++ 基类
    QoolBoxSettingsBase（QML_UNCREATABLE 注册——QML 中类型名可见但不可
    实例化，供 \c settings 属性类型解析与子类检查）；本类型承载 QML
    注册（可实例化），宿主以 \c settings 属性访问：
    \qml
    QoolBox {
        settings {
            cutSizeTL: 12
            cutSizeTR: 12
            cutSizeBL: 12
            cutSizeBR: 12
            borderWidth: 2
            borderColor: "white"
            fillColor: "black"
            offsetX: 0
            offsetY: 0
            curved: true
        }
    }
    \endqml

    全部属性可绑定（如 \c settings.borderWidth: slider.value）与动画
    （Behavior/NumberAnimation 作用于字段）。

    \section1 引用语义

    settings 是 QObject 引用语义：
    \list
    \li \c qbox1.settings: qbox2.settings 共享同一实例——字段级绑定与动画
        作用于共享对象，一处修改全量生效；
    \li 独立副本 = 新建实例赋值（互不影响）。
    \endlist

    \section1 默认值

    类型默认值为 C++ 常量（cutSize*: 0、borderWidth: 0、borderColor:
    \c red、fillColor: \c yellow、offsetX/Y: 0、curved: \c false）——
    主题联动默认由消费方（QoolBox、QoolBGBox 等）在实例化处显式绑定
    Style 字段实现：宿主直接实例化即得当前主题外观，可覆盖个别字段。
*/
#include "qool_qoolbox_settings.h"

QOOL_NS_BEGIN

QoolBoxSettings::QoolBoxSettings(QObject* parent)
  : QoolBoxSettingsBase { parent } {
}

QOOL_NS_END
