// Qool 核心 C++ 类型测试：QoolBoxGadget（Qool/shapecontrol/gadgets/）
//
// 被测面（spec qoolbox-shapecontrol-redesign）：
//   - used 派生（max 构造性保证：cut 溢出/负 cut 归零）
//   - vec 符号表 8 点（向量系，无锚定）
//   - point 锚定（origin + offset + vec + shrink；正常形态与现状一致）
//   - shrink 层：正确点坐标算法（oracle）——测试内置独立几何真值实现
//     （平移 8 边 → 24 对非平行线交点 → 过滤满足全部 8 半平面 → 命名点 =
//     身份候选有效取之 / 失效归入最近交集顶点），断言实现逐点坐标 == oracle
//     ——不复制实现公式（d* 用二分独立求解，避免同源错误）
//   - 临界区档位 d=0.99/0.999/1.0/1.5·d*、极限收敛（d* 处八点重合）、
//     负 border 外扩、退化链线段态
//   - contains 契约（粗判 + 四角排除 + 开集语义 + cut 溢出反例 + offset）
//   - referenceBox（5 介入点跟随 / 单层保证：链式与环被阻止 + 清 null）
//   - bindable 传播（target → control → gadget）
//
// 链构造：QQuickItem target → ShapeControl（set_target）→ QoolBoxGadget
// （appendChild 自动 set_control——宏生成 setter 在 protected 作用域，
// 测试子类用 using 声明提升为 public）。
//
// oracle 平移线公式 = 几何定义：顶 y=−uH/2+d、底 y=uH/2−d、
// 左 x=−uW/2+d、右 x=uW/2−d、左斜 x+y=−uW/2−uH/2+sTL+d√2、右斜
// x−y=uW/2+uH/2−sTR−d√2、右底斜 x+y=uW/2+uH/2−sBR−d√2、左底斜
// x−y=−uW/2−uH/2+sBL+d√2；半平面判定 s*(A·x+B·y−C) ≥ −1e-9（与实现同容差）。

#include <QtTest>
#include <QQuickItem>

#include "qool_test.hpp"

#include "shapecontrol/qool_shapecontrol.h"
#include "shapecontrol/gadgets/qool_shapegadget_qoolbox.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <random>

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

void comparePoints(const QPointF& actual, const QPointF& expected,
    const char* tag = nullptr) {
  comparePoint(actual, expected.x(), expected.y(), tag);
}

// 宏生成 setter/追加接口在 protected 作用域——测试经 using 提升
class TestShapeControl : public ShapeControl {
public:
  using ShapeControl::set_target;
  using ShapeControl::appendChild;
};

class TestQoolBoxGadget : public QoolBoxGadget {
public:
  using QoolBoxGadget::set_control;
};

// 完整链夹具：target（几何源头）→ control → gadget
class QoolBoxFixture {
public:
  QQuickItem target;
  TestShapeControl control;
  TestQoolBoxGadget gadget;

  QoolBoxFixture() {
    gadget.setParent(&control); // control 绑定依赖 parent 链
    control.set_target(&target);
    control.appendChild(&gadget); // appendChild 内 set_control(this)
  }

  void setSize(qreal w, qreal h) {
    target.setWidth(w);
    target.setHeight(h);
  }
  void setCuts(qreal tl, qreal tr, qreal bl, qreal br) {
    gadget.set_cutTL(tl);
    gadget.set_cutTR(tr);
    gadget.set_cutBL(bl);
    gadget.set_cutBR(br);
  }
};

// —— 正确点坐标算法（oracle）：独立几何真值实现，不复制实现公式 ——
struct Oracle {
  qreal uW, uH;
  qreal sTL, sTR, sBL, sBR;
  qreal d;

  Oracle(qreal w, qreal h, qreal cutTL, qreal cutTR, qreal cutBL,
      qreal cutBR, qreal border) {
    sTL = qMax(0.0, cutTL);
    sTR = qMax(0.0, cutTR);
    sBL = qMax(0.0, cutBL);
    sBR = qMax(0.0, cutBR);
    uW = qMax(w, qMax(sTL + sTR, sBL + sBR));
    uH = qMax(h, qMax(sTL + sBL, sTR + sBR));
    d = border;
  }

  struct Line {
    qreal a, b, c;
    int s;
  };

  // 8 条平移线（Ax+By=C；半平面符号 s：+1 内部在 ≥ C 侧）
  QList<Line> lines() const {
    static constexpr qreal K = 1.4142135623730951; // √2
    return {
        {0, 1, -uH / 2 + d, +1},                 // 0 顶
        {0, 1, uH / 2 - d, -1},                  // 1 底
        {1, 0, -uW / 2 + d, +1},                 // 2 左
        {1, 0, uW / 2 - d, -1},                  // 3 右
        {1, 1, -uW / 2 - uH / 2 + sTL + d * K, +1},  // 4 左斜
        {1, -1, uW / 2 + uH / 2 - sTR - d * K, -1},  // 5 右斜
        {1, 1, uW / 2 + uH / 2 - sBR - d * K, -1},   // 6 右底斜
        {1, -1, -uW / 2 - uH / 2 + sBL + d * K, +1}  // 7 左底斜
    };
  }

  static bool isParallel(int i, int j) {
    return (i == 0 && j == 1) || (i == 2 && j == 3) || (i == 4 && j == 6)
        || (i == 5 && j == 7);
  }

  static QPointF lineIntersect(const Line& l1, const Line& l2) {
    const qreal det = l1.a * l2.b - l2.a * l1.b;
    return {(l1.c * l2.b - l2.c * l1.b) / det,
        (l1.a * l2.c - l2.a * l1.c) / det};
  }

  QPointF intersect(int i, int j) const {
    const auto ls = lines();
    return lineIntersect(ls[i], ls[j]);
  }

  // 全部 8 半平面（≥ −1e-9，与实现同容差）
  bool satisfiesAll(const QPointF& p) const {
    constexpr qreal kEps = 1e-9;
    const auto ls = lines();
    for (const auto& l : ls) {
      if (l.s * (l.a * p.x() + l.b * p.y() - l.c) < -kEps) return false;
    }
    return true;
  }

  // 交集顶点集（24 对非平行线交点中满足全部半平面者）
  QList<QPointF> verts() const {
    QList<QPointF> v;
    for (int i = 0; i < 8; ++i) {
      for (int j = i + 1; j < 8; ++j) {
        if (isParallel(i, j)) continue;
        const QPointF p = intersect(i, j);
        if (satisfiesAll(p)) v.append(p);
      }
    }
    return v;
  }

  bool nonEmpty() const { return !verts().isEmpty(); }

  // d*：二分交集非空临界（独立于实现的 12 候选解析式）
  qreal dStar() const {
    qreal lo = 0.0;
    qreal hi = qMin(uW, uH) / 2 + 1;
    for (int k = 0; k < 80; ++k) {
      const qreal mid = (lo + hi) / 2;
      Oracle t = *this;
      t.d = mid;
      if (t.nonEmpty())
        lo = mid;
      else
        hi = mid;
    }
    return lo;
  }

  // 命名点 = 身份候选（相邻平移线对交点）有效取之 / 失效归入最近交集顶点
  QPointF namedPoint(int i, int j) const {
    const QPointF cand = intersect(i, j);
    if (satisfiesAll(cand)) return cand;
    const QList<QPointF> v = verts();
    if (v.isEmpty()) return cand; // 防御
    qreal best = std::numeric_limits<qreal>::max();
    QPointF r = v.first();
    for (const auto& p : v) {
      const QPointF dd = p - cand;
      const qreal d2 = QPointF::dotProduct(dd, dd);
      if (d2 < best) {
        best = d2;
        r = p;
      }
    }
    return r;
  }
};

// 断言 gadget 8 点 == oracle 期望（oracle 内点 + origin + offset 锚定）
void assertShrinkAgainstOracle(QoolBoxFixture& f, const Oracle& o,
    qreal ox = 0.0, qreal oy = 0.0) {
  const QPointF origin = f.gadget.origin();
  // oracle 平移距离 = min(border, d*_oracle)（实现 d_eff 同构）
  Oracle oo = o;
  oo.d = qMin(o.d, oo.dStar());
  struct Named {
    int i, j;
    QPointF (QoolBoxGadget::*get)() const;
  };
  const QList<Named> names = {
      {0, 4, &QoolBoxGadget::pointTL}, {0, 5, &QoolBoxGadget::pointTR},
      {3, 5, &QoolBoxGadget::pointRT}, {3, 6, &QoolBoxGadget::pointRB},
      {1, 6, &QoolBoxGadget::pointBR}, {1, 7, &QoolBoxGadget::pointBL},
      {2, 7, &QoolBoxGadget::pointLB}, {2, 4, &QoolBoxGadget::pointLT},
  };
  for (const auto& n : names) {
    const QPointF inner = oo.namedPoint(n.i, n.j); // 向量系内点
    const QPointF expected = origin + QPointF(ox, oy) + inner;
    const QPointF actual = (f.gadget.*(n.get))();
    QVERIFY2(fuzzy_eq(actual.x(), expected.x()) && fuzzy_eq(actual.y(), expected.y()),
        qPrintable(QString("oracle 断言失败：期望 %1,%2 实际 %3,%4")
                       .arg(expected.x())
                       .arg(expected.y())
                       .arg(actual.x())
                       .arg(actual.y())));
  }
}

// 集合归属断言（退化场景：d = d* 处交集退化——线段/点，归入对 d 的
// 1e-12 微差敏感，坐标断言退化为"命名点 ∈ oracle 交集顶点集"）
void assertShrinkInOracleVerts(QoolBoxFixture& f, const Oracle& o) {
  Oracle oo = o;
  oo.d = qMin(o.d, oo.dStar());
  const QList<QPointF> vs = oo.verts();
  QVERIFY2(!vs.isEmpty(), "oracle 交集顶点集为空");
  const QPointF origin = f.gadget.origin();
  const QList<QPointF> actual = {
      f.gadget.pointTL(), f.gadget.pointTR(), f.gadget.pointRT(),
      f.gadget.pointRB(), f.gadget.pointBR(), f.gadget.pointBL(),
      f.gadget.pointLB(), f.gadget.pointLT(),
  };
  for (const auto& p : actual) {
    const QPointF rel = p - origin;
    bool found = false;
    for (const auto& v : vs) {
      if (fuzzy_eq(rel.x(), v.x()) && fuzzy_eq(rel.y(), v.y())) {
        found = true;
        break;
      }
    }
    QVERIFY2(found,
        qPrintable(QString("集合归属失败：点 %1,%2 不在 oracle 交集顶点集")
                       .arg(rel.x())
                       .arg(rel.y())));
  }
}

} // namespace

class TestQoolBoxGadgetUnit : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(used_derives) {
    // 正常形态：used = 期望尺寸
    QoolBoxFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);
    QVERIFY(fuzzy_eq(f.gadget.usedWidth(), 100));
    QVERIFY(fuzzy_eq(f.gadget.usedHeight(), 80));

    // cut 溢出：used 钉在 cut 需求
    f.setSize(50, 50);
    f.setCuts(30, 30, 30, 30);
    QVERIFY(fuzzy_eq(f.gadget.usedWidth(), 60)); // max(50, 60)
    QVERIFY(fuzzy_eq(f.gadget.usedHeight(), 60));

    // 负 cut 归零（直角点）
    f.setSize(100, 80);
    f.setCuts(-10, 20, 30, -40);
    QVERIFY(fuzzy_eq(f.gadget.usedWidth(), 100)); // max(100, 20, 30)
    QVERIFY(fuzzy_eq(f.gadget.usedHeight(), 80)); // max(80, max(0, 50))

    // 零尺寸 + cut > 0：图形完整
    f.setSize(0, 0);
    f.setCuts(10, 10, 10, 10);
    QVERIFY(fuzzy_eq(f.gadget.usedWidth(), 20));
    QVERIFY(fuzzy_eq(f.gadget.usedHeight(), 20));
  }

  QOOL_TEST_CASE(vec_symbol_table) {
    // w=100 h=80 cuts 10/20/30/40：向量系（原点 0,0，无锚定）
    QoolBoxFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);

    comparePoint(f.gadget.vecTL(), -40, -40, "vecTL");
    comparePoint(f.gadget.vecTR(), 30, -40, "vecTR");
    comparePoint(f.gadget.vecRT(), 50, -20, "vecRT");
    comparePoint(f.gadget.vecRB(), 50, 0, "vecRB");
    comparePoint(f.gadget.vecBR(), 10, 40, "vecBR");
    comparePoint(f.gadget.vecBL(), -20, 40, "vecBL");
    comparePoint(f.gadget.vecLB(), -50, 10, "vecLB");
    comparePoint(f.gadget.vecLT(), -50, -30, "vecLT");

    // cut 溢出（s=30×4, used 60）：8 点仍满足 |x| ≤ uW/2 ∧ |y| ≤ uH/2
    f.setSize(50, 50);
    f.setCuts(30, 30, 30, 30);
    comparePoint(f.gadget.vecTL(), 0, -30, "vecTL 溢出");
    comparePoint(f.gadget.vecTR(), 0, -30, "vecTR 溢出");
    comparePoint(f.gadget.vecBR(), 0, 30, "vecBR 溢出");
    comparePoint(f.gadget.vecBL(), 0, 30, "vecBL 溢出");
    comparePoint(f.gadget.vecRT(), 30, 0, "vecRT 溢出");
    comparePoint(f.gadget.vecLT(), -30, 0, "vecLT 溢出");
  }

  QOOL_TEST_CASE(point_anchor_default) {
    // borderWidth=0：shrinkA 全零 → pointA = origin + vecA（无描边形态）
    QoolBoxFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);

    QVERIFY(fuzzy_eq(f.gadget.origin().x(), 50));
    QVERIFY(fuzzy_eq(f.gadget.origin().y(), 40));
    // 正常形态与现状坐标一致（期望中心锚定）
    comparePoint(f.gadget.pointTL(), 10, 0, "pointTL");
    comparePoint(f.gadget.pointTR(), 80, 0, "pointTR");
    comparePoint(f.gadget.pointRT(), 100, 20, "pointRT");
    comparePoint(f.gadget.pointRB(), 100, 40, "pointRB");
    comparePoint(f.gadget.pointBR(), 60, 80, "pointBR");
    comparePoint(f.gadget.pointBL(), 30, 80, "pointBL");
    comparePoint(f.gadget.pointLB(), 0, 50, "pointLB");
    comparePoint(f.gadget.pointLT(), 0, 10, "pointLT");

    // 分量与点一致
    QVERIFY(fuzzy_eq(f.gadget.pointTLx(), 10));
    QVERIFY(fuzzy_eq(f.gadget.pointTLy(), 0));
    QVERIFY(fuzzy_eq(f.gadget.pointBRx(), 60));
    QVERIFY(fuzzy_eq(f.gadget.pointBRy(), 80));

    // shrink 全零向量（border 0）
    QVERIFY(fuzzy_eq(f.gadget.shrinkTL().x(), 0));
    QVERIFY(fuzzy_eq(f.gadget.shrinkTL().y(), 0));
  }

  QOOL_TEST_CASE(edge_collapse_stable) {
    // 顶边消失（sTL+sTR == width）：两点重合，继续缩小不漂移
    QoolBoxFixture f;
    f.setSize(40, 100);
    f.setCuts(20, 20, 10, 10);
    // usedW = max(40, 40, 20) = 40；锚定 = 期望中心 (20, 50)
    comparePoint(f.gadget.pointTL(), 20, 0, "TL 重合");
    comparePoint(f.gadget.pointTR(), 20, 0, "TR 重合");
    comparePoint(f.gadget.pointLT(), 0, 20, "LT");
    comparePoint(f.gadget.pointRT(), 40, 20, "RT");

    // 继续缩小 width（30 < 40）：used 钉住（used 几何不漂移），
    // 组件坐标跟随期望中心（锚定语义）
    f.setSize(30, 100);
    QVERIFY(fuzzy_eq(f.gadget.usedWidth(), 40));
    comparePoint(f.gadget.vecTL(), 0, -50, "vecTL 不漂移");
    comparePoint(f.gadget.vecTR(), 0, -50, "vecTR 不漂移");
    comparePoint(f.gadget.pointTL(), 15, 0, "TL 跟随中心");

    // 不对称消失：重合点偏离中心 x = (sTL−sTR)/2（相对中心）
    QoolBoxFixture g;
    g.setSize(40, 100);
    g.setCuts(25, 15, 0, 0);
    QVERIFY(fuzzy_eq(g.gadget.usedWidth(), 40)); // max(40, 40)
    comparePoint(g.gadget.pointTL(), 25, 0, "TL 不对称");
    comparePoint(g.gadget.pointTR(), 25, 0, "TR 不对称");
  }

  QOOL_TEST_CASE(degenerate_shapes) {
    // 四 cut 全 0：矩形（四角双点重合）
    QoolBoxFixture f;
    f.setSize(100, 80);
    f.setCuts(0, 0, 0, 0);
    comparePoint(f.gadget.pointTL(), 0, 0, "TL");
    comparePoint(f.gadget.pointLT(), 0, 0, "LT");
    comparePoint(f.gadget.pointTR(), 100, 0, "TR");
    comparePoint(f.gadget.pointRT(), 100, 0, "RT");
    comparePoint(f.gadget.pointBR(), 100, 80, "BR");
    comparePoint(f.gadget.pointRB(), 100, 80, "RB");
    comparePoint(f.gadget.pointBL(), 0, 80, "BL");
    comparePoint(f.gadget.pointLB(), 0, 80, "LB");

    // 四边消失：菱形（s = 半尺寸）
    QoolBoxFixture g;
    g.setSize(100, 100);
    g.setCuts(50, 50, 50, 50);
    comparePoint(g.gadget.pointTL(), 50, 0, "菱形顶尖");
    comparePoint(g.gadget.pointTR(), 50, 0, "菱形顶尖2");
    comparePoint(g.gadget.pointRT(), 100, 50, "菱形右尖");
    comparePoint(g.gadget.pointRB(), 100, 50, "菱形右尖2");
    comparePoint(g.gadget.pointBR(), 50, 100, "菱形底尖");
    comparePoint(g.gadget.pointBL(), 50, 100, "菱形底尖2");
    comparePoint(g.gadget.pointLB(), 0, 50, "菱形左尖");
    comparePoint(g.gadget.pointLT(), 0, 50, "菱形左尖2");

    // 对角双巨大（sTL=sBR=80，w=h=100）：六边形（TR=RT、BL=LB 双点重合）
    QoolBoxFixture h;
    h.setSize(100, 100);
    h.setCuts(80, 0, 0, 80);
    comparePoint(h.gadget.pointTL(), 80, 0, "对角 TL");
    comparePoint(h.gadget.pointTR(), 100, 0, "对角 TR");
    comparePoint(h.gadget.pointRT(), 100, 0, "对角 RT（与 TR 重合）");
    comparePoint(h.gadget.pointRB(), 100, 20, "对角 RB");
    comparePoint(h.gadget.pointBR(), 20, 100, "对角 BR");
    comparePoint(h.gadget.pointBL(), 0, 100, "对角 BL");
    comparePoint(h.gadget.pointLB(), 0, 100, "对角 LB（与 BL 重合）");
    comparePoint(h.gadget.pointLT(), 0, 80, "对角 LT");

    // 单角巨大（sTL=100，w=h=100）：顶边/左边消失 → 直角三角形（3 点）
    QoolBoxFixture t;
    t.setSize(100, 100);
    t.setCuts(100, 0, 0, 0);
    comparePoint(t.gadget.pointTL(), 100, 0, "单角 TL");
    comparePoint(t.gadget.pointTR(), 100, 0, "单角 TR（重合）");
    comparePoint(t.gadget.pointRT(), 100, 0, "单角 RT（重合）");
    comparePoint(t.gadget.pointRB(), 100, 100, "单角 RB");
    comparePoint(t.gadget.pointBR(), 100, 100, "单角 BR（重合）");
    comparePoint(t.gadget.pointBL(), 0, 100, "单角 BL");
    comparePoint(t.gadget.pointLB(), 0, 100, "单角 LB（重合）");
    comparePoint(t.gadget.pointLT(), 0, 100, "单角 LT（重合）");
  }

  QOOL_TEST_CASE(shrink_oracle_normal) {
    // 正常内缩（d < d*：全部身份候选有效）——oracle 逐点坐标断言
    QoolBoxFixture f;
    f.setSize(100, 100);
    f.setCuts(30, 30, 30, 0);
    f.gadget.set_borderWidth(10);
    assertShrinkAgainstOracle(f, Oracle(100, 100, 30, 30, 30, 0, 10));

    // 不对称 cut + 非正方形
    QoolBoxFixture g;
    g.setSize(120, 90);
    g.setCuts(10, 25, 5, 40);
    g.gadget.set_borderWidth(15);
    assertShrinkAgainstOracle(g, Oracle(120, 90, 10, 25, 5, 40, 15));

    // 平行性契约抽查：内点两两构成边平行于外对应边（顶边 y 相等）
    QVERIFY(fuzzy_eq(f.gadget.pointTL().y(), f.gadget.pointTR().y()));
    QVERIFY(fuzzy_eq(f.gadget.pointBR().y(), f.gadget.pointBL().y()));
    QVERIFY(fuzzy_eq(f.gadget.pointRT().x(), f.gadget.pointRB().x()));
    QVERIFY(fuzzy_eq(f.gadget.pointLT().x(), f.gadget.pointLB().x()));
  }

  QOOL_TEST_CASE(shrink_rect_right_angle) {
    // 直角角（cut=0）：身份候选失效 → 归入角平分线精确内缩 d√2
    //（矩形四角；直角点沿角平分线到两直边垂直距离 = d）
    QoolBoxFixture f;
    f.setSize(100, 80);
    f.setCuts(0, 0, 0, 0);
    f.gadget.set_borderWidth(10);
    assertShrinkAgainstOracle(f, Oracle(100, 80, 0, 0, 0, 0, 10));
    // TL 内点 = (10,10)（相对向量系 (−40,−30) + (10,10)——角平分线内缩）
    comparePoint(f.gadget.pointTL(), 10, 10, "TL 直角归入");
    comparePoint(f.gadget.pointBR(), 90, 70, "BR 直角归入");
  }

  QOOL_TEST_CASE(shrink_degenerate_chain) {
    // 退化链线段态：w=20 h=100 cuts 10×4, d=10 → 内多边形退化为线段
    //（长度 = 2×(50−10√2) ≈ 71.716，design 4.5.3 V3）
    QoolBoxFixture f;
    f.setSize(20, 100);
    f.setCuts(10, 10, 10, 10);
    f.gadget.set_borderWidth(10);
    assertShrinkAgainstOracle(f, Oracle(20, 100, 10, 10, 10, 10, 10));

    // 线段态：8 内点收束为两个端点（顶/底各 4 点重合）
    const qreal len = 2 * (50 - 10 * 1.4142135623730951);
    QVERIFY2(fuzzy_eq(f.gadget.pointTL().x(), f.gadget.pointTR().x())
            && fuzzy_eq(f.gadget.pointTL().y(), f.gadget.pointTR().y()),
        "线段态顶端重合");
    QVERIFY(fuzzy_eq(f.gadget.pointTL().x(), 10)); // 左约束 x = −10+10 = 0 → 组件 10
    QVERIFY(fuzzy_eq(f.gadget.pointTL().y(), 50 - len / 2));
  }

  QOOL_TEST_CASE(shrink_negative_border) {
    // 负 border = 正常外扩（凸保持、点间距增大）
    QoolBoxFixture f;
    f.setSize(100, 100);
    f.setCuts(30, 30, 30, 0);
    f.gadget.set_borderWidth(-10);
    assertShrinkAgainstOracle(f, Oracle(100, 100, 30, 30, 30, 0, -10));
    // 外扩验证：内点应位于外点外侧（点间距增大）
    QVERIFY(f.gadget.pointTL().x() < f.gadget.vecTL().x() + f.gadget.origin().x());
    QVERIFY(f.gadget.pointBR().x() > f.gadget.vecBR().x() + f.gadget.origin().x());
  }

  QOOL_TEST_CASE(shrink_critical_bands) {
    // 临界区档位 d=0.99/0.999/1.0/1.5·d*——oracle 逐点断言（d>d* 锁定）
    QoolBoxFixture f;
    f.setSize(100, 100);
    f.setCuts(30, 30, 30, 0);
    const qreal dstar = f.gadget.dStar();
    QVERIFY(fuzzy_eq(dstar, 49.49747468305833, 1e-9)); // 70/√2
    // d < d*：交集非退化（面积 > 0），归入对 d 微差不敏感——坐标断言
    for (const qreal factor : {0.99, 0.999}) {
      f.gadget.set_borderWidth(factor * dstar);
      assertShrinkAgainstOracle(
          f, Oracle(100, 100, 30, 30, 30, 0, factor * dstar));
    }
    // d = 1.0·d*：交集退化（线段态——TR斜 vs BL斜 平行对瓶颈），
    // 归入对 d 的 1e-12 微差敏感（oracle 二分 vs 实现解析式）——集合归属断言
    f.gadget.set_borderWidth(dstar);
    assertShrinkInOracleVerts(f, Oracle(100, 100, 30, 30, 30, 0, dstar));
    // 锁定：d = 1.5·d* 输出 == d* 处输出（逐点）
    f.gadget.set_borderWidth(dstar);
    const QList<QPointF> atStar = {
        f.gadget.pointTL(), f.gadget.pointTR(), f.gadget.pointRT(),
        f.gadget.pointRB(), f.gadget.pointBR(), f.gadget.pointBL(),
        f.gadget.pointLB(), f.gadget.pointLT(),
    };
    f.gadget.set_borderWidth(1.5 * dstar);
    const QList<QPointF> atOver = {
        f.gadget.pointTL(), f.gadget.pointTR(), f.gadget.pointRT(),
        f.gadget.pointRB(), f.gadget.pointBR(), f.gadget.pointBL(),
        f.gadget.pointLB(), f.gadget.pointLT(),
    };
    for (int i = 0; i < 8; ++i) {
      QVERIFY2(fuzzy_eq(atStar[i].x(), atOver[i].x())
              && fuzzy_eq(atStar[i].y(), atOver[i].y()),
          "锁定失败：d > d* 输出应恒等于 d* 处");
    }
  }

  QOOL_TEST_CASE(shrink_converge_limit) {
    // 极限收敛：点瓶颈场景（三线组合 d*——cuts 90×4 → used 180、d* = 63.64）
    // 交集收缩为单点，8 命名点重合于临界点（八点重合）
    QoolBoxFixture g;
    g.setSize(100, 100);
    g.setCuts(90, 90, 90, 90);
    g.gadget.set_borderWidth(g.gadget.dStar());
    const QList<QPointF> pts = {
        g.gadget.pointTL(), g.gadget.pointTR(), g.gadget.pointRT(),
        g.gadget.pointRB(), g.gadget.pointBR(), g.gadget.pointBL(),
        g.gadget.pointLB(), g.gadget.pointLT(),
    };
    for (int i = 0; i < 8; ++i) {
      for (int j = i + 1; j < 8; ++j) {
        const QPointF d = pts[i] - pts[j];
        QVERIFY2(QPointF::dotProduct(d, d) < 1e-6,
            qPrintable(QString("极限收敛失败：点 %1/%2 未重合，距离 %3")
                           .arg(i)
                           .arg(j)
                           .arg(std::sqrt(QPointF::dotProduct(d, d)))));
      }
    }
    // 线段瓶颈场景（平行对 d*）：d* 处交集退化（线段，面积 0）——
    // 命名点全部 ∈ 交集顶点集（退化一致性，非坐标级）
    QoolBoxFixture f;
    f.setSize(100, 100);
    f.setCuts(30, 30, 30, 0);
    f.gadget.set_borderWidth(f.gadget.dStar());
    assertShrinkInOracleVerts(f, Oracle(100, 100, 30, 30, 30, 0, f.gadget.dStar()));
  }

  QOOL_TEST_CASE(dstar_parity) {
    // 解析式 d* vs 二分基准（随机 200 组，误差 < 1e-6）
    QoolBoxFixture f;
    f.setSize(1, 1);
    std::mt19937 rng(42);
    std::uniform_real_distribution<qreal> dim(1.0, 400.0);
    std::uniform_real_distribution<qreal> cut(0.0, 300.0);
    for (int k = 0; k < 200; ++k) {
      const qreal w = dim(rng), h = dim(rng);
      const qreal cTL = cut(rng), cTR = cut(rng);
      const qreal cBL = cut(rng), cBR = cut(rng);
      f.setSize(w, h);
      f.setCuts(cTL, cTR, cBL, cBR);
      const qreal impl = f.gadget.dStar();
      const qreal oracle = Oracle(w, h, cTL, cTR, cBL, cBR, 0).dStar();
      QVERIFY2(fuzzy_eq(impl, oracle, 1e-6),
          qPrintable(QString("d* 偏差：实现 %1 二分 %2 (w=%3 h=%4 cuts %5/%6/%7/%8)")
                         .arg(impl)
                         .arg(oracle)
                         .arg(w)
                         .arg(h)
                         .arg(cTL)
                         .arg(cTR)
                         .arg(cBL)
                         .arg(cBR)));
    }
  }

  QOOL_TEST_CASE(contains_matrix) {
    // w=100 h=80 cuts 10/20/30/40：命中契约全点矩阵
    QoolBoxFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);

    QVERIFY(f.gadget.contains(QPointF(50, 40)));  // 中心
    QVERIFY(f.gadget.contains(QPointF(50, 20)));  // 内部
    QVERIFY(f.gadget.contains(QPointF(20, 20)));  // 内部
    QVERIFY(f.gadget.contains(QPointF(10, 0)));   // 顶点 TL
    QVERIFY(f.gadget.contains(QPointF(80, 0)));   // 顶点 TR
    QVERIFY(f.gadget.contains(QPointF(100, 40))); // 右直边中点（RT/RB 之间）
    QVERIFY(f.gadget.contains(QPointF(30, 80)));  // 顶点 BL
    QVERIFY(f.gadget.contains(QPointF(60, 80)));  // 顶点 BR
    QVERIFY(f.gadget.contains(QPointF(0, 50)));   // 左直边中点
    // 斜边开集命中（dx+dy == s）
    QVERIFY(f.gadget.contains(QPointF(5, 5)));    // TL 斜边（p' 系 dx+dy=10）
    QVERIFY(f.gadget.contains(QPointF(90, 10)));  // TR 斜边
    QVERIFY(f.gadget.contains(QPointF(80, 60)));  // BR 斜边
    QVERIFY(f.gadget.contains(QPointF(25, 65)));  // BL 斜边

    // 切角域不命中（dx+dy < s）
    QVERIFY(!f.gadget.contains(QPointF(0, 0)));   // TL 角点
    QVERIFY(!f.gadget.contains(QPointF(2, 2)));   // TL 角域
    QVERIFY(!f.gadget.contains(QPointF(100, 0))); // TR 角点
    QVERIFY(!f.gadget.contains(QPointF(90, 2)));  // TR 角域
    QVERIFY(!f.gadget.contains(QPointF(100, 80))); // BR 角点
    QVERIFY(!f.gadget.contains(QPointF(85, 75))); // BR 角域
    QVERIFY(!f.gadget.contains(QPointF(0, 80)));  // BL 角点
    QVERIFY(!f.gadget.contains(QPointF(5, 70)));  // BL 角域

    // used 矩形外不命中
    QVERIFY(!f.gadget.contains(QPointF(150, 40)));
    QVERIFY(!f.gadget.contains(QPointF(-50, 40)));
    QVERIFY(!f.gadget.contains(QPointF(50, -5)));
    QVERIFY(!f.gadget.contains(QPointF(50, 90)));
  }

  QOOL_TEST_CASE(contains_cut_overflow) {
    // cut 溢出反例（design 4.4）：sTL=80、uW=100——点 p'=(0,−30) 在 TL
    // 切角三角形内（角域 dx/dy 相对 used 角点），象限门会漏排除
    QoolBoxFixture f;
    f.setSize(100, 100);
    f.setCuts(80, 0, 0, 0);
    // used = 100×100；p' = (0,−30) → 组件点 (50, 20)
    QVERIFY(fuzzy_eq(f.gadget.usedWidth(), 100));
    QVERIFY(fuzzy_eq(f.gadget.usedHeight(), 100));
    QVERIFY2(!f.gadget.contains(QPointF(50, 20)),
        "p'=(0,−30) 应在 TL 切角内（象限门反例）");
    // 角域内（dx+dy < 80）：p'=(0,−25) → 组件 (50,25)：dx=50 dy=25 → 75 < 80
    QVERIFY(!f.gadget.contains(QPointF(50, 25)));
    // 斜边开集命中（dx+dy == 80）：p'=(10,−30) → 组件 (60,20)：dx=60 dy=20
    QVERIFY(f.gadget.contains(QPointF(60, 20)));
    // 溢出区域（used 矩形内、期望矩形外）命中：p' = (0, 0) → 组件 (50,50)
    QVERIFY(f.gadget.contains(QPointF(50, 50)));
  }

  QOOL_TEST_CASE(contains_offset) {
    // offset 平移：判定区跟随
    QoolBoxFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);
    f.gadget.set_offsetX(10);
    f.gadget.set_offsetY(-5);

    QVERIFY(f.gadget.contains(QPointF(60, 35)));  // 旧中心 (50,40) 平移后
    QVERIFY(f.gadget.contains(QPointF(20, -5)));  // 平移后 TL 顶点
    QVERIFY(f.gadget.contains(QPointF(50, 40)));  // 平移后仍在形状内
    QVERIFY(!f.gadget.contains(QPointF(10, 0)));  // 旧 TL 顶点（现处切角域）
    // 与 oracle 锚定一致：pointA = origin + offset + vecA
    comparePoint(f.gadget.pointTL(), 20, -5, "pointTL + offset");
  }

  QOOL_TEST_CASE(reference_box_follow) {
    // A 为几何源，B.referenceBox = A → B 的介入量完全跟随 A；
    // B 的 borderWidth 独立（唯一自由输入）
    QoolBoxFixture fa, fb;
    fa.setSize(100, 80);
    fa.setCuts(10, 20, 30, 40);
    fa.gadget.set_borderWidth(8);
    fb.setSize(100, 80);
    fb.gadget.set_referenceBox(&fa.gadget);

    // 介入量跟随 A（B 自有 cut/offset 不生效）
    fb.gadget.set_cutTL(99); // 应被 ref 覆盖
    fb.gadget.set_offsetX(77);
    QVERIFY(fuzzy_eq(fb.gadget.usedWidth(), fa.gadget.usedWidth()));
    comparePoints(fb.gadget.vecTL(), fa.gadget.vecTL(), "ref vecTL");
    comparePoints(fb.gadget.vecBR(), fa.gadget.vecBR(), "ref vecBR");
    comparePoints(fb.gadget.origin(), fa.gadget.origin(), "ref origin");
    comparePoints(fb.gadget.vecLT(), fa.gadget.vecLT(), "ref vecLT");
    comparePoints(fb.gadget.vecRT(), fa.gadget.vecRT(), "ref vecRT");

    // B 的 borderWidth 独立：B border 0（默认）→ B 点 = origin + vec（外轮廓）
    comparePoint(fb.gadget.pointTL(),
        fa.gadget.vecTL().x() + fa.gadget.origin().x(),
        fa.gadget.vecTL().y() + fa.gadget.origin().y(), "B 外轮廓 TL");

    // B 设与 A 相同 border → 8 点全等
    fb.gadget.set_borderWidth(8);
    comparePoints(fb.gadget.pointTL(), fa.gadget.pointTL(), "同 border TL");
    comparePoints(fb.gadget.pointBR(), fa.gadget.pointBR(), "同 border BR");
    comparePoints(fb.gadget.pointLT(), fa.gadget.pointLT(), "同 border LT");
    comparePoints(fb.gadget.pointRT(), fa.gadget.pointRT(), "同 border RT");

    // A 变化 → B 跟随（cut/尺寸）
    fa.setSize(120, 60);
    fa.setCuts(15, 5, 25, 35);
    comparePoints(fb.gadget.pointTL(), fa.gadget.pointTL(), "ref 跟随 TL");
    comparePoints(fb.gadget.pointBR(), fa.gadget.pointBR(), "ref 跟随 BR");

    // B 的 border 变化独立（不影响 A）
    fb.gadget.set_borderWidth(10);
    QVERIFY(fuzzy_eq(fb.gadget.shrinkD(), 10));
    QVERIFY(fuzzy_eq(fa.gadget.shrinkD(), 8));

    // A 的 offset 变化 → B 8 点整体跟随（介入点 offset；B border 调回与
    // A 一致——border 独立影响 shrink，先对齐再断言全等）
    fa.gadget.set_offsetX(5);
    fa.gadget.set_offsetY(-3);
    fb.gadget.set_borderWidth(8);
    comparePoints(fb.gadget.pointTL(), fa.gadget.pointTL(), "ref offset 跟随 TL");
    comparePoints(fb.gadget.pointBR(), fa.gadget.pointBR(), "ref offset 跟随 BR");

    // ref 模式 contains 与 A 完全等价（切角域排除/粗判/顶点命中）
    for (const QPointF& pt : {QPointF(5, -3), QPointF(0, 0), QPointF(120, 60),
             QPointF(60, 30), fa.gadget.pointTL(), fa.gadget.pointBR()}) {
      QVERIFY2(fb.gadget.contains(pt) == fa.gadget.contains(pt),
          qPrintable(QString("ref contains 不等价：点 %1,%2")
                         .arg(pt.x())
                         .arg(pt.y())));
    }
  }

  QOOL_TEST_CASE(reference_box_chain_blocked) {
    // 单层保证：目标已有 reference → 赋值无效 + 本 gadget 清旧值
    QoolBoxFixture fa, fb, fc;
    fa.setSize(100, 80);
    fa.setCuts(10, 10, 10, 10);
    fb.setSize(100, 80);
    fc.setSize(100, 80);

    // C → A 成功（A 是根）
    fc.gadget.set_referenceBox(&fa.gadget);
    QVERIFY(fc.gadget.referenceBox() == &fa.gadget);

    // 环：A → C 无效（C 已有 reference A）→ A 清空
    fa.gadget.set_referenceBox(&fc.gadget);
    QVERIFY(fa.gadget.referenceBox() == nullptr);

    // 链：B → A 成功后，C → B 无效（B 已有 A）→ C 清空旧值
    fb.gadget.set_referenceBox(&fa.gadget);
    QVERIFY(fb.gadget.referenceBox() == &fa.gadget);
    fc.gadget.set_referenceBox(&fb.gadget);
    QVERIFY(fc.gadget.referenceBox() == nullptr);

    // 既有引用不受影响（B 仍引用 A；A 现为根可被引用）
    QVERIFY(fb.gadget.referenceBox() == &fa.gadget);
    QVERIFY(fa.gadget.referenceBox() == nullptr);

    // 自引用（A→A，1-环）同样被阻止（审查 F1 回归）
    fa.gadget.set_referenceBox(&fa.gadget);
    QVERIFY(fa.gadget.referenceBox() == nullptr);
  }

  QOOL_TEST_CASE(bindable_follows) {
    // bindable 传播：target 尺寸/位置变化 → used/8 点跟随
    QoolBoxFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);
    f.gadget.set_borderWidth(5);

    f.target.setWidth(200);
    f.target.setHeight(120);
    QVERIFY(fuzzy_eq(f.gadget.usedWidth(), 200));
    QVERIFY(fuzzy_eq(f.gadget.origin().x(), 100));
    QVERIFY(fuzzy_eq(f.gadget.origin().y(), 60));
    // 8 点随尺寸变化（border=5 内缩）——oracle 对照
    assertShrinkAgainstOracle(f, Oracle(200, 120, 10, 20, 30, 40, 5));
  }
};

QTEST_MAIN(TestQoolBoxGadgetUnit)

#include "tst_qoolboxgadget.moc"
