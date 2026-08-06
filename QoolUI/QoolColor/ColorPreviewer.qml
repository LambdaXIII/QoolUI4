pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype ColorPreviewer
    \inqmlmodule Qool.Color
    \brief 当前色预览 + 前景色对比（v3 ColorPreviewer 迁移）。

    圆角预览面：左半为去 alpha 的实色（solidColor），右半为带 alpha 的
    原色（上半透明衬底、下半白色衬底）——直观显示半透明色与浅色背景的
    混合效果。外圈 1px 圆角边框为前景对比色，随颜色明暗自动取黑/白。

    \section1 结构（v3 对照）

    \list
    \li 左半：\c solidColor 实色（alpha 已剥离）。
    \li 右半：\c color（含 alpha）；上半透明衬底、下半白色衬底——
        alpha 透明度的两段演示（默认实例 alpha 0.5 时可见）。
    \li v3 的黑色衬底路径被不透明左半完全遮挡（不可见死代码），
        v4 不迁移。
    \endlist

    \section1 前景色对比（易误解，特别说明）

    边框颜色是 \c colorAssistant.recommendedForegroundColor——\b 不是
    主题描边色（Style.controlBorderColor），而是 \l ColorAssistant 按
    亮度阈值（0.299/0.587/0.114）派生的前景色：深色预览配白边框、浅色
    预览配黑边框。实现委托 \l {ThemeDB}{ThemeDB.recommendForeground}
    （v3 \c Style.recommendedForegroundColor 的对位）。

    \section1 默认状态自洽

    默认 \c colorAssistant 自带默认色
    \c {ColorAssistant { color: Qt.alpha(Style.highlight, 0.5) }}——
    独立使用（不注入）即成立，无需外部上下文。

    \section1 尺寸

    本组件不设默认尺寸（v3 同）：宿主决定宽高，如示例页
    \c Layout.preferredHeight: 80、色槽背景 \c implicitHeight: 30
    （\l ColorBankSlotButton 以本件为背景，radius 5）。独立使用时须
    显式设置尺寸。

    \section1 属性

    \qmlproperty ColorAssistant ColorPreviewer::colorAssistant
    预览数据源（v3 同名 API 照迁）。注入后预览与边框即时跟随
    （属性绑定）。

    \qmlproperty real ColorPreviewer::radius
    圆角半径，默认 10。

    \section1 用途参考

    宿主可将本件用作颜色 Popup/卡片背景，前景色文字用
    \c colorAssistant.recommendedForegroundColor 保证可读（v3
    Page_Color 用法）。
*/
Item {
    id: root

    // 默认状态自洽：默认实例自带默认色，独立使用成立（v3 同构）。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Qt.alpha(Style.highlight, 0.5)
    }

    property real radius: 10

    Shape {
        id: mainShape
        anchors.fill: parent

        // 右下衬底：半透明色与白色背景的混合效果（v3 whiteBg）。
        ShapePath {
            id: whiteUnderlay
            startX: root.width / 2
            startY: root.height / 2
            PathLine {
                x: root.width
                y: root.height / 2
            }
            PathLine {
                x: root.width
                y: root.height - root.radius
            }
            PathArc {
                x: root.width - root.radius
                y: root.height
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: root.width / 2
                y: root.height
            }
            PathLine {
                x: root.width / 2
                y: root.height / 2
            }
            strokeColor: "transparent"
            fillColor: "white"
        } //whiteUnderlay

        // 左半：实色（去 alpha）。
        ShapePath {
            id: leftPath
            startX: root.width / 2
            startY: 0
            PathLine {
                x: root.width / 2
                y: root.height
            }
            PathLine {
                x: root.radius
                y: root.height
            }
            PathArc {
                x: 0
                y: root.height - root.radius
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: 0
                y: root.radius
            }
            PathArc {
                x: root.radius
                y: 0
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: root.width / 2
                y: 0
            }
            fillColor: root.colorAssistant.solidColor
            strokeWidth: 0
            strokeColor: "transparent"
        } //leftPath

        // 右半：带 alpha 的原色（上半透明衬底、下半白衬底）。
        ShapePath {
            id: rightPath
            startX: root.width / 2
            startY: root.height
            PathLine {
                x: root.width / 2
                y: 0
            }
            PathLine {
                x: root.width - root.radius
                y: 0
            }
            PathArc {
                x: root.width
                y: root.radius
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: root.width
                y: root.height - root.radius
            }
            PathArc {
                x: root.width - root.radius
                y: root.height
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: root.width / 2
                y: root.height
            }
            fillColor: root.colorAssistant.color
            strokeWidth: 0
            strokeColor: "transparent"
        } //rightPath
    } //mainShape

    // 前景色对比：1px 圆角边框 = recommendedForegroundColor（明暗自动黑/白）。
    Rectangle {
        id: borderBox
        anchors.fill: parent
        radius: root.radius
        border.width: 1
        color: "transparent"
        border.color: root.colorAssistant.recommendedForegroundColor
    } //borderBox
}
