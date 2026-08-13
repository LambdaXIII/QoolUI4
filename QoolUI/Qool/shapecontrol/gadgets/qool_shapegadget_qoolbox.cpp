#include "qool_shapegadget_qoolbox.h"

#include "qoolcommon/debug.hpp"
#include <algorithm>
#include <limits>

QOOL_NS_BEGIN

namespace {

// —— shrink 层几何常量（平移半平面交集，推导见模块文档《几何与内缩算法》）——
// 8 条平移线（Ax+By=C 表示；s = 半平面符号：+1 内部在 ≥ C 侧、−1 在 ≤ C 侧）
struct QoolBoxLine {
  qreal a, b;
  int s;
};

constexpr QoolBoxLine kLines[8] = {
    {0, 1, +1},  // 0 顶（y = C）
    {0, 1, -1},  // 1 底
    {1, 0, +1},  // 2 左（x = C）
    {1, 0, -1},  // 3 右
    {1, 1, +1},  // 4 左斜（TL 斜边：x+y = C）
    {1, -1, -1}, // 5 右斜（TR 斜边：x−y = C）
    {1, 1, -1},  // 6 右底斜（BR 斜边：x+y = C）
    {1, -1, +1}  // 7 左底斜（BL 斜边：x−y = C）
};

// 平行对（无交点）：顶/底、左/右、左斜/右底斜、右斜/左底斜——
// C(8,2)−4 = 24 对非平行线才有交点（几何真值，验证基准）
bool is_parallel(int i, int j) {
  return (i == 0 && j == 1) || (i == 2 && j == 3) || (i == 4 && j == 6)
      || (i == 5 && j == 7);
}

// 两线交点（调用方已排除平行对；det 恒为 ±1/±2——45° 网格无病态）
QPointF line_intersect(int i, int j, const QList<qreal>& c) {
  const auto& l1 = kLines[i];
  const auto& l2 = kLines[j];
  const qreal det = l1.a * l2.b - l2.a * l1.b;
  const qreal x = (c[i] * l2.b - c[j] * l1.b) / det;
  const qreal y = (l1.a * c[j] - l2.a * c[i]) / det;
  return {x, y};
}

// 半平面判定：s*(A·x+B·y−C) ≥ −eps。
// 专项注释：勿写 +C（曾致交集恒空）；−eps 容差吸收交点求值的 IEEE 舍入
// （边界点对生成线 ≈ 0，可 ±1e-15），1e-9 远小于断言精度 1e-6 无语义偏差。
bool satisfies_all(const QPointF& p, const QList<qreal>& c) {
  constexpr qreal kEps = 1e-9;
  for (int i = 0; i < 8; ++i) {
    const auto& l = kLines[i];
    const qreal v = l.s * (l.a * p.x() + l.b * p.y() - c[i]);
    if (v < -kEps) return false;
  }
  return true;
}

// 归入最近有效交集顶点（自然重合位置——极值收敛；勿无条件钳制尖点/中点
// 法线——逐点钳制范式 6%~22% 非凸/自交已废弃）
QPointF nearest_vertex(const QPointF& p, const QList<QPointF>& verts) {
  if (verts.isEmpty()) return p; // 防御：d_eff ≤ d* 保证交集非空
  qreal best = std::numeric_limits<qreal>::max();
  QPointF r = verts.first();
  for (const auto& v : verts) {
    const QPointF d = v - p;
    const qreal d2 = QPointF::dotProduct(d, d);
    if (d2 < best) {
      best = d2;
      r = v;
    }
  }
  return r;
}

} // namespace

/*!
    \qmltype QoolBoxGadget
    \inqmlmodule Qool
    \nativetype qoolui::QoolBoxGadget
    \brief 八边形控制点计算器（Gadget）：cut 硬参数 + 期望尺寸的单一 8 点模型。

    挂载于标准 \l ShapeControl 之下（ShapeControl 子对象自动关联
    \c control），输出单一 8 点 \c pointTL..pointLT（每点另有
    \c pointTLx/\c pointTLy 等分量）——由 \c borderWidth 参数化形态：
    0 为外轮廓，> 0 时 8 点沿各边法线内缩，< 0 为外扩。
    双实例描边 = 宿主实例化两个 gadget（外环 \c borderWidth 0 /
    内环 = 目标描边宽度），组件字面只有 8 点。

    \section1 语义

    \c cutTL..cutBR 是硬参数：形状由 cut 决定，不因尺寸不足而压缩；
    \c width/\c height（经 \c control 读取）是期望尺寸——图形尽量符合，
    极限情况（cut 需求超过期望尺寸）从期望中心对称溢出，而非压缩 cut。
    负 cut 归零（直角点）。所有退化状态（矩形/菱形/三角形/凸多边形/
    点重合/线段）都是定义良好的合法极限形态。

    \section1 输入接线

    \list
    \li \c cutTL..cutBR：四角切角尺寸（硬参数，默认 0 = 直角）；
    \li \c borderWidth：内缩距离（默认 0 = 外轮廓；双实例描边时内环
        实例设为目标描边宽度）；
    \li \c offsetX/\c offsetY：整体平移（唯一位置输入）；
    \li \c width/\c height：经 \c control 读取（期望尺寸）——宿主设置
        \c target 的几何即可，无需为 gadget 另设尺寸；
    \li \c referenceBox：几何参考源（见下）。
    \endlist

    \section1 命名规范

    首字母 = 点所在边、次字母 = 该边端点位置——\c TL = Top 边 Left
    端点、\c LT = Left 边 Top 端点（8 个命名互不混淆）。每点另有
    \c pointTLx/\c pointTLy 等分量属性。

    \section1 referenceBox（几何参考源）

    \c referenceBox 赋另一个 gadget 时，本 gadget 的 \c origin、\c offset、
    \c vec*、\c used*、\c cut* 经其覆盖（ref 优先），仅 \c borderWidth
    与 shrink 层自行处理——几何完全委托。赋值校验：目标自身已有
    reference 时赋值无效（链式引用与环被阻止），本 gadget 的
    referenceBox 置 null。

    \section1 命中判定

    \l {contains()} 精确命中八边形：斜边/边/顶点命中（开集语义），
    切角区域不命中；\c borderWidth 不影响判定。

    \section1 算法

    点定位与内缩（shrink）算法、临界距离解析式的推导与边界条件详见
    \l {qoolbox-geometry.html} {QoolBoxGadget 几何与内缩算法}。
*/

QoolBoxGadget::QoolBoxGadget(QObject* parent)
  : ShapeControlGadget(parent) {
  // —— ① used（ref 介入：ref.used : 自算）——
  // 自算分支只在 ref 为 null 时执行（ref 分支早退），读自有 cuts；
  // s* = qMax(0, cut*)——语义下限（负切角无几何意义，归零直角点），
  // 唯一下限、无尺寸耦合钳制（safe 链 SHORT_EDGE 递推式已废弃）。
  QBINDABLE_SET_BINDING(usedWidth, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_usedWidth().value();
    const auto c = bindable_control().value();
    const qreal w = c ? c->bindable_width().value() : 0.0;
    const qreal sTL = qMax(0.0, m_cutTL.value());
    const qreal sTR = qMax(0.0, m_cutTR.value());
    const qreal sBL = qMax(0.0, m_cutBL.value());
    const qreal sBR = qMax(0.0, m_cutBR.value());
    // usedW = max(期望, 对角 cut 和)——构造性保证四边长度非负、角间零交互
    return qMax(w, qMax(sTL + sTR, sBL + sBR));
  });
  QBINDABLE_SET_BINDING(usedHeight, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_usedHeight().value();
    const auto c = bindable_control().value();
    const qreal h = c ? c->bindable_height().value() : 0.0;
    const qreal sTL = qMax(0.0, m_cutTL.value());
    const qreal sTR = qMax(0.0, m_cutTR.value());
    const qreal sBL = qMax(0.0, m_cutBL.value());
    const qreal sBR = qMax(0.0, m_cutBR.value());
    return qMax(h, qMax(sTL + sBL, sTR + sBR));
  });

  // —— ② usedHalf ——
  QBINDABLE_SET_BINDING(usedHalfWidth, [&] { return m_usedWidth.value() / 2; });
  QBINDABLE_SET_BINDING(
      usedHalfHeight, [&] { return m_usedHeight.value() / 2; });

  // —— ③ vec×8（ref 介入：ref.vec : 符号表）——
  // 符号表：角点在 x 方向注入 cut、边端点在 y 方向注入
  // cut——注入轴 = 点所在斜边的法线轴；8 点保证 |x| ≤ uW/2 ∧ |y| ≤ uH/2
  // （形状 ⊆ used 矩形，相切）。
  QBINDABLE_SET_BINDING(vecTL, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_vecTL().value();
    return QPointF(-m_usedHalfWidth.value() + qMax(0.0, m_cutTL.value()),
        -m_usedHalfHeight.value());
  });
  QBINDABLE_SET_BINDING(vecTR, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_vecTR().value();
    return QPointF(
        m_usedHalfWidth.value() - qMax(0.0, m_cutTR.value()),
        -m_usedHalfHeight.value());
  });
  QBINDABLE_SET_BINDING(vecRT, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_vecRT().value();
    return QPointF(m_usedHalfWidth.value(),
        -m_usedHalfHeight.value() + qMax(0.0, m_cutTR.value()));
  });
  QBINDABLE_SET_BINDING(vecRB, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_vecRB().value();
    return QPointF(m_usedHalfWidth.value(),
        m_usedHalfHeight.value() - qMax(0.0, m_cutBR.value()));
  });
  QBINDABLE_SET_BINDING(vecBR, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_vecBR().value();
    return QPointF(m_usedHalfWidth.value() - qMax(0.0, m_cutBR.value()),
        m_usedHalfHeight.value());
  });
  QBINDABLE_SET_BINDING(vecBL, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_vecBL().value();
    return QPointF(-m_usedHalfWidth.value() + qMax(0.0, m_cutBL.value()),
        m_usedHalfHeight.value());
  });
  QBINDABLE_SET_BINDING(vecLB, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_vecLB().value();
    return QPointF(-m_usedHalfWidth.value(),
        m_usedHalfHeight.value() - qMax(0.0, m_cutBL.value()));
  });
  QBINDABLE_SET_BINDING(vecLT, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_vecLT().value();
    return QPointF(-m_usedHalfWidth.value(),
        -m_usedHalfHeight.value() + qMax(0.0, m_cutTL.value()));
  });

  // —— ④ dStar（12 候选 min，O(1) 无二分；cuts 读取介入——ref 模式经
  // ref 读取；used 已介入）——
  // 对偶 LP 推导：8 法线恰成 4 对相反，平衡组合只有
  // 平行对（4 个）与三线组合（8 个）可行——12 候选无冗余无遗漏；
  // 非负性由 used ≥ 对角 cut 和构造性保证。
  QBINDABLE_SET_BINDING(dStar, [&] {
    const auto ref = bindable_referenceBox().value();
    const qreal sTL = qMax(0.0,
        ref ? ref->bindable_cutTL().value() : m_cutTL.value());
    const qreal sTR = qMax(0.0,
        ref ? ref->bindable_cutTR().value() : m_cutTR.value());
    const qreal sBL = qMax(0.0,
        ref ? ref->bindable_cutBL().value() : m_cutBL.value());
    const qreal sBR = qMax(0.0,
        ref ? ref->bindable_cutBR().value() : m_cutBR.value());
    const qreal uW = m_usedWidth.value();
    const qreal uH = m_usedHeight.value();
    static constexpr qreal K = 1.4142135623730951; // √2
    const qreal d1 = uH / 2;                       // N/S 平行对
    const qreal d2 = uW / 2;                       // W/E 平行对
    const qreal d3 = (uW + uH - sTL - sBR) / (2 * K); // TL斜 vs BR斜
    const qreal d4 = (uW + uH - sTR - sBL) / (2 * K); // TR斜 vs BL斜
    const qreal d5 = (uW + uH - sBR) / (2 + K);       // E+N+BR斜
    const qreal d6 = (uW + uH - sTL) / (2 + K);       // W+S+TL斜
    const qreal d7 = (uW + uH - sBL) / (2 + K);       // W+N+BL斜
    const qreal d8 = (uW + uH - sTR) / (2 + K);       // E+S+TR斜
    const qreal d9 = (uW + 2 * uH - sBR - sBL) / (K * (2 + K)); // N+BR斜+BL斜
    const qreal d10 = (uW + 2 * uH - sTL - sTR) / (K * (2 + K)); // S+TL斜+TR斜
    const qreal d11 = (2 * uW + uH - sTL - sBL) / (K * (2 + K)); // W+TL斜+BL斜
    const qreal d12 = (2 * uW + uH - sTR - sBR) / (K * (2 + K)); // E+TR斜+BR斜
    // 链式 min（不用 std::min({...})——花括号逗号会分割宏参数）
    qreal r = d1;
    r = qMin(r, d2);
    r = qMin(r, d3);
    r = qMin(r, d4);
    r = qMin(r, d5);
    r = qMin(r, d6);
    r = qMin(r, d7);
    r = qMin(r, d8);
    r = qMin(r, d9);
    r = qMin(r, d10);
    r = qMin(r, d11);
    r = qMin(r, d12);
    return r;
  });

  // —— ⑤ shrinkD（d 层面钳制——保交集永不空；d* 为形状参数连续函数；
  // 负 border 自动走外扩分支：min(负, d*) = 负）——
  QBINDABLE_SET_BINDING(shrinkD, [&] {
    return qMin(m_borderWidth.value(), m_dStar.value());
  });

  // —— ⑥ linesC（8 条平移线常量，Ax+By=C；cuts 读取介入）——
  // 平移线公式：每条边沿法线内错 d——shrink 语义 = 边平移
  QBINDABLE_SET_BINDING(linesC, [&] {
    const auto ref = bindable_referenceBox().value();
    const qreal sTL = qMax(0.0,
        ref ? ref->bindable_cutTL().value() : m_cutTL.value());
    const qreal sTR = qMax(0.0,
        ref ? ref->bindable_cutTR().value() : m_cutTR.value());
    const qreal sBL = qMax(0.0,
        ref ? ref->bindable_cutBL().value() : m_cutBL.value());
    const qreal sBR = qMax(0.0,
        ref ? ref->bindable_cutBR().value() : m_cutBR.value());
    const qreal uW = m_usedWidth.value();
    const qreal uH = m_usedHeight.value();
    const qreal d = m_shrinkD.value();
    static constexpr qreal K = 1.4142135623730951; // √2
    // append 序列（不用 QList<qreal>{...}——花括号逗号会分割宏参数）
    QList<qreal> c;
    c.reserve(8);
    c.append(-uH / 2 + d);                     // 0 顶
    c.append(uH / 2 - d);                      // 1 底
    c.append(-uW / 2 + d);                     // 2 左
    c.append(uW / 2 - d);                      // 3 右
    c.append(-uW / 2 - uH / 2 + sTL + d * K);  // 4 左斜
    c.append(uW / 2 + uH / 2 - sTR - d * K);   // 5 右斜
    c.append(uW / 2 + uH / 2 - sBR - d * K);   // 6 右底斜
    c.append(-uW / 2 - uH / 2 + sBL + d * K);  // 7 左底斜
    return c;
  });

  // —— ⑦ intersectVerts（24 对非平行线交点满足全部 8 半平面者 = 交集
  // 顶点，几何真值；d_eff ≤ d* 保证非空）——
  QBINDABLE_SET_BINDING(intersectVerts, [&] {
    const QList<qreal> c = m_linesC.value();
    QList<QPointF> verts;
    for (int i = 0; i < 8; ++i) {
      for (int j = i + 1; j < 8; ++j) {
        if (is_parallel(i, j)) continue;
        const QPointF p = line_intersect(i, j, c);
        if (satisfies_all(p, c)) verts.append(p);
      }
    }
    return verts;
  });

  // —— ⑧ shrink×8（每点 = 身份候选交点有效取之 / 失效归入最近交集顶点，
  // 再 − vecA 得位移）——
  // 专项注释：8 个命名点是 8 个不同对象，各自依赖正确
  // 的来源线对（身份候选 = 相邻平移线对交点，勿与 135° 位移表混淆）；
  // 候选与交集顶点用同一 linesC 求值 ⟹ 有效候选精确 ∈ 交集顶点（浮点一致）
#define SETUP_SHRINK(_N_, _I_, _J_)                                   \
  QBINDABLE_SET_BINDING(shrink##_N_, [&] {                            \
    const QList<qreal> c = m_linesC.value();                          \
    const QList<QPointF> verts = m_intersectVerts.value();            \
    const QPointF cand = line_intersect(_I_, _J_, c);                 \
    const QPointF p = satisfies_all(cand, c) ? cand                   \
                                             : nearest_vertex(cand, verts); \
    return p - m_vec##_N_.value();                                    \
  });
  SETUP_SHRINK(TL, 0, 4) // TL = 顶×左斜
  SETUP_SHRINK(TR, 0, 5) // TR = 顶×右斜
  SETUP_SHRINK(RT, 3, 5) // RT = 右×右斜
  SETUP_SHRINK(RB, 3, 6) // RB = 右×右底斜
  SETUP_SHRINK(BR, 1, 6) // BR = 底×右底斜
  SETUP_SHRINK(BL, 1, 7) // BL = 底×左底斜
  SETUP_SHRINK(LB, 2, 7) // LB = 左×左底斜
  SETUP_SHRINK(LT, 2, 4) // LT = 左×左斜
#undef SETUP_SHRINK

  // —— ⑨ origin（ref 介入：ref.origin : control.center）——
  // 锚定基准 = 期望尺寸中心（非 used 中心——曾数值验证 used 中心锚定致
  // 图形错位；used 永远是两个标量，向量从 (0,0) 直接加 origin 零转换）
  QBINDABLE_SET_BINDING(origin, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_origin().value();
    const auto c = bindable_control().value();
    return c ? c->bindable_center().value() : QPointF(0, 0);
  });

  // —— ⑩ point×8（唯一锚定处：origin + offset + vecA + shrinkA；
  // offset 介入在消费点直接分支，不引入 effOffset 中间量）——
#define SETUP_POINT(_N_)                                                  \
  QBINDABLE_SET_BINDING(point##_N_, [&] {                                 \
    const auto ref = bindable_referenceBox().value();                     \
    const qreal ox = ref ? ref->bindable_offsetX().value()                \
                         : m_offsetX.value();                             \
    const qreal oy = ref ? ref->bindable_offsetY().value()                \
                         : m_offsetY.value();                             \
    return m_origin.value() + QPointF(ox, oy) + m_vec##_N_.value()        \
        + m_shrink##_N_.value();                                          \
  });
  QOOL_FOREACH_8(SETUP_POINT, TL, TR, RT, RB, BR, BL, LB, LT)
#undef SETUP_POINT

  // —— ⑪ 分量×16（对外面；依赖整个 pointA——单轴变化多触发一次加法，
  // 可忽略；换取结构简单，不做 x/y 分量直连）——
#define SETUP_XY(_N_)                                              \
  QBINDABLE_SET_BINDING(point##_N_##x, [&] {                       \
    return m_point##_N_.value().x();                               \
  });                                                              \
  QBINDABLE_SET_BINDING(point##_N_##y, [&] {                       \
    return m_point##_N_.value().y();                               \
  });
  QOOL_FOREACH_8(SETUP_XY, TL, TR, RT, RB, BR, BL, LB, LT)
#undef SETUP_XY
}

/*!
    \qmlmethod bool QoolBoxGadget::contains(point point)
    \brief 精确命中判定：八边形内命中，切角区域不命中。

    开集语义：斜边/边/顶点命中（边界本身算命中）。\c borderWidth
    不影响判定（双实例描边中任选实例语义一致）。\c referenceBox
    模式下自动跟随几何参考。算法细节见
    \l {qoolbox-geometry.html} {QoolBoxGadget 几何与内缩算法}。
*/
bool QoolBoxGadget::contains(const QPointF& point) const {
  const auto ref = m_referenceBox.value();
  const qreal ox = ref ? ref->bindable_offsetX().value() : m_offsetX.value();
  const qreal oy = ref ? ref->bindable_offsetY().value() : m_offsetY.value();
  const QPointF o = m_origin.value();
  const qreal x = point.x() - o.x() - ox;
  const qreal y = point.y() - o.y() - oy;

  // 粗判（used 半量——非期望半量；cut 溢出时溢出带命中须接受）
  const qreal uW2 = m_usedHalfWidth.value();
  const qreal uH2 = m_usedHalfHeight.value();
  if (x > uW2 || x < -uW2) return false;
  if (y > uH2 || y < -uH2) return false;

  // 四角排除（s* = qMax(0, cut*)；s > 0 守卫——cut ≤ 0 直角跳过）
  const qreal sTL =
      qMax(0.0, ref ? ref->bindable_cutTL().value() : m_cutTL.value());
  const qreal sTR =
      qMax(0.0, ref ? ref->bindable_cutTR().value() : m_cutTR.value());
  const qreal sBL =
      qMax(0.0, ref ? ref->bindable_cutBL().value() : m_cutBL.value());
  const qreal sBR =
      qMax(0.0, ref ? ref->bindable_cutBR().value() : m_cutBR.value());
  if (sTL > 0 && (x + uW2) + (y + uH2) < sTL) return false; // TL 角
  if (sTR > 0 && (uW2 - x) + (y + uH2) < sTR) return false; // TR 角
  if (sBR > 0 && (uW2 - x) + (uH2 - y) < sBR) return false; // BR 角
  if (sBL > 0 && (x + uW2) + (uH2 - y) < sBL) return false; // BL 角
  return true;
}

void QoolBoxGadget::set_referenceBox(QoolBoxGadget* value) {
  // 专项注释：referenceBox 赋值校验——待引用目标自身已有 reference
  // （链式 A→R→X 与环 A→R→A 同阻）或为自身（自引用 A→A 是 1-环）时
  // 赋值无效：xWarningQ 提示 + 本 gadget 清除旧值（置 null）。单层保证：
  // 被引用者必须是无 reference 的"根"。校验仅在赋值时刻（赋值后 ref 再
  // 获得 reference 不追溯）。不修改内部绑定（无动态 setBinding 安装/卸载
  // ——绑定分支是静态 lambda 内的来源选择，见各绑定 ref 分支）；相等守卫
  // 与 NOTIFY 由 Q_OBJECT_BINDABLE_PROPERTY::operator= 内置（值实际变化
  // 才通知）。自引用必须拒绝：绑定对自身重入求值，Qt 以 BindingLoop 停止
  // 求值、几何静默停留在陈旧值（审查 F1：value == this 曾绕过校验）。
  if (value == this
      || (value != nullptr && value->m_referenceBox != nullptr)) {
    xWarningQ << "QoolBoxGadget::set_referenceBox: 目标已有 referenceBox 或为自身（"
              << value << "）——链式/自引用环被阻止，本 gadget 的 referenceBox 置 null";
    m_referenceBox = nullptr;
    return;
  }
  m_referenceBox = value;
}

QOOL_NS_END
