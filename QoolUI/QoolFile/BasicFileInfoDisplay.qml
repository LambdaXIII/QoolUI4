import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Qool
import Qool.File
import Qool.Controls.Components

Control {
    id: root

    property fileinfo fileInfo
    property bool checked: false

    hoverEnabled: true
    padding: 2

    QtObject {
        id: pCtrl
        property color textColor: {
            if (!root.fileInfo.isValid())
                return root.Style.negative;
            if (root.checked)
                return root.Style.highlightedText;
            if (root.hovered)
                return root.Style.highlight;
            return root.Style.text;
        }

        property color bgColor: {
            if (!root.fileInfo.isValid())
                return Qt.alpha(root.Style.negative, 0.08);
            if (root.checked)
                return root.Style.highlight;
            return "transparent";
        }

        BasicColorBehavior on textColor {}
        BasicColorBehavior on bgColor {}
    }

    contentItem: RowLayout {
        spacing: 4
        Image {
            id: iconImg
            source: root.fileInfo.iconUrl
            Layout.preferredWidth: height
            Layout.preferredHeight: mainText.implicitHeight
        }
        Text {
            id: mainText
            text: root.fileInfo.isValid() ? root.fileInfo.fileName : qsTr("无效文件")
            color: pCtrl.textColor
            elide: Text.ElideMiddle
            wrapMode: Text.NoWrap
            Layout.fillWidth: true
            verticalAlignment: Text.AlignHCenter
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: root.Style.controlTextSize
        }
    }

    background: Rectangle {
        implicitWidth: 10
        implicitHeight: 10
        border.width: 0
        color: pCtrl.bgColor
    }
}
