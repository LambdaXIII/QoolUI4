import QtQuick
import Qool
import "_private"

//超低级API
Item {
    id: root
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    //必选
    required property color color
    required property string colorName
    //状态
    property bool highlighted: false
    //options
    property color borderColor: ThemeHQ.recommendForeground(root.color)
    property color textColor: Style.buttonText
    property real spacing: 8
    property real indicatorShrinkSize: 4

    property alias font: nameText.font

    SmartObject {
        id: pCtrl
        readonly property color foregroundColor: ThemeHQ.recommendForeground(root.color)
        DummyItem {
            id: smallBox
            height: nameText.implicitHeight - root.indicatorShrinkSize * 2
            width: height
            x: root.indicatorShrinkSize
            y: (root.height - height) / 2
        }

        DummyItem {
            id: bigBox
            width: root.width
            height: root.height
        }
    }//pCtrl

    ColorNumText {
        id: nameText
        color: root.highlighted ? root.borderColor : root.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        text: root.colorName
        leftPadding: 4
        rightPadding: 4
        topPadding: 2
        bottomPadding: 2
        y: (parent.height - height) / 2
        x: {
            if (root.highlighted)
                return 0;
            else
                return smallBox.x + smallBox.width + root.spacing;
        }
        BasicNumberBehavior on x {
            enabled: root.animationEnabled
            easing.type: Easing.InOutQuart
            duration: Style.movementDuration
        }
    }

    Rectangle {
        z: -1
        GeoLocker {
            target: parent
            lockTo: root.highlighted ? bigBox : smallBox
        }
        color: root.color
        border.width: 1
        border.color: root.borderColor
        BasicNumberBehavior on x {
            enabled: root.animationEnabled
            easing.type: Easing.OutElastic
            duration: Style.movementDuration * 2
        }
        BasicNumberBehavior on y {
            enabled: root.animationEnabled
            easing.type: Easing.OutElastic
            duration: Style.movementDuration * 2
        }
        BasicNumberBehavior on width {
            enabled: root.animationEnabled
            easing.type: Easing.OutElastic
            duration: Style.movementDuration * 2
        }
        BasicNumberBehavior on height {
            enabled: root.animationEnabled
            easing.type: Easing.OutElastic
            duration: Style.movementDuration * 2
        }
        BasicColorBehavior on color {
            enabled: root.animationEnabled
        }
        BasicColorBehavior on border.color {
            enabled: root.animationEnabled
        }
    }

    implicitWidth: smallBox.x + smallBox.width + root.spacing * 2 + nameText.implicitWidth
    implicitHeight: nameText.implicitHeight
}
