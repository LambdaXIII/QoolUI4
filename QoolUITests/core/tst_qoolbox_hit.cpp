// Qool 端到端命中测试：QoolBox 直角/圆角变体的真实鼠标路径
// （containmentMask 委托 + FillContains 路径填充判定）。
//
// 背景（沿用 tst_hover_e2e 机制）：
// - 直角变体（OctagonShape）containmentMask 挂 QObject 掩码 control——
//   QQuickItem::contains 对非 Item 掩码直接 invoke 掩码的 contains(point)
//   （掩码持有 Item 的本地坐标，见 Qt 6.11 qquickitem.cpp）；control 委托
//   outer gadget 的 O(1) 线性不等式判定：切角区域不命中、形状外不命中、
//   判定区随 settings.offsetX/Y 平移。宿主 MouseArea 须显式挂载
//   QoolBox.containmentMask（Qt hover 分发不检查祖先掩码——见
//   tst_hover_e2e 头注释，本测试即正确用法）。
// - 圆角变体（OctagonCurvedShape）containsMode: Shape.FillContains——
//   QQuickShape::contains 逐子 ShapePath 判路径填充（union 语义，
//   qquickshape.cpp）。
//
// 场景几何（QoolBox 100×60 @ (20,20)，四角 cut 20）：
// 直角外轮廓本地系：(20,0)(80,0)(100,20)(100,40)(80,60)(20,60)(0,40)(0,20)；
// 半平面（开集语义：边界本身命中）x∈[0,100] ∧ y∈[0,60] ∧ X+Y≥20（TL 斜）
// ∧ X−Y≤80（TR 斜）∧ X+Y≤140（BR 斜）∧ X−Y≥−35（BL 斜）。切角区
// （5,5）：X+Y=10<20 不命中；（10,10）：X+Y=20 恰在斜边边界命中。
// 圆角外弧：PathArc 半径 = cut = 20；PathArc.direction 默认 Clockwise
// （Qt 6.11 qquickpath.cpp/qquicksvgparser.cpp，sweep=1）→ TL 角弧心
// (20,20)、弧向外凸（过 (5.86,5.86)）——圆角区 = 距弧心 ≤ 20 的角内
// 区域：（8,8）（距 16.97）命中而直角变体不命中（8+8<20）；（5,5）
// （距 21.21）不命中（退行矩形会命中——排除退行分支）。
//
// 主题插件 WARN：本测试全部场景覆写 settings（QoolBox 默认 settings 的
// Style 绑定不参与求值），场景不实例化任何引用 Style/ThemeHQ 的组件——
// ThemeDB 进程单例不会被构造（ThemeDB::instance() 调用点仅 ThemeHQ/
// ThemeHQModel 构造与 Style 主题切换，qool_theme_db.cpp），故不会出现
// tst_hover_e2e 中的 "No ThemeLoader installed" WARN。因此**不做**
// QTest::ignoreMessage：Qt Test 对"预期但未收到"的消息会判失败
// （"Not all expected messages were received"，qtestresult.cpp）。

#include <QtTest>

#include "qool_test.hpp"

#include <QQuickItem>
#include <QQuickWindow>

#include <QQmlComponent>
#include <QQmlEngine>

#include <QMetaObject>
#include <QPoint>

class TestQoolBoxHit : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(straightOctagonHitEndToEnd);
  QOOL_TEST_CASE(straightOctagonOffsetFollows);
  QOOL_TEST_CASE(curvedOctagonFillContainsEndToEnd);
};

namespace {

// 场景内窗口坐标 = contentItem 坐标（QoolBox 在 contentItem (20,20)）
QPoint windowPos(int localX, int localY) {
  return QPoint(20 + localX, 20 + localY);
}

} // namespace

void TestQoolBoxHit::straightOctagonHitEndToEnd() {
  QQmlEngine engine;
  engine.addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));
  QQmlComponent component(&engine);
  component.setData(
      R"(
import QtQuick
import Qool

Item {
    width: 360
    height: 220

    property alias qbox: box
    property alias boxArea: boxArea
    property alias plainArea: plainArea

    QoolBox {
        id: box
        x: 20
        y: 20
        width: 100
        height: 60
        // 覆写默认 settings（cut 20 + 直角变体）：默认实例的 Style 绑定
        // 不参与求值——本测试进程不构造 ThemeDB，无主题插件 WARN
        settings: QoolBoxSettings {
            cutSizeTL: 20
            cutSizeTR: 20
            cutSizeBL: 20
            cutSizeBR: 20
            curved: false
        }
        MouseArea {
            id: boxArea
            anchors.fill: parent
            hoverEnabled: true
            // 宿主显式挂载组件掩码（Qt hover 分发不检查祖先掩码——
            // tst_hover_e2e 同款正确用法）
            containmentMask: box.containmentMask
        }
    }

    // 无掩码对照：矩形全区域应 hover（验证鼠标注入通道本身可用）
    Rectangle {
        x: 200
        y: 20
        width: 120
        height: 120
        color: "gray"
        MouseArea {
            id: plainArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
)",
      QUrl());

  QVERIFY2(component.isReady(), qPrintable(component.errorString()));
  QQuickWindow window;
  auto root = qobject_cast<QQuickItem*>(component.create());
  QVERIFY(root);
  root->setParentItem(window.contentItem());
  window.resize(360, 220);
  window.show();
  QVERIFY(QTest::qWaitForWindowExposed(&window));

  auto qbox = root->property("qbox").value<QQuickItem*>();
  auto boxArea = root->property("boxArea").value<QQuickItem*>();
  auto plainArea = root->property("plainArea").value<QQuickItem*>();
  QVERIFY(qbox);
  QVERIFY(boxArea);
  QVERIFY(plainArea);

  // ---- 对照：无掩码矩形（注入通道可用性）----
  QTest::mouseMove(&window, QPoint(200 + 60, 20 + 45));
  QTRY_VERIFY(plainArea->property("containsMouse").toBool());

  // ---- 掩码链（公开契约）：QoolBox.containmentMask = 当前变体
  //（loader.item）；宿主 MouseArea 显式挂载同一掩码；直角变体 Shape
  // 自身 containmentMask = control（QObject 掩码——委托
  // QoolBoxShapeControl::contains 的 O(1) 线性不等式）----
  auto shape = qbox->property("shape").value<QQuickItem*>();
  QVERIFY(shape);
  QCOMPARE(qbox->containmentMask(), static_cast<QObject*>(shape));
  QCOMPARE(boxArea->containmentMask(), static_cast<QObject*>(shape));
  auto control = shape->containmentMask();
  QVERIFY(control);
  QCOMPARE(qbox->property("control").value<QObject*>(), control);

  // ---- 直接调用（引擎 hitTest 同款检查——掩码委托，tst_hover_e2e
  // 同风格）----
  QCOMPARE(shape->contains(QPointF(50, 30)), true);   // 八边形内（中心）
  QCOMPARE(shape->contains(QPointF(15, 15)), true);   // 斜边内侧（近切角）
  QCOMPARE(shape->contains(QPointF(10, 10)), true);   // 切角斜边边界（开集语义）
  QCOMPARE(shape->contains(QPointF(5, 5)), false);    // TL 切角区域不命中
  QCOMPARE(shape->contains(QPointF(0, 0)), false);    // TL 角外
  QCOMPARE(shape->contains(QPointF(99, 0)), false);   // TR 角外（斜边外）
  QCOMPARE(shape->contains(QPointF(100, 60)), false); // BR 角外

  // control->contains 经 QMetaObject 调用（= QQuickItemPrivate 对 QObject
  // 掩码的 invoke 通道，qquickitem.cpp containmentMaskContains）
  bool hit = false;
  QVERIFY(QMetaObject::invokeMethod(control, "contains",
      Q_RETURN_ARG(bool, hit), Q_ARG(QPointF, QPointF(50, 30))));
  QCOMPARE(hit, true);
  QVERIFY(QMetaObject::invokeMethod(control, "contains",
      Q_RETURN_ARG(bool, hit), Q_ARG(QPointF, QPointF(5, 5))));
  QCOMPARE(hit, false);

  // ---- 真实鼠标（offscreen 注入通道，QTest::mouseMove）----
  // 中心：hover
  QTest::mouseMove(&window, windowPos(50, 30));
  QTRY_VERIFY(boxArea->property("containsMouse").toBool());

  // 切角区域：不 hover（用户报告误判区域）
  QTest::mouseMove(&window, windowPos(5, 5));
  QTRY_VERIFY(!boxArea->property("containsMouse").toBool());

  // 形状外边界：不 hover
  QTest::mouseMove(&window, windowPos(0, 0));
  QTRY_VERIFY(!boxArea->property("containsMouse").toBool());
  QTest::mouseMove(&window, windowPos(99, 0));
  QTRY_VERIFY(!boxArea->property("containsMouse").toBool());

  // 斜边内侧近切角：hover
  QTest::mouseMove(&window, windowPos(15, 15));
  QTRY_VERIFY(boxArea->property("containsMouse").toBool());

  // 移出组件（窗口左上角，box 外）：不 hover
  QTest::mouseMove(&window, QPoint(5, 5));
  QTRY_VERIFY(!boxArea->property("containsMouse").toBool());

  root->deleteLater();
}

void TestQoolBoxHit::straightOctagonOffsetFollows() {
  // 场景同直角测试，settings 增加 offsetX: 10 / offsetY: 5——判定区整体
  // 平移：八边形占位 x∈[10,110]、y∈[5,65]（切角区随平移：TL 斜边
  // X+Y=35）。
  QQmlEngine engine;
  engine.addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));
  QQmlComponent component(&engine);
  component.setData(
      R"(
import QtQuick
import Qool

Item {
    width: 360
    height: 220

    property alias qbox: box
    property alias boxArea: boxArea
    property alias plainArea: plainArea

    QoolBox {
        id: box
        x: 20
        y: 20
        width: 100
        height: 60
        settings: QoolBoxSettings {
            cutSizeTL: 20
            cutSizeTR: 20
            cutSizeBL: 20
            cutSizeBR: 20
            offsetX: 10
            offsetY: 5
            curved: false
        }
        MouseArea {
            id: boxArea
            anchors.fill: parent
            hoverEnabled: true
            containmentMask: box.containmentMask
        }
    }

    Rectangle {
        x: 200
        y: 20
        width: 120
        height: 120
        color: "gray"
        MouseArea {
            id: plainArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
)",
      QUrl());

  QVERIFY2(component.isReady(), qPrintable(component.errorString()));
  QQuickWindow window;
  auto root = qobject_cast<QQuickItem*>(component.create());
  QVERIFY(root);
  root->setParentItem(window.contentItem());
  window.resize(360, 220);
  window.show();
  QVERIFY(QTest::qWaitForWindowExposed(&window));

  auto qbox = root->property("qbox").value<QQuickItem*>();
  auto boxArea = root->property("boxArea").value<QQuickItem*>();
  auto plainArea = root->property("plainArea").value<QQuickItem*>();
  QVERIFY(qbox);
  QVERIFY(boxArea);
  QVERIFY(plainArea);

  // ---- 对照：无掩码矩形（注入通道可用性）----
  QTest::mouseMove(&window, QPoint(200 + 60, 20 + 45));
  QTRY_VERIFY(plainArea->property("containsMouse").toBool());

  auto shape = qbox->property("shape").value<QQuickItem*>();
  QVERIFY(shape);

  // ---- 直接调用（判定区跟随 offset）----
  QCOMPARE(shape->contains(QPointF(5, 30)), false);  // 无 offset 时命中
                                                     //（左边缘 x=0）→ 平移后
                                                     // 新左边缘 x=10，不命中
  QCOMPARE(shape->contains(QPointF(15, 30)), true);  // 平移后新左区域
  QCOMPARE(shape->contains(QPointF(60, 35)), true);  // 平移后形状中心
  QCOMPARE(shape->contains(QPointF(5, 5)), false);   // 切角区随平移（X+Y<35）

  // ---- 真实鼠标 ----
  QTest::mouseMove(&window, windowPos(15, 30));
  QTRY_VERIFY(boxArea->property("containsMouse").toBool());
  QTest::mouseMove(&window, windowPos(5, 30));
  QTRY_VERIFY(!boxArea->property("containsMouse").toBool());
  QTest::mouseMove(&window, windowPos(60, 35));
  QTRY_VERIFY(boxArea->property("containsMouse").toBool());

  root->deleteLater();
}

void TestQoolBoxHit::curvedOctagonFillContainsEndToEnd() {
  // 场景：cut 20 + curved: true + animatingHint: true——跳过退行判定
  //（cut ≤ half 30 时默认退行为原生矩形），保持 roundShape 渲染；
  // 退行判定本身由 QML 批次覆盖，本测试目标是圆角变体的 FillContains
  // 路径填充命中契约。
  QQmlEngine engine;
  engine.addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));
  QQmlComponent component(&engine);
  component.setData(
      R"(
import QtQuick
import Qool

Item {
    width: 360
    height: 220

    property alias qbox: box
    property alias boxArea: boxArea
    property alias plainArea: plainArea

    QoolBox {
        id: box
        x: 20
        y: 20
        width: 100
        height: 60
        animatingHint: true
        settings: QoolBoxSettings {
            cutSizeTL: 20
            cutSizeTR: 20
            cutSizeBL: 20
            cutSizeBR: 20
            curved: true
        }
        MouseArea {
            id: boxArea
            anchors.fill: parent
            hoverEnabled: true
            containmentMask: box.containmentMask
        }
    }

    Rectangle {
        x: 200
        y: 20
        width: 120
        height: 120
        color: "gray"
        MouseArea {
            id: plainArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
)",
      QUrl());

  QVERIFY2(component.isReady(), qPrintable(component.errorString()));
  QQuickWindow window;
  auto root = qobject_cast<QQuickItem*>(component.create());
  QVERIFY(root);
  root->setParentItem(window.contentItem());
  window.resize(360, 220);
  window.show();
  QVERIFY(QTest::qWaitForWindowExposed(&window));

  auto qbox = root->property("qbox").value<QQuickItem*>();
  auto boxArea = root->property("boxArea").value<QQuickItem*>();
  auto plainArea = root->property("plainArea").value<QQuickItem*>();
  QVERIFY(qbox);
  QVERIFY(boxArea);
  QVERIFY(plainArea);

  // ---- 对照：无掩码矩形（注入通道可用性）----
  QTest::mouseMove(&window, QPoint(200 + 60, 20 + 45));
  QTRY_VERIFY(plainArea->property("containsMouse").toBool());

  auto shape = qbox->property("shape").value<QQuickItem*>();
  QVERIFY(shape);
  // 圆角变体公开契约：containsMode = Shape.FillContains（枚举值 1——
  // qquickshape_p.h ContainsMode）——路径填充判定；QoolBox 掩码委托
  // 该变体（Shape 自身无 containmentMask → QQuickShape::contains）
  QCOMPARE(shape->property("containsMode").toInt(), 1);
  QCOMPARE(qbox->containmentMask(), static_cast<QObject*>(shape));
  QCOMPARE(boxArea->containmentMask(), static_cast<QObject*>(shape));

  // 首断言轮询：Shape 路径于组件完成时构建（QQuickPath::componentComplete
  // → doProcessPath），静态场景路径立即可用——轮询吸收任何异步重算
  QTRY_VERIFY(shape->contains(QPointF(50, 30)));

  // ---- 直接调用（路径填充判定，union 各子 ShapePath）----
  QCOMPARE(shape->contains(QPointF(50, 30)), true); // 中心
  QCOMPARE(shape->contains(QPointF(15, 15)), true); // 弧内
  QCOMPARE(shape->contains(QPointF(8, 8)), true);   // 圆角区命中（直角变体
                                                    // 不命中：8+8<20）
  QCOMPARE(shape->contains(QPointF(5, 5)), false);  // 弧外不命中（退行矩形
                                                    // 会命中——排除退行分支）
  QCOMPARE(shape->contains(QPointF(2, 2)), false);  // 弧外不命中
  QCOMPARE(shape->contains(QPointF(0, 0)), false);  // 角外不命中

  // ---- 真实鼠标：圆角区命中、弧外不命中 ----
  QTest::mouseMove(&window, windowPos(50, 30));
  QTRY_VERIFY(boxArea->property("containsMouse").toBool());
  QTest::mouseMove(&window, windowPos(8, 8));
  QTRY_VERIFY(boxArea->property("containsMouse").toBool());
  QTest::mouseMove(&window, windowPos(5, 5));
  QTRY_VERIFY(!boxArea->property("containsMouse").toBool());
  QTest::mouseMove(&window, windowPos(0, 0));
  QTRY_VERIFY(!boxArea->property("containsMouse").toBool());

  root->deleteLater();
}

// 强制 offscreen：本测试为真实窗口 + QTest::mouseMove 注入路径，任何运行
// 通道（QtCreator 测试面板/ctest/命令行）都必须 offscreen 平台，否则
// QQuickWindow 弹真实窗口并卡住。静态对象在 main() 前构造，早于
// QTEST_MAIN 展开的 QGuiApplication 创建——QT_QPA_PLATFORM 即时生效。
namespace {
struct QoolTestForceOffscreen {
  QoolTestForceOffscreen() { qputenv("QT_QPA_PLATFORM", "offscreen"); }
} _qoolTestForceOffscreen;
} // namespace

QTEST_MAIN(TestQoolBoxHit)

#include "tst_qoolbox_hit.moc"
