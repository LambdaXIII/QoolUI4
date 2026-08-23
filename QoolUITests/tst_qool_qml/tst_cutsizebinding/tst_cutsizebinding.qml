import QtQuick
import QtTest
import Qool

// CutSizeBinding 行为测试（Qool/CutSizeBinding.qml）
//
// 被测契约：
// - 默认 bindingMode = CutSizeBinding.AllCorners、when = true
// - AllCorners：from 的 cutSizeTL/TR/BL/BR 四角全部同步写入 to 对应属性，
//   源属性变化实时传播
// - TopLeftCornerOnly：仅同步左上角（cutSizeTL），其余三角绑定失活保持原值
// - when = false 时全部绑定失活（to 保持原值）；恢复 true 后重新同步
// - from/to 缺少对应属性（hasOwnProperty 为 false）时该绑定不激活
// - from/to 动态更换后绑定重指向新对象并同步
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（状态隔离规范），
// 时序/异步断言一律 tryCompare 轮询；负向断言（值不变化）用 wait 短窗口。
//
// QML 测试注意：id 不是对象属性——场景子对象经 property alias 暴露
// （scene.srcRef/dstRef/binderRef 等）。

TestCase {
    id: root

    name: "CutSizeBinding"

    Component {
        id: sceneComp
        Item {
            property alias srcRef: src
            property alias dstRef: dst
            property alias altSrcRef: altSrc
            property alias altDstRef: altDst
            property alias plainItemRef: plainItem
            property alias binderRef: binder

            Item {
                id: src
                property real cutSizeTL: 10
                property real cutSizeTR: 20
                property real cutSizeBL: 30
                property real cutSizeBR: 40

                Item {
                    id: dst
                    property real cutSizeTL: 0
                    property real cutSizeTR: 0
                    property real cutSizeBL: 0
                    property real cutSizeBR: 0
                }

                // 备用源/目标：验证动态更换 from/to
                Item {
                    id: altSrc
                    property real cutSizeTL: 5
                    property real cutSizeTR: 6
                    property real cutSizeBL: 7
                    property real cutSizeBR: 8
                }
                Item {
                    id: altDst
                    property real cutSizeTL: 0
                    property real cutSizeTR: 0
                    property real cutSizeBL: 0
                    property real cutSizeBR: 0
                }

                // 无 cutSize* 属性的普通对象：验证缺属性时绑定不激活
                Item {
                    id: plainItem
                }

                CutSizeBinding {
                    id: binder
                    from: src
                    to: dst
                }
            }
        }
    }

    function makeScene() {
        return createTemporaryObject(sceneComp, root)
    }

    function test_defaults() {
        const scene = makeScene()
        compare(scene.binderRef.bindingMode, CutSizeBinding.AllCorners)
        compare(scene.binderRef.when, true)
    }

    function test_allCornersSync() {
        const scene = makeScene()
        // 初始同步：四角全部写入目标
        tryCompare(scene.dstRef, "cutSizeTL", 10, 1000)
        tryCompare(scene.dstRef, "cutSizeTR", 20, 1000)
        tryCompare(scene.dstRef, "cutSizeBL", 30, 1000)
        tryCompare(scene.dstRef, "cutSizeBR", 40, 1000)
    }

    function test_sourceChangePropagates() {
        const scene = makeScene()
        scene.srcRef.cutSizeTL = 55
        scene.srcRef.cutSizeBR = -7
        tryCompare(scene.dstRef, "cutSizeTL", 55, 1000)
        tryCompare(scene.dstRef, "cutSizeBR", -7, 1000)
    }

    function test_topLeftCornerOnly() {
        const scene = makeScene()
        // 先等初始同步完成（绑定求值在帧尾异步发生），再切模式
        tryCompare(scene.dstRef, "cutSizeTR", 20, 1000)
        scene.binderRef.bindingMode = CutSizeBinding.TopLeftCornerOnly
        // 失活瞬间 Qt Binding 可能让目标回落到默认值——快照当前值，
        // 断言"失活后不再传播"（修改源不改变目标），不依赖回落与否
        const frozenTR = scene.dstRef.cutSizeTR
        scene.srcRef.cutSizeTR = 99
        wait(100) // 负向断言：TL-only 模式下 TR 绑定失活，源修改不传播
        compare(scene.dstRef.cutSizeTR, frozenTR)
        // TL 不受模式限制（tlBinding 的 when 不检查 bindingMode），继续同步
        scene.srcRef.cutSizeTL = 7
        tryCompare(scene.dstRef, "cutSizeTL", 7, 1000)
    }

    function test_whenGate() {
        const scene = makeScene()
        tryCompare(scene.dstRef, "cutSizeTL", 10, 1000) // 初始同步完成
        scene.binderRef.when = false
        // 失活后快照当前值，断言"不再传播"（见 test_topLeftCornerOnly 注释）
        const frozenTL = scene.dstRef.cutSizeTL
        scene.srcRef.cutSizeTL = 123
        wait(100) // 负向断言：when=false 时绑定失活，源修改不传播
        compare(scene.dstRef.cutSizeTL, frozenTL)
        // 恢复 when 后重新同步当前源值
        scene.binderRef.when = true
        tryCompare(scene.dstRef, "cutSizeTL", 123, 1000)
    }

    function test_missingPropertyDeactivates() {
        const scene = makeScene()
        tryCompare(scene.dstRef, "cutSizeTL", 10, 1000) // 初始同步完成
        // 源换成无 cutSize* 属性的对象 → 对应绑定不激活；先等失活
        // （异步）生效再快照（失活瞬间可能回落默认值），断言不再传播
        scene.binderRef.from = scene.plainItemRef
        wait(100)
        const frozenTL = scene.dstRef.cutSizeTL
        scene.srcRef.cutSizeTL = 11
        wait(100) // 负向断言：缺属性时绑定不激活，源修改不传播
        compare(scene.dstRef.cutSizeTL, frozenTL)
        // 换回合法源 → 绑定恢复，同步当前源值
        scene.binderRef.from = scene.srcRef
        tryCompare(scene.dstRef, "cutSizeTL", 11, 1000)
    }

    function test_retarget() {
        const scene = makeScene()
        tryCompare(scene.dstRef, "cutSizeTL", 10, 1000) // 初始同步完成
        scene.binderRef.from = scene.altSrcRef
        scene.binderRef.to = scene.altDstRef
        tryCompare(scene.altDstRef, "cutSizeTL", 5, 1000)
        tryCompare(scene.altDstRef, "cutSizeTR", 6, 1000)
        tryCompare(scene.altDstRef, "cutSizeBL", 7, 1000)
        tryCompare(scene.altDstRef, "cutSizeBR", 8, 1000)
        // 旧目标失活后快照，断言"不再被写入"（见 test_topLeftCornerOnly 注释）
        const frozenTL = scene.dstRef.cutSizeTL
        scene.altSrcRef.cutSizeTL = 42
        wait(100) // 负向断言：重定向后旧目标不再被写入
        compare(scene.dstRef.cutSizeTL, frozenTL)
    }
}
