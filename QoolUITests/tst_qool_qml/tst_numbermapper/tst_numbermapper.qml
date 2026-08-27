import QtQuick
import QtTest
import Qool

// NumberMapper 行为契约测试（QML 面）
//
// 被测契约（docs/reference/Qool/NumberMapper.md）：
// - valueAt：无 stop→0 / 单 stop→该值 / 多 stop 分段线性插值 /
//   超界 clamp 到端点 / 命中返回精确值 / 乱序 stops 内部排序
// - 排序缓存：stop position 变化后 valueAt 用新排序（缓存失效契约）
// - positionN 默认 N/10（0.0..0.9）、valueN == valueAt(positionN)
// - stops 变化 → valueNChanged 跟随（QML 可观察面）
//
// 隔离策略：每个测试函数 createTemporaryObject 独立场景（状态隔离规范）。
// 场景内 id 经 property alias 暴露（scene.stopA 等）。

TestCase {
    id: root

    name: "NumberMapper"
    width: 200
    height: 200

    function fuzzyEq(a, b, eps) {
        return Math.abs(a - b) <= (eps === undefined ? 1e-9 : eps)
    }

    function makeSpy(target, signalName) {
        const spy = Qt.createQmlObject("import QtTest; SignalSpy {}", root)
        spy.target = target
        spy.signalName = signalName
        return spy
    }

    Component {
        id: emptyComp
        NumberMapper {}
    }

    Component {
        id: singleStopComp
        NumberMapper {
            NumberMapperStop { position: 0.3; value: 7.5 }
        }
    }

    Component {
        id: twoStopComp
        NumberMapper {
            NumberMapperStop { position: 0.0; value: 0.0 }
            NumberMapperStop { position: 1.0; value: 10.0 }
        }
    }

    Component {
        id: clampedComp
        NumberMapper {
            NumberMapperStop { position: 0.2; value: 1.0 }
            NumberMapperStop { position: 0.8; value: 9.0 }
        }
    }

    Component {
        id: unsortedComp
        NumberMapper {
            NumberMapperStop { position: 1.0; value: 10.0 }
            NumberMapperStop { position: 0.0; value: 0.0 }
            NumberMapperStop { position: 0.5; value: 5.0 }
        }
    }

    Component {
        id: swappableComp
        NumberMapper {
            property alias stopA: a
            property alias stopB: b
            NumberMapperStop { id: a; position: 0.0; value: 0.0 }
            NumberMapperStop { id: b; position: 1.0; value: 10.0 }
        }
    }

    function test_noStops_returnsZero() {
        const mapper = createTemporaryObject(emptyComp, root)
        compare(mapper.valueAt(0.5), 0)
        compare(mapper.valueAt(-1.0), 0)
    }

    function test_singleStop_constant() {
        const mapper = createTemporaryObject(singleStopComp, root)
        verify(fuzzyEq(mapper.valueAt(0.0), 7.5))
        verify(fuzzyEq(mapper.valueAt(0.3), 7.5))
        verify(fuzzyEq(mapper.valueAt(1.0), 7.5))
    }

    function test_interpolation() {
        const mapper = createTemporaryObject(twoStopComp, root)
        verify(fuzzyEq(mapper.valueAt(0.5), 5.0))
        verify(fuzzyEq(mapper.valueAt(0.25), 2.5))
        // 命中端点返回精确值
        verify(fuzzyEq(mapper.valueAt(0.0), 0.0))
        verify(fuzzyEq(mapper.valueAt(1.0), 10.0))
    }

    function test_clamped_outOfRange() {
        const mapper = createTemporaryObject(clampedComp, root)
        // 超界 clamp 到端点（不外推）
        verify(fuzzyEq(mapper.valueAt(0.0), 1.0))
        verify(fuzzyEq(mapper.valueAt(0.19), 1.0))
        verify(fuzzyEq(mapper.valueAt(0.81), 9.0))
        verify(fuzzyEq(mapper.valueAt(5.0), 9.0))
    }

    function test_unsortedStops_sortedInternally() {
        const mapper = createTemporaryObject(unsortedComp, root)
        verify(fuzzyEq(mapper.valueAt(0.25), 2.5))
        verify(fuzzyEq(mapper.valueAt(0.75), 7.5))
        verify(fuzzyEq(mapper.valueAt(0.5), 5.0))
    }

    function test_cacheInvalidation_onPositionChange() {
        // 排序缓存失效契约：stop position 变化后 valueAt 按新排序计算
        const mapper = createTemporaryObject(swappableComp, root)
        verify(fuzzyEq(mapper.valueAt(0.5), 5.0))
        // 交换位置：a→1.0，b→0.0 → 排序反转
        mapper.stopA.position = 1.0
        mapper.stopB.position = 0.0
        // 新排序：(b@0,10) (a@1,0) → 中点 5
        verify(fuzzyEq(mapper.valueAt(0.5), 5.0))
        verify(fuzzyEq(mapper.valueAt(0.25), 7.5))
        verify(fuzzyEq(mapper.valueAt(0.75), 2.5))
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

    function test_valueSamples_equalValueAt() {
        const mapper = createTemporaryObject(twoStopComp, root)
        for (let n = 0; n <= 9; ++n) {
            const pn = mapper["position" + n]
            const vn = mapper["value" + n]
            verify(fuzzyEq(vn, mapper.valueAt(pn)),
                   "value" + n + " != valueAt(position" + n + ")")
        }
        // value9 = valueAt(0.9) = 9.0
        verify(fuzzyEq(mapper.value9, 9.0))
    }

    function test_stops_declaredAsDefaultProperty() {
        // stops 是默认属性：QML 声明子对象即参与插值（twoStopComp 契约面）
        // 不索引访问 stops（QQmlListProperty 暴露属 Qt 引擎机制，非契约）
        const mapper = createTemporaryObject(twoStopComp, root)
        verify(fuzzyEq(mapper.valueAt(0.5), 5.0))
    }

    function test_positionChange_notifiesValueSamples() {
        const mapper = createTemporaryObject(twoStopComp, root)
        const spy = makeSpy(mapper, "value5Changed")
        // position5 默认 0.5 → 改成 0.7 → value5Changed
        mapper.position5 = 0.7
        compare(spy.count, 1)
        // 相等守卫：同值赋值不发
        mapper.position5 = 0.7
        compare(spy.count, 1)
    }
}
