import QtQuick
import Qool

/*!
    \qmltype RectResizer
    \inqmlmodule Qool.Debug
    \brief 六手柄尺寸调整框：拖动手柄调整宿主（父项）的几何。

    调试用装饰控件：六个手柄（Floater content 渲染在 Overlay 层）围绕
    宿主四周——左右手柄调宽、上下手柄调高、四角手柄双向调整（拖动直接
    修改宿主的 x/y/width/height，属调试语义：赋值会破坏宿主既有尺寸
    绑定，宿主自行决定是否可接受）。手柄位置由 Floater 内置
    PositionTracker 自动跟随祖先链变化（平移/缩放/旋转），无需手动刷新。

    \section1 使用

    直接作为目标的子项声明（\c anchors.fill: parent 自动铺满）：

    \qml
    Dial { RectResizer {} }
    \endqml

    手柄外观经 \c color / \c spacing / \c handleWidth 配置。
*/

Item {
    id: root

    property color color: Style.toolTipBase
    property real spacing: 20
    property real handleWidth: 10

    anchors.fill: parent

    // 手柄位置由 Floater 内置 PositionTracker 自动覆盖（逐层监听祖先链：
    // 本组件经 anchors 跟随 root.parent 平移/缩放/旋转均触发重算）——
    // 旧版手动监听 root.parent 几何变化 + refresh() 补偿已移除（集成后
    // 冗余）。
    Floater {
        id: rightFloater
        content: DragMoveArea {
            // autoBind 默认 true：拖动会移动 target（parent=Floater），
            // 与下方 onWannaMove 对 root.parent 的手动调整构成双重驱动
            // （句柄漂移）。句柄只应经 onWannaMove 生效，故显式关闭。
            autoBind: false
            cursorShape: Qt.SizeHorCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
            }
            onWannaMove: (x, _) => {
                             root.parent.width += x
                         }
        }
        width: root.handleWidth
        height: root.height
        x: root.width + root.spacing
    }

    Floater {
        id: leftFloater
        content: DragMoveArea {
            // autoBind 默认 true：拖动会移动 target（parent=Floater），
            // 与下方 onWannaMove 对 root.parent 的手动调整构成双重驱动
            // （句柄漂移）。句柄只应经 onWannaMove 生效，故显式关闭。
            autoBind: false
            cursorShape: Qt.SizeHorCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
            }
            onWannaMove: (x, _) => {
                             root.parent.x += x
                             root.parent.width -= x
                         }
        }
        width: root.handleWidth
        height: root.height
        x: 0 - root.spacing - width
    }

    Floater {
        id: topFloater
        content: DragMoveArea {
            // autoBind 默认 true：拖动会移动 target（parent=Floater），
            // 与下方 onWannaMove 对 root.parent 的手动调整构成双重驱动
            // （句柄漂移）。句柄只应经 onWannaMove 生效，故显式关闭。
            autoBind: false
            cursorShape: Qt.SizeVerCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
            }
            onWannaMove: (_, y) => {
                             root.parent.y += y
                             root.parent.height -= y
                         }
        }
        width: root.width
        height: root.handleWidth
        y: 0 - root.spacing - height
    }

    Floater {
        id: bottomFloater
        content: DragMoveArea {
            // autoBind 默认 true：拖动会移动 target（parent=Floater），
            // 与下方 onWannaMove 对 root.parent 的手动调整构成双重驱动
            // （句柄漂移）。句柄只应经 onWannaMove 生效，故显式关闭。
            autoBind: false
            cursorShape: Qt.SizeVerCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
            }
            onWannaMove: (_, y) => {
                             root.parent.height += y
                         }
        }
        width: root.width
        height: root.handleWidth
        y: root.height + root.spacing
    }

    Floater {
        id: topLeftFloater
        content: DragMoveArea {
            // autoBind 默认 true：拖动会移动 target（parent=Floater），
            // 与下方 onWannaMove 对 root.parent 的手动调整构成双重驱动
            // （句柄漂移）。句柄只应经 onWannaMove 生效，故显式关闭。
            autoBind: false
            cursorShape: Qt.SizeAllCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
                radius: width / 2
            }
            onWannaMove: (x, y) => {
                             root.parent.x += x
                             root.parent.y += y
                         }
        }
        width: root.handleWidth * 1.5
        height: root.handleWidth * 1.5
        x: 0 - root.spacing - width
        y: 0 - root.spacing - height
    }

    Floater {
        id: bottomRightFloater
        content: DragMoveArea {
            // autoBind 默认 true：拖动会移动 target（parent=Floater），
            // 与下方 onWannaMove 对 root.parent 的手动调整构成双重驱动
            // （句柄漂移）。句柄只应经 onWannaMove 生效，故显式关闭。
            autoBind: false
            cursorShape: Qt.SizeFDiagCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
            }
            onWannaMove: (x, y) => {
                             root.parent.width += x
                             root.parent.height += y
                         }
        }
        width: root.handleWidth
        height: root.handleWidth
        x: root.width + root.spacing
        y: root.height + root.spacing
    }
}

/*!
    \qmlproperty color Qool::RectResizer::color
    \brief 手柄颜色。默认取 Style.toolTipBase。
*/

/*!
    \qmlproperty real Qool::RectResizer::spacing
    \brief 手柄与宿主的间距（默认 20）。
*/

/*!
    \qmlproperty real Qool::RectResizer::handleWidth
    \brief 手柄厚度（默认 10）。
*/
