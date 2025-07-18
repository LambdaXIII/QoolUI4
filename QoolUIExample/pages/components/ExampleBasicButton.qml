import QtQuick
import Qool.Controls.Components

BasicButton {
    id: root
    title: qsTr("自定义的按钮")

    contentItem: PaPaWall {
        id: wall
        words: [qsTr("欢迎使用QoolUI!"), qsTr("我是一块砖！"), qsTr("垂死病中惊坐起"), qsTr("笑问客从何处来"),
            qsTr("快点我！"), qsTr("Look in my eyes!")]

        highColor: {
            if (root.down)
                return Style.positive;
            if (root.hovered)
                return Style.highlight;
            return Style.accent;
        }

        textSizeMode: PaPaWall.SmallerTextSize
        text: qsTr("点我试试？")
        clip: true
        font.pixelSize: Style.importantTextSize
    }
    onClicked: wall.refresh()
    QoolTip {
        //% "介绍 BasicButton 货 papa words"
        text: qsTrId("qooltip-basicbutton-example")
    }
}
