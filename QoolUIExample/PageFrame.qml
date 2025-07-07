import QtQuick
import QtQuick.Layouts
import Qool.Controls
import Qool.Controls.Components
import Qool

BasicControlFrame {
    id: root

    property url page_url

    backgroundSettings {
        fillColor: Style.window
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
            topPadding: 2
            rightPadding: 2
        }
        BasicDecorativeText {
            text: pCtrl.note
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: Math.min(parent.width, implicitWidth)
            rightPadding: 2
            leftPadding: 2
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
            width: main.contentWidth
            source: root.page_url
            onLoaded: {
                pCtrl.title = item.title
                pCtrl.note = item.note
                item.viewBox = main
                root.pageLoaded()
                main.contentY = 0
            }
        }
    } //contentItem
}
