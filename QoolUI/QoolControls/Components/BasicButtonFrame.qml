import QtQuick
import QtQuick.Templates as T
import Qool

T.AbstractButton {
    id: root

    property bool showTitle: false
    property string title: qsTr("Qool Button")
    property color backgroundColor: palette.button
    property color borderColor: palette.midlight

    property Component titleComponent: BasicControlTitleText {
        color: root.borderColor
    }
    readonly property alias titleLoader: titleLoader

    property OctagonSettings backgroundSettings: OctagonSettings {
        cutSize: Style.controlCutSize
        borderWidth: Style.controlBorderWidth
        borderColor: root.borderColor
        fillColor: root.backgroundColor
    }
    readonly property alias backgroundShapeControl: bgShape.shapeControl

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
            margins: root.backgroundSettings.borderWidth
        }
        Binding {
            target: titleLoader.item
            property: "text"
            value: root.title
            when: root.showTitle && titleLoader.item
        }
    }

    containmentMask: background
}
