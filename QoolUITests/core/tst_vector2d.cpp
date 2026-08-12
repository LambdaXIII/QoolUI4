// Qool 核心 C++ 类型测试：Vector2D（Qool/datatypes/qool_vector2d.h）
//
// 被测面：Q_GADGET 值类型 Vector2D 的构造、运算符、转换、静态工厂、
// Q_GADGET 属性契约（QML 暴露属性）与相等比较。
// QCoreApplication 环境即可（不实例化 QQuickItem）。

#include <QtTest>

#include "qool_test.hpp"

#include "datatypes/qool_vector2d.h"

#include <cmath>

using namespace qoolui;

namespace {

bool fuzzy_eq(double actual, double expected, double eps = 1e-6) {
  return std::abs(actual - expected) <= eps;
}

} // namespace

class TestVector2D : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(default_construction) {
  const Vector2D v;
  QCOMPARE(v.from(), QPointF(0, 0));
  QCOMPARE(v.vector(), QVector2D(0, 0));
  QCOMPARE(v.to(), QPointF(0, 0));
  QCOMPARE(v.length(), 0.0);
  QCOMPARE(v.x(), 0.0);
  QCOMPARE(v.y(), 0.0);
  QVERIFY(v.isZero());
}
  QOOL_TEST_CASE(two_point_construction) {
  const Vector2D v(QPointF(0, 0), QPointF(3, 4));
  QCOMPARE(v.from(), QPointF(0, 0));
  QCOMPARE(v.vector(), QVector2D(3, 4));
  QCOMPARE(v.to(), QPointF(3, 4));
  QCOMPARE(v.length(), 5.0);
  QCOMPARE(v.x(), 3.0);
  QCOMPARE(v.y(), 4.0);

  // 非零起点：vector 仍为终点 - 起点
  const Vector2D shifted(QPointF(1, 1), QPointF(4, 5));
  QCOMPARE(shifted.from(), QPointF(1, 1));
  QCOMPARE(shifted.vector(), QVector2D(3, 4));
  QCOMPARE(shifted.to(), QPointF(4, 5));
}
  QOOL_TEST_CASE(from_vector2d_construction) {
  const Vector2D v(QVector2D(6, 8));
  QCOMPARE(v.from(), QPointF(0, 0));
  QCOMPARE(v.vector(), QVector2D(6, 8));
  QCOMPARE(v.length(), 10.0);
}
  QOOL_TEST_CASE(static_factories) {
  // fromVector：显式带起点
  const auto v = Vector2D::fromVector(QVector2D(3, 4), QPointF(10, 20));
  QCOMPARE(v.from(), QPointF(10, 20));
  QCOMPARE(v.vector(), QVector2D(3, 4));

  // fromWayPoints：首尾点；空列表回退到原点
  const auto wp = Vector2D::fromWayPoints({ QPointF(1, 2), QPointF(4, 6) });
  QCOMPARE(wp.from(), QPointF(1, 2));
  QCOMPARE(wp.vector(), QVector2D(3, 4));
  const auto empty = Vector2D::fromWayPoints({});
  QCOMPARE(empty.from(), QPointF(0, 0));
  QCOMPARE(empty.vector(), QVector2D(0, 0));

  // fromVectors：向量求和
  const auto sum =
    Vector2D::fromVectors({ QVector2D(1, 2), QVector2D(3, 4) });
  QCOMPARE(sum.vector(), QVector2D(4, 6));
  const auto zero_sum = Vector2D::fromVectors({});
  QCOMPARE(zero_sum.vector(), QVector2D(0, 0));
}
  QOOL_TEST_CASE(arithmetic_plus_vector) {
  const Vector2D v(QPointF(1, 1), QPointF(4, 5)); // vector (3,4)
  const auto sum = v + QVector2D(1, -1);
  QCOMPARE(sum.from(), QPointF(1, 1)); // 起点不变
  QCOMPARE(sum.vector(), QVector2D(4, 3));
  QCOMPARE(sum.to(), QPointF(5, 4));
}
  QOOL_TEST_CASE(arithmetic_length) {
  const Vector2D v(QVector2D(3, 4)); // length 5
  // 正延长：方向不变，长度 +2
  const auto longer = v + 5.0;
  QCOMPARE(longer.vector(), QVector2D(6, 8));
  QCOMPARE(longer.length(), 10.0);
  // 缩短：长度 -2（3-4-5 缩放为 1.8/2.4）
  const auto shorter = v - 2.0;
  QVERIFY(fuzzy_eq(shorter.length(), 3.0));
  QVERIFY(fuzzy_eq(shorter.x(), 1.8));
  QVERIFY(fuzzy_eq(shorter.y(), 2.4));
}
  QOOL_TEST_CASE(arithmetic_scale) {
  const Vector2D v(QVector2D(3, 4));
  const auto doubled = v * 2.0;
  QCOMPARE(doubled.vector(), QVector2D(6, 8));
  const auto halved = v / 2.0;
  QCOMPARE(halved.vector(), QVector2D(1.5, 2.0));
  const auto negated = -v;
  QCOMPARE(negated.vector(), QVector2D(-3, -4));
  // 起点在缩放/取反中保持不变
  const Vector2D shifted(QPointF(1, 1), QPointF(4, 5));
  QCOMPARE((shifted * 2.0).from(), QPointF(1, 1));
}
  QOOL_TEST_CASE(arithmetic_negate) {
  const Vector2D v(QPointF(1, 2), QPointF(4, 6));
  const auto neg = -v;
  QCOMPARE(neg.from(), QPointF(1, 2));
  QCOMPARE(neg.vector(), QVector2D(-3, -4));
}
  QOOL_TEST_CASE(conversions) {
  const Vector2D v(QPointF(1, 2), QPointF(4, 6)); // vector (3,4) length 5
  const QPointF as_point = v;
  QCOMPARE(as_point, QPointF(4, 6)); // == to()
  const QVector2D as_vector = v;
  QCOMPARE(as_vector, QVector2D(3, 4)); // == vector()
  const qreal as_length = v;
  QCOMPARE(as_length, 5.0); // == length()
}
  QOOL_TEST_CASE(normalized_and_iszero) {
  const Vector2D v(QVector2D(3, 4));
  const QVector2D n = v.normalized();
  QVERIFY(fuzzy_eq(n.x(), 0.6));
  QVERIFY(fuzzy_eq(n.y(), 0.8));
  QVERIFY(fuzzy_eq(n.length(), 1.0));

  QVERIFY(Vector2D().isZero());
  QVERIFY(!v.isZero());
  // 起点非零但向量为零：isZero 要求两者皆零
  const Vector2D zero_vec(QPointF(5, 5), QPointF(5, 5));
  QVERIFY(!zero_vec.isZero());
}
  QOOL_TEST_CASE(index_access) {
  const Vector2D v(QPointF(1, 2), QPointF(4, 6));
  QCOMPARE(v[0], QPointF(1, 2));
  QCOMPARE(v[1], QPointF(4, 6));
}
  QOOL_TEST_CASE(equality) {
  // 相同 from 与 vector 才相等
  QVERIFY(Vector2D(QPointF(0, 0), QPointF(3, 4))
          == Vector2D(QVector2D(3, 4)));
  QVERIFY(Vector2D(QPointF(0, 0), QPointF(3, 4))
          != Vector2D(QPointF(1, 1), QPointF(4, 5))); // from 不同
  QVERIFY(Vector2D(QVector2D(3, 4)) != Vector2D(QVector2D(4, 3)));
}
  QOOL_TEST_CASE(copy_semantics) {
  const Vector2D a(QPointF(1, 2), QPointF(4, 6)); // vector (3,4)
  const Vector2D b(a); // 拷贝构造
  QCOMPARE(b.from(), QPointF(1, 2));
  QCOMPARE(b.vector(), QVector2D(3, 4));
  QCOMPARE(b.to(), QPointF(4, 6));

  Vector2D c;
  c = a; // 拷贝赋值
  QCOMPARE(c.from(), QPointF(1, 2));
  QCOMPARE(c.vector(), QVector2D(3, 4));
  QCOMPARE(c.to(), QPointF(4, 6));
}
  QOOL_TEST_CASE(cross_product) {
  QCOMPARE(crossProduct(Vector2D(QVector2D(1, 0)), Vector2D(QVector2D(0, 1))),
           1.0);
  QCOMPARE(crossProduct(Vector2D(QVector2D(0, 1)), Vector2D(QVector2D(1, 0))),
           -1.0);
  QCOMPARE(crossProduct(Vector2D(QVector2D(2, 3)), Vector2D(QVector2D(4, 5))),
           2.0 * 5.0 - 3.0 * 4.0);
  QCOMPARE(crossProduct(Vector2D(QVector2D(1, 1)), Vector2D(QVector2D(1, 1))),
           0.0);
}
  QOOL_TEST_CASE(gadget_property_contract) {
  // Q_GADGET 属性契约：QML 暴露的 6 个属性必须注册（公开即承诺）
  const auto& mo = Vector2D::staticMetaObject;
  const char* const expected[] = { "from", "vector", "to", "length", "x", "y" };
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
















QTEST_MAIN(TestVector2D)

#include "tst_vector2d.moc"
