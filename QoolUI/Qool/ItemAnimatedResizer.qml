import QtQuick
import Qool
import Qool.Controls

SmartObject {
    id: root
    // property bool enabled: true
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    property alias forewardAnimation: templateFowardAni
    property alias backwardAnimation: templateBackwardAni

    // readonly property QtObject from: backGroup
    // readonly property QtObject to: foreGroup

    property alias fromWidth: backGroup.width
    property alias fromHeight: backGroup.height
    property alias toWidth: foreGroup.width
    property alias toHeight: foreGroup.height

    property bool resized: false
    readonly property real width: pCtrl.width
    readonly property real height: pCtrl.height
    readonly property bool running: forewardAni.running || backwardAni.running

    NumberAnimation {
        id: templateFowardAni
        easing.type: Easing.OutCurve
        duration: Style.transitionDuration
    }

    NumberAnimation {
        id: templateBackwardAni
        easing.type: Easing.OutCurve
        duration: Style.transitionDuration
    }

    QtObject {
        id: backGroup
        property real width: 100
        property real height: 100

        readonly property bool reached: width === pCtrl.width && height === pCtrl.height
    }

    QtObject {
        id: foreGroup
        property real width: 120
        property real height: 120

        readonly property bool reached: width === pCtrl.width && height === pCtrl.height
    }

    ParallelAnimation {
        id: forewardAni
        NumberAnimation {
            target: pCtrl
            property: "width"
            to: foreGroup.width
            easing: templateFowardAni.easing
            duration: templateFowardAni.duration
        }
        NumberAnimation {
            target: pCtrl
            property: "height"
            to: foreGroup.height
            easing: templateFowardAni.easing
            duration: templateFowardAni.duration
        }
        onStarted: pCtrl.unlock()
        onFinished: pCtrl.lock_foreward()
    }

    ParallelAnimation {
        id: backwardAni
        NumberAnimation {
            target: pCtrl
            property: "width"
            to: backGroup.width
            easing: templateFowardAni.easing
            duration: templateFowardAni.duration
        }
        NumberAnimation {
            target: pCtrl
            property: "height"
            to: backGroup.height
            easing: templateFowardAni.easing
            duration: templateFowardAni.duration
        }
        onStarted: pCtrl.unlock()
        onFinished: pCtrl.lock_backward()
    }

    SmartObject {
        id: pCtrl
        property real width
        property real height

        property bool forewardLocked: false
        property bool backwardLocked: true

        function unlock() {
            forewardLocked = false;
            backwardLocked = false;
        }

        function lock_foreward() {
            forewardLocked = true;
            backwardLocked = false;
        }

        function lock_backward() {
            forewardLocked = false;
            backwardLocked = true;
        }

        function jump_foreward() {
            unlock();
            pCtrl.width = foreGroup.width;
            pCtrl.height = foreGroup.height;
            lock_foreward();
        }

        function jump_backward() {
            unlock();
            pCtrl.width = backGroup.width;
            pCtrl.height = backGroup.height;
            lock_backward();
        }

        function dive_foreward() {
            if (backwardAni.running)
                backwardAni.stop();
            forewardAni.restart();
        }

        function dive_backward() {
            if (forewardAni.running)
                forewardAni.stop();
            backwardAni.restart();
        }

        function go_foreward() {
            if (foreGroup.reached)
                return;
            if (root.animationEnabled && templateFowardAni.duration > 0)
                dive_foreward();
            else
                jump_foreward();
        }

        function go_backward() {
            if (backGroup.reached)
                return;
            if (root.animationEnabled && templateFowardAni.duration > 0)
                dive_backward();
            else
                jump_backward();
        }

        function ensure() {
            if (root.resized)
                go_foreward();
            else
                go_backward();
        }

        Connections {
            target: root
            function onResizedChanged() {
                pCtrl.ensure();
            }
        }
    }//pCtrl

    Binding {
        when: pCtrl.forewardLocked
        target: pCtrl
        property: "width"
        value: foreGroup.width
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: pCtrl.forewardLocked
        target: pCtrl
        property: "height"
        value: foreGroup.height
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: pCtrl.backwardLocked
        target: pCtrl
        property: "width"
        value: backGroup.width
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: pCtrl.backwardLocked
        target: pCtrl
        property: "height"
        value: backGroup.height
        restoreMode: Binding.RestoreNone
    }
}
