import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qool
import Qool.Controls

BasicPage {
    id: root

    title: qsTr("欢迎")
    note: qsTr("欢迎使用 QoolUI 4! ")

    ColumnLayout {
        anchors.centerIn: parent

        Image {
            source: "qrc:/qoolui/assets/qoolui_color.svg"
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 250
        }

        Item {
            Layout.preferredHeight: 50
        }

        Text {
            text: qsTr("欢迎探索来到酷酷的世界")
            font.pixelSize: 36
            color: Style.text
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        Item {
            Layout.preferredHeight: 150
        }

        LinkButton {
            text: "LambdaXIII/QoolUI4"
            url: "https://github.com/LambdaXIII/QoolUI4"
            Layout.alignment: Qt.AlignHCenter
        }
        Item {
            Layout.preferredHeight: 100
        }
    }//column
}
