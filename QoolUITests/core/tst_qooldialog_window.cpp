// QoolDialog 窗口级行为测试（真实 QQuickWindow + 真实按键/关闭请求路径）。
//
// 为什么在 C++ 层：QML 批次（tst_qooldialogs_qml）的 TestCase 只有自己那一个
// 窗口，按键、系统关闭、窗口激活都到不了被测对话框窗口；QoolDialog 是独立
// Window，行为只能在这一层验证。
//
// 覆盖的契约（QoolDialog 全部退出与结果行为）：
// - footer 槽里的 DialogButtonBox 必须真正可见：样式层内容宿主存在、按钮
//   挂在该宿主下、进入场景图、有非零尺寸且不重叠。只继承 Template 时按钮
//   无父件——count 与 implicit 尺寸全对，屏幕上什么都没有。
// - Esc ≡ Cancel：Esc 走 reject()，等价于 Cancel（RejectRole → rejected）。
// - 系统关闭请求（close/Alt+F4/标题栏）≡ reject：窗口不被真的关掉，结果
//   由 rejected 送出。
// - accept()/reject()：发出对应信号各一次并隐藏窗口。

#include <QtTest>

#include <QQuickItem>
#include <QQuickWindow>
#include <QRegularExpression>

#include <QQmlComponent>
#include <QQmlEngine>
#include <QSignalSpy>

class TestQoolDialogWindow: public QObject {
  Q_OBJECT

private slots:
  void footerButtonsAreHosted();
  void escapeRejectsLikeCancel();
  void escapeActivatesCancelButton();
  void overlayPopupClosesOnEscape();
  void systemCloseRejects();
  void acceptAndRejectResults();

private:
  struct Fixture {
    QQmlEngine engine;
    QQmlComponent component { &engine };
    QScopedPointer<QObject> root;
    QQuickWindow* window = nullptr;

    bool build(const char* source = kDialogQml) {
      engine.addImportPath(QStringLiteral(QOOLUI_TEST_QML_IMPORT_PATH));
      component.setData(source, QUrl());
      if (!component.isReady()) {
        qWarning("%s", qPrintable(component.errorString()));
        return false;
      }
      root.reset(component.create());
      window = qobject_cast<QQuickWindow*>(root.data());
      if (!window) {
        return false;
      }
      window->show();
      return QTest::qWaitForWindowExposed(window);
    }

    QQuickItem* footer() const {
      return qvariant_cast<QQuickItem*>(window->property("footer"));
    }
  };

  static constexpr const char* kDialogQml = R"(
import QtQuick
import Qool
import Qool.Dialogs

QoolDialog {
    id: dialog
    title: "QoolDialog 行为测试"

    content: Item {
        implicitWidth: 160
        implicitHeight: 40
    }

    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
        onAccepted: dialog.accept()
        onRejected: dialog.reject()
    }
}
)";

  // Esc 走 Cancel 按钮通道的证据面：Cancel 刻意不关窗，只记账。
  static constexpr const char* kCancelChannelQml = R"(
import QtQuick
import Qool
import Qool.Dialogs

QoolDialog {
    id: dialog
    title: "Cancel 通道"

    property int cancelClicks: 0

    content: Item {
        implicitWidth: 160
        implicitHeight: 40
    }

    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
        onRejected: dialog.cancelClicks++
    }
}
)";

  // 参考文档里 overlay 用法的镜像：Popup 自带 dim/closePolicy，表面件只管表面。
  static constexpr const char* kPopupQml = R"(
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qool
import Qool.Dialogs

Window {
    id: win
    width: 400
    height: 300
    visible: true

    property alias popup: popup

    Popup {
        id: popup
        modal: true
        dim: true
        // Popup.focus 默认 false——不取焦点就没有 CloseOnEscape
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Item {}
        width: 320
        height: 200
        anchors.centerIn: Overlay.overlay

        DialogSurface {
            anchors.fill: parent
            title: "overlay"
            content: Item {}
        }
    }

    Component.onCompleted: popup.open()
}
)";
};

void TestQoolDialogWindow::footerButtonsAreHosted() {
  Fixture f;
  QVERIFY(f.build());

  QQuickItem* box = f.footer();
  QVERIFY2(box, "footer 槽应拿到 DialogButtonBox");
  QTRY_COMPARE(box->property("count").toInt(), 2);

  QQuickItem* host = qvariant_cast<QQuickItem*>(box->property("contentItem"));
  QVERIFY2(host, "盒必须有内容宿主——样式层提供，Template 层不提供");

  QQuickItem* previous = nullptr;
  for (int i = 0; i < 2; ++i) {
    QQuickItem* button = nullptr;
    QVERIFY(QMetaObject::invokeMethod(box, "itemAt",
        Q_RETURN_ARG(QQuickItem*, button), Q_ARG(int, i)));
    QVERIFY2(button, qPrintable(QStringLiteral("itemAt(%1)").arg(i)));

    // 进入场景图是「看得见」的硬前提：只继承 Template 时按钮无父件，
    // count 与 implicit 尺寸全对，但永不绘制。
    QTRY_VERIFY2(button->window() != nullptr,
        "标准按钮必须进入场景图（挂在样式层内容宿主下）");
    QVERIFY(button->isVisible());
    QVERIFY(button->width() > 0);
    QVERIFY(button->height() > 0);
    QVERIFY(button->mapToScene(QPointF(0, 0)).y() >= 0);
    QVERIFY(button->mapToScene(QPointF(0, 0)).y()
            + button->height() <= f.window->height() + 0.5);

    if (previous) {
      QVERIFY2(button->mapToScene(QPointF(0, 0)).x()
                   >= previous->mapToScene(QPointF(0, 0)).x() + previous->width(),
          "同一行按钮不得重叠（排布必须生效）");
    }
    previous = button;
  }

  QVERIFY(box->width() > 0);
  QVERIFY(box->height() > 0);
  QVERIFY(box->y() + box->height() <= f.window->height() + 0.5);
}

void TestQoolDialogWindow::escapeRejectsLikeCancel() {
  Fixture f;
  QVERIFY(f.build());
  QVERIFY(f.window->isVisible());

  QSignalSpy acceptedSpy(f.window, SIGNAL(accepted()));
  QSignalSpy rejectedSpy(f.window, SIGNAL(rejected()));

  QTest::keyClick(f.window, Qt::Key_Escape);

  QTRY_COMPARE(rejectedSpy.count(), 1);
  QCOMPARE(acceptedSpy.count(), 0);
  QVERIFY2(!f.window->isVisible(), "Esc 必须关闭对话框（等价于 Cancel）");
}

void TestQoolDialogWindow::escapeActivatesCancelButton() {
  Fixture f;
  QVERIFY(f.build(kCancelChannelQml));
  QVERIFY(f.window->isVisible());

  // 刻意把 Cancel 接到计数器而不是 reject()：Esc 若直接关窗，这个计数不会动
  QCOMPARE(f.window->property("cancelClicks").toInt(), 0);

  QTest::keyClick(f.window, Qt::Key_Escape);

  QTRY_COMPARE(f.window->property("cancelClicks").toInt(), 1);
  QVERIFY2(f.window->isVisible(),
      "Esc 走的是 Cancel 按钮通道——按钮自己没关窗，对话框就不该关");
}

void TestQoolDialogWindow::overlayPopupClosesOnEscape() {
  Fixture f;
  QVERIFY(f.build(kPopupQml));

  QObject* popup = f.window->property("popup").value<QObject*>();
  QVERIFY(popup);
  QTRY_VERIFY(popup->property("visible").toBool());

  QTest::keyClick(f.window, Qt::Key_Escape);
  QTRY_VERIFY2(!popup->property("visible").toBool(),
      "overlay 用法的 Esc 由 Popup 的 closePolicy 负责");
}

void TestQoolDialogWindow::systemCloseRejects() {
  Fixture f;
  QVERIFY(f.build());

  QSignalSpy acceptedSpy(f.window, SIGNAL(accepted()));
  QSignalSpy rejectedSpy(f.window, SIGNAL(rejected()));

  f.window->close();

  QTRY_COMPARE(rejectedSpy.count(), 1);
  QCOMPARE(acceptedSpy.count(), 0);
  QVERIFY(!f.window->isVisible());
}

void TestQoolDialogWindow::acceptAndRejectResults() {
  {
    Fixture f;
    QVERIFY(f.build());
    QSignalSpy acceptedSpy(f.window, SIGNAL(accepted()));
    QVERIFY(QMetaObject::invokeMethod(f.window, "accept"));
    QTRY_COMPARE(acceptedSpy.count(), 1);
    QVERIFY(!f.window->isVisible());
  }
  {
    Fixture f;
    QVERIFY(f.build());
    QSignalSpy rejectedSpy(f.window, SIGNAL(rejected()));
    QVERIFY(QMetaObject::invokeMethod(f.window, "reject"));
    QTRY_COMPARE(rejectedSpy.count(), 1);
    QVERIFY(!f.window->isVisible());
  }
}

// 强制 offscreen：本测试开真实窗口并注入按键/关闭请求，任何通道都必须无头
// （静态对象在 main() 前构造，早于 QTEST_MAIN 创建 QGuiApplication）。
// 同时锚死 Qt Quick Controls 风格为 Basic：Qool.Dialogs 的 DialogButtonBox
// 基座在 QtQuick.Controls 样式层，import 该模块会初始化 Controls 运行时并
// 加载所选风格插件；平台默认的 Windows 风格插件在测试 exe 目录不可加载，
// 而 Basic 是 Qt 必装、DLL 已随 target 部署。
namespace {
struct QoolTestForceOffscreen {
  QoolTestForceOffscreen() {
    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
  }
} _qoolTestForceOffscreen;
} // namespace

QTEST_MAIN(TestQoolDialogWindow)

#include "tst_qooldialog_window.moc"
