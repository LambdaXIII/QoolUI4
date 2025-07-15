import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qool.Controls
import Qool.Controls.Components
import Qool
import Qool.Chat
import "pages/components"

BasicControlFrame {
    id: root

    property url page_url

    backgroundSettings {
        fillColor: Style.shadow
    }

    signal pageLoaded

    QtObject {
        id: pCtrl
        property string title
        property string note
    }

    titleComponent: ColumnLayout {
        BasicBigTitleText {
            text: pCtrl.title
            Layout.alignment: Qt.AlignRight
            topPadding: 4
            rightPadding: 6
        }
        BasicDecorativeText {
            text: pCtrl.note
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: Math.min(parent.width, implicitWidth)
            rightPadding: 6
            leftPadding: 6
        }
    }

    contentSpacing: 5

    contentItem: Flickable {
        id: main

        clip: true
        boundsBehavior: Flickable.StopAtBounds
        synchronousDrag: false

        contentWidth: width
        contentHeight: pageLoader.height

        Loader {
            id: pageLoader
            asynchronous: true
            width: main.contentWidth
            source: root.page_url
            onLoaded: {
                pCtrl.title = item.title
                pCtrl.note = item.note
                item.viewBox = main
                root.pageLoaded()
                main.contentY = 0
            }
            QoolTipPanel {}
        }
    } //contentItem

    Popup {
        id: loadingBar
        contentItem: ProgressBar {
            value: pageLoader.progress
            radius: 0
        }
        padding: 0
        background: Item {}
        width: parent.width - Style.controlBorderWidth * 2
        height: 15
        x: Style.controlBorderWidth
        y: parent.height - height - Style.controlBorderWidth
        closePolicy: Popup.NoAutoClose
        popupType: Popup.Item
    }

    Connections {
        target: pageLoader
        function onLoaded() {
            // if (pageLoader.status != Loader.Loading)
            loadingBar.visible = false
        }
    }

    Connections {
        target: root
        function onPage_urlChanged() {
            loadingBar.visible = true
        }
    }
}
