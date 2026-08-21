import QtQuick

import Qool
import Qool.Controls.Components

import QtQuick.Controls.Basic as B

B.Tumbler {
    id: root

    font.pixelSize: Style.controlTextSize

    model: 15

    delegate: BasicControlText {
        text: modelData
        font: root.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        opacity: 1.0 - Math.abs(Tumbler.displacement) / (root.visibleItemCount / 2)

        required property var modelData
        required property int index
    }
}
