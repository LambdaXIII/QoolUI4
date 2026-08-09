import QtQuick
import QtQuick.Templates as T
import QtQuick.Layouts

/*!
    \qmltype IndexIndicator
    \inqmlmodule Qool.Controls.Components
    \brief 指示当前索引的圆点指示器（ComboBox 等控件的 indicator 用）。

    \c model 提供点位数量，\c currentIndex 高亮对应位（默认 -1 全不高亮）；
    \c delegate 可整体替换点位外观，默认为 4x4 圆点（高亮色/普通色，
    高亮位不透明，普通位 0.35 透明度）。\c implicitDelegateWidth/
    \c implicitDelegateHeight 调整默认点位尺寸。\c orientation 决定排布
    方向（默认 Qt.Vertical）。

    \section2 单列/单行按 count 排布（刻意设计）
    纵向（Qt.Vertical）时固定 \c columns 为 1、按 count 向下排布；
    横向（Qt.Horizontal）时固定 \c rows 为 1、向右排布。此前 rows 曾
    绑定 grid.height、columns 绑定 grid.width，形成自引用环（高度→行数
    →高度），绑定循环求值不稳定；固定单列/单行同时保证 delegate
    行高/列宽自适应，等宽覆盖场景可独立使用。
*/

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
            // 居中排布（修复 2026-08-10）：此前裸 Grid 从内容区左上排布，
            // ComboBox 拉满全高时圆点列偏上 ~3.5px——anchors.centerIn 使
            // 圆点列在内容区垂直/水平居中
            anchors.centerIn: parent
            // flow: Grid.TopToBottom
            layoutDirection: root.mirrored ? Qt.LeftToRight : Qt.RightToLeft

            Repeater {
                id: repeater
                delegate: root.delegate
            }

            // rows: Math.floor(grid.height / root.implicitDelegateHeight)
            columnSpacing: 1
            rowSpacing: 1

            Binding {
                when: root.orientation === Qt.Vertical
                grid.flow: Grid.TopToBottom
                // 固定单列、按 count 向下排布。此前 rows 绑定 grid.height
                // 形成自引用环（高度→行数→高度），绑定循环求值不稳定；
                // 单列同时保证 delegate 行高自适应（等宽覆盖场景独立可用）。
                grid.columns: 1
            }

            Binding {
                when: root.orientation === Qt.Horizontal
                grid.flow: Grid.LeftToRight
                // 固定单行、按 count 向右排布，理由同上（columns 绑定
                // grid.width 自引用）。
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
