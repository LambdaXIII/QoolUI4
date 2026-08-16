// Qool 端到端 hover 测试：真实窗口 + 真实鼠标事件路径下，HalfCrystal 的
// hover 判定域（掩码契约——内接画布矩形判定）。
//
// 背景（2026-08-16 HalfCrystal 重做）：用户裁决禁止 FillContains 掩码
// 判定（性能代价过大）——containsMode 不设；命中掩码由 gB（RectGadget，
// 数值矩形 contains——非路径填充面判定）承接：根 containmentMask = gB，
// 命中域 = 内接画布矩形（三角外的左右条带被排除；精确三角判定不提供）。
// Qt 6.11 的 QHoverEvent 分发（QQuickDeliveryAgent::deliverHoverEvent
// Recursive）对每个 item 独立调用其自身 contains——MouseArea 不挂掩码时
// hover 域 = 自身矩形；挂 \c{containmentMask: hc.containmentMask}
// （anchors.fill 时本地坐标一致）才获得画布矩形精确 hover。
//
// 注：QML 测试批次（qml/）TestCase.mouseMove 在 offscreen 平台不注入事件
// ——真实鼠标路径在本层用 QTest::mouseMove（Qt 官方 QQuickTest 同款通道）
// 验证。
//
// 场景 = HalfCrystal 120×80（非方形——内接画布 80×80 居中 (20,0)，
// 掩码 = x∈[20,100]、y∈[0,80]），direction=N（默认）。判定契约：画布
// 内 hover（含三角外区域——掩码是矩形非三角）、左右条带（x<20/x>100）
// 不 hover、组件外不 hover、containmentMask 非空。

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
  void halfCrystalMaskContract();
};

namespace {

// 场景内窗口坐标 = contentItem 坐标（HalfCrystal 在 contentItem (20,20)）
QPoint windowPos(int localX, int localY) {
  return QPoint(20 + localX, 20 + localY);
}

} // namespace

void TestHoverE2E::halfCrystalMaskContract() {
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
        height: 80
        MouseArea {
            id: hcArea
            anchors.fill: parent
            hoverEnabled: true
            // 掩码契约：挂组件掩码（= gB 内接画布矩形——anchors.fill
            // 时本地坐标一致）——左右条带（三角外）不 hover
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

  // ---- 掩码契约断言：containmentMask = gB（非空）----
  QVERIFY2(hc->containmentMask() != nullptr,
      "HalfCrystal 命中掩码 = gB（内接画布矩形——RectGadget 数值 contains）");

  // ---- 对照：无掩码矩形（注入通道可用性）----
  QTest::mouseMove(&window, QPoint(200 + 60, 20 + 45));
  QTRY_VERIFY(plainArea->property("containsMouse").toBool());

  // ---- 引擎路径：MouseArea 挂掩码，hover 域 = 内接画布矩形 ----
  // 120×80 N 态：画布 x∈[20,100] y∈[0,80]——三角内（60,45）：hover
  QTest::mouseMove(&window, windowPos(60, 45));
  QTRY_VERIFY(hcArea->property("containsMouse").toBool());

  // 画布内、三角外（60,70——y>40 下半）：掩码为矩形——仍 hover
  QTest::mouseMove(&window, windowPos(60, 70));
  QTRY_VERIFY(hcArea->property("containsMouse").toBool());

  // 左条带（10,40——x<20，画布外）：掩码排除——不 hover
  QTest::mouseMove(&window, windowPos(10, 40));
  QTRY_VERIFY(!hcArea->property("containsMouse").toBool());

  // 右条带（110,40——x>100，画布外）：掩码排除——不 hover
  QTest::mouseMove(&window, windowPos(110, 40));
  QTRY_VERIFY(!hcArea->property("containsMouse").toBool());

  // 移出组件（窗口左上角，hc 外）：不应 hover
  QTest::mouseMove(&window, QPoint(5, 5));
  QTRY_VERIFY(!hcArea->property("containsMouse").toBool());

  root->deleteLater();
}

QTEST_MAIN(TestHoverE2E)

#include "tst_hover_e2e.moc"
