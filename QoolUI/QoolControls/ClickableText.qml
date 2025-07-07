import QtQuick
import QtQuick.Templates as T
import QtQuick.Layouts
import Qool
import Qool.Controls.Components

T.AbstractButton {
    id: root

    property bool animationEnabled: parent?.animationEnabled
                                    ?? Qore.animationEnabled

    property string checkedText: text

    property alias horizontalAlignment: mainText.horizontalAlignment
    property alias verticalAlignment: mainText.verticalAlignment
    property alias elide: mainText.elide

    font.pixelSize: Style.controlTextSize

    property bool showBar: true
    property real barSpacing: 2
    property real barHeight: 2

    contentItem: BasicButtonText {
        id: mainText
        font: root.font
        text: root.text
        color: {
            if (root.down)
                return palette.highlight
            if (root.checked)
                return palette.highlightedText
            return palette.buttonText
        }
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        elide: Text.ElideMiddle
        bottomPadding: root.showBar ? root.barHeight + root.barSpacing : 0
        topPadding: bottomPadding
        HorizontalBar {
            id: bar
            visible: root.showBar
            alignment: root.horizontalAlignment
            color: (root.checked
                    || root.down) ? palette.highlight : palette.buttonText
            percentage: (root.down || root.hovered || root.checked) ? 1 : 0
            width: parent.width
            height: root.checked ? parent.height : root.barHeight
            y: parent.height - height
            z: -20
            BasicNumberBehavior on percentage {
                enabled: root.animationEnabled
                easing.type: Easing.OutBack
            }
            BasicNumberBehavior on height {
                enabled: root.animationEnabled
                duration: Style.transitionDuration
                easing.type: Easing.OutBack
            }
            BasicColorBehavior on color {
                enabled: root.animationEnabled
            }
        }
    }

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding
}
