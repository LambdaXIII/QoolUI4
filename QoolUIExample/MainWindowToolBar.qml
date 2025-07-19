import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls

Flow {
    id: root

    ButtonGroup {
        id: languageGroup
    }

    ToolButton {
        id: zhbutton
        width: 65
        checkable: true
        onCheckedChanged: {
            if (checked && Qt.uiLanguage !== "zh")
                Qt.uiLanguage = "zh"
        }
        text: qsTr("中文")
        ButtonGroup.group: languageGroup
    }

    ToolButton {
        id: enbutton
        width: 65
        checkable: true
        onCheckedChanged: {
            if (checked && Qt.uiLanguage !== "en")
                Qt.uiLanguage = "en"
        }
        text: qsTr("英文")
        ButtonGroup.group: languageGroup
    }

    Component.onCompleted: {
        switch (Qt.uiLanguage) {
        case "zh":
            zhbutton.checked = true
            break
        case "en":
            enbutton.checked = true
            break
        }
    }
}
