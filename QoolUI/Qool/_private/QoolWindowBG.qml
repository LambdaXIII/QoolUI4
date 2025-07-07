import QtQuick
import QtQuick.Window
import Qool

QoolBox {
    id: root

    readonly property Window window: (parent as Window) ?? (Window.window as Window)
    property real resizerSize: 3
    property bool autoBind: true
    property bool forceResizeTopLeftCorner: false

    anchors.fill: parent

    signal wannaMove(real dx, real dy)
    signal wannaResizeLeftEdge(real dx)
    signal wannaResizeRightEdge(real dx)
    signal wannaResizeTopEdge(real dy)
    signal wannaResizeBottomEdge(real dy)
    signal wannaResizeTopRightCorner(real dx, real dy)
    signal wannaResizeBottomLeftCorner(real dx, real dy)
    signal wannaResizeBottomRightCorner(real dx, real dy)
    signal wannaREsizeTopLeftCorner(real dx, real dy)

    settings {
        cutSize: Style.windowCutSize
        borderWidth: Style.windowBorderWidth
        borderColor: Style.accent
        fillColor: Style.window
    }

    QtObject {
        id: pCtrl
        readonly property real resizerSize: Math.max(root.resizerSize, root.settings.borderWidth)
        property bool isResizing: false
        function resizeWindow(dx, dy, dw, dh) {
            if (!root.autoBind)
                return;
            if (isResizing)
                return;
            isResizing = true;

            if (dx)
                root.window.x += dx;
            if (dy)
                root.window.y += dy;
            if (dw)
                root.window.width += dw;
            if (dh)
                root.window.height += dh;

            isResizing = false;
        }
    }

    DragMoveArea {
        id: movingArea
        target: null
        autoBind: false
        containmentMask: root
        z: -10
        anchors.fill: parent
        property bool fallback: false
        onPressed: {
            if (!root.autoBind)
                return;
            let res = root.window.startSystemMove();
            if (!res)
                fallback = true;
            console.debug("window move fallback:", res);
        }
        onWannaMove: (dx, dy) => {
            root.wannaMove(dx, dy);
            if (!fallback)
                return;
            pCtrl.resizeWindow(dx, dy, 0, 0);
        }
        // propagateComposedEvents: true
        // preventStealing: false
    }

    DragMoveArea {
        id: rightResizer
        target: null
        autoBind: false
        width: pCtrl.resizerSize
        height: root.height - pCtrl.resizerSize * 2
        x: root.width - width
        cursorShape: Qt.SizeHorCursor
        property bool fallback: false
        onPressed: {
            if (!root.autoBind)
                return;
            let res = root.window.startSystemResize(Qt.RightEdge);
            if (!res)
                fallback = true;
            console.debug("window resize right edge fallback:", res);
        }
        onWannaMove: (dx, dy) => {
            root.wannaResizeRightEdge(dx);
            if (!fallback)
                return;
            pCtrl.resizeWindow(0, 0, dx, 0);
        }
    }

    DragMoveArea {
        id: leftResizer
        target: null
        autoBind: false
        width: pCtrl.resizerSize
        height: root.height - pCtrl.resizerSize * 2
        cursorShape: Qt.SizeHorCursor
        property bool fallback: false
        onPressed: {
            if (!root.autoBind)
                return;
            let res = root.window.startSystemResize(Qt.LeftEdge);
            if (!res)
                fallback = true;
            console.debug("window resize left edge fallback:", res);
        }
        onWannaMove: (dx, dy) => {
            root.wannaResizeLeftEdge(dx);
            if (!fallback)
                return;
            pCtrl.resizeWindow(0, 0, 0, dy);
        }
    }

    DragMoveArea {
        id: topResizer
        target: null
        autoBind: false
        width: root.width - pCtrl.resizerSize * 2
        height: pCtrl.resizerSize
        x: pCtrl.resizerSize
        cursorShape: Qt.SizeVerCursor
        property bool fallback: false
        onPressed: {
            if (!root.autoBind)
                return;
            let res = root.window.startSystemResize(Qt.TopEdge);
            if (!res)
                fallback = true;
            console.debug("window resize top edge fallback:", res);
        }
        onWannaMove: (dx, dy) => {
            root.wannaResizeTopEdge(dy);
            if (!fallback)
                return;
            pCtrl.resizeWindow(0, 0 - dy, 0, dy);
        }
    }

    DragMoveArea {
        id: bottomResizer
        target: null
        autoBind: false
        width: root.width - pCtrl.resizerSize * 2
        height: pCtrl.resizerSize
        x: pCtrl.resizerSize
        y: root.height - height
        cursorShape: Qt.SizeVerCursor
        property bool fallback: false
        onPressed: {
            if (!root.autoBind)
                return;
            let res = root.window.startSystemResize(Qt.BottomEdge);
            if (!res)
                fallback = true;
            console.debug("window resize bottom edge fallback:", res);
        }
        onWannaMove: (dx, dy) => {
            root.wannaResizeBottomEdge(dy);
            if (!fallback)
                return;
            pCtrl.resizeWindow(0, 0, 0, dy);
        }
    }

    DragMoveArea {
        id: topRightResizer
        target: null
        autoBind: false
        width: pCtrl.resizerSize
        height: pCtrl.resizerSize
        x: root.width - width
        cursorShape: Qt.SizeBDiagCursor
        property bool fallback: false
        onPressed: {
            if (!root.autoBind)
                return;
            let res = root.window.startSystemResize(Qt.TopEdge | Qt.RightEdge);
            if (!res)
                fallback = true;
            console.debug("window resize top right corner fallback:", res);
        }
        onWannaMove: (dx, dy) => {
            root.wannaResizeTopRightCorner(dx, dy);
            if (!fallback)
                return;
            pCtrl.resizeWindow(0, 0 - dy, dx, dy);
        }
    }

    DragMoveArea {
        id: bottomRightResizer
        target: null
        autoBind: false
        width: pCtrl.resizerSize
        height: pCtrl.resizerSize
        x: root.width - width
        y: root.height - height
        cursorShape: Qt.SizeFDiagCursor
        property bool fallback: false
        onPressed: {
            if (!root.autoBind)
                return;
            let res = root.window.startSystemResize(Qt.BottomEdge | Qt.RightEdge);
            if (!res)
                fallback = true;
            console.debug("window resize bottom right corner fallback:", res);
        }
        onWannaMove: (dx, dy) => {
            root.wannaResizeBottomRightCorner(dx, dy);
            if (!fallback)
                return;
            pCtrl.resizeWindow(0, 0, dx, dy);
        }
    }

    DragMoveArea {
        id: bottomLeftResizer
        target: null
        autoBind: false
        width: pCtrl.resizerSize
        height: pCtrl.resizerSize
        y: root.height - height
        cursorShape: Qt.SizeBDiagCursor
        property bool fallback: false
        onPressed: {
            if (!root.autoBind)
                return;
            let res = root.window.startSystemResize(Qt.BottomEdge | Qt.LeftEdge);
            if (!res)
                fallback = true;
            console.debug("window resize bottom left corner fallback:", res);
        }
        onWannaMove: (dx, dy) => {
            root.wannaResizeBottomLeftCorner(dx, dy);
            if (!fallback)
                return;
            pCtrl.resizeWindow(0 - dx, 0, dx, dy);
        }
    }

    DragMoveArea {
        id: topLeftResizer
        enabled: root.forceResizeTopLeftCorner
        target: null
        autoBind: false
        width: pCtrl.resizerSize
        height: pCtrl.resizerSize
        cursorShape: Qt.SizeFDiagCursor
        property bool fallback: false
        onPressed: {
            if (!root.autoBind)
                return;
            let res = root.window.startSystemResize(Qt.TopEdge | Qt.LeftEdge);
            if (!res)
                fallback = true;
            console.debug("window resize top left corner fallback:", res);
        }
        onWannaMove: (dx, dy) => {
            root.wannaREsizeTopLeftCorner(dx, dy);
            if (!fallback)
                return;
            pCtrl.resizeWindow(0 - dx, 0 - dy, dx, dy);
        }
    }
}
