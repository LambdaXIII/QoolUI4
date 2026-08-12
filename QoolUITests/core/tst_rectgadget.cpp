// Qool 核心 C++ 类型测试：RectGadget（Qool/shapecontrol/gadgets/）
//
// 被测面：派生几何契约（HalfCrystal 画布依赖 + 通用 RectGadget 消费面）——
//   九点（含偏移本地坐标语义）、四半区矩形、maxInnerSquareRect/
//   minOutterSquareRect/shortEdge/longEdge/isSquare、rect 属性同步、
//   contains 外接矩形判定（含边界）。
//
// 历史回归哨兵：halfWidth 曾误绑 m_hcenter（中心坐标而非半宽）导致半区
// 矩形全错、rightHalfRect 曾误写 x=halfWidth——本文件覆盖全部派生量。
// 宏生成 setter 在 protected 作用域——测试子类用 using 声明提升为 public。

#include <QtTest>

#include "qool_test.hpp"

#include "shapecontrol/gadgets/qool_shapegadget_rect.h"

#include <cmath>

using namespace qoolui;

namespace {

bool fuzzy_eq(qreal actual, qreal expected, qreal eps = 1e-6) {
  return std::abs(actual - expected) <= eps;
}

void comparePoint(const QPointF& p, qreal ex, qreal ey,
    const char* tag = nullptr) {
  QVERIFY2(fuzzy_eq(p.x(), ex),
      qPrintable(QString("点 %1 的 x 期望 %2 实际 %3")
                     .arg(tag ? tag : "")
                     .arg(ex)
                     .arg(p.x())));
  QVERIFY2(fuzzy_eq(p.y(), ey),
      qPrintable(QString("点 %1 的 y 期望 %2 实际 %3")
                     .arg(tag ? tag : "")
                     .arg(ey)
                     .arg(p.y())));
}

void compareRect(const QRectF& r, qreal x, qreal y, qreal w, qreal h,
    const char* tag = nullptr) {
  QVERIFY2(fuzzy_eq(r.x(), x) && fuzzy_eq(r.y(), y) && fuzzy_eq(r.width(), w)
          && fuzzy_eq(r.height(), h),
      qPrintable(QString("矩形 %1 期望 (%2,%3 %4x%5) 实际 (%6,%7 %8x%9)")
                     .arg(tag ? tag : "")
                     .arg(x)
                     .arg(y)
                     .arg(w)
                     .arg(h)
                     .arg(r.x())
                     .arg(r.y())
                     .arg(r.width())
                     .arg(r.height())));
}

class TestRectGadget : public RectGadget {
public:
  using RectGadget::set_x;
  using RectGadget::set_y;
  using RectGadget::set_width;
  using RectGadget::set_height;
};

} // namespace

class TestRectGadgetGeometry : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(nine_points_offset) {
  // x=10 y=20 w=100 h=60：九点全部含偏移（本地坐标语义）
  TestRectGadget r;
  r.set_x(10);
  r.set_y(20);
  r.set_width(100);
  r.set_height(60);

  comparePoint(r.topLeft(), 10, 20, "topLeft");
  comparePoint(r.topCenter(), 60, 20, "topCenter");
  comparePoint(r.topRight(), 110, 20, "topRight");
  comparePoint(r.leftCenter(), 10, 50, "leftCenter");
  comparePoint(r.center(), 60, 50, "center");
  comparePoint(r.rightCenter(), 110, 50, "rightCenter");
  comparePoint(r.bottomLeft(), 10, 80, "bottomLeft");
  comparePoint(r.bottomCenter(), 60, 80, "bottomCenter");
  comparePoint(r.bottomRight(), 110, 80, "bottomRight");

  // 分量属性与 QPointF 一致
  QVERIFY(fuzzy_eq(r.centerX(), 60));
  QVERIFY(fuzzy_eq(r.centerY(), 50));
}
  QOOL_TEST_CASE(half_rects_offset) {
  // 四半区矩形在任意位置偏移下正确（曾误绑半宽为 x 偏移——回归哨兵）
  TestRectGadget r;
  r.set_x(10);
  r.set_y(20);
  r.set_width(100);
  r.set_height(60);

  compareRect(r.topHalfRect(), 10, 20, 100, 30, "topHalfRect");
  compareRect(r.bottomHalfRect(), 10, 50, 100, 30, "bottomHalfRect");
  compareRect(r.leftHalfRect(), 10, 20, 50, 60, "leftHalfRect");
  compareRect(r.rightHalfRect(), 60, 20, 50, 60, "rightHalfRect");
}
  QOOL_TEST_CASE(square_derived) {
  TestRectGadget r;
  r.set_x(0);
  r.set_y(0);
  r.set_width(40);
  r.set_height(40);

  QVERIFY(fuzzy_eq(r.shortEdge(), 40));
  QVERIFY(fuzzy_eq(r.longEdge(), 40));
  QVERIFY(r.isSquare());
  compareRect(r.maxInnerSquareRect(), 0, 0, 40, 40, "maxInnerSquare");
  compareRect(r.minOutterSquareRect(), 0, 0, 40, 40, "minOutterSquare");
  compareRect(r.topHalfRect(), 0, 0, 40, 20, "topHalfRect");
  compareRect(r.rightHalfRect(), 20, 0, 20, 40, "rightHalfRect");
}
  QOOL_TEST_CASE(wide_derived) {
  // 100×60：maxInnerSquare 以 shortEdge 居中；minOutterSquare 以 longEdge 居中
  TestRectGadget r;
  r.set_x(0);
  r.set_y(0);
  r.set_width(100);
  r.set_height(60);

  QVERIFY(fuzzy_eq(r.shortEdge(), 60));
  QVERIFY(fuzzy_eq(r.longEdge(), 100));
  QVERIFY(!r.isSquare());
  compareRect(r.maxInnerSquareRect(), 20, 0, 60, 60, "maxInnerSquare");
  compareRect(r.minOutterSquareRect(), 0, -20, 100, 100, "minOutterSquare");
}
  QOOL_TEST_CASE(rect_property_sync) {
  // rect 由 x/y/width/height 派生（构造绑定）；显式 set_rect 写回四元
  TestRectGadget r;
  r.set_x(1);
  r.set_y(2);
  r.set_width(30);
  r.set_height(40);
  compareRect(r.rect(), 1, 2, 30, 40, "rect");

  r.set_rect(QRectF(5, 6, 50, 60));
  compareRect(r.rect(), 5, 6, 50, 60, "rect");
  QVERIFY(fuzzy_eq(r.x(), 5));
  QVERIFY(fuzzy_eq(r.y(), 6));
  QVERIFY(fuzzy_eq(r.width(), 50));
  QVERIFY(fuzzy_eq(r.height(), 60));
}
  QOOL_TEST_CASE(contains_boundary) {
  // RectGadget::contains = 外接矩形判定（含边界——QRectF::contains 语义）
  TestRectGadget r;
  r.set_x(10);
  r.set_y(20);
  r.set_width(100);
  r.set_height(60);

  QVERIFY(r.contains(QPointF(10, 20)));   // 左上角（边界含）
  QVERIFY(r.contains(QPointF(60, 50)));   // 中心
  QVERIFY(r.contains(QPointF(110, 80)));  // 右下角（边界含）
  QVERIFY(!r.contains(QPointF(9, 50)));
  QVERIFY(!r.contains(QPointF(60, 81)));
}
};

QTEST_MAIN(TestRectGadgetGeometry)

#include "tst_rectgadget.moc"
