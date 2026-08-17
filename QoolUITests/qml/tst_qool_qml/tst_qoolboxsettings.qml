import QtQuick
import QtTest
import Qool

// QoolBoxSettings 测试（Qool/shapecontrol/qool_qoolbox_settings.*）
//
// 被测契约（spec D2 最终定案：单一类型——QML 继承 Base 主路径实证否定后
// Base 删除，属性类型直接为本类；ADR-0005 修订）：
// - QoolBoxSettings 是 C++ 类型（QML_ELEMENT，可实例化）；类型默认值 = C++
//   常量（cut* 0、borderWidth 0、borderColor red、fillColor yellow、
//   offsetX/Y 0、curved false）——无 Style 默认，主题联动由消费方
//   （QoolBox 等）在实例化处显式绑定
// - 9 属性可读写（写后读回）；变化发 *_Changed 信号；同值赋值不发信号
//   （属性宏体系相等守卫）
// - 字段可绑定（绑定到可驱动值，变化后读取跟随）与动画（Behavior 可挂字段、
//   NumberAnimation 作用于字段）
// - control.settings（属性类型 QoolBoxSettings*）接受 QoolBoxSettings
//   实例（内联/引用赋值类型完全匹配）；settings 实例替换后绑定链路自动重挂
// - 引用语义（文档契约）：整组赋值共享实例（一处修改另一处可见、字段绑定
//   作用于共享对象）；独立副本 = 新建实例赋值（互不影响）
// - QoolBox 默认 wiring：settings 非 null、control.settings === settings、
//   字段默认来自 Style 绑定（borderWidth == Style.controlBorderWidth、
//   borderColor == Style.accent、fillColor == Style.dark）
//
// 隔离策略：TestCase 各测试函数共享同一实例——每个测试函数用
// createTemporaryQmlObject/createTemporaryObject 创建独立实例（状态隔离规范，
// 测试结束自动销毁）；SignalSpy 动态创建；异步/时序断言一律
// tryCompare/tryVerify 轮询，不写固定 sleep。

TestCase {
    id: root

    name: "QoolBoxSettings"
    width: 320
    height: 320

    function makeSettings() {
        return createTemporaryQmlObject("import Qool; QoolBoxSettings {}", root)
    }

    function makeSpy(target, signalName) {
        const spy = Qt.createQmlObject("import QtTest; SignalSpy {}", root)
        spy.target = target
        spy.signalName = signalName
        return spy
    }

    // —— 1. 可实例化 + 属性契约 ——

    function test_defaultValues() {
        const s = makeSettings()
        // 类型默认值 = C++ 常量（fallback 定案：无 Style 默认——主题联动由
        // 消费方实例化处显式绑定，未绑定前的瞬时值沿用 C++ 兜底）
        compare(s.cutSizeTL, 0)
        compare(s.cutSizeTR, 0)
        compare(s.cutSizeBL, 0)
        compare(s.cutSizeBR, 0)
        compare(s.borderWidth, 0)
        compare(s.borderColor, Qt.rgba(1, 0, 0, 1)) // Qt::red
        compare(s.fillColor, Qt.rgba(1, 1, 0, 1)) // Qt::yellow
        compare(s.offsetX, 0)
        compare(s.offsetY, 0)
        compare(s.curved, false)
    }

    function test_propertiesReadWrite() {
        const s = makeSettings()
        // 9 属性全部写后读回（含小数/负数/颜色/布尔）
        s.cutSizeTL = 12.5
        s.cutSizeTR = 13
        s.cutSizeBL = 14.25
        s.cutSizeBR = 15
        s.borderWidth = 2.5
        s.borderColor = Qt.rgba(0.1, 0.5, 0.9, 0.75)
        s.fillColor = Qt.rgba(0, 0, 0, 1)
        s.offsetX = -3.25
        s.offsetY = 7.5
        s.curved = true
        compare(s.cutSizeTL, 12.5)
        compare(s.cutSizeTR, 13)
        compare(s.cutSizeBL, 14.25)
        compare(s.cutSizeBR, 15)
        compare(s.borderWidth, 2.5)
        compare(s.borderColor, Qt.rgba(0.1, 0.5, 0.9, 0.75))
        compare(s.fillColor, Qt.rgba(0, 0, 0, 1))
        compare(s.offsetX, -3.25)
        compare(s.offsetY, 7.5)
        compare(s.curved, true)
    }

    function test_signalsOnChange() {
        const s = makeSettings()
        const spyCutTL = makeSpy(s, "cutSizeTLChanged")
        const spyCutTR = makeSpy(s, "cutSizeTRChanged")
        const spyCutBL = makeSpy(s, "cutSizeBLChanged")
        const spyCutBR = makeSpy(s, "cutSizeBRChanged")
        const spyBorderWidth = makeSpy(s, "borderWidthChanged")
        const spyBorderColor = makeSpy(s, "borderColorChanged")
        const spyFillColor = makeSpy(s, "fillColorChanged")
        const spyOffsetX = makeSpy(s, "offsetXChanged")
        const spyOffsetY = makeSpy(s, "offsetYChanged")
        const spyCurved = makeSpy(s, "curvedChanged")

        // 每属性一次变化 → 对应信号各发一次
        s.cutSizeTL = 1
        s.cutSizeTR = 2
        s.cutSizeBL = 3
        s.cutSizeBR = 4
        s.borderWidth = 1.5
        s.borderColor = Qt.rgba(0.2, 0.4, 0.6, 1)
        s.fillColor = Qt.rgba(0.8, 0.6, 0.4, 1)
        s.offsetX = 3
        s.offsetY = -2
        s.curved = true

        compare(spyCutTL.count, 1)
        compare(spyCutTR.count, 1)
        compare(spyCutBL.count, 1)
        compare(spyCutBR.count, 1)
        compare(spyBorderWidth.count, 1)
        compare(spyBorderColor.count, 1)
        compare(spyFillColor.count, 1)
        compare(spyOffsetX.count, 1)
        compare(spyOffsetY.count, 1)
        compare(spyCurved.count, 1)
    }

    function test_sameValueAssignmentNoSignal() {
        const s = makeSettings()
        const spyWidth = makeSpy(s, "borderWidthChanged")
        const spyCut = makeSpy(s, "cutSizeTLChanged")
        const spyCurved = makeSpy(s, "curvedChanged")

        // 属性宏体系相等守卫：同值赋值不发信号（数值/布尔各验一类）
        s.borderWidth = 3
        s.borderWidth = 3
        compare(spyWidth.count, 1)
        s.borderWidth = 3.5
        compare(spyWidth.count, 2)

        s.cutSizeTL = 8
        s.cutSizeTL = 8
        compare(spyCut.count, 1)

        s.curved = true
        s.curved = true
        compare(spyCurved.count, 1)
        s.curved = false
        compare(spyCurved.count, 2)
    }

    // —— 2. 字段可绑定 + 动画 ——

    Component {
        id: bindingSceneComp
        Item {
            property alias driverRef: driver
            property alias settingsRef: settings
            Item {
                id: driver
                property real widthValue: 2
                property real offsetValue: -1.5
            }
            QoolBoxSettings {
                id: settings
                borderWidth: driver.widthValue
                offsetX: driver.offsetValue
            }
        }
    }

    function test_fieldBindingFollowsDriver() {
        const scene = createTemporaryObject(bindingSceneComp, root)
        const s = scene.settingsRef
        // 绑定初始值
        tryCompare(s, "borderWidth", 2, 1000)
        compare(s.offsetX, -1.5)
        // 驱动值变化 → 字段读取跟随（slider.value 语义）
        scene.driverRef.widthValue = 8
        scene.driverRef.offsetValue = 3.25
        tryCompare(s, "borderWidth", 8, 1000)
        tryCompare(s, "offsetX", 3.25, 1000)
        // 持续跟随（非一次性求值）
        scene.driverRef.widthValue = 0.5
        tryCompare(s, "borderWidth", 0.5, 1000)
    }

    Component {
        id: animationSceneComp
        Item {
            property alias settingsRef: settings
            QoolBoxSettings {
                id: settings
                Behavior on borderWidth {
                    NumberAnimation { duration: 300 }
                }
            }
        }
    }

    function test_behaviorAnimatesField() {
        const scene = createTemporaryObject(animationSceneComp, root)
        const s = scene.settingsRef
        compare(s.borderWidth, 0)
        s.borderWidth = 30
        // Behavior 拦截赋值：同步读仍是旧值（动画未起跳）——字段类型可被
        // 动画作用（NumberAnimation 驱动属性过渡）
        verify(s.borderWidth < 30)
        tryCompare(s, "borderWidth", 30, 3000) // 动画到达目标
    }

    // —— 3. 多态 + 引用语义 ——

    Component {
        id: controlComp
        QoolBoxShapeControl {
            settings: QoolBoxSettings {
                cutSizeTL: 12
                borderWidth: 3
                offsetX: 5
                curved: true
                borderColor: Qt.rgba(0, 1, 0, 1)
                fillColor: Qt.rgba(0, 0, 1, 1)
            }
        }
    }

    function test_controlAcceptsSettingsInstance() {
        const control = createTemporaryObject(controlComp, root)
        // 属性类型为 QoolBoxSettings*，接受 QoolBoxSettings 实例
        // （QML 内联对象赋值）
        verify(control.settings !== null)
        compare(control.settings.cutSizeTL, 12)
        compare(control.settings.borderWidth, 3)
        compare(control.settings.offsetX, 5)
        compare(control.settings.curved, true)
        compare(control.settings.borderColor, Qt.rgba(0, 1, 0, 1))
        compare(control.settings.fillColor, Qt.rgba(0, 0, 1, 1))

        // 实例替换：属性可写，新实例接入（独立副本——旧值不残留）
        const s2 = createTemporaryQmlObject(
            "import Qool; QoolBoxSettings { cutSizeTR: 42 }", root)
        control.settings = s2
        tryVerify(function() { return control.settings === s2 }, 1000)
        compare(control.settings.cutSizeTR, 42)
        compare(control.settings.cutSizeTL, 0) // 新实例独立默认
    }

    Component {
        id: sharedSceneComp
        Item {
            property alias boxARef: boxA
            property alias boxBRef: boxB
            property alias sharedRef: shared
            property alias driverRef: driver
            Item {
                id: driver
                property real widthValue: 1
            }
            QoolBoxSettings {
                id: shared
                borderWidth: driver.widthValue
            }
            QoolBox { id: boxA; width: 60; height: 60; settings: shared }
            QoolBox { id: boxB; width: 60; height: 60; settings: shared }
        }
    }

    function test_sharedInstanceAcrossBoxes() {
        const scene = createTemporaryObject(sharedSceneComp, root)
        // 引用语义：两个对象 settings 指向同一实例
        tryVerify(function() {
            return scene.boxARef.settings === scene.sharedRef
                && scene.boxBRef.settings === scene.sharedRef
        }, 1000)
        // 字段绑定作用于共享对象：驱动值变化，两盒经同一 settings 同时可见
        tryCompare(scene.boxARef.settings, "borderWidth", 1, 1000)
        scene.driverRef.widthValue = 6
        tryCompare(scene.boxBRef.settings, "borderWidth", 6, 1000)
        tryCompare(scene.boxARef.settings, "borderWidth", 6, 1000)
        // 一处修改另一处可见
        scene.boxARef.settings.cutSizeTL = 17
        tryCompare(scene.boxBRef.settings, "cutSizeTL", 17, 1000)
    }

    Component {
        id: twoBoxesComp
        Item {
            property alias boxARef: boxA
            property alias boxBRef: boxB
            QoolBox { id: boxA; width: 60; height: 60 }
            QoolBox { id: boxB; width: 60; height: 60 }
        }
    }

    function test_independentCopiesDoNotShare() {
        const scene = createTemporaryObject(twoBoxesComp, root)
        verify(scene.boxARef.settings !== scene.boxBRef.settings)
        const bBorderWidth = scene.boxBRef.settings.borderWidth // Style 默认快照
        scene.boxARef.settings.borderWidth = 7
        scene.boxARef.settings.cutSizeTL = 9
        // 独立副本：修改一个实例不影响另一个（互不干扰）
        compare(scene.boxBRef.settings.borderWidth, bBorderWidth)
        compare(scene.boxBRef.settings.cutSizeTL, 0)
    }

    Component {
        id: boxComp
        QoolBox { width: 100; height: 100 }
    }

    function test_settingsReplacementRewires() {
        const box = createTemporaryObject(boxComp, root)
        // 默认 settings（cut 0）→ extTLx = 0（gadget 锚定：point = origin +
        // offset + vec + shrink；Top 边 Left 端点 x = cutSizeTL）
        compare(box.control.extTLx, 0)
        const s2 = createTemporaryQmlObject(
            "import Qool; QoolBoxSettings { cutSizeTL: 30 }", root)
        box.settings = s2
        // 整体替换：control.settings 绑定自动重挂新实例
        tryVerify(function() { return box.control.settings === s2 }, 1000)
        compare(box.settings.cutSizeTL, 30)
        tryCompare(box.control, "extTLx", 30, 1000) // 新实例字段接入几何
        // 新实例字段变化实时重挂（信号连接链路）
        s2.cutSizeTL = 45
        tryCompare(box.control, "extTLx", 45, 1000)
    }

    // —— 4. QoolBox 默认 wiring ——

    function test_qoolBoxDefaultWiring() {
        const box = createTemporaryQmlObject(
            "import Qool; import QtQuick; QoolBox { width: 100; height: 100 }",
            root)
        // 默认 wiring：settings/control 均非 null，control 消费同一 settings 实例
        verify(box.settings !== null)
        verify(box.control !== null)
        tryVerify(function() { return box.control.settings === box.settings }, 1000)
        // 字段默认来自 Style 绑定（fallback 形态：类型默认 C++ 常量，主题联动
        // 在 QoolBox 实例化处显式绑定——测试环境 Style 可用，绑定必须生效）
        compare(box.settings.borderWidth, box.Style.controlBorderWidth)
        compare(box.settings.borderColor, box.Style.accent)
        compare(box.settings.fillColor, box.Style.dark)
        // 未绑定 Style 的字段保持 C++ 常量默认
        compare(box.settings.cutSizeTL, 0)
        compare(box.settings.cutSizeTR, 0)
        compare(box.settings.cutSizeBL, 0)
        compare(box.settings.cutSizeBR, 0)
        compare(box.settings.offsetX, 0)
        compare(box.settings.offsetY, 0)
        compare(box.settings.curved, false)
    }
}
