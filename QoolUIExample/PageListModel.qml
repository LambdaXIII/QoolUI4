// pragma Singleton

import QtQuick
import QtQml.Models

ListModel {
    ListElement {
        title: qsTr("欢迎")
        note: qsTr("欢迎使用 QoolUI")
        page: "Page_Welcome.qml"
    }

    ListElement {
        title: qsTr("酷酷的按钮")
        note: qsTr("先从最简单的按钮开始吧！")
        page: "Page_Buttons.qml"
    }

    ListElement {
        title: qsTr("酷酷的 BOX")
        note: qsTr("QoolUI 4 完全重做了经典的切角矩形。")
        page: "Page_QoolBox.qml"
    }

    ListElement {
        title: qsTr("基本输入控件")
        note: qsTr("定制的基础输入控件")
        page: "Page_InputControls.qml"
    }

    ListElement {
        title: qsTr("输入控件（二）")
        note: qsTr("Slider 与 Dial——滑块与转盘")
        page: "Page_InputControls2.qml"
    }

    ListElement {
        title: qsTr("颜色控件")
        note: qsTr("操纵颜色的模块")
        page: "Page_Color.qml"
    }

    ListElement {
        title: qsTr("文件系统")
        note: qsTr("一些和文件系统交互的控件")
        page: "Page_QoolFile.qml"
    }

    ListElement {
        title: qsTr("试炼场")
        note: qsTr("测试空间")
        page: "Page_Playground.qml"
    }
}
