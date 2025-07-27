import QtQuick
import Qool
import Qool.Controls
import Qool.File

import "components"

BasicPage {
    id: root

    title: qsTr("Qool.File 模块")
    note: qsTr("QoolUI 的 File 模块提供了一些用于与文件系统交互的简单组件")

    implicitHeight: cc.implicitHeight

    Column {
        id: cc
        spacing: 25

        FileDropper {
            id: dropper
            title: qsTr("可以把文件丢到这里")
            width: 200
            height: 200
            contentItem: Item {
                SimpleFileItem {
                    id: fileItem
                    preferredIconSize: 64
                    anchors.centerIn: parent
                }
            }

            onAccepted: urls => {
                            let info = FileInfoDB.getFileInfo(urls[0]);
                            fileItem.fileInfo = info;
                        }

            QoolTip {
                //% "介绍FileDropper以及Qool.File的基本原理"
                text: qsTrId("qooltip-filedropper")
            }
        }

        FileInfoListControl {
            id: infoControl
            title: qsTr("文件列表控件")
            width: 400
            height: 600
            QoolTip {
                //% "介绍文件列表控件
                text: qsTrId("qooltip-fileinfolistcontrol")
            }
        }
    }
}
