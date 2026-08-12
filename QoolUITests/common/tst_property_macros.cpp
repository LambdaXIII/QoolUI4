// QoolCommon 属性宏体系契约测试（Qt Test）
//
// 被测面（QoolCommon/qoolcommon/）：
//   qobject_property_macros.hpp  — QOBJECT_WRITABLE/READONLY/CONSTANT_PROPERTY
//                                  （含 DECLARE 分离版）
//   qbindable_property_macros.hpp — QBINDABLE_WRITABLE_PROPERTY（bindable 语义）
//   qgadget_property_macros.hpp  — QGADGET_WRITABLE/CONSTANT_PROPERTY（值类型）
//   macro_foreach.hpp            — QOOL_FOREACH_N 批量属性生成
//
// 被测契约：
//   - 宏生成的属性默认值 / getter / setter 行为
//   - 可写属性相等守卫：同值赋值不发 Changed（NOTIFY 语义）
//   - READONLY / CONSTANT / 无 NOTIFY / 无 WRITE 的 Q_PROPERTY 注册形态
//   - bindable 属性：setValue / setBinding / 相等守卫（bindable 宏内置）
//   - DECLARE 分离版：声明由宏生成、实现手写（Vector2D 模式）仍成立
//   - QOOL_FOREACH_N 批量属性完整注册
//   - setter 参数类型约定（编译期 static_assert）：值类型 const T&、指针按值
//
// 纯头文件依赖（QoolCommon 可脱离 Qool 独立使用），QCoreApplication 环境即可。

#include <QtTest>
#include <QSignalSpy>

#include "qool_test.hpp"

#include "qoolns.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolcommon/qgadget_property_macros.hpp"
#include "qoolcommon/qobject_property_macros.hpp"

#include <QBindable>
#include <QProperty>
#include <type_traits>

// 注意：不写 using namespace qoolui——宏头文件是纯宏定义，不含
// QOOL_NS_BEGIN 展开块，命名空间 qoolui 在本翻译单元未定义
// （tst_math 能引用是因为 math.hpp 的实现代码展开了命名空间）。

// 被测类：覆盖三种宏族 + 批量宏 + DECLARE 分离版
class PropHost : public QObject {
  Q_OBJECT
public:
  QOBJECT_WRITABLE_PROPERTY(int, intValue, 42)
  QOBJECT_WRITABLE_PROPERTY(QString, textValue, QStringLiteral("default"))
  QOBJECT_WRITABLE_PROPERTY(QObject*, objPtr, nullptr)
  QOBJECT_READONLY_PROPERTY(int, readOnlyValue, 7)
  QOBJECT_CONSTANT_PROPERTY(int, constantValue, 99)
  // 注意：QBINDABLE 宏族无默认值参数（与 QOBJECT_WRITABLE 的 _D_ 不同）——
  // 默认值由 Q_OBJECT_BINDABLE_PROPERTY 的 {} 值初始化提供（int → 0）；
  // 多传的第 4 参数会进入 __VA_ARGS__ 展开到 Q_PROPERTY 尾部导致 moc 语法错误
  QBINDABLE_WRITABLE_PROPERTY(PropHost, int, bindableInt)
  // DECLARE 版宏同样无默认值参数（不生成成员变量，默认值由成员初始化承担）
  QOBJECT_WRITABLE_PROPERTY_DECLARE(int, declaredValue)
private:
  int m_declaredValue { 0 };
};

// ---- 编译期契约：setter 参数类型（_QL_PARAM_TYPE_）----
// 值类型属性 → setter 取 const T&；指针属性 → 按值传 T*（不取引用）
static_assert(
  std::is_same_v<decltype(&PropHost::set_intValue),
                 void (PropHost::*)(const int&)>,
  "值类型属性 setter 必须取 const T&");
static_assert(
  std::is_same_v<decltype(&PropHost::set_objPtr), void (PropHost::*)(QObject*)>,
  "指针属性 setter 必须按值传 T*");

// DECLARE 分离版：宏只生成声明（信号/getter/setter/Q_PROPERTY），
// 成员与实现由类/类外手写（Vector2D 模式：to/length 等派生计算属性）
void PropHost::set_declaredValue(const int& new_declaredValue) {
  if (m_declaredValue == new_declaredValue)
    return;
  m_declaredValue = new_declaredValue;
  emit declaredValueChanged();
}

int PropHost::declaredValue() const { return m_declaredValue; }

// 批量属性：QOOL_FOREACH_10 展开 10 条同型可写属性
class BatchHost : public QObject {
  Q_OBJECT
#define __HANDLE__(N) QOBJECT_WRITABLE_PROPERTY(int, N, 0)
  QOOL_FOREACH_10(__HANDLE__, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9)
#undef __HANDLE__
};

// 值类型（Q_GADGET）：无信号，可写/常量属性注册
class GadgetHost {
  Q_GADGET
public:
  QGADGET_WRITABLE_PROPERTY(int, value, 5)
  QGADGET_CONSTANT_PROPERTY(int, fixed, 8)
};

class TestPropertyMacros : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(writable_defaults_and_setters) {
  const PropHost host;
  QCOMPARE(host.intValue(), 42);
  QCOMPARE(host.textValue(), QStringLiteral("default"));
  QCOMPARE(host.objPtr(), nullptr);

  PropHost mutable_host;
  mutable_host.set_intValue(7);
  QCOMPARE(mutable_host.intValue(), 7);
  mutable_host.set_textValue(QStringLiteral("changed"));
  QCOMPARE(mutable_host.textValue(), QStringLiteral("changed"));
}
  QOOL_TEST_CASE(writable_notify_equal_guard) {
  PropHost host;
  QSignalSpy intSpy(&host, &PropHost::intValueChanged);
  QSignalSpy textSpy(&host, &PropHost::textValueChanged);

  // 首次赋值（值变化）→ 发出
  host.set_intValue(1);
  QCOMPARE(intSpy.count(), 1);
  // 相等守卫：同值赋值不发
  host.set_intValue(1);
  QCOMPARE(intSpy.count(), 1);
  // 再次变化 → 发出
  host.set_intValue(2);
  QCOMPARE(intSpy.count(), 2);

  host.set_textValue(QStringLiteral("a"));
  QCOMPARE(textSpy.count(), 1);
  host.set_textValue(QStringLiteral("a"));
  QCOMPARE(textSpy.count(), 1);
  host.set_textValue(QStringLiteral("b"));
  QCOMPARE(textSpy.count(), 2);
}
  QOOL_TEST_CASE(writable_pointer_property) {
  PropHost a;
  PropHost b;
  a.set_objPtr(&b);
  QCOMPARE(a.objPtr(), &b);
  // 指针相等守卫：同指针不发
  QSignalSpy spy(&a, &PropHost::objPtrChanged);
  a.set_objPtr(&b);
  QCOMPARE(spy.count(), 0);
  a.set_objPtr(nullptr);
  QCOMPARE(spy.count(), 1);
}
  QOOL_TEST_CASE(readonly_and_constant_registration) {
  // READONLY：可读、不可写、有 NOTIFY；CONSTANT：可读、不可写、无 NOTIFY
  const auto& mo = PropHost::staticMetaObject;
  const auto readOnlyIdx = mo.indexOfProperty("readOnlyValue");
  QVERIFY(readOnlyIdx >= 0);
  const QMetaProperty ro = mo.property(readOnlyIdx);
  QVERIFY(ro.isReadable());
  QVERIFY(!ro.isWritable());
  QVERIFY(ro.hasNotifySignal());
  QVERIFY(!ro.isConstant());

  const auto constantIdx = mo.indexOfProperty("constantValue");
  QVERIFY(constantIdx >= 0);
  const QMetaProperty c = mo.property(constantIdx);
  QVERIFY(c.isReadable());
  QVERIFY(!c.isWritable());
  QVERIFY(!c.hasNotifySignal());
  QVERIFY(c.isConstant());
  const PropHost h;
  QCOMPARE(c.read(&h).toInt(), 99);
}
  QOOL_TEST_CASE(bindable_semantics) {
  PropHost host;
  QSignalSpy spy(&host, &PropHost::bindableIntChanged);

  // 默认值（{} 值初始化 → 0）+ setValue
  QCOMPARE(host.bindableInt(), 0);
  QBindable<int> b = host.bindable_bindableInt();
  QVERIFY(b.isValid());
  b.setValue(20);
  QCOMPARE(host.bindableInt(), 20);
  QCOMPARE(spy.count(), 1);
  // bindable 宏的相等守卫（QObjectBindableProperty::operator= 内置）
  b.setValue(20);
  QCOMPARE(spy.count(), 1);
  b.setValue(30);
  QCOMPARE(spy.count(), 2);

  // setBinding：外部 QProperty 驱动（setBinding 立即求值 30→5，发信号）
  QProperty<int> source(5);
  b.setBinding([&source] { return source.value(); });
  QCOMPARE(host.bindableInt(), 5);
  QCOMPARE(spy.count(), 3);
  source = 7;
  QCOMPARE(host.bindableInt(), 7);
  QCOMPARE(spy.count(), 4);
  // 绑定替换为定值（30→1，发信号）
  b.setValue(1);
  QCOMPARE(host.bindableInt(), 1);
  QCOMPARE(spy.count(), 5);
}
  QOOL_TEST_CASE(declare_impl_separation) {
  // DECLARE 版宏：声明由宏生成，实现手写——默认值/读写/信号契约仍成立
  const PropHost host;
  QCOMPARE(host.declaredValue(), 0);

  PropHost mutable_host;
  QSignalSpy spy(&mutable_host, &PropHost::declaredValueChanged);
  mutable_host.set_declaredValue(5);
  QCOMPARE(mutable_host.declaredValue(), 5);
  QCOMPARE(spy.count(), 1);
  // 相等守卫由手写实现保证（契约：与宏版一致）
  mutable_host.set_declaredValue(5);
  QCOMPARE(spy.count(), 1);

  // Q_PROPERTY 注册完整
  const auto idx = PropHost::staticMetaObject.indexOfProperty("declaredValue");
  QVERIFY(idx >= 0);
  QVERIFY(PropHost::staticMetaObject.property(idx).isWritable());
}
  QOOL_TEST_CASE(foreach_batch_registration) {
  // QOOL_FOREACH_10 批量属性：全部注册、可写、默认 0、读写生效
  BatchHost host;
  const auto& mo = BatchHost::staticMetaObject;
  for (int i = 0; i < 10; ++i) {
    const QString name = QStringLiteral("a%1").arg(i);
    const int idx = mo.indexOfProperty(name.toUtf8().constData());
    QVERIFY2(idx >= 0, qPrintable(QStringLiteral("缺少批量属性: %1").arg(name)));
    const QMetaProperty p = mo.property(idx);
    QVERIFY2(p.isWritable(), qPrintable(QStringLiteral("批量属性不可写: %1").arg(name)));
    QVERIFY2(p.hasNotifySignal(), qPrintable(QStringLiteral("批量属性无 NOTIFY: %1").arg(name)));
    QCOMPARE(p.read(&host).toInt(), 0);
  }

  // 读写生效（经宏生成 setter）
  host.set_a0(1);
  host.set_a5(6);
  host.set_a9(10);
  QCOMPARE(host.a0(), 1);
  QCOMPARE(host.a5(), 6);
  QCOMPARE(host.a9(), 10);
}
  QOOL_TEST_CASE(gadget_registration) {
  // Q_GADGET 值类型：属性可读可写、无信号（hasNotifySignal false）
  GadgetHost host;
  const auto& mo = GadgetHost::staticMetaObject;

  const int valueIdx = mo.indexOfProperty("value");
  QVERIFY(valueIdx >= 0);
  QVERIFY(mo.property(valueIdx).isWritable());
  QVERIFY(!mo.property(valueIdx).hasNotifySignal());
  QCOMPARE(host.value(), 5);
  host.set_value(9);
  QCOMPARE(host.value(), 9);

  const int fixedIdx = mo.indexOfProperty("fixed");
  QVERIFY(fixedIdx >= 0);
  QVERIFY(mo.property(fixedIdx).isConstant());
  QVERIFY(!mo.property(fixedIdx).isWritable());
  QCOMPARE(host.fixed(), 8);
}
};

QTEST_APPLESS_MAIN(TestPropertyMacros)

#include "tst_property_macros.moc"
