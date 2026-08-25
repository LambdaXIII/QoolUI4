import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qool
import Qool.Color
import Qool.Controls
import "components"

BasicPage {
    id: root

    title: qsTr("颜色控件")
    note: qsTr("操纵颜色的模块")

    implicitHeight: cc.implicitHeight

    Component.onCompleted: mainColor.color = Style.highlight

    // 共享颜色源：全页唯一 ColorAssistant，四面板/预览器绑定它，
    // picker/editor 经 Connections 双向同步。
    ColorAssistant {
        id: mainColor
    }

    Column {
        id: cc
        spacing: 20

        BasicControl {
            contentPadding: 4
            contentItem: ColorPreviewer {
                colorAssistant: mainColor
                width: 300
                height: 120
                ColorNameEdit {
                    PropertySync {
                        target1: mainColor
                        property1: "color"
                        target2: parent
                        property2: "value"
                    }
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    horizontalAlignment: Text.AlignLeft
                    color: ThemeHQ.recommendForeground(value)
                }
            }

            title: qsTr("简单的色彩操作")
        }//topRow

        GridLayout {
            columns: 2
            columnSpacing: 12
            rowSpacing: 12
            LayoutItemProxy {
                target: colorSelectingPanelsControl
                Layout.rowSpan: 2
            }
            LayoutItemProxy {
                target: colorNameListViewControl
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
            LayoutItemProxy {
                target: colorBankPanelControl
            }
        }
    }//cc

    BasicControl {
        id: colorSelectingPanelsControl
        contentPadding: 4
        contentItem: GridLayout {
            columns: 2
            columnSpacing: 16
            rowSpacing: 8
            ColorQuickPicker {
                PropertySync {
                    target1: mainColor
                    property1: "color"
                    target2: parent
                    property2: "color"
                }
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.preferredHeight: 50
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                ColorChannelEdit {
                    colorAssistant: mainColor
                    channel: ColorHQ.Alpha
                    Layout.fillWidth: true
                }
                ColorChannelVerticalSlider {
                    colorAssistant: mainColor
                    channel: ColorHQ.Alpha
                    orientation: Qt.Horizontal
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                }
            }

            HSVPanel {
                colorAssistant: mainColor
            }
            HSLPanel {
                colorAssistant: mainColor
            }
            RGBPanel {
                colorAssistant: mainColor
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.preferredHeight: 100
            }
            CMYKPanel {
                colorAssistant: mainColor
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.preferredHeight: 100
            }
        }
        title: qsTr("多种颜色选取面板")
    }

    BasicControl {
        id: colorNameListViewControl
        contentPadding: 4
        ButtonGroup {
            id: catGroup
        }

        contentItem: SplitView {
            Column {
                Repeater {
                    model: ColorHQ.categories()
                    ClickableText {
                        text: modelData
                        checkable: true
                        checked: model.index === 0
                        ButtonGroup.group: catGroup
                    }
                }
            }

            ColorNameListView {
                clip: true
                ScrollIndicator.vertical: ScrollIndicator {}
                category: catGroup.checkedButton.text
                onCurrentColorChanged: mainColor.color = currentColor
                SplitView.fillWidth: true
                SplitView.preferredHeight: 400
                SplitView.preferredWidth: 200
            }
        }
        title: qsTr("插件提供色彩名数据库")
    }

    BasicControl {
        id: colorBankPanelControl
        title: qsTr("颜色银行")
        contentPadding: 8
        Settings {
            id: colorBankSettings
        }

        ColorBank {
            id: colorBank
            Component.onCompleted: {
                for (let i = 0; i < 24; i++) {
                    let color = colorBankSettings.value(i);
                    if (color)
                        colorBank.setCellColor(i, color);
                }
                console.log("ColorBank colors restored!");
            }
            onCellColorUpdated: i => {
                let color = colorBank.cellColor(i);
                colorBankSettings.setValue(i, color);
                console.log("Cell", i, "color updated to", color);
            }
        }

        contentItem: ColorBankPanel {
            id: colorBankPanel
            colorBank: colorBank
            PropertySync {
                target1: mainColor
                property1: "color"
                target2: parent
                property2: "color"
            }
        }
    }
}
