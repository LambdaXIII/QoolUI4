// Qool 核心 C++ 类型测试：QoolBoxShapeControl（Qool/shapecontrol/）
//
// 被测面：
//   - settings 绑定链路（信号连接同步）：字段变化 → ext*/int* 点更新
//     （数值断言 = 直接套 gadget 公开公式 origin + vec，不复制内部实现）
//   - settings 实例整体替换 → 绑定链路重挂（新实例字段驱动点；旧实例
//     字段不再影响；settingsChanged 信号）
//   - ext*/int* 16 点 + x/y 分量 + usedWidth/usedHeight 转发值对照：
//     直接构造 QoolBoxGadget 同参数（gadget 算法是已测 oracle）
//   - *Space 公式：max(0, max(相邻 cut) − (used − 期望)/2)——top/bottom
//     垂直轴、left/right 水平轴；cut 硬参数溢出换算、钳 0 边界
//   - contains（委托 outer gadget）：形状内命中、切角不命中、开集边界、
//     offset 平移后判定区跟随
//   - referenceBox 内环链：inner 指 outer——border 0 时 int == ext、
//     border 变化只动内环、内环几何源（cut/offset）跟随外环
//   - settings null 退化：按 0 输入计算（矩形/无偏移/无描边），不崩溃
//   - 析构安全：settings 先析构（局部作用域）不崩溃；control 先析构
//     （settings 存活/为子对象）不崩溃
//
// 链构造：QQuickItem target → QoolBoxShapeControl（set_target）→ 内部
// 双 QoolBoxGadget（构造时自装：outer borderWidth 0 + inner 指 outer，
// 无需 appendChild）。settings 经公开 set_settings 注入（Base* 多态）。

#include <QtTest>
#include <QQuickItem>
#include <QPointF>
#include <QSignalSpy>

#include "qool_test.hpp"

#include "shapecontrol/qool_qoolbox_shapecontrol.h"
#include "shapecontrol/qool_qoolbox_settings.h"
#include "shapecontrol/gadgets/qool_shapegadget_qoolbox.h"

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

void comparePoints(const QPointF& actual, const QPointF& expected,
    const char* tag = nullptr) {
  comparePoint(actual, expected.x(), expected.y(), tag);
}

// —— 被测类提升（宏生成 setter 的作用域以宏内 public: 为准，using 声明
// 冗余但无害——对齐 tst_qoolboxgadget.cpp 先例）——
class TestControl : public QoolBoxShapeControl {
public:
  using QoolBoxShapeControl::set_target;
};

// —— 独立 gadget 对照夹具（镜像 control 内部构造：outer 无 border +
// inner referenceBox 指 outer；直接构造同参数 = 独立 oracle）——
class TestShapeControl : public ShapeControl {
public:
  using ShapeControl::set_target;
  using ShapeControl::appendChild;
};

class TestQoolBoxGadget : public QoolBoxGadget {
public:
  using QoolBoxGadget::set_control;
};

class StandalonePair {
public:
  QQuickItem target;
  TestShapeControl control;
  TestQoolBoxGadget outer;
  TestQoolBoxGadget inner;

  StandalonePair() {
    outer.setParent(&control); // control 绑定依赖 parent 链
    inner.setParent(&control);
    control.set_target(&target);
    control.appendChild(&outer);
    control.appendChild(&inner);
    inner.set_referenceBox(&outer); // 镜像 control 的双实例描边链
  }

  void setSize(qreal w, qreal h) {
    target.setWidth(w);
    target.setHeight(h);
    // target 尺寸经 queued timer 同步到 control（ShapeControl 信号同步
    // 机制——延迟写避免布局/绑定求值栈内重入成环）——flush 后断言
    QCoreApplication::processEvents();
  }
  void setCuts(qreal tl, qreal tr, qreal bl, qreal br) {
    outer.set_cutTL(tl);
    outer.set_cutTR(tr);
    outer.set_cutBL(bl);
    outer.set_cutBR(br);
  }
  void setOffset(qreal ox, qreal oy) {
    outer.set_offsetX(ox);
    outer.set_offsetY(oy);
  }
};

// —— 主夹具：target → control（settings 注入）——
class QoolBoxControlFixture {
public:
  QQuickItem target;
  TestControl control;
  QoolBoxSettings settings;

  QoolBoxControlFixture() {
    control.set_target(&target);
    control.set_settings(&settings);
  }

  void setSize(qreal w, qreal h) {
    target.setWidth(w);
    target.setHeight(h);
    QCoreApplication::processEvents(); // 同上（延迟同步 flush）
  }
  void setCuts(qreal tl, qreal tr, qreal bl, qreal br) {
    settings.set_cutSizeTL(tl);
    settings.set_cutSizeTR(tr);
    settings.set_cutSizeBL(bl);
    settings.set_cutSizeBR(br);
  }
};

// 转发值对照：ext* ↔ 独立 outer、int* ↔ 独立 inner（ref 链镜像）、
// usedWidth/usedHeight ↔ outer、分量 ↔ 点。两侧同实现同输入——逐位
// 一致，默认 1e-6 容差足够（float 存储误差也远小于此）。
void assertControlMatchesGadgets(const QoolBoxShapeControl& c,
    const StandalonePair& sg) {
  comparePoints(c.extTL(), sg.outer.pointTL(), "extTL");
  comparePoints(c.extTR(), sg.outer.pointTR(), "extTR");
  comparePoints(c.extLT(), sg.outer.pointLT(), "extLT");
  comparePoints(c.extLB(), sg.outer.pointLB(), "extLB");
  comparePoints(c.extRT(), sg.outer.pointRT(), "extRT");
  comparePoints(c.extRB(), sg.outer.pointRB(), "extRB");
  comparePoints(c.extBL(), sg.outer.pointBL(), "extBL");
  comparePoints(c.extBR(), sg.outer.pointBR(), "extBR");
  comparePoints(c.intTL(), sg.inner.pointTL(), "intTL");
  comparePoints(c.intTR(), sg.inner.pointTR(), "intTR");
  comparePoints(c.intLT(), sg.inner.pointLT(), "intLT");
  comparePoints(c.intLB(), sg.inner.pointLB(), "intLB");
  comparePoints(c.intRT(), sg.inner.pointRT(), "intRT");
  comparePoints(c.intRB(), sg.inner.pointRB(), "intRB");
  comparePoints(c.intBL(), sg.inner.pointBL(), "intBL");
  comparePoints(c.intBR(), sg.inner.pointBR(), "intBR");
  QVERIFY2(fuzzy_eq(c.usedWidth(), sg.outer.usedWidth()), "usedWidth");
  QVERIFY2(fuzzy_eq(c.usedHeight(), sg.outer.usedHeight()), "usedHeight");
  QVERIFY2(fuzzy_eq(c.extTLx(), c.extTL().x()), "extTLx");
  QVERIFY2(fuzzy_eq(c.extTLy(), c.extTL().y()), "extTLy");
  QVERIFY2(fuzzy_eq(c.intBRx(), c.intBR().x()), "intBRx");
  QVERIFY2(fuzzy_eq(c.intBRy(), c.intBR().y()), "intBRy");
}

} // namespace

class TestQoolBoxShapeControlUnit : public QObject {
  Q_OBJECT

  QOOL_TEST_CASE(settings_fields_drive_points) {
    // settings 字段变化 → ext*/int* 点更新。数值断言 = 套 gadget 公开
    // 公式 origin + vec（cut 硬参数；同参数值与 tst_qoolboxgadget
    // point_anchor_default 一致）
    QoolBoxControlFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);

    // 初始形态：used = 期望（无溢出），8 外点全断言
    comparePoint(f.control.extTL(), 10, 0, "extTL");
    comparePoint(f.control.extTR(), 80, 0, "extTR");
    comparePoint(f.control.extLT(), 0, 10, "extLT");
    comparePoint(f.control.extLB(), 0, 50, "extLB");
    comparePoint(f.control.extRT(), 100, 20, "extRT");
    comparePoint(f.control.extRB(), 100, 40, "extRB");
    comparePoint(f.control.extBL(), 30, 80, "extBL");
    comparePoint(f.control.extBR(), 60, 80, "extBR");
    QVERIFY(fuzzy_eq(f.control.usedWidth(), 100));
    QVERIFY(fuzzy_eq(f.control.usedHeight(), 80));
    // x/y 分量与点一致（int 侧一并抽查）
    QVERIFY(fuzzy_eq(f.control.extTLx(), 10));
    QVERIFY(fuzzy_eq(f.control.extTLy(), 0));
    QVERIFY(fuzzy_eq(f.control.intBRx(), f.control.intBR().x()));
    QVERIFY(fuzzy_eq(f.control.intBRy(), f.control.intBR().y()));

    // cutSizeTL 变化 → extTL 更新、其它点不受影响
    f.settings.set_cutSizeTL(30);
    comparePoint(f.control.extTL(), 30, 0, "extTL after cutSizeTL");
    comparePoint(f.control.extTR(), 80, 0, "extTR 不受 TL 影响");

    // cutSizeBR 变化 → extBR 更新（垂直对 TR+BR = 20+20 ≤ 80 无溢出）
    f.settings.set_cutSizeBR(20);
    comparePoint(f.control.extBR(), 80, 80, "extBR after cutSizeBR");

    // offset 字段 → 整体平移
    f.settings.set_offsetX(7);
    f.settings.set_offsetY(-3);
    comparePoint(f.control.extTL(), 37, -3, "extTL + offset");
    comparePoint(f.control.extBR(), 87, 77, "extBR + offset");
    QVERIFY(fuzzy_eq(f.control.usedWidth(), 100));
    QVERIFY(fuzzy_eq(f.control.usedHeight(), 80));

    // target 尺寸变化 → 转发面跟随（bindable 传播：target → control → gadget）
    f.setSize(200, 80);
    QVERIFY(fuzzy_eq(f.control.usedWidth(), 200));
    comparePoint(f.control.extBR(), 187, 77, "extBR after resize");
  }

  QOOL_TEST_CASE(settings_replace_relinks) {
    // settings 实例整体替换 → 绑定链路重挂：新实例字段驱动点、
    // 旧实例字段不再影响；settingsChanged 信号
    QQuickItem target;
    TestControl control;
    control.set_target(&target);
    target.setWidth(100);
    target.setHeight(80);
    QCoreApplication::processEvents(); // 延迟同步 flush

    QoolBoxSettings a;
    a.set_cutSizeTL(10);
    a.set_cutSizeTR(20);
    a.set_cutSizeBL(30);
    a.set_cutSizeBR(40);
    control.set_settings(&a);
    comparePoint(control.extTL(), 10, 0, "A 驱动");

    QSignalSpy spy(&control, &QoolBoxShapeControl::settingsChanged);
    QVERIFY(spy.isValid());

    // 新实例用独立 QoolBoxSettings（单一类型——属性类型即本类）
    QoolBoxSettings b;
    b.set_cutSizeTL(60);
    b.set_cutSizeTR(50);
    b.set_cutSizeBL(40);
    b.set_cutSizeBR(30);
    b.set_offsetX(3);
    b.set_offsetY(-2);
    b.set_borderWidth(8);
    control.set_settings(&b);
    QCOMPARE(spy.count(), 1);

    // 新实例字段驱动点：used = max(100, max(110, 70)) → 110×100；
    // extTL = origin(50,40) + offset(3,−2) + vec(−55+60, −50) = (58,−12)
    QVERIFY(fuzzy_eq(control.usedWidth(), 110));
    QVERIFY(fuzzy_eq(control.usedHeight(), 100));
    comparePoint(control.extTL(), 58, -12, "extTL after replace");
    // 内环跟随新实例 borderWidth（顶边内点下移）
    QVERIFY(control.intTL().y() > control.extTL().y());

    // 旧实例字段不再影响
    a.set_cutSizeTL(90);
    comparePoint(control.extTL(), 58, -12, "旧实例不驱动");
    QVERIFY(fuzzy_eq(control.usedWidth(), 110));

    // 新实例继续驱动（cutSizeTL 10 → used 回落 100×80，
    // extTL = (50,40)+(3,−2)+(−50+10,−40) = (13,−2)）
    b.set_cutSizeTL(10);
    comparePoint(control.extTL(), 13, -2, "新实例驱动");
    QVERIFY(fuzzy_eq(control.usedWidth(), 100));
    QVERIFY(fuzzy_eq(control.usedHeight(), 80));
  }

  QOOL_TEST_CASE(forward_matches_gadgets) {
    // ext*/int* 转发值对照 gadget（直接构造同参数——gadget 算法是已测
    // oracle；含 borderWidth 内缩：int 点随 border 变化、ext 不变）
    QoolBoxControlFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);
    f.settings.set_offsetX(5);
    f.settings.set_offsetY(-3);

    StandalonePair sg;
    sg.setSize(100, 80);
    sg.setCuts(10, 20, 30, 40);
    sg.setOffset(5, -3);
    sg.inner.set_borderWidth(0); // 与 settings.borderWidth 默认 0 一致
    assertControlMatchesGadgets(f.control, sg);

    // borderWidth 变化 → 内环内缩（int 变）、外环不动（ext 不变）
    const QPointF extTLBefore = f.control.extTL();
    const QPointF extBRBefore = f.control.extBR();
    f.settings.set_borderWidth(8);
    sg.inner.set_borderWidth(8);
    assertControlMatchesGadgets(f.control, sg);
    comparePoints(f.control.extTL(), extTLBefore, "border 不动 extTL");
    comparePoints(f.control.extBR(), extBRBefore, "border 不动 extBR");
    QVERIFY(f.control.intTL() != f.control.extTL());

    // cut 字段变化 → 16 点整体跟随（对照 gadget 重算）；used 跟随溢出：
    // cuts (10,20,80,40) → usedW = max(100, 80+40) = 120、
    // usedH = max(80, 10+80) = 90
    f.settings.set_cutSizeBL(80);
    sg.setCuts(10, 20, 80, 40);
    assertControlMatchesGadgets(f.control, sg);
    QVERIFY(fuzzy_eq(f.control.usedWidth(), 120));
    QVERIFY(fuzzy_eq(f.control.usedHeight(), 90));
  }

  QOOL_TEST_CASE(space_formula) {
    // *Space = max(0, max(相邻 cut) − (used − 期望)/2)：top/bottom 取
    // 垂直轴、left/right 取水平轴；cut 硬参数溢出时换算回期望系；钳 0
    QoolBoxControlFixture f;
    f.setSize(100, 80);

    // 尺寸充足（used == 期望）：space = max 相邻 cut
    f.setCuts(10, 10, 10, 10);
    QVERIFY(fuzzy_eq(f.control.topSpace(), 10));
    QVERIFY(fuzzy_eq(f.control.bottomSpace(), 10));
    QVERIFY(fuzzy_eq(f.control.leftSpace(), 10));
    QVERIFY(fuzzy_eq(f.control.rightSpace(), 10));

    // 不对称 cut：space = 该侧两角较大者
    f.setCuts(10, 20, 30, 40);
    QVERIFY(fuzzy_eq(f.control.topSpace(), 20)); // max(TL, TR)
    QVERIFY(fuzzy_eq(f.control.bottomSpace(), 40)); // max(BL, BR)
    QVERIFY(fuzzy_eq(f.control.leftSpace(), 30)); // max(TL, BL)
    QVERIFY(fuzzy_eq(f.control.rightSpace(), 40)); // max(TR, BR)

    // 溢出转换：cut 30×4、期望 50×50 → used 60×60 → space = 30 − 5 = 25
    f.setSize(50, 50);
    f.setCuts(30, 30, 30, 30);
    QVERIFY(fuzzy_eq(f.control.topSpace(), 25));
    QVERIFY(fuzzy_eq(f.control.bottomSpace(), 25));
    QVERIFY(fuzzy_eq(f.control.leftSpace(), 25));
    QVERIFY(fuzzy_eq(f.control.rightSpace(), 25));

    // 钳 0 边界：cuts (40,40,2,2)、期望 20×20 → used 80×42；
    // 垂直溢出 (42−20)/2 = 11 → bottom = max(0, 2−11) = 0
    f.setSize(20, 20);
    f.setCuts(40, 40, 2, 2);
    QVERIFY(fuzzy_eq(f.control.topSpace(), 29)); // 40 − 11
    QVERIFY(fuzzy_eq(f.control.bottomSpace(), 0)); // 钳 0
    QVERIFY(fuzzy_eq(f.control.leftSpace(), 10)); // 40 − (80−20)/2
    QVERIFY(fuzzy_eq(f.control.rightSpace(), 10));

    // 负 cut：qMax 语义下限归 0
    f.setSize(100, 80);
    f.setCuts(-5, -5, -5, -5);
    QVERIFY(fuzzy_eq(f.control.topSpace(), 0));
    QVERIFY(fuzzy_eq(f.control.leftSpace(), 0));
  }

  QOOL_TEST_CASE(contains_contract) {
    // contains 委托 outer gadget：形状内命中、切角不命中、斜边/顶点开集
    // 命中、offset 平移后判定区跟随
    QoolBoxControlFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);

    QVERIFY(f.control.contains(QPointF(50, 40))); // 中心
    QVERIFY(f.control.contains(QPointF(20, 20))); // 内部
    QVERIFY(f.control.contains(QPointF(10, 0))); // TL 顶点
    QVERIFY(f.control.contains(QPointF(80, 0))); // TR 顶点
    QVERIFY(f.control.contains(QPointF(100, 40))); // 右直边中点
    QVERIFY(f.control.contains(QPointF(5, 5))); // TL 斜边（开集）
    QVERIFY(f.control.contains(QPointF(90, 10))); // TR 斜边

    QVERIFY(!f.control.contains(QPointF(0, 0))); // TL 切角角点
    QVERIFY(!f.control.contains(QPointF(2, 2))); // TL 切角域
    QVERIFY(!f.control.contains(QPointF(100, 0))); // TR 切角角点
    QVERIFY(!f.control.contains(QPointF(90, 2))); // TR 切角域
    QVERIFY(!f.control.contains(QPointF(100, 80))); // BR 切角角点
    QVERIFY(!f.control.contains(QPointF(85, 75))); // BR 切角域
    QVERIFY(!f.control.contains(QPointF(0, 80))); // BL 切角角点
    QVERIFY(!f.control.contains(QPointF(5, 70))); // BL 切角域
    QVERIFY(!f.control.contains(QPointF(150, 40))); // used 矩形外
    QVERIFY(!f.control.contains(QPointF(50, -5)));

    // offset 平移后判定区跟随
    f.settings.set_offsetX(10);
    f.settings.set_offsetY(-5);
    QVERIFY(f.control.contains(QPointF(60, 35))); // 平移后中心
    QVERIFY(f.control.contains(QPointF(20, -5))); // 平移后 TL 顶点
    QVERIFY(!f.control.contains(QPointF(10, 0))); // 旧 TL 顶点 → 现切角域
  }

  QOOL_TEST_CASE(reference_chain_inner) {
    // referenceBox 内环链：inner 指 outer——border 0 时 int == ext、
    // border 变化只动内环、内环几何源（cut/offset）跟随外环
    QoolBoxControlFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);

    // border 0：内环与外形重合（shrink 零向量）
    comparePoints(f.control.intTL(), f.control.extTL(), "intTL == extTL");
    comparePoints(f.control.intBR(), f.control.extBR(), "intBR == extBR");
    comparePoints(f.control.intLT(), f.control.extLT(), "intLT == extLT");

    // border 变化只动 int：ext 全等、int 沿边法线内缩（顶边下移/底边上移）
    const QPointF extTLBefore = f.control.extTL();
    const QPointF extBRBefore = f.control.extBR();
    f.settings.set_borderWidth(10);
    comparePoints(f.control.extTL(), extTLBefore, "border 后 extTL 不变");
    comparePoints(f.control.extBR(), extBRBefore, "border 后 extBR 不变");
    QVERIFY(f.control.intTL().x() > f.control.extTL().x());
    QVERIFY(f.control.intTL().y() > f.control.extTL().y());
    QVERIFY(f.control.intBR().x() < f.control.extBR().x());
    QVERIFY(f.control.intBR().y() < f.control.extBR().y());

    // 内环几何源跟随外环（settings cut 变化 → ext/int 同步更新），
    // 对照独立镜像 ref 链 gadget
    StandalonePair sg;
    sg.setSize(100, 80);
    sg.setCuts(30, 20, 30, 40);
    sg.inner.set_borderWidth(10);
    f.settings.set_cutSizeTL(30);
    comparePoints(f.control.extTL(), sg.outer.pointTL(), "extTL 跟随 cut");
    comparePoints(f.control.intTL(), sg.inner.pointTL(), "intTL 跟随 cut");

    // 直角形态数值锚定：cut 0、border 10 → 内环角点沿角平分线内缩
    //（TL = (10,10)、BR = (90,70)——与 tst_qoolboxgadget 同参数值一致）
    QoolBoxControlFixture g;
    g.setSize(100, 80);
    g.setCuts(0, 0, 0, 0);
    g.settings.set_borderWidth(10);
    comparePoint(g.control.intTL(), 10, 10, "rect intTL");
    comparePoint(g.control.intBR(), 90, 70, "rect intBR");
    comparePoint(g.control.extTL(), 0, 0, "rect extTL");
  }

  QOOL_TEST_CASE(settings_null_degradation) {
    // settings null：按 0 输入退化（cut/offset/border 全 0）——不崩溃、
    // 退化为矩形原点形态
    QoolBoxControlFixture f;
    f.setSize(100, 80);
    f.setCuts(10, 20, 30, 40);
    f.settings.set_borderWidth(8);
    f.settings.set_offsetX(5);
    f.settings.set_offsetY(-3);
    comparePoint(f.control.extTL(), 15, -3, "有 settings 形态");

    f.control.set_settings(nullptr);
    // 退化：矩形（cut 0）无偏移无描边
    comparePoint(f.control.extTL(), 0, 0, "null extTL");
    comparePoint(f.control.extTR(), 100, 0, "null extTR");
    comparePoint(f.control.extBR(), 100, 80, "null extBR");
    comparePoint(f.control.extLB(), 0, 80, "null extLB");
    comparePoints(f.control.intTL(), f.control.extTL(), "null int == ext");
    QVERIFY(fuzzy_eq(f.control.usedWidth(), 100));
    QVERIFY(fuzzy_eq(f.control.usedHeight(), 80));
    QVERIFY(fuzzy_eq(f.control.topSpace(), 0));
    QVERIFY(fuzzy_eq(f.control.leftSpace(), 0));
    // contains 矩形判定（开集：角点命中）
    QVERIFY(f.control.contains(QPointF(0, 0)));
    QVERIFY(f.control.contains(QPointF(50, 40)));
    QVERIFY(!f.control.contains(QPointF(-1, 40)));

    // 从未设置 settings 的 control：同 0 输入退化
    QQuickItem target2;
    TestControl c2;
    c2.set_target(&target2);
    target2.setWidth(100);
    target2.setHeight(80);
    QCoreApplication::processEvents(); // 延迟同步 flush
    comparePoint(c2.extTL(), 0, 0, "默认 null extTL");
    comparePoint(c2.extBR(), 100, 80, "默认 null extBR");

    // target 也为 null：全零退化（不崩溃）
    TestControl c3;
    comparePoint(c3.extTL(), 0, 0, "无 target extTL");
    QVERIFY(fuzzy_eq(c3.usedWidth(), 0));
    QVERIFY(fuzzy_eq(c3.topSpace(), 0));
  }

  QOOL_TEST_CASE(destruction_safety) {
    // settings 先析构（局部作用域）：QObject 连接自动断开 + QPointer 置空
    // ——control 读取不崩溃，几何停留在最后同步值；随后 set_settings(nullptr)
    // 走 QPointer-null 分支同步回 0 输入
    QQuickItem target;
    TestControl control;
    control.set_target(&target);
    target.setWidth(100);
    target.setHeight(80);
    QCoreApplication::processEvents(); // 延迟同步 flush
    {
      QoolBoxSettings s;
      control.set_settings(&s);
      s.set_cutSizeTL(10);
      s.set_cutSizeTR(20);
      s.set_cutSizeBL(30);
      s.set_cutSizeBR(40);
      s.set_borderWidth(8);
      comparePoint(control.extTL(), 10, 0, "scope 内");
      QVERIFY(fuzzy_eq(control.usedWidth(), 100));
    } // s 析构（control 存活）
    comparePoint(control.extTL(), 10, 0, "s 析构后不崩溃、值停留");
    comparePoint(control.extBR(), 60, 80, "s 析构后 extBR");
    control.set_settings(nullptr); // 断开分支跳过（QPointer 已空）、同步 0
    comparePoint(control.extTL(), 0, 0, "null 同步后");
    comparePoint(control.extBR(), 100, 80, "null 同步后 extBR");

    // control 先析构（settings 存活）：连接随 receiver 销毁自动移除——
    // 不崩溃，settings 仍可用
    QQuickItem target2;
    QoolBoxSettings s2;
    {
      TestControl c2;
      c2.set_target(&target2);
      target2.setWidth(100); // 与第一段同尺寸——期望 (10,0) 成立
      target2.setHeight(80);
      QCoreApplication::processEvents(); // 延迟同步 flush
      c2.set_settings(&s2);
      s2.set_cutSizeTL(10);
      comparePoint(c2.extTL(), 10, 0, "scope 内");
    }
    QVERIFY(fuzzy_eq(s2.cutSizeTL(), 10));

    // settings 为 control 子对象（QObject 析构序：control body → 子对象）
    // ——不崩溃
    {
      QQuickItem target3;
      auto* c3 = new TestControl;
      auto* s3 = new QoolBoxSettings(c3);
      c3->set_target(&target3);
      target3.setWidth(100); // 与第一段同尺寸——期望 (10,0) 成立
      target3.setHeight(80);
      QCoreApplication::processEvents(); // 延迟同步 flush
      c3->set_settings(s3);
      s3->set_cutSizeTL(10);
      comparePoint(c3->extTL(), 10, 0, "子对象 scope");
      delete c3;
    }
  }
};

QTEST_MAIN(TestQoolBoxShapeControlUnit)

#include "tst_qoolboxshapecontrol.moc"
