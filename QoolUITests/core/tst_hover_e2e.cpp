// Qool 端到端 hover 测试：真实窗口 + 真实鼠标事件路径下，HalfCrystal 的
// containmentMask 判定域与渲染形状一致。
//
// 背景（2026-08-13 修复）：
// - Qt 6.11 的 QHoverEvent 分发（QQuickDeliveryAgent::deliverHoverEvent
//   Recursive）对每个 item 独立调用其自身 contains——**不检查祖先 Item 的
//   containmentMask**。组件 root 上的掩码只约束 QPointerEvent（点击/按下）
//   路径；宿主 MouseArea 的 hover 走自身 contains（无掩码 = 矩形判定）。
// - 因此带掩码组件 + 宿主 MouseArea 的 hover 是矩形域（三角外误 hover）。
//   修复 = 宿主 MouseArea 显式挂载组件掩码（坐标基准一致：MouseArea
//   anchors.fill 时本地坐标即组件本地）。
// - 回归验证：本测试即正确用法（MouseArea containmentMask 绑定组件掩码）
//   下，hover 精确（三角内 hover、三角外不 hover）。
//
// 注：QML 测试批次（qml/）TestCase.mouseMove 在 offscreen 平台不注入事件
// （连无掩码矩形 hover 都不生效）——真实鼠标路径在本层用 QTest::mouseMove
// （Qt 官方 QQuickTest 同款通道）验证。
//
// 场景 = 测试页"掩码 hover 演示"masked：HalfCrystal 120×120，direction=N
// （默认）。N 三角顶点（组件本地）：north(60,0) east(120,60) west(0,60)。
// 判定契约：三角内 hover、三角外（下半/左右）不 hover。

#include <QtTest>

#include <QQuickItem>
#include <QQuickWindow>
#include <QRegularExpression>

#include <QQmlComponent>
#include <QQmlEngine>

#include <QPoint>

class TestHoverE2E : public QObject {
  Q_OBJECT

private slots:
  void halfCrystalMaskEndToEnd();
};

namespace {

// 场景内窗口坐标 = contentItem 坐标（HalfCrystal 在 contentItem (20,20)）
QPoint windowPos(int localX, int localY) {
  return QPoint(20 + localX, 20 + localY);
}

} // namespace

void TestHoverE2E::halfCrystalMaskEndToEnd() {
  // 期望 WARN（测试环境无主题插件）：本测试实例化 Qool 组件 → ThemeDB
  // 初始化 → PluginLoader 扫描不到 qoolplugins/（插件随 example 部署，
  // 测试 exe 目录无）→ "No ThemeLoader installed" WARN，ThemeDB 回退
  // system 主题。断言不依赖主题（几何/相对色），WARN 无影响；经
  // ignoreMessage 吞掉并验证其出现（未出现会提示——说明环境变化）。
  QTest::ignoreMessage(QtWarningMsg,
      QRegularExpression(QStringLiteral("No ThemeLoader installed.*")));

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

    property alias halfCrystal: hc
    property alias hcArea: hcArea
    property alias plainArea: plainArea

    HalfCrystal {
        id: hc
        x: 20
        y: 20
        width: 120
        height: 120
        MouseArea {
            id: hcArea
            anchors.fill: parent
            hoverEnabled: true
            // 修复验证：宿主 MouseArea 复用组件掩码（Qt hover 分发不检查
            // 祖先掩码——需显式挂到 MouseArea 自身）
            containmentMask: hc.containmentMask
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

  auto hc = root->property("halfCrystal").value<QQuickItem*>();
  auto hcArea = root->property("hcArea").value<QQuickItem*>();
  auto plainArea = root->property("plainArea").value<QQuickItem*>();
  QVERIFY(hc);
  QVERIFY(hcArea);
  QVERIFY(plainArea);

  // ---- 对照：无掩码矩形（注入通道可用性）----
  QTest::mouseMove(&window, QPoint(200 + 60, 20 + 45));
  QTRY_VERIFY(plainArea->property("containsMouse").toBool());

  // ---- 原掩码（HalfCrystalGadget）：直接调用 vs 引擎路径对照 ----
  QObject* origMask = hc->containmentMask();
  QVERIFY(origMask);
  QCOMPARE(hcArea->containmentMask(), origMask); // MouseArea QML 绑定已挂同掩码

  // 直接调用 QQuickItem::contains（= 引擎 hitTest 同款检查，含掩码）
  QCOMPARE(hc->contains(QPointF(60, 45)), true);
  QCOMPARE(hc->contains(QPointF(60, 90)), false);

  // ---- 引擎路径：MouseArea 挂掩码（Qt hover 分发不检查祖先掩码——
  // 组件掩码须显式挂到宿主 MouseArea 自身，见 HalfCrystal QDoc）----
  // 三角内：hover
  QTest::mouseMove(&window, windowPos(60, 45));
  QTRY_VERIFY(hcArea->property("containsMouse").toBool());

  // 下半（三角外）：不 hover（用户报告误判区域）
  QTest::mouseMove(&window, windowPos(60, 90));
  QTRY_VERIFY(!hcArea->property("containsMouse").toBool());

  // 移出组件（窗口左上角，hc 外）：不应 hover
  QTest::mouseMove(&window, QPoint(5, 5));
  QTRY_VERIFY(!hcArea->property("containsMouse").toBool());

  root->deleteLater();
}

QTEST_MAIN(TestHoverE2E)

#include "tst_hover_e2e.moc"
