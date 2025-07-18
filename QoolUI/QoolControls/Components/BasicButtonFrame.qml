import QtQuick
import QtQuick.Templates as T
import Qool

T.AbstractButton {
    id: root

    property bool showTitle: false
    property string title: qsTr("Qool Button")
    property color backgroundColor: Style.button
    property color borderColor: Style.midlight

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
    readonly property alias backgroundShapeControl: bgShape.control

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

        readonly property real topCutSpace: Math.max(
                                                root.backgroundSettings.cutSizeTL,
                                                root.backgroundSettings.cutSiztTR)
        readonly property real bottomCutSpace: Math.max(
                                                   root.backgroundSettings.cutSizeBL,
                                                   root.backgroundSettings.cutSizeBR)
        readonly property real leftCutSpace: Math.max(
                                                 root.backgroundSettings.cutSizeTL,
                                                 root.backgroundSettings.cutSizeBL)
        readonly property real rightCutSpace: Math.max(
                                                  root.backgroundSettings.cutSizeTR,
                                                  root.backgroundSettings.cutSizeBR)

        readonly property real headerSpace: {
            if (!root.showTitle)
                return 0
            return Math.max(titleLoader.height + titleLoader.anchors.topMargin,
                            topCutSpace)
        }

        readonly property real implicitTopPadding: root.topInset + root.backgroundSettings.borderWidth + spacer.headerSpace
        readonly property real implicitLeftPadding: root.leftInset
                                                    + root.backgroundSettings.borderWidth
                                                    + (root.showTitle ? 0 : leftCutSpace)
        readonly property real implicitRightPadding: root.rightInset
                                                     + root.backgroundSettings.borderWidth
                                                     + (root.showTitle ? 0 : rightCutSpace)
        readonly property real implicitBottomPadding: root.bottomInset
                                                      + root.backgroundSettings.borderWidth
                                                      + (root.showTitle ? bottomCutSpace : 0)
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
