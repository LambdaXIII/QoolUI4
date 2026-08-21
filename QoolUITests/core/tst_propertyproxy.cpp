// PropertyProxy 核心契约测试（C++ 直编被测源，core seam）
//
// 被测面（.scratch/property-proxy/spec.md「Testing Decisions」）：
// - 初始值（target/property 设置后 value = 当前值，初始同步不发 valueChanged）
// - 常量属性（读一次即终值、写忽略）
// - 有 NOTIFY（事件驱动：改目标 → value 立即更新 + valueChanged；相等不触发）
// - 无 NOTIFY + interval 三态（<0 不更新 / =0 事件循环周期 / >0 固定间隔；
//   轮询相等守卫）
// - 写方向（可写写回 / 不可写忽略 + value 保持 + xWarningQ）
// - 五能力（净化 isWritable、四透传：isReadable/isConstant/isResettable/
//   isBindable）
// - 无效态（target null / 属性无效 / property 空 → value 无效 + 能力全 false）
// - target/property 动态切换（重建观测、旧观测断开）
// - 动态属性属无效态（QQmlProperty 不解析动态属性）
//
// 测试目标：文件内自定义 QObject 子类暴露各属性特征（core 层 seam，不引新
// seam）。不用动态属性模拟无 NOTIFY（QQmlProperty 不解析动态属性）。
//
// 注意：Q_PROPERTY 强制 READ，C++ QObject 无"不可读"属性的实际形态——无效态
// 以"属性无效（不存在）/ target null / property 空"为代表。
//
// xWarningQ 断言：消息含 ANSI 转义（xDBGYellow），用包含匹配 "[W]"。

#include <QtTest>

#include "qool_test.hpp"

#include "qool_propertyproxy.h"

#include <QSignalSpy>
#include <QTimer>

using namespace qoolui;

// ---- 测试目标类型（core seam 内暴露各属性特征）----

// 带 NOTIFY 的可写属性（事件驱动 + 可写方向）；双属性供 property 切换测试
class NotifyTarget : public QObject {
  Q_OBJECT
  Q_PROPERTY(int counter READ counter WRITE setCounter NOTIFY counterChanged FINAL)
  Q_PROPERTY(int level READ level WRITE setLevel NOTIFY levelChanged FINAL)
public:
  int counter() const { return m_counter; }
  void setCounter(int v) {
    if (v == m_counter)
      return;
    m_counter = v;
    emit counterChanged();
  }
  int level() const { return m_level; }
  void setLevel(int v) {
    if (v == m_level)
      return;
    m_level = v;
    emit levelChanged();
  }
  Q_SIGNAL void counterChanged();
  Q_SIGNAL void levelChanged();
private:
  int m_counter = 0;
  int m_level = 0;
};

// 常量属性（读一次即终值、不可写）
class ConstantTarget : public QObject {
  Q_OBJECT
  Q_PROPERTY(int fixed READ fixed CONSTANT FINAL)
public:
  explicit ConstantTarget(int v = 7)
    : m_fixed(v) {}
  int fixed() const { return m_fixed; }
private:
  int m_fixed;
};

// 只读属性（无 WRITE）→ 不可写
class ReadOnlyTarget : public QObject {
  Q_OBJECT
  Q_PROPERTY(int ro READ ro FINAL)
public:
  int ro() const { return m_ro; }
private:
  int m_ro = 3;
};

// 可写无 NOTIFY（有 READ+WRITE 无 NOTIFY）→ 轮询
class NoNotifyTarget : public QObject {
  Q_OBJECT
  Q_PROPERTY(int value READ value WRITE setValue FINAL)
public:
  int value() const { return m_value; }
  void setValue(int v) { m_value = v; } // 无 notify
private:
  int m_value = 0;
};

// 可重置（RESET）→ isResettable
class ResetTarget : public QObject {
  Q_OBJECT
  Q_PROPERTY(int num READ num WRITE setNum RESET resetNum FINAL)
public:
  int num() const { return m_num; }
  void setNum(int v) { m_num = v; }
  void resetNum() { m_num = 0; }
private:
  int m_num = 5;
};

// bindable（属性宏）→ isBindable
class BindableTarget : public QObject {
  Q_OBJECT
  QBINDABLE_WRITABLE_PROPERTY(BindableTarget, int, amount, FINAL)
};

// write_direction 的 xWarningQ 捕获缓冲（QtMessageHandler 需无捕获可调用，
// 有捕获 lambda 不能转函数指针）
static QStringList g_capturedWarnings;

class TestPropertyProxyCore : public QObject {
  Q_OBJECT

  // 1 初始值：target/property 设置后 value 立即 = 当前值；初始同步不发 valueChanged
  QOOL_TEST_CASE(initial_value) {
    NotifyTarget t;
    PropertyProxy proxy;
    QSignalSpy spy(&proxy, &PropertyProxy::valueChanged);
    proxy.set_target(&t);
    proxy.set_property("counter");
    QCOMPARE(proxy.value().toInt(), 0); // 初始同步读当前值
    QCOMPARE(spy.count(), 0);           // 初始同步不发 valueChanged
    // 先设 property 再设 target 亦可
    PropertyProxy proxy2;
    proxy2.set_property("counter");
    proxy2.set_target(&t);
    QCOMPARE(proxy2.value().toInt(), 0);
  }

  // 2 常量属性：读一次即终值、写忽略
  QOOL_TEST_CASE(constant_property) {
    ConstantTarget t(42);
    PropertyProxy proxy;
    proxy.set_target(&t);
    proxy.set_property("fixed");
    QCOMPARE(proxy.value().toInt(), 42);
    QVERIFY(proxy.isReadable());
    QVERIFY(proxy.isConstant());
    QVERIFY(!proxy.isWritable()); // 净化：常量不可写
    // 写被忽略（不可写），value 保持
    proxy.setValue(99);
    QCOMPARE(proxy.value().toInt(), 42);
  }

  // 3 有 NOTIFY：事件驱动——改目标属性 → value 立即更新 + valueChanged；相等不触发
  QOOL_TEST_CASE(notify_event_driven) {
    NotifyTarget t;
    PropertyProxy proxy;
    proxy.set_target(&t);
    proxy.set_property("counter");
    QSignalSpy spy(&proxy, &PropertyProxy::valueChanged);
    t.setCounter(5);
    QCOMPARE(spy.count(), 1);
    QCOMPARE(proxy.value().toInt(), 5);
    // 相等守卫：值未变不发（setter 相同值亦不发 notify，双保险）
    t.setCounter(5);
    QCOMPARE(spy.count(), 1);
    t.setCounter(7);
    QCOMPARE(spy.count(), 2);
  }

  // 4 无 NOTIFY + interval 三态 + 轮询相等守卫
  QOOL_TEST_CASE(polling_interval_states) {
    // 4a: interval < 0（默认 -1）不轮询——value 不更新、不发
    {
      NoNotifyTarget t;
      PropertyProxy proxy;
      proxy.set_target(&t);
      proxy.set_property("value");
      QSignalSpy spy(&proxy, &PropertyProxy::valueChanged);
      t.setValue(10);
      QTest::qWait(80); // 等待超过任何轮询周期
      QCOMPARE(spy.count(), 0); // 不轮询 → 不发 valueChanged
      // value 无状态代理 getter 现读 target.property——读回 10 是无状态特性
      //（value 恒为真实值），非轮询更新；"不轮询"由 spy 无事件体现
      QCOMPARE(proxy.value().toInt(), 10);
    }
    // 4b: interval > 0 固定间隔轮询；相等守卫
    {
      NoNotifyTarget t;
      PropertyProxy proxy;
      proxy.set_target(&t);
      proxy.set_property("value");
      proxy.set_interval(30);
      QSignalSpy spy(&proxy, &PropertyProxy::valueChanged);
      t.setValue(10);
      QTRY_VERIFY_WITH_TIMEOUT(spy.count() >= 1, 2000);
      QCOMPARE(proxy.value().toInt(), 10);
      // 相等守卫：值未变（目标值仍是 10），后续轮询不发
      t.setValue(10);
      const int afterChange = spy.count();
      QTest::qWait(100); // 多个轮询周期
      QCOMPARE(spy.count(), afterChange);
    }
    // 4c: interval = 0 事件循环周期（零定时器）
    {
      NoNotifyTarget t;
      PropertyProxy proxy;
      proxy.set_target(&t);
      proxy.set_property("value");
      proxy.set_interval(0);
      QSignalSpy spy(&proxy, &PropertyProxy::valueChanged);
      t.setValue(20);
      QTRY_VERIFY_WITH_TIMEOUT(spy.count() >= 1, 2000);
      QCOMPARE(proxy.value().toInt(), 20);
    }
  }

  // 5 写方向：可写写回；不可写忽略 + value 保持 + xWarningQ
  QOOL_TEST_CASE(write_direction) {
    // 可写 → 写回生效
    NotifyTarget t;
    PropertyProxy proxy;
    proxy.set_target(&t);
    proxy.set_property("counter");
    proxy.setValue(42);
    QCOMPARE(t.counter(), 42);
    QCOMPARE(proxy.value().toInt(), 42);

    // 不可写（只读）→ 忽略 + value 保持 + 不发 + xWarningQ
    ReadOnlyTarget ro;
    PropertyProxy proxy2;
    proxy2.set_target(&ro);
    proxy2.set_property("ro");
    QSignalSpy spy(&proxy2, &PropertyProxy::valueChanged);
    g_capturedWarnings.clear();
    qInstallMessageHandler([](QtMsgType type, const QMessageLogContext&,
                          const QString& msg) {
      if (type == QtWarningMsg)
        g_capturedWarnings << msg;
    });
    proxy2.setValue(999);
    qInstallMessageHandler(nullptr);
    QCOMPARE(ro.ro(), 3);                // 目标未变
    QCOMPARE(proxy2.value().toInt(), 3); // value 保持
    QCOMPARE(spy.count(), 0);            // 未发 valueChanged
    // xWarningQ 输出：含 ANSI 转义 + "[W]"（包含匹配，勿整串精确匹配）
    bool found = false;
    for (const auto& w : g_capturedWarnings)
      if (w.contains("[W]"))
        found = true;
    QVERIFY(found);
  }

  // 6 五能力：净化 isWritable + 四透传
  QOOL_TEST_CASE(capabilities) {
    // 净化 isWritable + isConstant（常量）
    ConstantTarget c(7);
    PropertyProxy pc;
    pc.set_target(&c);
    pc.set_property("fixed");
    QVERIFY(pc.isReadable());
    QVERIFY(pc.isConstant());
    QVERIFY(!pc.isWritable());
    // isResettable（RESET 属性）
    ResetTarget r;
    PropertyProxy pr;
    pr.set_target(&r);
    pr.set_property("num");
    QVERIFY(pr.isResettable());
    // isBindable（属性宏 → true）
    BindableTarget b;
    PropertyProxy pb;
    pb.set_target(&b);
    pb.set_property("amount");
    QVERIFY(pb.isBindable());
    // 普通可写非 bindable 目标
    NotifyTarget n;
    PropertyProxy pn;
    pn.set_target(&n);
    pn.set_property("counter");
    QVERIFY(pn.isReadable());
    QVERIFY(pn.isWritable());
    QVERIFY(!pn.isConstant());
    QVERIFY(!pn.isResettable());
    QVERIFY(!pn.isBindable());
  }

  // 7 无效态：target null / 属性无效 / property 空 → value 无效 + 能力全 false
  QOOL_TEST_CASE(invalid_state) {
    NotifyTarget t;
    // target null
    PropertyProxy p1;
    p1.set_property("counter");
    QVERIFY(p1.value().isNull());
    QVERIFY(!p1.isReadable());
    QVERIFY(!p1.isWritable());
    QVERIFY(!p1.isConstant());
    QVERIFY(!p1.isResettable());
    QVERIFY(!p1.isBindable());
    // property 空
    PropertyProxy p2;
    p2.set_target(&t);
    QVERIFY(p2.value().isNull());
    QVERIFY(!p2.isReadable());
    // 属性无效（不存在）
    PropertyProxy p3;
    p3.set_target(&t);
    p3.set_property("no_such_property");
    QVERIFY(p3.value().isNull());
    QVERIFY(!p3.isReadable());
    // 无效态下写忽略（value 无效、不可写）
    p3.setValue(1);
    QVERIFY(p3.value().isNull());
  }

  // 8 target/property 动态切换：重建观测、旧观测断开
  QOOL_TEST_CASE(dynamic_switch) {
    NotifyTarget a, b;
    a.setCounter(1);
    b.setCounter(100);
    PropertyProxy proxy;
    proxy.set_target(&a);
    proxy.set_property("counter");
    QCOMPARE(proxy.value().toInt(), 1);
    // 换 target → 重建观测，初始同步新值
    proxy.set_target(&b);
    QCOMPARE(proxy.value().toInt(), 100);
    // 旧 target 的 notify 已断开：改 a 不影响 proxy
    QSignalSpy spy(&proxy, &PropertyProxy::valueChanged);
    a.setCounter(999);
    QCOMPARE(spy.count(), 0);
    QCOMPARE(proxy.value().toInt(), 100);
    // property 有效→有效切换：重建观测、初始同步新值、旧 property notify 断开
    b.setLevel(7); // 先改目标（proxy 仍观测 counter，不受影响）
    proxy.set_property("level");
    QCOMPARE(proxy.value().toInt(), 7); // 初始同步新 property 当前值
    QCOMPARE(spy.count(), 0);           // 重建初始同步不发 valueChanged
    b.setCounter(555);                  // 旧 property(counter) notify 已断开
    QCOMPARE(spy.count(), 0);
    QCOMPARE(proxy.value().toInt(), 7); // value 仍 level
    b.setLevel(9);                      // 新 property(level) notify 生效
    QCOMPARE(spy.count(), 1);
    QCOMPARE(proxy.value().toInt(), 9);
    // 换 property 到不存在的属性 → 无效态
    proxy.set_property("no_such_property");
    QVERIFY(proxy.value().isNull());
    QVERIFY(!proxy.isReadable());
  }

  // 9 动态属性属无效态（QQmlProperty 不解析动态属性）
  QOOL_TEST_CASE(dynamic_property_invalid) {
    NoNotifyTarget t;
    t.setProperty("dyn", 5); // 动态添加属性
    PropertyProxy proxy;
    proxy.set_target(&t);
    proxy.set_property("dyn");
    QVERIFY(proxy.value().isNull());
    QVERIFY(!proxy.isReadable());
    QVERIFY(!proxy.isWritable());
  }

  // 10 target 先析构：proxy 不悬空（轮询停、getter 安全返回无效态）
  QOOL_TEST_CASE(target_destroyed_safety) {
    PropertyProxy proxy;
    proxy.set_interval(0); // 开启轮询（零定时器）——析构后 sample 须安全
    {
      NoNotifyTarget t;
      proxy.set_target(&t);
      proxy.set_property("value");
      QCOMPARE(proxy.value().toInt(), 0);
      QVERIFY(proxy.isReadable());
      // t 出作用域析构 → destroyed → 重置观测
    }
    // target 已析构：getter 安全（无效态）、能力 false
    QVERIFY(proxy.value().isNull());
    QVERIFY(!proxy.isReadable());
    QVERIFY(!proxy.isWritable());
    // 事件循环转几圈（触发轮询 sample）：不崩溃、value 仍无效
    QTest::qWait(50);
    QVERIFY(proxy.value().isNull());
  }
};

QTEST_MAIN(TestPropertyProxyCore)

#include "tst_propertyproxy.moc"
