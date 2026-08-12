// Qool 核心 C++ 类型测试：NumberRanger（Qool/utils/qool_numberranger.h）
//
// 被测面：属性宏体系（QBINDABLE_*）产物的公开契约——
//   - 属性默认值 / 读写 / 相等守卫（同值赋值不发 Changed）
//   - 校验逻辑（validate / validatePrecision / format / decimalfy 语义）
//   - validatedTop/validatedBottom 绑定推导（top/bottom/decimals/validateMode）
//   - Q_PROPERTY 注册完整性（QML 暴露面）
// 直接实例化（SmartObject 基类无引擎依赖），QCoreApplication 环境即可。

#include <QtTest>
#include <QSignalSpy>

#include "utils/qool_numberranger.h"

#include <cmath>

using namespace qoolui;

namespace {

bool fuzzy_eq(double actual, double expected, double eps = 1e-6) {
  return std::abs(actual - expected) <= eps;
}

} // namespace

class TestNumberRanger : public QObject {
  Q_OBJECT

private slots:
  void defaults();
  void validate_plain();
  void validate_clamped_by_top();
  void validate_clamped_by_bottom();
  void validate_top_bottom_combined();
  void validate_mode_ignore_top();
  void validate_mode_ignore_bottom();
  void validate_mode_none();
  void validate_precision_modes();
  void validate_invalid_inputs();
  void validated_bindings_track_properties();
  void format_numbers();
  void format_strings();
  void notify_equal_value_guard();
  void property_registration();
};

void TestNumberRanger::defaults() {
  const NumberRanger r;
  // 构造时 decimals 默认 3
  QCOMPARE(r.decimals(), 3);
  // top/bottom 默认空（QVariant null）
  QVERIFY(r.top().isNull());
  QVERIFY(r.bottom().isNull());
  QCOMPARE(r.validateMode(), NumberRanger::AutoValidate);
  // 无上下界：任何值不被钳制
  QVERIFY(fuzzy_eq(r.validate(100.0).toDouble(), 100.0));
  QVERIFY(fuzzy_eq(r.validate(-100.0).toDouble(), -100.0));
}

void TestNumberRanger::validate_plain() {
  NumberRanger r;
  // 无上下界：仅做小数位规整
  QVERIFY(fuzzy_eq(r.validate(5.5).toDouble(), 5.5));
  QVERIFY(fuzzy_eq(r.validate(12.3456).toDouble(), 12.346)); // 3 位小数
  QVERIFY(fuzzy_eq(r.validate(0.0).toDouble(), 0.0));
  QVERIFY(fuzzy_eq(r.validate(-2.5).toDouble(), -2.5));
}

void TestNumberRanger::validate_clamped_by_top() {
  NumberRanger r;
  r.set_top(10.0);
  // 超出上界 → 钳到边界
  QVERIFY(fuzzy_eq(r.validate(12.3456).toDouble(), 10.0));
  // 界内 → 小数位规整后原样
  QVERIFY(fuzzy_eq(r.validate(5.5).toDouble(), 5.5));
  // 恰好等于边界 → 不钳（n > t 才钳）
  QVERIFY(fuzzy_eq(r.validate(10.0).toDouble(), 10.0));
}

void TestNumberRanger::validate_clamped_by_bottom() {
  NumberRanger r;
  r.set_bottom(-1.0);
  QVERIFY(fuzzy_eq(r.validate(-5.0).toDouble(), -1.0));
  QVERIFY(fuzzy_eq(r.validate(0.0).toDouble(), 0.0));
  // 恰好等于边界 → 不钳
  QVERIFY(fuzzy_eq(r.validate(-1.0).toDouble(), -1.0));
}

void TestNumberRanger::validate_top_bottom_combined() {
  NumberRanger r;
  r.set_bottom(-1.0);
  r.set_top(10.0);
  QVERIFY(fuzzy_eq(r.validate(-100.0).toDouble(), -1.0));
  QVERIFY(fuzzy_eq(r.validate(100.0).toDouble(), 10.0));
  QVERIFY(fuzzy_eq(r.validate(3.0).toDouble(), 3.0));
}

void TestNumberRanger::validate_mode_ignore_top() {
  NumberRanger r;
  r.set_top(10.0);
  r.set_bottom(-1.0);
  r.set_validateMode(NumberRanger::IgnoreTop);
  // 上界被忽略，下界仍生效（行为断言）
  QVERIFY(fuzzy_eq(r.validate(100.0).toDouble(), 100.0));
  QVERIFY(fuzzy_eq(r.validate(-100.0).toDouble(), -1.0));
}

void TestNumberRanger::validate_mode_ignore_bottom() {
  NumberRanger r;
  r.set_top(10.0);
  r.set_bottom(-1.0);
  r.set_validateMode(NumberRanger::IgnoreBottom);
  QVERIFY(fuzzy_eq(r.validate(100.0).toDouble(), 10.0));
  QVERIFY(fuzzy_eq(r.validate(-100.0).toDouble(), -100.0));
}

void TestNumberRanger::validate_mode_none() {
  NumberRanger r;
  r.set_top(10.0);
  r.set_bottom(-1.0);
  r.set_validateMode(NumberRanger::None);
  QVERIFY(fuzzy_eq(r.validate(100.0).toDouble(), 100.0));
  QVERIFY(fuzzy_eq(r.validate(-100.0).toDouble(), -100.0));
}

void TestNumberRanger::validate_precision_modes() {
  NumberRanger r;

  // decimals == 0：四舍五入到整数
  r.set_decimals(0);
  r.set_top(10.0);
  QVERIFY(fuzzy_eq(r.validate(10.6).toDouble(), 10.0)); // 11 → 钳 10
  QVERIFY(fuzzy_eq(r.validate(9.6).toDouble(), 10.0));  // round → 10
  QVERIFY(fuzzy_eq(r.validate(9.4).toDouble(), 9.0));

  // decimals == 2：两位小数
  r.set_decimals(2);
  r.set_top(QVariant()); // 移除上界
  QVERIFY(fuzzy_eq(r.validate(1.2345).toDouble(), 1.23));
  QVERIFY(fuzzy_eq(r.validate(1.2355).toDouble(), 1.24));

  // decimals < 0：不做小数位规整（原样返回）
  r.set_decimals(-1);
  QVERIFY(fuzzy_eq(r.validate(1.2345).toDouble(), 1.2345));
}

void TestNumberRanger::validate_invalid_inputs() {
  NumberRanger r;
  r.set_top(10.0);
  // null 原样返回
  QVERIFY(r.validate(QVariant()).isNull());
  // 注意：QString 恒 canConvert<qreal>（字符串→数值转换），转换失败得 0.0
  // ——"abc" 走数值路径（decimalfy(0.0) = 0），不原样返回字符串
  QVERIFY(fuzzy_eq(r.validate(QStringLiteral("abc")).toDouble(), 0.0));
  // 字符串数值参与校验：可转换 qreal
  QVERIFY(fuzzy_eq(r.validate(QStringLiteral("12.5")).toDouble(), 10.0));
}

void TestNumberRanger::validated_bindings_track_properties() {
  // validated_top/bottom 为内部绑定推导状态（QOOL_BINDABLE_MEMBER，非 Q_PROPERTY），
  // 通过 validate() 行为断言其推导结果随 top/bottom/decimals/validateMode 变化
  NumberRanger r;
  QVERIFY(fuzzy_eq(r.validate(100.0).toDouble(), 100.0)); // 无上界

  r.set_top(10.0);
  QVERIFY(fuzzy_eq(r.validate(100.0).toDouble(), 10.0));

  // 上界变化 → 推导跟随
  r.set_top(5.0);
  QVERIFY(fuzzy_eq(r.validate(7.0).toDouble(), 5.0));

  // 移除上界 → 推导回到空
  r.set_top(QVariant());
  QVERIFY(fuzzy_eq(r.validate(100.0).toDouble(), 100.0));

  // 小数位参与推导：9.9999 按 2 位规整为 10.0，恰好等于上界 → 不钳
  r.set_top(10.0);
  r.set_decimals(2);
  QVERIFY(fuzzy_eq(r.validate(9.9999).toDouble(), 10.0));
  QVERIFY(fuzzy_eq(r.validate(10.05).toDouble(), 10.0)); // 规整后 10.05 > 10 → 钳

  // validateMode 变化 → 推导跟随
  r.set_validateMode(NumberRanger::IgnoreTop);
  QVERIFY(fuzzy_eq(r.validate(100.0).toDouble(), 100.0));
}

void TestNumberRanger::format_numbers() {
  NumberRanger r;
  r.set_decimals(2);
  QCOMPARE(r.format(1.23456).toString(), QStringLiteral("1.23"));
  QCOMPARE(r.format(1.23556).toString(), QStringLiteral("1.24"));
  QCOMPARE(r.format(3.0).toString(), QStringLiteral("3"));
  // decimals < 0：不做规整（默认 QString::number 的 double 输出）
  r.set_decimals(-1);
  QCOMPARE(r.format(1.23456).toString(), QStringLiteral("1.23456"));
}

void TestNumberRanger::format_strings() {
  // 设计意图（qool_numberranger.cpp 注释）：字符串内数字按 decimals 精度
  // 规整替换。但实现中 QString 恒 canConvert<qreal>，先命中数值分支，
  // 字符串替换分支不可达——"v=1.23456" 整体转数值失败得 0.0。
  // 本用例断言设计意图（期望 "v=1.23"），当前失败 = 已知缺陷（待修）。
  NumberRanger r;
  r.set_decimals(2);
  QCOMPARE(r.format(QStringLiteral("v=1.23456")).toString(),
           QStringLiteral("v=1.23"));
  QCOMPARE(r.format(QStringLiteral("a=1.23456 b=9.9999")).toString(),
           QStringLiteral("a=1.23 b=10"));
  // 无数字的字符串原样返回
  QCOMPARE(r.format(QStringLiteral("abc")).toString(),
           QStringLiteral("abc"));
  // null 原样返回
  QVERIFY(r.format(QVariant()).isNull());
}

void TestNumberRanger::notify_equal_value_guard() {
  NumberRanger r;
  QSignalSpy topSpy(&r, &NumberRanger::topChanged);
  QSignalSpy decimalsSpy(&r, &NumberRanger::decimalsChanged);
  QSignalSpy modeSpy(&r, &NumberRanger::validateModeChanged);

  r.set_top(10.0);
  QCOMPARE(topSpy.count(), 1);
  // 相等守卫：同值赋值不发信号（bindable 宏内置语义）
  r.set_top(10.0);
  QCOMPARE(topSpy.count(), 1);
  r.set_top(20.0);
  QCOMPARE(topSpy.count(), 2);

  r.set_decimals(0);
  QCOMPARE(decimalsSpy.count(), 1);
  r.set_decimals(0);
  QCOMPARE(decimalsSpy.count(), 1);

  r.set_validateMode(NumberRanger::None);
  QCOMPARE(modeSpy.count(), 1);
}

void TestNumberRanger::property_registration() {
  // Q_PROPERTY 注册完整性（QML 暴露面契约）。
  // 注意：validatedTop/validatedBottom 是内部 QOOL_BINDABLE_MEMBER 状态
  // （无 getter、无 Q_PROPERTY），不属于 QML 暴露面——此处不断言。
  const NumberRanger r;
  const auto* mo = r.metaObject();
  const char* const expected[] = {
    "bottom", "top", "decimals", "validateMode",
    "input0", "input1", "input2", "input3", "input4",
    "input5", "input6", "input7", "input8", "input9",
    "validated0", "validated1", "validated2", "validated3", "validated4",
    "validated5", "validated6", "validated7", "validated8", "validated9",
  };
  for (const char* name : expected) {
    const int idx = mo->indexOfProperty(name);
    QVERIFY2(idx >= 0, qPrintable(QString("缺少属性: %1").arg(name)));
    QVERIFY2(mo->property(idx).isReadable(),
             qPrintable(QString("属性不可读: %1").arg(name)));
  }
}

QTEST_MAIN(TestNumberRanger)

#include "tst_numberranger.moc"
