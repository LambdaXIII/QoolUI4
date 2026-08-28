import QtQuick
import QtQuick.Templates as T
import QtQuick.Layouts

//TODO: 重新进行美观性设计+性能设计
T.Control {
    id: root

    property int currentIndex: -1

    property real implicitDelegateWidth: 4
    property real implicitDelegateHeight: 4

    property Component delegate: Rectangle {
        required property int index
        readonly property bool highlighted: index == root.currentIndex
        color: highlighted ? root.Style.highlight : root.Style.buttonText
        opacity: highlighted ? 1 : 0.35
        implicitWidth: root.implicitDelegateWidth
        implicitHeight: root.implicitDelegateHeight
    }

    property alias model: repeater.model

    property int orientation: Qt.Vertical

    // TODO（低优先）：大型模型场景性能优化——Repeater 按模型行数实例化
    // 圆点（数百行 → 数百点位、无 clip 无上限）。不紧急：超大模型大概率
    // 不使用本指示器（仓库当前模型均小）。
    contentItem: Item {
        implicitWidth: grid.implicitWidth
        implicitHeight: grid.implicitHeight

        Grid {
            id: grid
            // 居中排布：anchors.centerIn 使圆点列在内容区垂直/水平居中
            //（裸 Grid 从内容区左上排布，ComboBox 拉满全高时圆点列偏上
            // ~3.5px）
            anchors.centerIn: parent
            layoutDirection: root.mirrored ? Qt.LeftToRight : Qt.RightToLeft

            Repeater {
                id: repeater
                delegate: root.delegate
            }

            columnSpacing: 1
            rowSpacing: 1

            Binding {
                when: root.orientation === Qt.Vertical
                grid.flow: Grid.TopToBottom
                // 固定单列、按 count 向下排布——避免 rows↔grid.height 自引用环
                // （绑定循环求值不稳定）；单列保证 delegate 行高自适应
                grid.columns: 1
            }

            Binding {
                when: root.orientation === Qt.Horizontal
                grid.flow: Grid.LeftToRight
                // 固定单行、按 count 向右排布（columns↔grid.width 同理）
                grid.rows: 1
            }
        }
    }

    background: Item {
        implicitWidth: 4
        implicitHeight: 20
    }

    padding: 6

    implicitWidth: {
        let w1 = leftPadding + implicitContentWidth + rightPadding;
        let w2 = leftInset + implicitBackgroundWidth + rightInset;
        return Math.max(w1, w2);
    }
    implicitHeight: {
        let h1 = topPadding + implicitContentHeight + bottomPadding;
        let h2 = topInset + implicitBackgroundHeight + bottomInset;
        return Math.max(h1, h2);
    }
}
