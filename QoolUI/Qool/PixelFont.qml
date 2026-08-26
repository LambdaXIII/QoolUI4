pragma Singleton

import QtQuick

FontLoader {
    id: root
    source: "qrc:/qoolui/assets/UnifontExMono.ttf"
    readonly property string family: font.family

    property font normal
    normal {
        family: root.font.family
        pixelSize: 16
    }
}
