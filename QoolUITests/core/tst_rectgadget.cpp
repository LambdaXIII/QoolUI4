// Qool 核心 C++ 类型测试：RectGadget（Qool/shapecontrol/gadgets/）
//
// 被测面：派生几何契约（HalfCrystal 画布依赖 + 通用 RectGadget 消费面）——
//   九点（含偏移本地坐标语义）、四半区矩形、maxInnerSquareRect/
//   minOutterSquareRect/shortEdge/longEdge/isSquare、rect 属性同步、
//   contains 外接矩形判定（含边界）、target 尺寸跟随（非 boundingRect）、
//   设置覆盖初始化绑定、rect 外部绑定下的单一数据源契约。
//
// 行为规范：
//   1. m_rect 为内部数据源——派生几何统一基于 rect 计算；
//   2. 初始化 w/h 绑定 target 的 width/height（非 boundingRect），x/y 固定 0；
//   3. rect 与 x/y/w/h 联动（类似 Point 与分量）——任一属性设置即覆盖其
//      绑定（含初始化绑定），set_rect 等价于按需设定一遍四分量；
//   4. 其余派生数据统一基于 m_rect。
// 回归防护：本文件覆盖全部派生量（半区矩形在任意位置偏移下正确）。
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
  using ShapeControlGadget::set_target;
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
  // 四半区矩形在任意位置偏移下正确（回归防护）
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
  QOOL_TEST_CASE(target_size_follow) {
  // 规范 2：初始化 w/h 绑定 target 的 width/height（非 boundingRect）——
  // 尺寸跟随、位置不跟随（x/y 固定 0）、变换不影响（transform 只改
  // boundingRect，本地 width/height 不变——渲染与几何同基准）
  QQuickItem item;
  item.setWidth(120);
  item.setHeight(80);
  TestRectGadget r;
  r.set_target(&item);

  QVERIFY(fuzzy_eq(r.x(), 0));
  QVERIFY(fuzzy_eq(r.y(), 0));
  QVERIFY(fuzzy_eq(r.width(), 120));
  QVERIFY(fuzzy_eq(r.height(), 80));
  compareRect(r.rect(), 0, 0, 120, 80, "rect");

  // target 位置变化不影响几何（x/y 固定 0——派生几何本地坐标语义）
  item.setX(300);
  item.setY(400);
  QVERIFY(fuzzy_eq(r.x(), 0));
  QVERIFY(fuzzy_eq(r.y(), 0));
  compareRect(r.rect(), 0, 0, 120, 80, "rect");

  // target 尺寸变化跟随
  item.setWidth(200);
  item.setHeight(100);
  QVERIFY(fuzzy_eq(r.width(), 200));
  QVERIFY(fuzzy_eq(r.height(), 100));
  compareRect(r.rect(), 0, 0, 200, 100, "rect");

  // target 变换（旋转/缩放）不改本地 width/height——绑定的是 width/height
  // 而非 boundingRect（boundingRect 随变换扩张）
  item.setRotation(45);
  item.setScale(2);
  QVERIFY(fuzzy_eq(r.width(), 200));
  QVERIFY(fuzzy_eq(r.height(), 100));
  compareRect(r.rect(), 0, 0, 200, 100, "rect");
}
  QOOL_TEST_CASE(target_binding_overridden) {
  // 规范 3：属性设置覆盖初始化绑定（含 target 绑定）——且分量粒度独立：
  // 设置 width 只覆盖 width 的绑定，height 的 target 绑定保留
  QQuickItem item;
  item.setWidth(120);
  item.setHeight(80);
  TestRectGadget r;
  r.set_target(&item);
  QVERIFY(fuzzy_eq(r.width(), 120));

  r.set_width(100);  // 覆盖 width 的 target 绑定
  item.setWidth(200);
  QVERIFY(fuzzy_eq(r.width(), 100));  // 不再跟随 target
  QVERIFY(fuzzy_eq(r.height(), 80));  // height 绑定仍存活

  item.setHeight(50);
  QVERIFY(fuzzy_eq(r.height(), 50));  // height 继续跟随 target
  compareRect(r.rect(), 0, 0, 100, 50, "rect");
}
  QOOL_TEST_CASE(set_rect_overrides_bindings) {
  // 规范 3：set_rect 等价于按需设定一遍四分量——覆盖全部初始化绑定，
  // target 变化不再跟随
  QQuickItem item;
  item.setWidth(120);
  item.setHeight(80);
  TestRectGadget r;
  r.set_target(&item);

  r.set_rect(QRectF(10, 20, 30, 40));
  QVERIFY(fuzzy_eq(r.x(), 10));
  QVERIFY(fuzzy_eq(r.y(), 20));
  QVERIFY(fuzzy_eq(r.width(), 30));
  QVERIFY(fuzzy_eq(r.height(), 40));
  compareRect(r.rect(), 10, 20, 30, 40, "rect");

  item.setWidth(300);
  item.setHeight(200);
  QVERIFY(fuzzy_eq(r.width(), 30));
  QVERIFY(fuzzy_eq(r.height(), 40));
}
  QOOL_TEST_CASE(component_set_keeps_others) {
  // 规范 3：分量粒度联动——设置 x 只改 x（rect 联动更新），其余分量保留
  TestRectGadget r;
  r.set_x(10);
  r.set_y(20);
  r.set_width(100);
  r.set_height(60);
  r.set_x(15);
  QVERIFY(fuzzy_eq(r.x(), 15));
  QVERIFY(fuzzy_eq(r.y(), 20));
  QVERIFY(fuzzy_eq(r.width(), 100));
  QVERIFY(fuzzy_eq(r.height(), 60));
  compareRect(r.rect(), 15, 20, 100, 60, "rect");
}
  QOOL_TEST_CASE(rect_external_binding_single_source) {
  // 规范 1/4（核心契约）：rect 被外部绑定（QPropertyBinding 等价于 QML
  // 绑定 gB.rect = ...，替换合成绑定）后——全部派生几何统一基于 rect
  // 绑定值，而非 x/y/w/h 残留值（x/y/w/h 此时是写入口，rect 绑定优先）。
  // 当前实现派生量基于 x/y/w/h——本用例为规范重构的回归哨兵。
  TestRectGadget r;
  r.set_x(0);
  r.set_y(0);
  r.set_width(100);
  r.set_height(60);

  r.bindable_rect().setBinding([] { return QRectF(10, 20, 80, 40); });

  // 九点基于 rect (10,20,80,40)
  comparePoint(r.topLeft(), 10, 20, "topLeft");
  comparePoint(r.topCenter(), 50, 20, "topCenter");
  comparePoint(r.topRight(), 90, 20, "topRight");
  comparePoint(r.leftCenter(), 10, 40, "leftCenter");
  comparePoint(r.center(), 50, 40, "center");
  comparePoint(r.rightCenter(), 90, 40, "rightCenter");
  comparePoint(r.bottomLeft(), 10, 60, "bottomLeft");
  comparePoint(r.bottomCenter(), 50, 60, "bottomCenter");
  comparePoint(r.bottomRight(), 90, 60, "bottomRight");

  // 半区矩形基于 rect
  compareRect(r.topHalfRect(), 10, 20, 80, 20, "topHalfRect");
  compareRect(r.bottomHalfRect(), 10, 40, 80, 20, "bottomHalfRect");
  compareRect(r.leftHalfRect(), 10, 20, 40, 40, "leftHalfRect");
  compareRect(r.rightHalfRect(), 50, 20, 40, 40, "rightHalfRect");

  // 边/方块基于 rect
  QVERIFY(fuzzy_eq(r.halfWidth(), 40));
  QVERIFY(fuzzy_eq(r.halfHeight(), 20));
  QVERIFY(fuzzy_eq(r.shortEdge(), 40));
  QVERIFY(fuzzy_eq(r.longEdge(), 80));
  QVERIFY(!r.isSquare());
  compareRect(r.maxInnerSquareRect(), 30, 20, 40, 40, "maxInnerSquare");
  compareRect(r.minOutterSquareRect(), 10, 0, 80, 80, "minOutterSquare");

  // contains 判定域 = rect 绑定值（与派生几何同源）
  QVERIFY(r.contains(QPointF(10, 20)));
  QVERIFY(r.contains(QPointF(50, 40)));
  QVERIFY(!r.contains(QPointF(0, 0)));
  QVERIFY(!r.contains(QPointF(100, 80)));

  // 分量写入口在 rect 被外部绑定时不改变 rect（绑定优先）——派生量仍
  // 跟随 rect 绑定值
  r.set_x(15);
  QVERIFY(fuzzy_eq(r.x(), 15));
  comparePoint(r.topLeft(), 10, 20, "topLeft");
}
};

QTEST_MAIN(TestRectGadgetGeometry)

#include "tst_rectgadget.moc"
