import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls

Control {
    id: root

    contentItem: Flow {
        ActionInstantiator {
            Action {
                text: qsTr("全选")
            }
            Action {
                text: qsTr("反选")
            }
            Action {
                text: qsTr("取消选择")
            }
            Action {
                text: qsTr("移除选择")
            }
            Action {
                text: qsTr("移除所有")
            }
        }
    }//contentItem
}
