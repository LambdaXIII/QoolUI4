import QtQuick
import QtTest
import Qool

// QoolBox 组件测试（Qool/QoolBox.qml）——公开面与变体
//
// 被测契约：
// - 公开面：settings/control（可替换/共享）、fillItem/animatingHint 门控、
//   shape（= loader.item 委托，containmentMask 同步委托）
// - *Space 四值：转发 control，公式 max(0, max(相邻 cut) − (used − 期望)/2)
//   （used = max(期望, 对角 cut 和)——cut 硬参数溢出语义），含钳 0
// - 退行判定：!fillItem && !fillGradient && curved && (四角 cut 均 ≤ 短边/2
//   || 四角全 0) && animatingHint == false → 内联 Rectangle（无 control，
//   cut* 作圆角半径）；否则 curved ? OctagonCurvedShape : OctagonShape
// - 变体 required control 注入：shape.control === box.control；独立实例化
//   OctagonShape + 注入 control 渲染接线（掩码直挂 control + 路径消费
//   ext*/int* 起点）；不注入时拒绝实例化（创建为 null，required 契约）
// - 圆角内弧半径 = 内环相邻点弦长/√2（期望值经 control.int* 点独立推导，
//   防公式实现走样）；cut=0 时弦长 0 → 半径 0（退化自洽）
//
// 隔离策略：每个测试函数 createTemporaryObject/createTemporaryQmlObject
// 独立实例；绑定传播异步，值断言一律 tryCompare/tryVerify 轮询；浮点
// 断言 fuzzy_eq。命中判定的真实鼠标路径由 C++ tst_hover_e2e 批次覆盖
// （QML TestCase.mouseMove 在 offscreen 不注入事件）——本文件只直接调用
// 掩码 contains()（与 tst_crystal 同契约）。

TestCase {
    id: root

    name: "QoolBox"
    width: 300
    height: 300

    Component {
        id: qboxComp
        QoolBox {}
    }

    Component {
        id: settingsComp
        QoolBoxSettings {}
    }

    function makeBox(w, h) {
        const box = createTemporaryObject(qboxComp, root, {})
        box.width = w
        box.height = h
        return box
    }

    function setCuts(box, tl, tr, bl, br) {
        box.settings.cutSizeTL = tl
        box.settings.cutSizeTR = tr
        box.settings.cutSizeBL = bl
        box.settings.cutSizeBR = br
    }

    function fuzzy_eq(a, b, eps) {
        return Math.abs(a - b) <= (eps === undefined ? 1e-6 : eps)
    }

    // 退行/变体形态断言（轮询：loader sourceComponent 绑定求值与组件
    // 实例化异步，中间态可能短暂停留在旧实例）
    function expectShapeType(box, kind, tag) {
        tryVerify(function() {
            const s = box.shape
            if (kind === "rect") return s instanceof Rectangle
            if (kind === "octagon") return s instanceof OctagonShape
            if (kind === "curved") return s instanceof OctagonCurvedShape
            return false
        }, 3000, tag + " 应得到 " + kind + " 形态")
    }

    // 内弧半径期望值：内环相邻点弦长/√2。角点两相邻内环点：
    // TL = intTL/intLT、TR = intTR/intRT、BR = intBR/intRB、BL = intBL/intLB。
    // 与变体内 pCtrl 公式同源但独立推导——公式实现走样时可被抓住。
    function chordRadius(ctrl, corner) {
        let ax, ay, bx, by
        switch (corner) {
        case "TL": ax = ctrl.intTLx; ay = ctrl.intTLy; bx = ctrl.intLTx; by = ctrl.intLTy; break
        case "TR": ax = ctrl.intTRx; ay = ctrl.intTRy; bx = ctrl.intRTx; by = ctrl.intRTy; break
        case "BR": ax = ctrl.intBRx; ay = ctrl.intBRy; bx = ctrl.intRBx; by = ctrl.intRBy; break
        case "BL": ax = ctrl.intBLx; ay = ctrl.intBLy; bx = ctrl.intLBx; by = ctrl.intLBy; break
        default: return NaN
        }
        return Math.hypot(bx - ax, by - ay) / Math.SQRT2
    }

    // 圆角变体（Shape）的内部 ShapePath（外环/内环）都暴露 pCtrl（内弧
    // 半径计算属性）——取第一个即可（两处公式同源）
    function firstPathWithPCtrl(shape) {
        for (let i = 0; i < shape.data.length; ++i) {
            const p = shape.data[i]
            if (p.pCtrl !== undefined) return p
        }
        return null
    }

    function test_publicSurfaceSpaces() {
        const box = makeBox(100, 60)
        // 公开面存在性与默认值
        verify(box.control !== null, "control 应存在")
        verify(box.settings !== null, "settings 应存在")
        verify(box.fillItem === null, "fillItem 默认 null")
        verify(box.animatingHint === false, "animatingHint 默认 false")
        tryVerify(function() { return box.control.settings === box.settings }, 1000,
            "默认 wiring：control.settings 应绑定自身 settings")
        // 默认（curved=false）→ 直角变体，control 注入成立
        setCuts(box, 10, 10, 10, 10)
        expectShapeType(box, "octagon", "默认")
        verify(box.shape.control === box.control, "shape 应消费 box.control")
        verify(box.containmentMask === box.shape, "containmentMask 应委托当前变体")
        // *Space 四值：cut=10、100x60（无溢出）→ 10/10/10/10
        tryCompare(box, "topSpace", 10, 1000)
        tryCompare(box, "bottomSpace", 10, 1000)
        tryCompare(box, "leftSpace", 10, 1000)
        tryCompare(box, "rightSpace", 10, 1000)
    }

    function test_spacesOverflowClamp() {
        // cut 硬参数溢出：100x60、cut=40 → usedHeight 溢出到 80（垂直：
        // 40+40 > 60），水平不溢出（usedWidth=100）；*Space = max(0,
        // cut − (used − 期望)/2) → 上/下 = 40 − 10 = 30，左/右 = 40
        const box = makeBox(100, 60)
        setCuts(box, 40, 40, 40, 40)
        tryCompare(box, "topSpace", 30, 1000)
        tryCompare(box, "bottomSpace", 30, 1000)
        tryCompare(box, "leftSpace", 40, 1000)
        tryCompare(box, "rightSpace", 40, 1000)
    }

    function test_controlReplacementRebinds() {
        const box = makeBox(100, 60)
        setCuts(box, 10, 10, 10, 10)
        tryCompare(box, "topSpace", 10, 1000)
        // 独立 control（cut=20、target=宿主 Item）替换默认 control →
        // *Space 绑定链路重挂到新实例
        const scene = createTemporaryQmlObject(
            "import QtQuick; import Qool; Item { id: h; width: 100; height: 60; "
            + "property alias ctrlRef: ctrl; "
            + "QoolBoxShapeControl { id: ctrl; target: h; settings: st } "
            + "QoolBoxSettings { id: st; cutSizeTL: 20; cutSizeTR: 20; cutSizeBL: 20; cutSizeBR: 20 } }",
            root)
        tryCompare(scene.ctrlRef, "topSpace", 20, 1000) // 独立 control 自身几何成立
        box.control = scene.ctrlRef
        verify(box.control === scene.ctrlRef, "替换后 control 应为新实例")
        tryCompare(box, "topSpace", 20, 1000)
        tryCompare(box, "bottomSpace", 20, 1000)
        tryCompare(box, "leftSpace", 20, 1000)
        tryCompare(box, "rightSpace", 20, 1000)
        tryVerify(function() { return box.shape.control === scene.ctrlRef }, 1000,
            "变体应跟随新 control")
    }

    function test_settingsReplacementRebinds() {
        const box = makeBox(100, 60)
        box.settings.curved = true
        // 用 > half 的 cut（40 > 30）保持圆角变体——cut ≤ half 会退行矩形
        setCuts(box, 40, 40, 40, 40)
        expectShapeType(box, "curved", "替换前")
        tryCompare(box, "topSpace", 30, 1000) // 40 − (80−60)/2
        tryCompare(box, "leftSpace", 40, 1000) // 水平不溢出
        // 整体替换 settings 实例 → control.settings 绑定重挂 + 几何跟随
        const s2 = createTemporaryObject(settingsComp, root, {})
        s2.curved = true
        s2.cutSizeTL = 36
        s2.cutSizeTR = 36
        s2.cutSizeBL = 36
        s2.cutSizeBR = 36
        box.settings = s2
        verify(box.settings === s2, "替换后 settings 应为新实例")
        tryCompare(box, "topSpace", 30, 1000) // 36 − (72−60)/2（全溢出补偿）
        tryCompare(box, "bottomSpace", 30, 1000)
        tryCompare(box, "leftSpace", 36, 1000)
        tryCompare(box, "rightSpace", 36, 1000)
        tryVerify(function() { return box.control.settings === s2 }, 1000,
            "control.settings 应重挂新实例")
        tryVerify(function() { return box.shape.control.settings === s2 }, 1000,
            "变体（经 control）应跟随新 settings")
        expectShapeType(box, "curved", "替换后")
    }

    function test_fallbackAtHalfBoundary() {
        const box = makeBox(100, 60) // 短边 60 → half = 30
        box.settings.curved = true
        // cut 恰在 half 临界（== half → 四角均 ≤ half）→ 退行
        setCuts(box, 30, 30, 30, 30)
        expectShapeType(box, "rect", "cut==half")
        verify(box.shape.control === undefined, "退行矩形不应有 control")
        // half + ε → 越过临界 → 圆角变体（control 注入成立）
        setCuts(box, 30.5, 30.5, 30.5, 30.5)
        expectShapeType(box, "curved", "cut==half+ε")
        verify(box.shape.control === box.control, "圆角变体应消费 box.control")
    }

    function test_fallbackAllZeroCuts() {
        const box = makeBox(100, 60)
        box.settings.curved = true
        // 四角全 0 + curved → 退行（cond3）
        setCuts(box, 0, 0, 0, 0)
        expectShapeType(box, "rect", "四角全 0")
        verify(box.shape.control === undefined, "退行矩形不应有 control")
        // 关闭 curved → 直角变体（退行需要 curved 门控）
        box.settings.curved = false
        expectShapeType(box, "octagon", "curved=false")
        verify(box.shape.control === box.control, "直角变体应消费 box.control")
    }

    function test_fillItemExcludesFallback() {
        const box = makeBox(100, 60)
        box.settings.curved = true
        setCuts(box, 5, 5, 5, 5) // 小 cut（≤ half）——本应退行
        expectShapeType(box, "rect", "无 fillItem")
        // fillItem 非空 → 排除退行 → 圆角变体（保留 Shape 渲染）。
        // fillItem 用层化 Item（layer.enabled = Qt 文档列出的有效纹理源，
        // 不触发 "Fill item is not texture provider" 告警——不预注册
        // ignoreWarning：环境无警告时预期未收到会误判失败）。
        const fill = createTemporaryQmlObject(
            "import QtQuick; Item { width: 40; height: 40; layer.enabled: true }", root)
        box.fillItem = fill
        expectShapeType(box, "curved", "fillItem 非空")
        verify(box.shape.control === box.control, "fillItem 门控下仍应注入 control")
        // 清空 fillItem → 恢复退行
        box.fillItem = null
        expectShapeType(box, "rect", "fillItem 清空")
    }

    function test_fillGradientExcludesFallback() {
        // fillGradient 补面：公开属性默认 null；非空 → 排除退行
        // （与 fillItem 同款门控——Rectangle 渐变与 Shape 渐变不兼容，退行
        // 形态保持"无填充通道"语义边界）；转发到变体 fillShape。
        const box = makeBox(100, 60)
        verify(box.fillGradient === null, "fillGradient 默认 null")
        box.settings.curved = true
        setCuts(box, 5, 5, 5, 5) // 小 cut（≤ half）——本应退行
        expectShapeType(box, "rect", "无 fillGradient")
        box.fillGradient = createTemporaryQmlObject(
            "import QtQuick; import QtQuick.Shapes; LinearGradient { GradientStop { position: 0; color: 'red' } GradientStop { position: 1; color: 'blue' } }", root)
        expectShapeType(box, "curved", "fillGradient 非空")
        verify(box.shape.control === box.control, "fillGradient 门控下仍应注入 control")
        // 转发到变体（变体公开 fillGradient alias → fillShape.fillGradient）
        tryVerify(function() { return box.shape.fillGradient === box.fillGradient }, 1000,
            "fillGradient 应转发到变体")
        // 清空 → 恢复退行
        box.fillGradient = null
        expectShapeType(box, "rect", "fillGradient 清空")
    }

    function test_animatingHintSkipsFallback() {
        const box = makeBox(100, 60)
        box.settings.curved = true
        setCuts(box, 30, 30, 30, 30) // == half——本应退行
        box.animatingHint = true
        // animatingHint 为 true → 跳过退行判定 → 圆角变体
        expectShapeType(box, "curved", "animatingHint=true")
        verify(box.shape.control === box.control, "动画期间应保持 control 注入")
        // 动画结束（false）→ 退行生效
        box.animatingHint = false
        expectShapeType(box, "rect", "animatingHint=false")
        verify(box.shape.control === undefined, "退行矩形不应有 control")
    }

    function test_sharedControlContract() {
        const box1 = makeBox(100, 60)
        setCuts(box1, 10, 10, 10, 10)
        tryCompare(box1, "topSpace", 10, 1000)
        const box2 = createTemporaryObject(qboxComp, root, {})
        // 共享同一 control：*Space 转发同一几何源（文档引用/共享契约）
        box2.control = box1.control
        verify(box2.control === box1.control, "共享后两 box 应持同一 control")
        tryCompare(box2, "topSpace", 10, 1000)
        tryCompare(box2, "bottomSpace", 10, 1000)
        tryCompare(box2, "leftSpace", 10, 1000)
        tryCompare(box2, "rightSpace", 10, 1000)
        tryVerify(function() { return box2.shape.control === box1.control }, 1000,
            "共享 control 的组件变体应消费同一 control")
        // 共享几何源变化 → 两 box 同步跟随
        setCuts(box1, 25, 25, 25, 25)
        tryCompare(box1, "topSpace", 25, 1000)
        tryCompare(box2, "topSpace", 25, 1000)
        tryCompare(box2, "leftSpace", 25, 1000)
    }

    function test_variantStandaloneInjection() {
        // OctagonShape 独立实例化：注入 control（required 契约）→ 渲染接线
        const scene = createTemporaryQmlObject(
            "import QtQuick; import Qool; Item { id: h; width: 100; height: 60; "
            + "property alias ctrlRef: ctrl; property alias shapeRef: shape; "
            + "QoolBoxShapeControl { id: ctrl; target: h; settings: st } "
            + "QoolBoxSettings { id: st; cutSizeTL: 10; cutSizeTR: 10; cutSizeBL: 10; "
            + "cutSizeBR: 10; borderWidth: 4 } "
            + "OctagonShape { id: shape; control: ctrl; width: 100; height: 60 } }",
            root)
        tryCompare(scene.ctrlRef, "extTLx", 10, 1000) // 几何绑定落定
        const shape = scene.shapeRef
        verify(shape.control === scene.ctrlRef, "required control 注入")
        verify(shape.containmentMask === scene.ctrlRef, "直角变体掩码应直挂 control")
        // 渲染接线：外环/内环两条 ShapePath 分别消费 control 的 ext*/int*
        // 起点（borderWidth=4 → 内环收缩，两起点可区分）；绑定异步，轮询
        tryVerify(function() {
            if (shape.data.length < 2) return false
            let extStart = false
            let intStart = false
            for (let i = 0; i < shape.data.length; ++i) {
                const p = shape.data[i]
                if (fuzzy_eq(p.startX, scene.ctrlRef.extTLx)
                        && fuzzy_eq(p.startY, scene.ctrlRef.extTLy))
                    extStart = true
                if (fuzzy_eq(p.startX, scene.ctrlRef.intTLx)
                        && fuzzy_eq(p.startY, scene.ctrlRef.intTLy))
                    intStart = true
            }
            return extStart && intStart
        }, 1000, "路径应消费 control 的 ext*/int* 起点")
        // 掩码委托命中判定（直接调用 contains——与 tst_crystal 同契约；
        // 真实鼠标路径由 C++ tst_hover_e2e 批次覆盖）
        verify(shape.containmentMask.contains(Qt.point(50, 30)), "中心应命中")
        verify(!shape.containmentMask.contains(Qt.point(3, 3)), "左上切角区不应命中")
    }

    function test_variantRequiresControl() {
        // required control 不注入 → 运行时拒绝实例化（createTemporaryQmlObject
        // 抛异常）——低级组成件"独立使用不自洽是刻意"的契约行为（文档明示）
        let rejected = false
        try {
            createTemporaryQmlObject("import Qool; OctagonShape {}", root)
        } catch (e) {
            rejected = true
        }
        verify(rejected, "OctagonShape 缺 control 应拒绝实例化")
        rejected = false
        try {
            createTemporaryQmlObject("import Qool; OctagonCurvedShape {}", root)
        } catch (e) {
            rejected = true
        }
        verify(rejected, "OctagonCurvedShape 缺 control 应拒绝实例化")
    }

    function test_curvedInnerRadius() {
        // QoolBox 圆角变体：内弧半径 = 内环相邻点弦长/√2（四角独立）。
        // cut=40 > half=30 保持圆角变体（否则退行矩形）；borderWidth=0
        // → 内环 = 外环，弦长 = cut·√2 → 半径绝对值 = cut（哨兵防点错环）
        const box = makeBox(100, 60)
        box.settings.curved = true
        box.settings.borderWidth = 0
        setCuts(box, 40, 40, 40, 40)
        expectShapeType(box, "curved", "圆角")
        tryCompare(box.control, "intTLx", 40, 1000) // 几何绑定落定
        const p = firstPathWithPCtrl(box.shape)
        verify(p !== null, "圆角变体应含内弧半径计算路径")
        const corners = ["TL", "TR", "BL", "BR"]
        for (let i = 0; i < corners.length; ++i) {
            const c = corners[i]
            const expected = chordRadius(box.control, c)
            tryVerify(function() {
                return fuzzy_eq(p.pCtrl["radius" + c], expected)
            }, 1000, c + " 内弧半径应等于内环相邻点弦长/√2")
            tryVerify(function() {
                return fuzzy_eq(p.pCtrl["radius" + c], 40)
            }, 1000, c + " 内弧半径绝对值（cut=40、borderWidth=0）")
        }
    }

    function test_curvedInnerRadiusDegenerate() {
        // cut=0 → 内环相邻点重合，弦长 0 → 半径 0（退化自洽）。独立实例化
        // 圆角变体承载本场景——QoolBox 在四角全 0 时已退行矩形（无圆角路径）
        const scene = createTemporaryQmlObject(
            "import QtQuick; import Qool; Item { id: h; width: 100; height: 60; "
            + "property alias ctrlRef: ctrl; property alias shapeRef: shape; "
            + "QoolBoxShapeControl { id: ctrl; target: h; settings: st } "
            + "QoolBoxSettings { id: st; cutSizeTL: 10; cutSizeTR: 10; cutSizeBL: 10; cutSizeBR: 10 } "
            + "OctagonCurvedShape { id: shape; control: ctrl; width: 100; height: 60 } }",
            root)
        tryCompare(scene.ctrlRef, "intTLx", 10, 1000)
        const p = firstPathWithPCtrl(scene.shapeRef)
        verify(p !== null, "独立圆角变体应含内弧半径计算路径")
        tryVerify(function() { return fuzzy_eq(p.pCtrl.radiusTL, 10) }, 1000,
            "cut=10 时内弧半径应 = 10（弦长/√2）")
        scene.ctrlRef.settings.cutSizeTL = 0
        scene.ctrlRef.settings.cutSizeTR = 0
        scene.ctrlRef.settings.cutSizeBL = 0
        scene.ctrlRef.settings.cutSizeBR = 0
        tryVerify(function() { return fuzzy_eq(p.pCtrl.radiusTL, 0, 1e-9) }, 1000,
            "cut=0 时弦长 0 → 半径 0（退化自洽）")
    }
}
