// QoolCommon math 单元测试（Qt Test）
//
// 被测面（QoolCommon/qoolcommon/math/）：
//   utils.hpp    — is_equal / is_zero / auto_bound / set_precision / remap
//                  / cycle_in_range / average
//   geometry.hpp — normalize_degrees / normalize_degrees_180 / normalize_radians
//                  / polar_from_xy / xy_from_polar / hypotenuse
//   range_counter.hpp — RangeCounter（整数步进计数器）
//
// 全部为纯函数/纯模板，QCoreApplication 环境即可，无 GUI 依赖。
// 测试风格示范：数据驱动（_data 函数）、边界值、浮点容差、QBENCHMARK。

#include <QtTest>

#include "qoolcommon/math.hpp"

#include <cmath>

using namespace qoolui;

namespace {

constexpr double kEps = 1e-6;

bool fuzzy_eq(double actual, double expected, double eps = kEps) {
  return std::abs(actual - expected) <= eps;
}

} // namespace

class TestMath : public QObject {
  Q_OBJECT

private slots:
  // ---- math::utils ----
  void is_equal_data();
  void is_equal();
  void is_zero_data();
  void is_zero();
  void auto_bound_data();
  void auto_bound();
  void set_precision_data();
  void set_precision();
  void remap_data();
  void remap();
  void cycle_in_range_data();
  void cycle_in_range();
  void average();

  // ---- math::geometry ----
  void normalize_degrees_data();
  void normalize_degrees();
  void normalize_degrees_180_data();
  void normalize_degrees_180();
  void normalize_radians_data();
  void normalize_radians();
  void polar_roundtrip();
  void hypotenuse_data();
  void hypotenuse();

  // ---- math::RangeCounter ----
  void range_counter_data();
  void range_counter();

  // ---- 基准测试示范 ----
  void benchmark_remap();
};

// ===================== math::utils =====================

void TestMath::is_equal_data() {
  QTest::addColumn<double>("a");
  QTest::addColumn<double>("b");
  QTest::addColumn<bool>("expected");

  QTest::newRow("identical") << 1.0 << 1.0 << true;
  QTest::newRow("within default epsilon") << 1.0 << 1.0 + 1e-11 << true;
  QTest::newRow("beyond epsilon") << 1.0 << 1.000001 << false;
  // 双方都接近零时直接判等（绝对容差路径）
  QTest::newRow("both near zero") << 0.0 << 1e-12 << true;
  QTest::newRow("zero vs far") << 0.0 << 1e-8 << false;
  // 相对容差：大数下允许更大绝对差
  QTest::newRow("large relative") << 1e20 << 1e20 + 1e9 << true;
  QTest::newRow("large beyond") << 1e20 << 1e20 + 1e12 << false;
  QTest::newRow("negative") << -1.0 << -1.0 + 1e-11 << true;
}

void TestMath::is_equal() {
  QFETCH(double, a);
  QFETCH(double, b);
  QFETCH(bool, expected);

  QCOMPARE(math::is_equal(a, b), expected);
}

void TestMath::is_zero_data() {
  QTest::addColumn<double>("value");
  QTest::addColumn<bool>("expected");

  QTest::newRow("zero") << 0.0 << true;
  QTest::newRow("tiny") << 1e-21 << true;
  QTest::newRow("tiny negative") << -1e-21 << true;
  QTest::newRow("ordinary") << 0.001 << false;
  QTest::newRow("negative") << -0.001 << false;
}

void TestMath::is_zero() {
  QFETCH(double, value);
  QFETCH(bool, expected);

  QCOMPARE(math::is_zero(value), expected);
}

void TestMath::auto_bound_data() {
  QTest::addColumn<double>("left");
  QTest::addColumn<double>("x");
  QTest::addColumn<double>("right");
  QTest::addColumn<double>("expected");

  QTest::newRow("inside") << 0.0 << 5.0 << 10.0 << 5.0;
  QTest::newRow("below min") << 0.0 << -5.0 << 10.0 << 0.0;
  QTest::newRow("above max") << 0.0 << 15.0 << 10.0 << 10.0;
  QTest::newRow("exact min") << 0.0 << 0.0 << 10.0 << 0.0;
  QTest::newRow("exact max") << 0.0 << 10.0 << 10.0 << 10.0;
  QTest::newRow("reversed bounds") << 10.0 << 5.0 << 0.0 << 5.0;
  QTest::newRow("reversed below") << 10.0 << -1.0 << 0.0 << 0.0;
  QTest::newRow("reversed above") << 10.0 << 11.0 << 0.0 << 10.0;
  QTest::newRow("point interval") << 0.0 << 5.0 << 0.0 << 0.0;
}

void TestMath::auto_bound() {
  QFETCH(double, left);
  QFETCH(double, x);
  QFETCH(double, right);
  QFETCH(double, expected);

  QCOMPARE(math::auto_bound(left, x, right), expected);
}

void TestMath::set_precision_data() {
  QTest::addColumn<double>("number");
  QTest::addColumn<int>("precision");
  QTest::addColumn<double>("expected");

  QTest::newRow("two digits") << 1.23456 << 2 << 1.23;
  QTest::newRow("one digit") << 1.23456 << 1 << 1.2;
  QTest::newRow("round up") << 1.235 << 2 << 1.24;
  QTest::newRow("zero precision rounds") << 1.5 << 0 << 2.0;
  QTest::newRow("zero precision negative") << -1.5 << 0 << -2.0;
  // 负精度按绝对值处理（实现约定）
  QTest::newRow("negative precision") << 1.23456 << -2 << 1.23;
  QTest::newRow("integer") << 3.0 << 2 << 3.0;
}

void TestMath::set_precision() {
  QFETCH(double, number);
  QFETCH(int, precision);
  QFETCH(double, expected);

  QVERIFY2(
    fuzzy_eq(math::set_precision(number, precision), expected),
    qPrintable(QString("set_precision(%1, %2) != %3")
                 .arg(number)
                 .arg(precision)
                 .arg(expected)));
}

void TestMath::remap_data() {
  QTest::addColumn<double>("input");
  QTest::addColumn<double>("in_min");
  QTest::addColumn<double>("in_max");
  QTest::addColumn<double>("out_min");
  QTest::addColumn<double>("out_max");
  QTest::addColumn<double>("expected");

  QTest::newRow("mid") << 5.0 << 0.0 << 10.0 << 0.0 << 100.0 << 50.0;
  QTest::newRow("min") << 0.0 << 0.0 << 10.0 << 0.0 << 100.0 << 0.0;
  QTest::newRow("max") << 10.0 << 0.0 << 10.0 << 0.0 << 100.0 << 100.0;
  QTest::newRow("quarter") << 2.5 << 0.0 << 10.0 << 0.0 << 100.0 << 25.0;
  QTest::newRow("reversed out range") << 5.0 << 0.0 << 10.0 << 100.0 << 0.0
                                      << 50.0;
  // 超出输入范围不做钳制（线性外推）
  QTest::newRow("beyond input") << 15.0 << 0.0 << 10.0 << 0.0 << 100.0
                                << 150.0;
  QTest::newRow("negative input") << -5.0 << 0.0 << 10.0 << 0.0 << 100.0
                                  << -50.0;
  QTest::newRow("negative range") << -5.0 << -10.0 << 0.0 << 0.0 << 100.0
                                  << 50.0;
  // 输入范围退化为单点：避免除零，返回目标范围最小值
  QTest::newRow("degenerate in range") << 5.0 << 3.0 << 3.0 << 0.0 << 100.0
                                       << 0.0;
}

void TestMath::remap() {
  QFETCH(double, input);
  QFETCH(double, in_min);
  QFETCH(double, in_max);
  QFETCH(double, out_min);
  QFETCH(double, out_max);
  QFETCH(double, expected);

  const double actual =
    math::remap(input, in_min, in_max, out_min, out_max);
  QVERIFY2(
    fuzzy_eq(actual, expected),
    qPrintable(QString("remap(%1, %2, %3, %4, %5) != %6 (got %7)")
                 .arg(input)
                 .arg(in_min)
                 .arg(in_max)
                 .arg(out_min)
                 .arg(out_max)
                 .arg(expected)
                 .arg(actual)));
}

void TestMath::cycle_in_range_data() {
  QTest::addColumn<double>("min");
  QTest::addColumn<double>("value");
  QTest::addColumn<double>("max");
  QTest::addColumn<double>("expected");

  QTest::newRow("inside") << 0.0 << 5.0 << 10.0 << 5.0;
  QTest::newRow("min endpoint") << 0.0 << 0.0 << 10.0 << 0.0;
  QTest::newRow("max endpoint stays") << 0.0 << 10.0 << 10.0 << 10.0;
  // 模数回绕（区别于 auto_bound 的钳制）
  QTest::newRow("wrap above") << 0.0 << 12.0 << 10.0 << 2.0;
  QTest::newRow("wrap above twice") << 0.0 << 22.0 << 10.0 << 2.0;
  QTest::newRow("wrap below") << 0.0 << -3.0 << 10.0 << 7.0;
  QTest::newRow("wrap below twice") << 0.0 << -13.0 << 10.0 << 7.0;
  // 端点乱序自动取小大为界（与 auto_bound 语义一致）
  QTest::newRow("reversed bounds") << 10.0 << 3.0 << 0.0 << 3.0;
  QTest::newRow("reversed wrap") << 10.0 << -3.0 << 0.0 << 7.0;
  QTest::newRow("point interval") << 0.0 << 5.0 << 0.0 << 0.0;
  QTest::newRow("fractional") << 0.0 << 2.5 << 10.0 << 2.5;
  QTest::newRow("fractional wrap") << 0.0 << 11.5 << 10.0 << 1.5;
}

void TestMath::cycle_in_range() {
  QFETCH(double, min);
  QFETCH(double, value);
  QFETCH(double, max);
  QFETCH(double, expected);

  const double actual = math::cycle_in_range(min, value, max);
  QVERIFY2(
    fuzzy_eq(actual, expected),
    qPrintable(QString("cycle_in_range(%1, %2, %3) != %4 (got %5)")
                 .arg(min)
                 .arg(value)
                 .arg(max)
                 .arg(expected)
                 .arg(actual)));
}

void TestMath::average() {
  // 注意：average 接受 std::initializer_list，模板推导依赖列表元素，
  // 空列表必须显式指定类型（average<double>({}) 返回 0——"空集均值 = 0"
  // 为调用方依赖的自洽约定）
  QCOMPARE(math::average<double>({}), 0.0);
  QCOMPARE(math::average({5.0}), 5.0);
  QCOMPARE(math::average({1.0, 3.0}), 2.0);
  QCOMPARE(math::average({1.0, 2.0, 3.0, 4.0}), 2.5);
  QCOMPARE(math::average({1.5, 2.5}), 2.0);
  QCOMPARE(math::average({-1.0, 1.0}), 0.0);
  // 整型：整数除法截断（刻意语义）
  QCOMPARE(math::average({1, 2}), 1);
  QCOMPARE(math::average<int>({}), 0);
}

// ===================== math::geometry =====================

void TestMath::normalize_degrees_data() {
  QTest::addColumn<double>("degrees");
  QTest::addColumn<double>("expected");

  QTest::newRow("zero") << 0.0 << 0.0;
  QTest::newRow("positive") << 90.0 << 90.0;
  QTest::newRow("full circle") << 360.0 << 0.0;
  QTest::newRow("two circles") << 720.0 << 0.0;
  QTest::newRow("over") << 370.0 << 10.0;
  QTest::newRow("negative") << -10.0 << 350.0;
  QTest::newRow("negative circle") << -360.0 << 0.0;
  QTest::newRow("half circle") << 540.0 << 180.0;
  QTest::newRow("fractional") << 359.5 << 359.5;
}

void TestMath::normalize_degrees() {
  QFETCH(double, degrees);
  QFETCH(double, expected);

  const float actual = math::normalize_degrees(degrees);
  QVERIFY2(
    fuzzy_eq(actual, expected, 1e-3),
    qPrintable(QString("normalize_degrees(%1) != %2 (got %3)")
                 .arg(degrees)
                 .arg(expected)
                 .arg(actual)));
}

void TestMath::normalize_degrees_180_data() {
  QTest::addColumn<double>("degrees");
  QTest::addColumn<double>("expected");

  QTest::newRow("zero") << 0.0 << 0.0;
  QTest::newRow("positive") << 90.0 << 90.0;
  QTest::newRow("over 180") << 190.0 << -170.0;
  QTest::newRow("just over") << 181.0 << -179.0;
  QTest::newRow("under -180") << -190.0 << 170.0;
  QTest::newRow("just under") << -181.0 << 179.0;
  QTest::newRow("270 equivalent") << 350.0 << -10.0;
  QTest::newRow("inside") << -10.0 << -10.0;
  QTest::newRow("half circle") << 540.0 << 180.0;
  // 180° 端点为实现实测行为：不折返（normalize_degrees 后 == 180，> 180 不成立）
  QTest::newRow("exact 180") << 180.0 << 180.0;
  QTest::newRow("negative 180") << -180.0 << 180.0;
}

void TestMath::normalize_degrees_180() {
  QFETCH(double, degrees);
  QFETCH(double, expected);

  const float actual = math::normalize_degrees_180(degrees);
  QVERIFY2(
    fuzzy_eq(actual, expected, 1e-3),
    qPrintable(QString("normalize_degrees_180(%1) != %2 (got %3)")
                 .arg(degrees)
                 .arg(expected)
                 .arg(actual)));
}

void TestMath::normalize_radians_data() {
  QTest::addColumn<double>("radians");
  QTest::addColumn<double>("expected");

  QTest::newRow("zero") << 0.0 << 0.0;
  QTest::newRow("pi") << M_PI << M_PI;
  QTest::newRow("full circle") << 2 * M_PI << 0.0;
  QTest::newRow("one and half") << 3 * M_PI << M_PI;
  QTest::newRow("negative quarter") << -M_PI / 2 << 3 * M_PI / 2;
  QTest::newRow("negative full") << -2 * M_PI << 0.0;
}

void TestMath::normalize_radians() {
  QFETCH(double, radians);
  QFETCH(double, expected);

  const float actual = math::normalize_radians(radians);
  QVERIFY2(
    fuzzy_eq(actual, expected, 1e-4),
    qPrintable(QString("normalize_radians(%1) != %2 (got %3)")
                 .arg(radians)
                 .arg(expected)
                 .arg(actual)));
}

void TestMath::polar_roundtrip() {
  // 直角坐标 → 极坐标 → 直角坐标 往返一致
  const auto [r1, a1] = math::polar_from_xy(3.0f, 4.0f);
  QVERIFY2(
    fuzzy_eq(r1, 5.0),
    qPrintable(QString("radius != 5 (got %1)").arg(r1)));
  const auto [x1, y1] = math::xy_from_polar(r1, a1);
  QVERIFY(fuzzy_eq(x1, 3.0));
  QVERIFY(fuzzy_eq(y1, 4.0));

  // 负象限：角度为负（atan2 语义），半径恒正
  const auto [r2, a2] = math::polar_from_xy(-3.0f, -4.0f);
  QVERIFY(fuzzy_eq(r2, 5.0));
  QVERIFY(a2 < 0.0f);
  const auto [x2, y2] = math::xy_from_polar(r2, a2);
  QVERIFY(fuzzy_eq(x2, -3.0));
  QVERIFY(fuzzy_eq(y2, -4.0));

  // 轴向特例
  const auto [r3, a3] = math::polar_from_xy(0.0f, 2.0f);
  QVERIFY(fuzzy_eq(r3, 2.0));
  QVERIFY(fuzzy_eq(a3, M_PI / 2));

  // 原点：半径为 0，角度为 0（atan2(0,0)）
  const auto [r4, a4] = math::polar_from_xy(0.0f, 0.0f);
  QVERIFY(fuzzy_eq(r4, 0.0));
  QVERIFY(fuzzy_eq(a4, 0.0));
}

void TestMath::hypotenuse_data() {
  QTest::addColumn<double>("leg1");
  QTest::addColumn<double>("leg2");
  QTest::addColumn<double>("expected");

  QTest::newRow("3-4-5") << 3.0 << 4.0 << 5.0;
  QTest::newRow("5-12-13") << 5.0 << 12.0 << 13.0;
  QTest::newRow("zero") << 0.0 << 0.0 << 0.0;
  QTest::newRow("single leg") << 0.0 << 6.0 << 6.0;
  QTest::newRow("large") << 1e8 << 1e8 << std::sqrt(2.0) * 1e8;
}

void TestMath::hypotenuse() {
  QFETCH(double, leg1);
  QFETCH(double, leg2);
  QFETCH(double, expected);

  const float actual = math::hypotenuse(leg1, leg2);
  QVERIFY2(
    fuzzy_eq(actual, expected, 1e-3 * std::max(1.0, expected)),
    qPrintable(QString("hypotenuse(%1, %2) != %3 (got %4)")
                 .arg(leg1)
                 .arg(leg2)
                 .arg(expected)
                 .arg(actual)));
}

// ===================== math::RangeCounter =====================

void TestMath::range_counter_data() {
  QTest::addColumn<int>("first");
  QTest::addColumn<int>("last");
  QTest::addColumn<int>("step");
  QTest::addColumn<int>("count_expected");
  QTest::addColumn<int>("contained_last_expected");

  QTest::newRow("unit step") << 0 << 10 << 1 << 10 << 9;
  QTest::newRow("zero based") << 0 << 0 << 1 << 0 << -1;
  QTest::newRow("step three") << 0 << 10 << 3 << 3 << 7;
  QTest::newRow("exact multiple") << 0 << 9 << 3 << 3 << 6;
  // 端点乱序自动交换
  QTest::newRow("reversed") << 10 << 0 << 1 << 10 << 9;
  // count 整数截断（区间跨度为 step 非整数倍时步数向下取整——刻意语义）
  QTest::newRow("truncated") << 0 << 11 << 3 << 3 << 8;
}

void TestMath::range_counter() {
  QFETCH(int, first);
  QFETCH(int, last);
  QFETCH(int, step);
  QFETCH(int, count_expected);
  QFETCH(int, contained_last_expected);

  if (step == 1) {
    const math::RangeCounter<int> rc(first, last);
    QCOMPARE(rc.first(), std::min(first, last));
    QCOMPARE(rc.last(), std::max(first, last));
    QCOMPARE(rc.count(), count_expected);
    QCOMPARE(rc.contained_last(), contained_last_expected);
    QCOMPARE(rc.step(), 1);
  } else {
    const math::RangeCounter<int, 3> rc(first, last);
    QCOMPARE(rc.first(), std::min(first, last));
    QCOMPARE(rc.last(), std::max(first, last));
    QCOMPARE(rc.count(), count_expected);
    QCOMPARE(rc.contained_last(), contained_last_expected);
    QCOMPARE(rc.step(), 3);
  }
}

// ===================== benchmark =====================

void TestMath::benchmark_remap() {
  QBENCHMARK {
    const auto v = math::remap<int, int>(123, 0, 255, 0, 100);
    Q_UNUSED(v);
  }
}

QTEST_MAIN(TestMath)

#include "tst_math.moc"
