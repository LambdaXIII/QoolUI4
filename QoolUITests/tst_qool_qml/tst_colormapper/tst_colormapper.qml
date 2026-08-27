import QtQuick
import QtTest
import Qool

// ColorMapper 行为契约测试（QML 面）
//
// 被测契约（docs/reference/Qool/ColorMapper.md）：
// - colorAt：无 stop→Qt.white / 单 stop→该色 / 双 stop 通道插值 /
//   命中返回精确色 / 超界 clamp 到端点（B3 修复）/ 乱序 stops 内部排序
// - 排序缓存：stop position 变化后 colorAt 用新排序（B2 修复）
// - mode 插值空间（RGB/HSV/HSL/CMYK）
// - positionN 默认 N/10（B1 修复）、colorN == colorAt(positionN)
// - stops/mode/positionN 变化 → colorNChanged 跟随（QML 可观察面）
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（状态隔离规范）。

TestCase {
    id: root

    name: "ColorMapper"
    width: 200
    height: 200

    function fuzzyEq(a, b, eps) {
        // QML color.r/g/b 是 0.0-1.0 浮点；容差 1e-3 覆盖
        // QColor 16-bit 存储 + remap 的量化误差
        return Math.abs(a - b) <= (eps === undefined ? 1e-3 : eps)
    }

    function makeSpy(target, signalName) {
        const spy = Qt.createQmlObject("import QtTest; SignalSpy {}", root)
        spy.target = target
        spy.signalName = signalName
        return spy
    }

    Component {
        id: emptyComp
        ColorMapper {}
    }

    Component {
        id: singleStopComp
        ColorMapper {
            ColorMapperStop { position: 0.3; color: "red" }
        }
    }

    Component {
        id: blackWhiteComp
        ColorMapper {
            ColorMapperStop { position: 0.0; color: "black" }
            ColorMapperStop { position: 1.0; color: "white" }
        }
    }

    Component {
        id: clampedComp
        ColorMapper {
            ColorMapperStop { position: 0.2; color: "red" }
            ColorMapperStop { position: 0.8; color: "blue" }
        }
    }

    Component {
        id: unsortedComp
        ColorMapper {
            ColorMapperStop { position: 1.0; color: "white" }
            ColorMapperStop { position: 0.0; color: "black" }
        }
    }

    Component {
        id: swappableComp
        ColorMapper {
            property alias stopA: a
            property alias stopB: b
            ColorMapperStop { id: a; position: 0.0; color: "black" }
            ColorMapperStop { id: b; position: 1.0; color: "white" }
        }
    }

    function test_noStops_returnsWhite() {
        const mapper = createTemporaryObject(emptyComp, root)
        compare(mapper.colorAt(0.5), "#ffffff")
    }

    function test_singleStop_constant() {
        const mapper = createTemporaryObject(singleStopComp, root)
        compare(mapper.colorAt(0.0), "#ff0000")
        compare(mapper.colorAt(0.3), "#ff0000")
        compare(mapper.colorAt(1.0), "#ff0000")
    }

    function test_rgbInterpolation() {
        const mapper = createTemporaryObject(blackWhiteComp, root)
        const mid = mapper.colorAt(0.5)
        // QML color.r 是 0.0-1.0：黑→白中点 = 0.5
        verify(fuzzyEq(mid.r, 0.5))
        verify(fuzzyEq(mid.g, 0.5))
        verify(fuzzyEq(mid.b, 0.5))
        // 命中端点返回精确色
        compare(mapper.colorAt(0.0), "#000000")
        compare(mapper.colorAt(1.0), "#ffffff")
    }

    function test_clamped_outOfRange() {
        // B3 修复：超界 clamp 到端点（不外推、不读越界）
        const mapper = createTemporaryObject(clampedComp, root)
        compare(mapper.colorAt(0.0), "#ff0000")
        compare(mapper.colorAt(0.19), "#ff0000")
        compare(mapper.colorAt(0.81), "#0000ff")
        compare(mapper.colorAt(5.0), "#0000ff")
    }

    function test_unsortedStops_sortedInternally() {
        const mapper = createTemporaryObject(unsortedComp, root)
        const mid = mapper.colorAt(0.5)
        verify(fuzzyEq(mid.r, 0.5))
        compare(mapper.colorAt(0.0), "#000000")
        compare(mapper.colorAt(1.0), "#ffffff")
    }

    function test_cacheInvalidation_onPositionChange() {
        // B2 修复：stop position 变化后 colorAt 按新排序计算
        const mapper = createTemporaryObject(swappableComp, root)
        verify(fuzzyEq(mapper.colorAt(0.5).r, 0.5))
        // 交换位置：a→1.0（白），b→0.0（黑）→ 排序反转
        mapper.stopA.position = 1.0
        mapper.stopB.position = 0.0
        // 新排序：(b@0,白) (a@1,黑) → 端点互换
        compare(mapper.colorAt(0.0), "#ffffff")
        compare(mapper.colorAt(1.0), "#000000")
        const mid = mapper.colorAt(0.5)
        verify(fuzzyEq(mid.r, 0.5))
    }

    function test_mode_interpolationSpaces() {
        // 四种 mode 都可插值（黑→白 在任何空间有定义）
        const modes = [ColorMapper.RGB, ColorMapper.HSV,
                       ColorMapper.HSL, ColorMapper.CMYK]
        for (const mode of modes) {
            const mapper = createTemporaryObject(blackWhiteComp, root)
            mapper.mode = mode
            const mid = mapper.colorAt(0.5)
            verify(mid.valid, "mode " + mode + " 插值结果无效")
        }
    }

    function test_positionDefaults() {
        // B1 修复：positionN 默认 N/10（浮点除法）
        const mapper = createTemporaryObject(emptyComp, root)
        compare(mapper.position0, 0.0)
        compare(mapper.position1, 0.1)
        compare(mapper.position2, 0.2)
        compare(mapper.position5, 0.5)
        compare(mapper.position9, 0.9)
    }

    function test_colorSamples_equalColorAt() {
        const mapper = createTemporaryObject(blackWhiteComp, root)
        for (let n = 0; n <= 9; ++n) {
            const pn = mapper["position" + n]
            const cn = mapper["color" + n]
            verify(cn === mapper.colorAt(pn),
                   "color" + n + " != colorAt(position" + n + ")")
        }
        // color9 = colorAt(0.9) ≈ 90% 白（0-1 尺度 0.9）
        verify(fuzzyEq(mapper.color9.r, 0.9))
    }

    function test_stops_declaredAsDefaultProperty() {
        // stops 是默认属性：QML 声明子对象即参与插值（blackWhiteComp 契约面）
        // 不索引访问 stops（QQmlListProperty 暴露属 Qt 引擎机制，非契约）
        const mapper = createTemporaryObject(blackWhiteComp, root)
        verify(fuzzyEq(mapper.colorAt(0.5).r, 0.5))
    }

    function test_modeChange_notifiesColorSamples() {
        const mapper = createTemporaryObject(blackWhiteComp, root)
        const spy = makeSpy(mapper, "color0Changed")
        mapper.mode = ColorMapper.HSV
        compare(spy.count, 1)
    }

    function test_positionChange_notifiesColorSamples() {
        const mapper = createTemporaryObject(blackWhiteComp, root)
        const spy = makeSpy(mapper, "color5Changed")
        // position5 默认 0.5 → 改 0.7 → color5Changed
        mapper.position5 = 0.7
        compare(spy.count, 1)
        // 相等守卫：同值不发
        mapper.position5 = 0.7
        compare(spy.count, 1)
    }
}
