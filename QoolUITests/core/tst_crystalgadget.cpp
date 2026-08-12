// Qool 核心 C++ 类型测试：CrystalGadget（Qool/shapecontrol/gadgets/）
//
// 被测面：
//   - 八点模型几何（TL/TC/TR/RT/RB/BC/LB/LT + cutSize/halfWidth/halfHeight）——
//     三种形态（宽六边形 w>h / 菱形 w=h / 瘦六边形 w<h）下的点位置与重合语义
//   - bindable 链传播（target → control → gadget 几何跟随）
//   - contains 精确命中判定契约（外接矩形粗判 + 四角切角域排除）：
//     角域内不命中、斜边/顶点开集命中、形状内部命中、矩形外不命中
//
// 链构造：QQuickItem target → ShapeControl（set_target）→ CrystalGadget
// （appendChild 自动 set_control——宏生成 setter 在 protected 作用域，
// 测试子类用 using 声明提升为 public）。
//
// 契约依据（qool_shapegadget_crystal.cpp QDoc + 形状几何）：
//   cutSize = shortEdge/2；角域 = 外接矩形四角的等腰直角三角形（直角顶点
//   在矩形角、直角边沿坐标轴、斜边连接相邻八点），斜边 dx+dy == cutSize
//   开集命中。角域内点（靠近矩形角）必须不命中。

#include <QtTest>
#include <QQuickItem>

#include "qool_test.hpp"

#include "shapecontrol/qool_shapecontrol.h"
#include "shapecontrol/gadgets/qool_shapegadget_crystal.h"

#include <cmath>

using namespace qoolui;

namespace {

bool fuzzy_eq(qreal actual, qreal expected, qreal eps = 1e-6) {
  return std::abs(actual - expected) <= eps;
}

// 宏生成 setter/追加接口在 protected 作用域——测试经 using 提升
class TestShapeControl : public ShapeControl {
public:
  using ShapeControl::set_target;
  using ShapeControl::appendChild;
};

class TestCrystalGadget : public CrystalGadget {
public:
  using CrystalGadget::set_control;
};

// 完整链夹具：target（几何源头）→ control → gadget
class CrystalFixture {
public:
  QQuickItem target;
  TestShapeControl control;
  TestCrystalGadget gadget;

  CrystalFixture() {
    gadget.setParent(&control); // control 绑定依赖 parent 链
    control.set_target(&target);
    control.appendChild(&gadget); // appendChild 内 set_control(this)
  }

  void setSize(qreal w, qreal h) {
    target.setWidth(w);
    target.setHeight(h);
  }
};

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

} // namespace

class TestCrystalGadgetUnit : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(geometry_wide_hexagon) {
  // w=100 h=80：宽六边形，cutSize = shortEdge/2 = 40
  CrystalFixture f;
  f.setSize(100, 80);

  QVERIFY(fuzzy_eq(f.gadget.cutSize(), 40));
  QVERIFY(fuzzy_eq(f.gadget.halfWidth(), 50));
  QVERIFY(fuzzy_eq(f.gadget.halfHeight(), 40));

  comparePoint(f.gadget.TL(), 40, 0, "TL");
  comparePoint(f.gadget.TC(), 50, 0, "TC");
  comparePoint(f.gadget.TR(), 60, 0, "TR");
  comparePoint(f.gadget.RT(), 100, 40, "RT");
  comparePoint(f.gadget.RB(), 60, 80, "RB");
  comparePoint(f.gadget.BC(), 50, 80, "BC");
  comparePoint(f.gadget.LB(), 40, 80, "LB");
  comparePoint(f.gadget.LT(), 0, 40, "LT");
}
  QOOL_TEST_CASE(geometry_square_diamond) {
  // w=h=80：菱形（旋转 45° 正方形）——四点重合收缩，cutSize = 40
  CrystalFixture f;
  f.setSize(80, 80);

  QVERIFY(fuzzy_eq(f.gadget.cutSize(), 40));
  // 顶边三点重合于菱形上尖
  comparePoint(f.gadget.TL(), 40, 0, "TL");
  comparePoint(f.gadget.TC(), 40, 0, "TC");
  comparePoint(f.gadget.TR(), 40, 0, "TR");
  // 右尖
  comparePoint(f.gadget.RT(), 80, 40, "RT");
  // 底边三点重合于菱形下尖
  comparePoint(f.gadget.RB(), 40, 80, "RB");
  comparePoint(f.gadget.BC(), 40, 80, "BC");
  comparePoint(f.gadget.LB(), 40, 80, "LB");
  // 左尖
  comparePoint(f.gadget.LT(), 0, 40, "LT");
}
  QOOL_TEST_CASE(geometry_tall_hexagon) {
  // w=80 h=100：瘦六边形（上下尖 + 左右直边），cutSize = 40
  CrystalFixture f;
  f.setSize(80, 100);

  QVERIFY(fuzzy_eq(f.gadget.cutSize(), 40));
  // 顶边三点重合于上尖
  comparePoint(f.gadget.TL(), 40, 0, "TL");
  comparePoint(f.gadget.TC(), 40, 0, "TC");
  comparePoint(f.gadget.TR(), 40, 0, "TR");
  // 右直边两端
  comparePoint(f.gadget.RT(), 80, 40, "RT");
  comparePoint(f.gadget.RB(), 80, 60, "RB");
  // 底尖
  comparePoint(f.gadget.BC(), 40, 100, "BC");
  // 左直边两端
  comparePoint(f.gadget.LB(), 0, 60, "LB");
  comparePoint(f.gadget.LT(), 0, 40, "LT");
}
  QOOL_TEST_CASE(geometry_follows_target) {
  // bindable 链传播：target 尺寸/位置变化 → gadget 八点跟随
  CrystalFixture f;
  f.setSize(100, 80);

  f.target.setX(30);
  f.target.setY(50);
  f.target.setWidth(200);
  f.target.setHeight(120);

  // cutSize = shortEdge/2 = 60
  QVERIFY(fuzzy_eq(f.gadget.cutSize(), 60));
  // 几何跟随（x/y 偏移只影响位置量，点相对坐标不变）
  comparePoint(f.gadget.TL(), 60, 0, "TL");
  comparePoint(f.gadget.TR(), 140, 0, "TR");
  comparePoint(f.gadget.RT(), 200, 60, "RT");
  comparePoint(f.gadget.RB(), 140, 120, "RB");
  comparePoint(f.gadget.BC(), 100, 120, "BC");
  comparePoint(f.gadget.LB(), 60, 120, "LB");
  comparePoint(f.gadget.LT(), 0, 60, "LT");
}
  QOOL_TEST_CASE(contains_wide_hexagon) {
  // w=100 h=80（cut=40 六边形）——contains 契约全点矩阵
  CrystalFixture f;
  f.setSize(100, 80);

  // 形状内部命中
  QVERIFY(f.gadget.contains(QPointF(50, 40)));  // 中心
  QVERIFY(f.gadget.contains(QPointF(40, 40)));  // 内部（y=40 处 x 全宽）
  QVERIFY(f.gadget.contains(QPointF(60, 40)));  // 内部
  QVERIFY(f.gadget.contains(QPointF(50, 20)));  // 内部
  // 斜边开集命中（dx+dy == cutSize）
  QVERIFY(f.gadget.contains(QPointF(20, 20)));
  QVERIFY(f.gadget.contains(QPointF(2, 38)));
  // 八点顶点命中
  QVERIFY(f.gadget.contains(QPointF(40, 0)));   // TL
  QVERIFY(f.gadget.contains(QPointF(100, 40))); // RT
  QVERIFY(f.gadget.contains(QPointF(50, 80)));  // BC
  QVERIFY(f.gadget.contains(QPointF(0, 40)));   // LT

  // 四角切角域不命中（靠近矩形角，dx+dy < cutSize）
  QVERIFY(!f.gadget.contains(QPointF(0, 0)));   // 左上角点
  QVERIFY(!f.gadget.contains(QPointF(10, 10)));
  QVERIFY(!f.gadget.contains(QPointF(2, 2)));
  QVERIFY(!f.gadget.contains(QPointF(100, 0))); // 右上角点
  QVERIFY(!f.gadget.contains(QPointF(90, 10)));
  QVERIFY(!f.gadget.contains(QPointF(100, 80))); // 右下角点
  QVERIFY(!f.gadget.contains(QPointF(90, 70)));
  QVERIFY(!f.gadget.contains(QPointF(0, 80))); // 左下角点
  QVERIFY(!f.gadget.contains(QPointF(10, 70)));
  QVERIFY(!f.gadget.contains(QPointF(20, 80))); // 底边外（切角域内）

  // 矩形外不命中
  QVERIFY(!f.gadget.contains(QPointF(150, 40)));
  QVERIFY(!f.gadget.contains(QPointF(-5, 40)));
  QVERIFY(!f.gadget.contains(QPointF(50, -5)));
  QVERIFY(!f.gadget.contains(QPointF(50, 90)));
}
  QOOL_TEST_CASE(contains_square_diamond) {
  // w=h=80（cut=40 菱形）
  CrystalFixture f;
  f.setSize(80, 80);

  QVERIFY(f.gadget.contains(QPointF(40, 40))); // 中心
  QVERIFY(f.gadget.contains(QPointF(60, 40))); // 内部
  QVERIFY(f.gadget.contains(QPointF(20, 20))); // 斜边
  QVERIFY(f.gadget.contains(QPointF(40, 0)));  // 上尖
  QVERIFY(f.gadget.contains(QPointF(80, 40))); // 右尖
  QVERIFY(f.gadget.contains(QPointF(40, 80))); // 下尖
  QVERIFY(f.gadget.contains(QPointF(0, 40)));  // 左尖

  QVERIFY(!f.gadget.contains(QPointF(0, 0)));
  QVERIFY(!f.gadget.contains(QPointF(10, 10)));
  QVERIFY(!f.gadget.contains(QPointF(70, 10))); // 右上角域
  QVERIFY(!f.gadget.contains(QPointF(70, 70))); // 右下角域
  QVERIFY(!f.gadget.contains(QPointF(10, 70))); // 左下角域
  QVERIFY(!f.gadget.contains(QPointF(-10, 40)));
}
  QOOL_TEST_CASE(contains_tall_hexagon) {
  // w=80 h=100（cut=40 瘦六边形：上下尖 + 左右直边）
  CrystalFixture f;
  f.setSize(80, 100);

  QVERIFY(f.gadget.contains(QPointF(40, 50))); // 中心
  QVERIFY(f.gadget.contains(QPointF(40, 0)));  // 上尖
  QVERIFY(f.gadget.contains(QPointF(80, 50))); // 右直边中点
  QVERIFY(f.gadget.contains(QPointF(0, 50)));  // 左直边中点
  QVERIFY(f.gadget.contains(QPointF(20, 50))); // 内部
  QVERIFY(f.gadget.contains(QPointF(20, 20))); // 斜边

  QVERIFY(!f.gadget.contains(QPointF(10, 10)));
  QVERIFY(!f.gadget.contains(QPointF(70, 10))); // 右上角域
  QVERIFY(!f.gadget.contains(QPointF(10, 90))); // 左下角域
  QVERIFY(!f.gadget.contains(QPointF(70, 90))); // 右下角域
  QVERIFY(!f.gadget.contains(QPointF(-1, 50)));
  QVERIFY(!f.gadget.contains(QPointF(40, 110)));
}
  QOOL_TEST_CASE(contains_follows_size_change) {
  // 尺寸变化 → 判定跟随（bindable 链）
  CrystalFixture f;
  f.setSize(100, 80); // cut=40

  QVERIFY(!f.gadget.contains(QPointF(10, 10))); // 角域
  QVERIFY(f.gadget.contains(QPointF(50, 40)));          // 中心

  // 缩成正方形 40×40：cut=20，(10,10) 变为斜边（x+y=20）命中
  f.setSize(40, 40);
  QVERIFY(fuzzy_eq(f.gadget.cutSize(), 20));
  QVERIFY(f.gadget.contains(QPointF(10, 10))); // 斜边开集
  QVERIFY(f.gadget.contains(QPointF(20, 20))); // 中心
  QVERIFY(!f.gadget.contains(QPointF(5, 5)));  // 角域
}
};

QTEST_MAIN(TestCrystalGadgetUnit)

#include "tst_crystalgadget.moc"
