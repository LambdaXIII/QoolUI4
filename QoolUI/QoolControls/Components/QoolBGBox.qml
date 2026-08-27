import QtQuick
import Qool

QoolBox {
    id: root

    property string title

    //label应该自己控制相对位置和visible
    property Item titleItem: BasicControlTitleText {
        parent: root //非必须
        text: root.title
        visible: text && text !== ""
        color: root.settings.borderColor
        anchors {
            top: parent.top
            right: parent.right
            topMargin: contentBox.borderSpace
            rightMargin: contentBox.borderSpace + root.settings.cutSizeTR
            leftMargin: contentBox.borderSpace + root.settings.cutSizeTL
        }
    }

    readonly property alias contentBoundingRect: contentBox.boundingRect
    readonly property alias topSpace: contentBox.topSpace
    readonly property alias leftSpace: contentBox.borderSpace
    readonly property alias rightSpace: contentBox.borderSpace
    readonly property alias bottomSpace: contentBox.borderSpace

    settings: QoolBoxSettings {
        borderWidth: Style.controlBorderWidth
        borderColor: Style.controlBorderColor
        fillColor: Style.controlBackgroundColor
        cutSizeTL: Style.controlCutSize
    }

    DummyItem {
        id: contentBox

        readonly property real borderSpace: root.settings.borderWidth + 1

        readonly property bool hasLabel: root.titleItem?.visible ?? false

        //label所占空间
        readonly property real implicitLabelHeight: root.titleItem?.implicitHeight ?? 0
        readonly property real implicitLabelWidth: root.titleItem?.implicitWidth ?? 0

        //上下两端可用空间
        readonly property real labelTopSpace: hasLabel ? (root.titleItem.y + root.titleItem.height) : 0

        readonly property real topSpace: Math.max(labelTopSpace, root.settings.cutSpaceOnTop) + borderSpace
        readonly property real bottomSpace: root.settings.cutSpaceOnBottom + borderSpace

        //contentBox 用于测量参考空间坐标，不参与提供implicitSizes
        x: borderSpace
        y: topSpace
        width: root.width - borderSpace * 2
        height: root.height - topSpace - bottomSpace
    }

    Binding {
        when: root.titleItem
        target: root.titleItem
        property: "parent"
        value: root
    }

    implicitHeight: {
        let impLabelSpace = root.titleItem ? (root.titleItem.y + root.titleItem.implicitHeight) : 0;
        return Math.max(impLabelSpace, root.settings.cutSpaceOnTop);
    }

    implicitWidth: {
        let cutw = root.settings.cutSpaceOnLeft + root.settings.cutSpaceOnRight;
        let labelW = root.titleItem ? root.titleItem.implicitWidth : 0;
        return Math.max(cutw, labelW);
    }
}
