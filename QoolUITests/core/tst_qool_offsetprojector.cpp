// Qool 核心 C++ 类型测试：OffsetProjector（Qool/shapecontrol/）
//
// 被测面：
//   - 投影精确性——v = direction_unit × refDistance / (direction_unit ·
//     refDirection_unit)：同向、45° 非单位输入 (1,1)、度量方向切换、
//     22.5° 夹角折算（v·refDirection_unit == refDistance 恒成立）
//   - 退化契约（spec「退化契约」）——零向量输入、两方向正交（proj≈0）、
//     refDistance == 0 → offset 零向量
//   - 短路语义——输入变化但实际结果不变时不发 offsetChanged（refDistance==0
//     时 direction/refDirection 变化不传播）；恢复非零后链条自动恢复
//   - 符号规则——点积 ≤ 0 不校验，offset 反向（方向对配错的可观察症状）
//
// 契约依据（qool_offsetprojector.cpp 文件头文档）：
//   offset 满足 offset ∥ direction_unit 且 offset·refDirection_unit ==
//   refDistance；默认值 (1,0)/(1,0)/0 → 独立使用 offset 恒零向量。

#include <QtTest>

#include "qool_test.hpp"

#include "shapecontrol/qool_offsetprojector.h"

#include <cmath>

using namespace qoolui;

namespace {

bool fuzzy_eq(qreal actual, qreal expected, qreal eps = 1e-4) {
  return std::abs(actual - expected) <= eps;
}

bool fuzzy_vec(const QVector2D& actual, qreal ex, qreal ey,
    qreal eps = 1e-4) {
  return fuzzy_eq(actual.x(), ex, eps) && fuzzy_eq(actual.y(), ey, eps);
}

} // namespace

class TestOffsetProjectorUnit : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(defaults_zero) {
  // 独立使用（不设任何属性）→ refDistance=0 → offset 恒零向量
  OffsetProjector p;
  QVERIFY(fuzzy_vec(p.offset(), 0, 0));
}

  QOOL_TEST_CASE(projection_aligned) {
  // 同向：direction=refDirection=(1,0)，d=10 → offset=(10,0)
  OffsetProjector p;
  p.set_refDistance(10);
  QVERIFY(fuzzy_vec(p.offset(), 10, 0));
}

  QOOL_TEST_CASE(projection_45deg) {
  // 45° 非单位输入：direction=(1,1) → m=(√2/2,√2/2)，proj=√2/2
  // offset = m × 10/(√2/2) = (10,10)——v·refDirection_unit == 10
  OffsetProjector p;
  p.set_refDistance(10);
  p.set_direction(QVector2D(1, 1));
  QVERIFY(fuzzy_vec(p.offset(), 10, 10));
}

  QOOL_TEST_CASE(projection_measure_direction_switch) {
  // 度量方向切换：refDirection=(0,1) 后 v·r 仍 == refDistance → (10,10)
  OffsetProjector p;
  p.set_refDistance(10);
  p.set_direction(QVector2D(1, 1));
  p.set_refDirection(QVector2D(0, 1));
  QVERIFY(fuzzy_vec(p.offset(), 10, 10));
}

  QOOL_TEST_CASE(projection_22_5deg) {
  // 22.5° 夹角折算：direction=(1, tan22.5°)，r=(1,0)，d=10
  // v·r = 10 → vx = 10；vy = 10·tan22.5° ≈ 4.1421356
  OffsetProjector p;
  p.set_refDistance(10);
  p.set_direction(QVector2D(1, 0.41421356));
  QVERIFY(fuzzy_vec(p.offset(), 10, 4.1421356));
}

  QOOL_TEST_CASE(degenerate_zero_direction) {
  // 零向量 direction → normalized() 返回零向量 → proj=0 → offset 零向量
  OffsetProjector p;
  p.set_refDistance(5);
  p.set_direction(QVector2D(0, 0));
  QVERIFY(fuzzy_vec(p.offset(), 0, 0));
}

  QOOL_TEST_CASE(degenerate_zero_ref_direction) {
  OffsetProjector p;
  p.set_refDistance(5);
  p.set_direction(QVector2D(1, 1));
  p.set_refDirection(QVector2D(0, 0));
  QVERIFY(fuzzy_vec(p.offset(), 0, 0));
}

  QOOL_TEST_CASE(degenerate_orthogonal) {
  // 两方向正交（proj≈0，qFuzzyIsNull 容差）→ offset 零向量
  OffsetProjector p;
  p.set_refDistance(5);
  p.set_direction(QVector2D(0, 1));
  p.set_refDirection(QVector2D(1, 0));
  QVERIFY(fuzzy_vec(p.offset(), 0, 0));
}

  QOOL_TEST_CASE(degenerate_zero_distance) {
  // refDistance == 0 → 提前短路 → offset 零向量
  OffsetProjector p;
  p.set_refDistance(0);
  p.set_direction(QVector2D(1, 1));
  p.set_refDirection(QVector2D(1, 0));
  QVERIFY(fuzzy_vec(p.offset(), 0, 0));
}

  QOOL_TEST_CASE(short_circuit_no_notify_when_zero_distance) {
  // 短路：refDistance==0 时 direction/refDirection 变化不产生
  // offsetChanged（结果恒零向量，相等守卫）——下游无假更新
  OffsetProjector p;
  p.set_refDistance(0);
  QSignalSpy spy(&p, &OffsetProjector::offsetChanged);
  p.set_direction(QVector2D(0, 1));
  p.set_refDirection(QVector2D(1, 1));
  QCOMPARE(spy.count(), 0);
}

  QOOL_TEST_CASE(short_circuit_recovers) {
  // 恢复非零后链条自动恢复：offset 更新 + 通知发出
  // 注：direction=(0,1) 与 refDirection=(1,0) 正交 → 恢复 refDistance 后
  // offset 仍恒零（无通知）是正确行为——恢复路径须用非正交方向对
  OffsetProjector p;
  p.set_refDistance(0);
  QSignalSpy spy(&p, &OffsetProjector::offsetChanged);
  p.set_direction(QVector2D(0, 1));
  QCOMPARE(spy.count(), 0);
  p.set_refDirection(QVector2D(0, 1)); // 与 direction 同向（d==0 仍短路）
  QCOMPARE(spy.count(), 0);
  p.set_refDistance(5); // 恢复：m=(0,1), proj=1 → offset=(0,5) 变化 → 通知
  QCOMPARE(spy.count(), 1);
  QVERIFY(fuzzy_vec(p.offset(), 0, 5));
}

  QOOL_TEST_CASE(sign_reversed) {
  // 符号规则：点积 < 0 不校验 → offset 反向
  // 期望方向 (-1,0)（负 x），输出 (5,0)（正 x）——描边向几何外扩张症状
  OffsetProjector p;
  p.set_refDistance(5);
  p.set_direction(QVector2D(-1, 0));
  p.set_refDirection(QVector2D(1, 0));
  QVERIFY(fuzzy_vec(p.offset(), 5, 0));
}
};

QTEST_MAIN(TestOffsetProjectorUnit)

#include "tst_qool_offsetprojector.moc"
