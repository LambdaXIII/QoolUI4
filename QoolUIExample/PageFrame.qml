import QtQuick
import QtQuick.Layouts
import Qool.Controls
import Qool.Controls.Components
import Qool

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
        }
    } //contentItem
}
