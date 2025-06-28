import QtQuick
import QtQuick.Window
import Qool

Item {
    id: root

    property QoolWindow window: Window.window
    property color color: "purple"

    property alias showTitleItem: titleItem.visible
    property alias showToolBar: toolBar.visible
    property alias showHeader: header.visible
    property alias showContent: content.visible
    property alias showFooter: footer.visible

    RectIndicator {
        id: titleItem
        name: "titleItem"
        anchors.fill: parent
        parent: root.window.titleItem
        color: root.color
        showPosition: false
        showSize: false
    }

    RectIndicator {
        id: toolBar
        name: "toolBar"
        anchors.fill: parent
        parent: root.window.toolBar
        color: root.color
        showPosition: false
        showSize: false
    }

    RectIndicator {
        id: header
        name: "header"
        anchors.fill: parent
        parent: root.window.header
        color: root.color
        showPosition: false
        showSize: false
        showName: root.window.header.height > 20
    }

    RectIndicator {
        id: content
        name: "content"
        anchors.fill: parent
        parent: root.window.content
        color: root.color
        showPosition: true
        showSize: true
    }

    RectIndicator {
        id: footer
        name: "footer"
        anchors.fill: parent
        parent: root.window.footer
        color: root.color
        showPosition: false
        showSize: false
        showName: root.window.footer.height > 20
    }
}
