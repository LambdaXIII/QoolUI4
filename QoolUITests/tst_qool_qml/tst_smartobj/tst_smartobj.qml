import QtQuick
import QtTest
import Qool

// SmartObject 行为契约测试（QML 面）
//
// 被测契约（docs/reference/Qool/SmartObj.md）：
// - parent 属性：QML 可写 reparent、写 null 分离
//
// 说明：smartItems 默认属性/信号在 QML 侧无可测契约面（QQmlListProperty
// 暴露属 Qt 引擎机制，itemAppended 声明期已发射不可捕获）——行为由派生
// 组件（SpaceHelper 等）的 QML 测试与文档契约覆盖。
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（状态隔离规范）。

TestCase {
    id: root

    name: "SmartObject"
    width: 200
    height: 200

    function makeSpy(target, signalName) {
        const spy = Qt.createQmlObject("import QtTest; SignalSpy {}", root)
        spy.target = target
        spy.signalName = signalName
        return spy
    }

    Component {
        id: withChildrenComp
        SmartObject {
            // 默认属性声明子对象
            QtObject { id: child1 }
            QtObject { id: child2 }
        }
    }

    function test_parent_write_behavior() {
        const obj = createTemporaryObject(withChildrenComp, root)
        const host = Qt.createQmlObject("import QtQuick; QtObject {}", root)
        // 写入父对象：reparent 生效
        obj.parent = host
        compare(obj.parent, host)
        // 写 null 分离
        obj.parent = null
        compare(obj.parent, null)
    }
}
