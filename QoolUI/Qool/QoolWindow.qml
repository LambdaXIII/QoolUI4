pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import "_private"

QoolWindowBasic {
    id: root

    property bool showCloseButton: true

    readonly property QtObject dummyItems: QtObject {
        property alias titleItem: dummyTitleItem
        property alias toolBar: dummyToolBar
        property alias header: dummyHeader
        property alias content: dummyContent
        property alias footer: dummyFooter
    }

    Loader {
        id: closeButtonLoader
        sourceComponent: QoolWindowCloseButton {
            windowCutSize: root.backgroundSettings.cutSize
            onClicked: root.close()
            visible: root.active
        }
        active: root.showCloseButton
    }

    property Item titleItem: QoolWindowTitleItem {
        text: root.title
    }
    property Item toolBar: Item {}
    property Item header: Item {}
    property Item content: Item {}
    property Item footer: Item {}

    property real topPadding: 0
    property real bottomPadding: topPadding
    property real leftPadding: 0
    property real rightPadding: leftPadding
    property real elementSpacing: QoolConstants.windowElementSpacing
    property real edgeSpacing: QoolConstants.windowEdgeSpacing

    DummyItem {
        id: dummyTitleItem
        objectName: "dummyTitle"
        width: root.titleItem.implicitWidth
        height: {
            const prefered_height = root.titleItem.implicitHeight;
            const min_height = root.backgroundSettings.cutSize - y;
            return Math.max(prefered_height, min_height);
        }
        x: root.width - root.edgeSpacing - width
        y: root.edgeSpacing
        Binding {
            when: root.titleItem
            root.titleItem.x: dummyTitleItem.x
            root.titleItem.y: dummyTitleItem.y
            root.titleItem.width: dummyTitleItem.width
            root.titleItem.height: dummyTitleItem.height
            root.titleItem.parent: root.contentItem
        }
    }//dummyTitleItem

    DummyItem {
        id: dummyToolBar
        objectName: "dummyToolBar"
        x: root.backgroundSettings.cutSize + root.elementSpacing
        y: root.edgeSpacing
        width: root.width - dummyToolBar.x - root.elementSpacing - dummyTitleItem.x
        height: {
            const prefered_height = dummyTitleItem.height;
            const preffered_min_height = root.backgroundSettings.cutSize - dummyToolBar.y;
            return Math.max(root.toolBar.implicitHeight, Math.min(prefered_height, preffered_min_height));
        }
        Binding {
            when: root.toolBar
            root.toolBar.x: dummyToolBar.x
            root.toolBar.y: dummyToolBar.y
            root.toolBar.width: dummyToolBar.width
            root.toolBar.height: dummyToolBar.height
            root.toolBar.parent: root.contentItem
        }
    }//dummyToolBar

    DummyItem {
        id: dummyHeader
        objectName: "dummyHeader"
        x: root.leftPadding + root.edgeSpacing
        y: dummyToolBar.y + dummyToolBar.height + Math.max(root.elementSpacing, root.edgeSpacing)
        width: root.width - root.leftPadding - root.edgeSpacing * 2 - root.rightPadding
        height: root.header?.height ?? 0
        Binding {
            when: root.header
            root.header.x: dummyHeader.x
            root.header.y: dummyHeader.y
            root.header.width: dummyHeader.width
            //leave the height control to itself
            root.header.parent: root.contentItem
        }
    }//dummyHeader

    DummyItem {
        id: dummyFooter
        objectName: "dummyFooter"
        x: root.leftPadding + root.edgeSpacing + root.backgroundSettings.cutSizeBL
        y: root.height - root.edgeSpacing - height
        width: root.width - root.leftPadding - root.edgeSpacing * 2 - root.rightPadding - root.backgroundSettings.cutSizeBL - root.backgroundSettings.cutSizeBR
        height: {
            const preferred_height = root.footer?.implicitHeight ?? 0;
            return Math.max(preferred_height, root.backgroundSettings.cutSizeBL, root.backgroundSettings.cutSizeBR);
        }
        Binding {
            when: root.footer
            root.footer.x: dummyFooter.x
            root.footer.y: dummyFooter.y
            root.footer.width: dummyFooter.width
            root.footer.height: dummyFooter.height
            root.footer.parent: root.contentItem
        }
    }//dummyFooter

    DummyItem {
        id: dummyContent
        objectName: "dummyContent"
        x: root.leftPadding + root.edgeSpacing
        y: dummyHeader.y + dummyHeader.height + root.elementSpacing
        width: root.width - root.leftPadding - root.edgeSpacing * 2 - root.rightPadding
        height: dummyFooter.y - y - root.elementSpacing
        Binding {
            when: root.content
            root.content.x: dummyContent.x
            root.content.y: dummyContent.y
            root.content.width: dummyContent.width
            root.content.height: dummyContent.height
            root.content.parent: root.contentItem
        }
    }
}
