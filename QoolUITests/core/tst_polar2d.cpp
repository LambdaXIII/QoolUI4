// Qool 核心 C++ 类型测试：Polar2D（Qool/datatypes/qool_polar2d.h）
//
// 被测面：Q_GADGET 值类型 Polar2D（极坐标）的构造、转换、属性、运算、
// 相等比较与拷贝语义。
// 与 Vector2D 互补：极坐标形态（radius/radians）与笛卡尔形态的互转。
// QCoreApplication 环境即可（不实例化 QQuickItem）。

#include <QtTest>

#include "qool_test.hpp"

#include "datatypes/qool_polar2d.h"

#include <cmath>

using namespace qoolui;

namespace {

bool fuzzy_eq(double actual, double expected, double eps = 1e-6) {
  return std::abs(actual - expected) <= eps;
}

bool fuzzy_eq(const QVector2D& actual, const QVector2D& expected,
  double eps = 1e-6) {
  return fuzzy_eq(actual.x(), expected.x(), eps)
         && fuzzy_eq(actual.y(), expected.y(), eps);
}

} // namespace

class TestPolar2D : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(vector_construction) {
  // 3-4-5 三角形：radius = 5，radians = atan2(4, 3)
  const Polar2D p(QVector2D(3, 4));
  QVERIFY(fuzzy_eq(p.radius(), 5.0));
  QVERIFY(fuzzy_eq(p.radians(), std::atan2(4.0, 3.0)));
  QVERIFY(!p.isZero());
}
  QOOL_TEST_CASE(points_construction) {
  // from/to 两点 → 差向量转极坐标
  const Polar2D p(QPointF(1, 1), QPointF(4, 5));
  QVERIFY(fuzzy_eq(p.radius(), 5.0));
  QVERIFY(fuzzy_eq(p.radians(), std::atan2(4.0, 3.0)));
}
  QOOL_TEST_CASE(radius_radians_construction) {
  const Polar2D p(5, M_PI / 2);
  QVERIFY(fuzzy_eq(p.radius(), 5.0));
  QVERIFY(fuzzy_eq(p.radians(), M_PI / 2));
}
  QOOL_TEST_CASE(negative_radius_flips_angle) {
  // 负半径规范化：半径取绝对值，角度翻转 180°
  // 注意：翻转后角度经 fmod 归一化到 [-π, π)（π → -π 等价，方向相同）
  const Polar2D p(-5, 0);
  QVERIFY(fuzzy_eq(p.radius(), 5.0));
  QVERIFY(fuzzy_eq(p.vector(), QVector2D(-5, 0))); // 方向断言不受 ±π 归一化影响
  // 负半径 + 已有角度：角度 = 原角度 + π（归一化到 [-π, π)）
  const Polar2D q(-1, M_PI / 2);
  QVERIFY(fuzzy_eq(q.radius(), 1.0));
  QVERIFY(fuzzy_eq(q.vector(), QVector2D(0, -1))); // π/2 + π = 3π/2 → -π/2
}
  QOOL_TEST_CASE(zero_vector) {
  const Polar2D p(QVector2D(0, 0));
  QVERIFY(p.isZero());
  QVERIFY(fuzzy_eq(p.radius(), 0.0));
  QVERIFY(fuzzy_eq(p.radians(), 0.0));
  QCOMPARE(p.vector(), QVector2D(0, 0));
  // 零半径：方向无意义，任何角度都判等（见 equality）
}
  QOOL_TEST_CASE(conversions) {
  const Polar2D p(QVector2D(3, 4));
  const QVector2D as_vector = p;
  QVERIFY(fuzzy_eq(as_vector, QVector2D(3, 4)));
  const QPointF as_point = p;
  QVERIFY(fuzzy_eq(as_point.x(), 3.0));
  QVERIFY(fuzzy_eq(as_point.y(), 4.0));
}
  QOOL_TEST_CASE(degrees_and_vector_properties) {
  // degrees：radians → 度
  const Polar2D p(5, M_PI / 2);
  QVERIFY(fuzzy_eq(p.degrees(), 90.0));
  const Polar2D q(2, M_PI);
  QVERIFY(fuzzy_eq(q.degrees(), 180.0));
  // vector：极坐标 → 笛卡尔
  const Polar2D r(5, 0);
  QVERIFY(fuzzy_eq(r.vector(), QVector2D(5, 0)));
  const Polar2D s(5, M_PI / 2);
  QVERIFY(fuzzy_eq(s.vector(), QVector2D(0, 5)));
}
  QOOL_TEST_CASE(normalized) {
  // normalized：单位半径，方向不变
  const Polar2D p(7, 1.0);
  const auto n = p.normalized();
  QVERIFY(fuzzy_eq(n.radius(), 1.0));
  QVERIFY(fuzzy_eq(n.radians(), 1.0));
  // 零向量归一化：半径 1、角度保持（0）
  const auto zn = Polar2D(QVector2D(0, 0)).normalized();
  QVERIFY(fuzzy_eq(zn.radius(), 1.0));
  QVERIFY(fuzzy_eq(zn.radians(), 0.0));
}
  QOOL_TEST_CASE(addition_subtraction) {
  // 极坐标加法/减法在笛卡尔空间进行（向量和/差）
  const Polar2D a(QVector2D(3, 4));
  const Polar2D b(QVector2D(1, -1));
  const auto sum = a + b;
  QVERIFY(fuzzy_eq(sum.vector(), QVector2D(4, 3)));
  QVERIFY(fuzzy_eq(sum.radius(), 5.0));
  const auto diff = a - b;
  QVERIFY(fuzzy_eq(diff.vector(), QVector2D(2, 5)));
  // 与 QVector2D 混合运算
  const auto withVec = a + QVector2D(1, -1);
  QVERIFY(fuzzy_eq(withVec.vector(), QVector2D(4, 3)));
  const auto withVecDiff = a - QVector2D(1, -1);
  QVERIFY(fuzzy_eq(withVecDiff.vector(), QVector2D(2, 5)));
}
  QOOL_TEST_CASE(unary_minus) {
  // 一元负：方向反转（负半径翻转角度 = 加 π）
  const Polar2D p(QVector2D(3, 4));
  const auto neg = -p;
  QVERIFY(fuzzy_eq(neg.vector(), QVector2D(-3, -4)));
  QVERIFY(fuzzy_eq(neg.radius(), 5.0));
}
  QOOL_TEST_CASE(scale_multiply) {
  // 乘标量 = 半径缩放，方向不变（极坐标的标量乘法语义）
  const Polar2D p(3, 0.5);
  const auto doubled = p * 2.0;
  QVERIFY(fuzzy_eq(doubled.radius(), 6.0));
  QVERIFY(fuzzy_eq(doubled.radians(), 0.5));
  // 缩放 0 → 零向量
  const auto zeroed = p * 0.0;
  QVERIFY(zeroed.isZero());
}
  QOOL_TEST_CASE(scale_divide) {
  // 除标量 = 半径缩放
  const Polar2D p(6, 0.5);
  const auto halved = p / 2.0;
  QVERIFY(fuzzy_eq(halved.radius(), 3.0));
  QVERIFY(fuzzy_eq(halved.radians(), 0.5));
}
  QOOL_TEST_CASE(equality) {
  // 相同 radius + radians 判等
  QVERIFY(Polar2D(3, 0.5) == Polar2D(3, 0.5));
  QVERIFY(Polar2D(3, 0.5) != Polar2D(4, 0.5));
  QVERIFY(Polar2D(3, 0.5) != Polar2D(3, 1.0));
  // 负半径构造与等价正半径翻转：实现把翻转角度归一化到 [-π, π)
  // （-π 边界），与显式 π 精确比较不等——几何等价用向量断言
  {
    const Polar2D neg(-5, 0);
    const Polar2D pos(5, M_PI);
    QVERIFY(fuzzy_eq(neg.vector(), pos.vector()));
    QVERIFY(fuzzy_eq(neg.radius(), pos.radius()));
  }
  // 零半径：角度无意义，判等
  QVERIFY(Polar2D(QVector2D(0, 0)) == Polar2D(0, 1.5));
  // 构造路径等价性：QVector2D（float 精度）与 double 直构的半径/角度
  // 存在浮点差异，operator== 是精确比较——用向量近似断言（非精确判等）
  const Polar2D fromVec(QVector2D(3, 4));
  const Polar2D fromRad(5, std::atan2(4.0, 3.0));
  QVERIFY(fuzzy_eq(fromVec.vector(), fromRad.vector()));
  QVERIFY(fuzzy_eq(fromVec.radius(), fromRad.radius()));
}
  QOOL_TEST_CASE(copy_semantics) {
  const Polar2D a(QVector2D(3, 4));
  const Polar2D b(a); // 拷贝构造
  QVERIFY(fuzzy_eq(b.radius(), a.radius()));
  QVERIFY(fuzzy_eq(b.radians(), a.radians()));

  Polar2D c;
  c = a; // 拷贝赋值
  QVERIFY(fuzzy_eq(c.radius(), a.radius()));
  QVERIFY(fuzzy_eq(c.radians(), a.radians()));
  QVERIFY(c == a);
}
  QOOL_TEST_CASE(gadget_property_contract) {
  // Q_GADGET 属性契约：QML 暴露的 4 个属性必须注册（公开即承诺）
  const auto& mo = Polar2D::staticMetaObject;
  const char* const expected[] = { "radius", "radians", "degrees", "vector" };
  for (const char* name : expected) {
    const int idx = mo.indexOfProperty(name);
    QVERIFY2(idx >= 0, qPrintable(QString("缺少属性: %1").arg(name)));
    QVERIFY2(mo.property(idx).isValid(),
             qPrintable(QString("属性无效: %1").arg(name)));
    QVERIFY2(mo.property(idx).isReadable(),
             qPrintable(QString("属性不可读: %1").arg(name)));
  }
}
};

QTEST_MAIN(TestPolar2D)

#include "tst_polar2d.moc"
