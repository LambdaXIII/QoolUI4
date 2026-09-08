import QtQuick
import Qool
import Qool.Controls.Components

// DialogSurface：容器无关的对话框表面件（契约见 ADR-0021 与参考文档）。
// 背景为 QoolBGBox（dialog token 组）；header/content/footer 三槽经 DummyItem
// 纵向排布（同 QoolWindow 手法），共同填满背景件报告的内容区。
Item {
    id: root

    property alias title: bgbox.title
    property alias titleItem: bgbox.titleItem

    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        cutSizeTL: root.Style.dialogCutSize
        borderWidth: root.Style.dialogBorderWidth
        borderColor: root.Style.accent
        fillColor: root.Style.window
    }

    property Item header: Item {}
    property Item content: Item {}
    property Item footer: Item {}
    property real spacing: root.Style.windowElementSpacing

    // 三槽纵向填满 BGBox 内容区：header 顶、footer 底、content 取中段
    implicitWidth: Math.max(bgbox.implicitWidth,
                            bgbox.leftSpace + Math.max(root.header.implicitWidth,
                                                       root.content.implicitWidth,
                                                       root.footer.implicitWidth)
                            + bgbox.rightSpace)
    implicitHeight: Math.max(bgbox.implicitHeight,
                             bgbox.topSpace + root.header.height + root.content.implicitHeight
                             + root.footer.height + root.spacing * 2 + bgbox.bottomSpace)

    containmentMask: bgbox

    QoolBGBox {
        id: bgbox
        anchors.fill: parent
        settings: root.backgroundSettings
    }

    DummyItem {
        id: dummyHeader
        objectName: "dummyHeader"
        x: bgbox.leftSpace
        y: bgbox.topSpace
        width: root.width - bgbox.leftSpace - bgbox.rightSpace
        height: root.header ? root.header.height : 0
    }

    DummyItem {
        id: dummyFooter
        objectName: "dummyFooter"
        x: bgbox.leftSpace
        y: root.height - bgbox.bottomSpace - height
        width: root.width - bgbox.leftSpace - bgbox.rightSpace
        height: root.footer ? root.footer.height : 0
    }

    DummyItem {
        id: dummyContent
        objectName: "dummyContent"
        x: bgbox.leftSpace
        y: dummyHeader.y + dummyHeader.height + root.spacing
        width: root.width - bgbox.leftSpace - bgbox.rightSpace
        height: Math.max(0, dummyFooter.y - y - root.spacing)
    }

    Binding {
        when: root.header
        root.header.parent: root
        root.header.x: dummyHeader.x
        root.header.y: dummyHeader.y
        root.header.width: dummyHeader.width
    }

    Binding {
        when: root.footer
        root.footer.parent: root
        root.footer.x: dummyFooter.x
        root.footer.y: dummyFooter.y
        root.footer.width: dummyFooter.width
    }

    Binding {
        when: root.content
        root.content.parent: root
        root.content.x: dummyContent.x
        root.content.y: dummyContent.y
        root.content.width: dummyContent.width
        root.content.height: dummyContent.height
    }
}
