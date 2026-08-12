// Qool 核心 C++ 类型测试：HalfCrystalGadget::contains（Qool/shapecontrol/gadgets/）
//
// 被测面：
//   - 无 geometrySource → 恒不命中（初始化期无交互）
//   - direction N/S/W/E → 半区粗判（topHalfRect 等）+ 内正方形四角域排除
//   - 其余方向值（Unknown/对角）→ 整正方形粗判（菱形形态）
//   - 斜边开集命中（dx+dy == halfS）、角域不命中、半区外不命中
//   - direction / 几何源变化 → 判定跟随
//   - 几何源为带偏移画布（本地画布坐标语义——组件任意位置下判定准确）
//
// 契约依据（qool_shapegadget_halfcrystal.cpp QDoc）：
//   形状 = shapeRect（半区/内正方形）减内正方形四角等腰直角三角形
//   （直角顶点在内正方形角、直角边沿坐标轴、斜边斜率 -1，直角边 = halfS）。
//   使用前提：geometrySource 恒为正方形画布（HalfCrystal 中 gB =
//   maxInnerSquareRect——非正方形画布时半区粗判超出内正方形，掩码域会
//   大于渲染形状，组件不构造该形态）。
//
// RectGadget 派生几何契约（HalfCrystal 画布依赖）见 tst_rectgadget.cpp。

#include <QtTest>

#include "qool_test.hpp"

#include "qool_literals.h"
#include "shapecontrol/qool_shapecontrol.h"
#include "shapecontrol/gadgets/qool_shapegadget_rect.h"
#include "shapecontrol/gadgets/qool_shapegadget_halfcrystal.h"

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

// 宏生成 setter 在 protected 作用域——测试经 using 提升
class TestRectGadget : public RectGadget {
public:
  using RectGadget::set_x;
  using RectGadget::set_y;
  using RectGadget::set_width;
  using RectGadget::set_height;
};

class TestHalfCrystalGadget : public HalfCrystalGadget {
public:
  using HalfCrystalGadget::set_geometrySource;
  using HalfCrystalGadget::set_direction;
};

// 画布夹具：gB = 内正方形画布（x=10,y=10,w=20,h=20，halfS=10，中心 (20,20)）
// ——带偏移，验证本地画布坐标语义（contains 收到的 point 为组件本地坐标）
class CanvasFixture {
public:
  TestRectGadget gb;
  TestHalfCrystalGadget mask;

  CanvasFixture() { mask.set_geometrySource(&gb); }

  void setCanvas(qreal x, qreal y, qreal w, qreal h) {
    gb.set_x(x);
    gb.set_y(y);
    gb.set_width(w);
    gb.set_height(h);
  }

  void setDirection(int d) { mask.set_direction(d); }
};

} // namespace

// ---------- HalfCrystalGadget::contains ----------

class TestHalfCrystalGadgetUnit : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(no_source_never_hits) {
  // 几何源未就绪——初始化期无交互
  TestHalfCrystalGadget m;
  QVERIFY(!m.contains(QPointF(0, 0)));
  QVERIFY(!m.contains(QPointF(20, 20)));
  QVERIFY(!m.contains(QPointF(1000, 1000)));
}
  QOOL_TEST_CASE(direction_n) {
  // N：topHalfRect 粗判 + 四角域排除 → 三角形 north(20,10) east(30,20)
  // west(10,20)（直角顶点 north）
  CanvasFixture f;
  f.setCanvas(10, 10, 20, 20);
  f.setDirection(QoolLiterals::N);

  QVERIFY(f.mask.contains(QPointF(20, 15))); // 三角形内部
  QVERIFY(f.mask.contains(QPointF(20, 10))); // north 顶点
  QVERIFY(f.mask.contains(QPointF(10, 20))); // west 顶点
  QVERIFY(f.mask.contains(QPointF(30, 20))); // east 顶点
  QVERIFY(f.mask.contains(QPointF(15, 15))); // 斜边开集（dx+dy == halfS）
  QVERIFY(f.mask.contains(QPointF(25, 15))); // 斜边开集

  QVERIFY(!f.mask.contains(QPointF(14, 14))); // 左上角域
  QVERIFY(!f.mask.contains(QPointF(26, 14))); // 右上角域
  QVERIFY(!f.mask.contains(QPointF(20, 25))); // 半区外（下半）
  QVERIFY(!f.mask.contains(QPointF(5, 15)));  // 半区外（左）
  QVERIFY(!f.mask.contains(QPointF(35, 15))); // 半区外（右）
}
  QOOL_TEST_CASE(direction_s) {
  CanvasFixture f;
  f.setCanvas(10, 10, 20, 20);
  f.setDirection(QoolLiterals::S);

  QVERIFY(f.mask.contains(QPointF(20, 25))); // 三角形内部
  QVERIFY(f.mask.contains(QPointF(20, 30))); // south 顶点
  QVERIFY(f.mask.contains(QPointF(10, 20))); // west 顶点
  QVERIFY(f.mask.contains(QPointF(30, 20))); // east 顶点
  QVERIFY(f.mask.contains(QPointF(15, 25))); // 斜边开集

  QVERIFY(!f.mask.contains(QPointF(14, 26))); // 左下角域
  QVERIFY(!f.mask.contains(QPointF(26, 26))); // 右下角域
  QVERIFY(!f.mask.contains(QPointF(20, 15))); // 半区外（上半）
}
  QOOL_TEST_CASE(direction_w) {
  CanvasFixture f;
  f.setCanvas(10, 10, 20, 20);
  f.setDirection(QoolLiterals::W);

  QVERIFY(f.mask.contains(QPointF(15, 20))); // 三角形内部
  QVERIFY(f.mask.contains(QPointF(10, 20))); // west 顶点
  QVERIFY(f.mask.contains(QPointF(20, 10))); // north 顶点
  QVERIFY(f.mask.contains(QPointF(20, 30))); // south 顶点
  QVERIFY(f.mask.contains(QPointF(15, 15))); // 斜边开集
  QVERIFY(f.mask.contains(QPointF(15, 25))); // 斜边开集

  QVERIFY(!f.mask.contains(QPointF(14, 14))); // 左上角域
  QVERIFY(!f.mask.contains(QPointF(14, 26))); // 左下角域
  QVERIFY(!f.mask.contains(QPointF(25, 20))); // 半区外（右）
}
  QOOL_TEST_CASE(direction_e) {
  CanvasFixture f;
  f.setCanvas(10, 10, 20, 20);
  f.setDirection(QoolLiterals::E);

  QVERIFY(f.mask.contains(QPointF(25, 20))); // 三角形内部
  QVERIFY(f.mask.contains(QPointF(30, 20))); // east 顶点
  QVERIFY(f.mask.contains(QPointF(20, 10))); // north 顶点
  QVERIFY(f.mask.contains(QPointF(20, 30))); // south 顶点
  QVERIFY(f.mask.contains(QPointF(25, 15))); // 斜边开集

  QVERIFY(!f.mask.contains(QPointF(26, 14))); // 右上角域
  QVERIFY(!f.mask.contains(QPointF(26, 26))); // 右下角域
  QVERIFY(!f.mask.contains(QPointF(15, 20))); // 半区外（左——rightHalfRect 外）
}
  QOOL_TEST_CASE(direction_default_diamond) {
  // Unknown=0（默认）与对角方向 → 整正方形粗判（菱形形态）
  CanvasFixture f;
  f.setCanvas(10, 10, 20, 20);
  f.setDirection(QoolLiterals::Unknown);

  QVERIFY(f.mask.contains(QPointF(20, 20))); // 中心
  QVERIFY(f.mask.contains(QPointF(20, 10))); // north 顶点
  QVERIFY(f.mask.contains(QPointF(30, 20))); // east 顶点
  QVERIFY(f.mask.contains(QPointF(20, 30))); // south 顶点
  QVERIFY(f.mask.contains(QPointF(10, 20))); // west 顶点
  QVERIFY(f.mask.contains(QPointF(15, 15))); // 斜边开集
  QVERIFY(f.mask.contains(QPointF(15, 25))); // 斜边开集

  QVERIFY(!f.mask.contains(QPointF(14, 14))); // 左上角域
  QVERIFY(!f.mask.contains(QPointF(26, 14))); // 右上角域
  QVERIFY(!f.mask.contains(QPointF(26, 26))); // 右下角域
  QVERIFY(!f.mask.contains(QPointF(14, 26))); // 左下角域
  QVERIFY(!f.mask.contains(QPointF(5, 15)));  // 正方形外
  QVERIFY(!f.mask.contains(QPointF(20, 35))); // 正方形外

  // 对角方向（NW/NE/SW/SE）与 Unknown 同语义（菱形形态）
  f.setDirection(QoolLiterals::NW);
  QVERIFY(f.mask.contains(QPointF(20, 20)));
  QVERIFY(!f.mask.contains(QPointF(14, 14)));
  f.setDirection(QoolLiterals::SE);
  QVERIFY(f.mask.contains(QPointF(20, 20)));
  QVERIFY(!f.mask.contains(QPointF(26, 26)));
}
  QOOL_TEST_CASE(direction_switch_follows) {
  // direction 变化 → 粗判区域切换（判定跟随）
  CanvasFixture f;
  f.setCanvas(10, 10, 20, 20);
  f.setDirection(QoolLiterals::N);
  QVERIFY(f.mask.contains(QPointF(20, 15)));

  f.setDirection(QoolLiterals::S);
  QVERIFY(!f.mask.contains(QPointF(20, 15))); // 上半区不再是形状
  QVERIFY(f.mask.contains(QPointF(20, 25)));

  f.setDirection(QoolLiterals::Unknown);
  QVERIFY(f.mask.contains(QPointF(20, 15))); // 菱形包含上半内部
  QVERIFY(f.mask.contains(QPointF(20, 25)));
}
  QOOL_TEST_CASE(geometry_change_follows) {
  // 画布几何变化 → 判定跟随（bindable 派生）。注意使用前提：geometrySource
  // 恒为正方形画布（HalfCrystal 中 gB = maxInnerSquareRect）——变化保持方形
  CanvasFixture f;
  f.setCanvas(10, 10, 20, 20);
  f.setDirection(QoolLiterals::N);
  QVERIFY(f.mask.contains(QPointF(20, 15)));

  // 画布放大 40×40（halfS=20，中心 (30,30)）→ 三角形 north(30,10) east(50,30)
  // west(10,30)——旧判定点 (20,15) 进入新角域（dx+dy=15 < 20）→ 转为不命中
  f.setCanvas(10, 10, 40, 40);
  QVERIFY(fuzzy_eq(f.gb.shortEdge(), 40));
  QVERIFY(fuzzy_eq(f.gb.halfWidth(), 20));
  QVERIFY(f.mask.contains(QPointF(30, 20)));  // 新三角形内部
  QVERIFY(f.mask.contains(QPointF(30, 10)));  // north 顶点
  QVERIFY(f.mask.contains(QPointF(20, 25)));  // 内部
  QVERIFY(!f.mask.contains(QPointF(20, 15))); // 旧内部点进入新角域
  QVERIFY(!f.mask.contains(QPointF(15, 12))); // 左上角域
  QVERIFY(!f.mask.contains(QPointF(45, 12))); // 右上角域
}
};

QTEST_MAIN(TestHalfCrystalGadgetUnit)

#include "tst_halfcrystalgadget.moc"
