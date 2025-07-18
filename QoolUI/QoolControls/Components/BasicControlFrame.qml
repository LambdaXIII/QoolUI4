import QtQuick
import QtQuick.Templates as T

import Qool

T.Control {
    id: root

    property bool showTitle: true
    property string title: qsTr("Qool Control")
    property color backgroundColor: Style.base
    property color borderColor: Style.controlBorderColor

    //titleComponent must have a text property
    property Component titleComponent: BasicControlTitleText {
        color: root.borderColor
    }
    readonly property alias titleLoader: titleLoader

    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        cutSize: Style.controlCutSize
        borderWidth: Style.controlBorderWidth
        borderColor: root.borderColor
        fillColor: root.backgroundColor
    }
    readonly property QoolBoxShapeControl backgroundShapeControl: bgShape.shape.control

    background: QoolBox {
        id: bgShape
        settings: root.backgroundSettings
        implicitWidth: 10
        implicitHeight: 10
        z: -90
    }

    property alias contentSpacing: spacer.padding
    property alias contentTopSpacing: spacer.topPadding
    property alias contentBottomSpacing: spacer.bottomPadding
    property alias contentLeftSpacing: spacer.leftPadding
    property alias contentRightSpacing: spacer.rightPadding

    SpaceHelper {
        id: spacer

        readonly property real headerSpace: {
            if (!root.showTitle)
                return 0
            return Math.max(titleLoader.height + titleLoader.anchors.topMargin,
                            root.backgroundSettings.cutSize)
        }
        readonly property real implicitTopPadding: root.topInset + root.backgroundSettings.borderWidth + spacer.headerSpace
        readonly property real implicitLeftPadding: root.leftInset
                                                    + root.backgroundSettings.borderWidth
        readonly property real implicitRightPadding: root.rightInset
                                                     + root.backgroundSettings.borderWidth
        readonly property real implicitBottomPadding: root.bottomInset
                                                      + root.backgroundSettings.borderWidth

        padding: 0
    }

    topPadding: spacer.implicitTopPadding + contentTopSpacing
    leftPadding: spacer.implicitLeftPadding + contentLeftSpacing
    rightPadding: spacer.implicitRightPadding + contentRightSpacing
    bottomPadding: spacer.implicitBottomPadding + contentBottomSpacing

    implicitHeight: topPadding + implicitContentHeight + bottomPadding
    implicitWidth: leftPadding + implicitContentWidth + rightPadding

    Loader {
        id: titleLoader
        z: 20
        active: root.showTitle
        sourceComponent: root.titleComponent
        anchors {
            top: parent.top
            right: parent.right
            topMargin: root.topInset + root.backgroundSettings.borderWidth
            rightMargin: root.rightInset + root.backgroundSettings.borderWidth
        }

        width: {
            // let iw = titleLoader.item ? titleLoader.item.implicitWidth : 0
            let max_w = root.width - root.backgroundSettings.borderWidth * 2
                - root.leftInset - root.rightInset
            return max_w
        }

        Binding {
            target: titleLoader.item
            property: "text"
            value: root.title
            when: root.showTitle && titleLoader.item
                  && titleLoader.item.hasOwnProperty("text")
        }
    }

    containmentMask: background
}
