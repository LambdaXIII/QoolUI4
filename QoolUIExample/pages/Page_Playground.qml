// SpinBox 展示页：Qool.Controls 重写的数值步进器（int/double 一体，裸控件——
// 无内置背景壳；QoolControl 包装用法待验证，本页直接裸展示）。
//
// 演示内容：
//   1. 整数步进（decimals: 0 + stepSize: 1）
//   2. 小数步进（默认 decimals 2；自定义 decimals/stepSize）
//   3. 可编辑模式（editable: true，点击内容区覆盖编辑，Enter/失焦提交）
//   4. 禁用态（enabled: false，展示 ControlLockedCover）
//   5. 能力钩子：currentValue 覆写、textFromValue 自定义显示格式
//   6. wrap 回环
// 官方 API（from/to/stepSize/decimals/value/wrap/editable）与 Qool 新增
// 属性（horizontalAlignment/verticalAlignment/currentValue）均可用。
import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import Qool.Controls.Components

import "components"

BasicPage {
    id: root

    title: qsTr("数值步进器")
    note: qsTr("Qool.Controls 重写的 SpinBox（整数/小数步进）")

    implicitHeight: cc.implicitHeight

    Column {
        id: cc

        spacing: 25

        // 1) 整数步进：decimals 0 + stepSize 1
        SpinBox {
            from: 0
            to: 10
            value: 5
            decimals: 0
            stepSize: 1
            QoolTip {
                text: qsTr("整数步进：decimals 0 + stepSize 1")
            }
        }

        // 2) 小数步进：默认 decimals 2（0.00 - 99.99 域）
        SpinBox {
            from: 0
            to: 99.99
            value: 3.14
            QoolTip {
                text: qsTr("默认两位小数：0.00 - 99.99")
            }
        }

        // 2) 小数步进：自定义精度与步长
        SpinBox {
            from: 0
            to: 10
            decimals: 1
            stepSize: 0.5
            QoolTip {
                text: qsTr("自定义步长 0.5、一位小数")
            }
        }

        SectionBar {
            width: parent.width
        }

        // 3) 可编辑模式：editable: true，点击内容区进入覆盖编辑（selectAll 后
        //    键入即整体替换），Enter/失焦提交，校验失败回退原值
        SpinBox {
            editable: true
            from: 0
            to: 100
            value: 42
            QoolTip {
                text: qsTr("editable: true，点击数值进入编辑")
            }
        }

        // 4) 禁用态：展示 ControlLockedCover
        SpinBox {
            enabled: false
            from: 0
            to: 10
            value: 7
            QoolTip {
                text: qsTr("禁用态（enabled: false）")
            }
        }

        SectionBar {
            width: parent.width
        }

        // 5) 钩子：currentValue 默认绑定 value，可被外部覆写
        SpinBox {
            from: 0
            to: 10
            value: 3
            currentValue: value * 10
            QoolTip {
                text: qsTr("currentValue 可覆写（此处为 value * 10）")
            }
        }

        // 5) 钩子：textFromValue 自定义显示格式（官方 function 属性，零代码覆写）
        SpinBox {
            from: 0
            to: 10
            value: 2.5
            textFromValue: function(value, decimals, locale) {
                return Number(value).toLocaleString(locale, "f", decimals) + "x"
            }
            QoolTip {
                text: qsTr("textFromValue 自定义格式（追加 “x” 后缀）")
            }
        }

        // 6) wrap 回环：到达边界后回绕
        SpinBox {
            from: 0
            to: 6
            value: 6
            decimals: 0
            stepSize: 1
            wrap: true
            QoolTip {
                text: qsTr("wrap: true，到达边界后回环")
            }
        }
    } //cc
}
