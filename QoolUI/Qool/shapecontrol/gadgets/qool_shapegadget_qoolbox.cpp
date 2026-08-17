#include "qool_shapegadget_qoolbox.h"

#include "qoolcommon/debug.hpp"
#include <algorithm>
#include <limits>

QOOL_NS_BEGIN

namespace {

// —— shrink 层几何常量（平移半平面交集，推导见模块文档《几何与内缩算法》）——
// 8 条平移线（Ax+By=C 表示；halfPlaneSign = 半平面符号：+1 内部在 ≥ C
// 侧、−1 在 ≤ C 侧）
struct QoolBoxLine {
  qreal xCoefficient;  // A（x 系数）
  qreal yCoefficient;  // B（y 系数）
  int halfPlaneSign;   // 半平面符号：+1 内部在 ≥ C 侧、−1 在 ≤ C 侧
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
QPointF line_intersect(int i, int j, const QList<qreal>& constants) {
  const auto& l1 = kLines[i];
  const auto& l2 = kLines[j];
  const qreal det =
      l1.xCoefficient * l2.yCoefficient - l2.xCoefficient * l1.yCoefficient;
  const qreal x =
      (constants[i] * l2.yCoefficient - constants[j] * l1.yCoefficient) / det;
  const qreal y =
      (l1.xCoefficient * constants[j] - l2.xCoefficient * constants[i]) / det;
  return {x, y};
}

// 半平面判定：halfPlaneSign*(A·x+B·y−C) ≥ −eps。
// 专项注释：勿写 +C（曾致交集恒空）；−eps 容差吸收交点求值的 IEEE 舍入
// （边界点对生成线 ≈ 0，可 ±1e-15），1e-9 远小于断言精度 1e-6 无语义偏差。
bool satisfies_all(const QPointF& p, const QList<qreal>& constants) {
  constexpr qreal kEps = 1e-9;
  for (int i = 0; i < 8; ++i) {
    const auto& line = kLines[i];
    const qreal v = line.halfPlaneSign
        * (line.xCoefficient * p.x() + line.yCoefficient * p.y()
            - constants[i]);
    if (v < -kEps) return false;
  }
  return true;
}

// 归入最近有效交集顶点（自然重合位置——极值收敛；勿无条件钳制尖点/中点
// 法线——逐点钳制范式 6%~22% 非凸/自交已废弃）
QPointF nearest_vertex(const QPointF& point, const QList<QPointF>& verts) {
  if (verts.isEmpty()) return point; // 防御：shrinkDistance ≤ maxShrinkDistance
                                     // 保证交集非空
  qreal best = std::numeric_limits<qreal>::max();
  QPointF result = verts.first();
  for (const auto& vertex : verts) {
    const QPointF delta = vertex - point;
    const qreal distanceSquared = QPointF::dotProduct(delta, delta);
    if (distanceSquared < best) {
      best = distanceSquared;
      result = vertex;
    }
  }
  return result;
}

} // namespace

QoolBoxGadget::QoolBoxGadget(QObject* parent)
  : ShapeControlGadget(parent) {
  // —— ① used（ref 介入：ref.used : 自算）——
  // 自算分支只在 ref 为 null 时执行（ref 分支早退），读自有 cuts；
  // clampedCut* = qMax(0, cut*)——语义下限（负切角无几何意义，归零直角点），
  // 唯一下限、无尺寸耦合钳制（safe 链 SHORT_EDGE 递推式已废弃）。
  QBINDABLE_SET_BINDING(usedWidth, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_usedWidth().value();
    const auto control = bindable_control().value();
    const qreal width = control ? control->bindable_width().value() : 0.0;
    const qreal clampedCutTL = qMax(0.0, m_cutTL.value());
    const qreal clampedCutTR = qMax(0.0, m_cutTR.value());
    const qreal clampedCutBL = qMax(0.0, m_cutBL.value());
    const qreal clampedCutBR = qMax(0.0, m_cutBR.value());
    // usedWidth = max(期望, 对角 cut 和)——构造性保证四边长度非负、
    // 角间零交互
    return qMax(
        width, qMax(clampedCutTL + clampedCutTR, clampedCutBL + clampedCutBR));
  });
  QBINDABLE_SET_BINDING(usedHeight, [&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->bindable_usedHeight().value();
    const auto control = bindable_control().value();
    const qreal height = control ? control->bindable_height().value() : 0.0;
    const qreal clampedCutTL = qMax(0.0, m_cutTL.value());
    const qreal clampedCutTR = qMax(0.0, m_cutTR.value());
    const qreal clampedCutBL = qMax(0.0, m_cutBL.value());
    const qreal clampedCutBR = qMax(0.0, m_cutBR.value());
    return qMax(
        height, qMax(clampedCutTL + clampedCutBL, clampedCutTR + clampedCutBR));
  });

  // —— ② usedHalf（降权内部量：裸 QProperty + setBinding）——
  m_usedHalfWidth.setBinding([&] { return m_usedWidth.value() / 2; });
  m_usedHalfHeight.setBinding([&] { return m_usedHeight.value() / 2; });

  // —— ③ vec×8（ref 介入：ref.vec : 符号表；QVector2D 自由位移向量）——
  // 符号表：角点在 x 方向注入 cut、边端点在 y 方向注入
  // cut——注入轴 = 点所在斜边的法线轴；8 点保证 |x| ≤ usedHalfWidth ∧
  // |y| ≤ usedHalfHeight（形状 ⊆ used 矩形，相切）。ref 分支经普通
  // getter 读 ref 的向量——QProperty 绑定机制下 value() 读取即注册依赖。
  m_vecTL.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->vecTL();
    return QVector2D(-m_usedHalfWidth.value() + qMax(0.0, m_cutTL.value()),
        -m_usedHalfHeight.value());
  });
  m_vecTR.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->vecTR();
    return QVector2D(
        m_usedHalfWidth.value() - qMax(0.0, m_cutTR.value()),
        -m_usedHalfHeight.value());
  });
  m_vecRT.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->vecRT();
    return QVector2D(m_usedHalfWidth.value(),
        -m_usedHalfHeight.value() + qMax(0.0, m_cutTR.value()));
  });
  m_vecRB.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->vecRB();
    return QVector2D(m_usedHalfWidth.value(),
        m_usedHalfHeight.value() - qMax(0.0, m_cutBR.value()));
  });
  m_vecBR.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->vecBR();
    return QVector2D(m_usedHalfWidth.value() - qMax(0.0, m_cutBR.value()),
        m_usedHalfHeight.value());
  });
  m_vecBL.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->vecBL();
    return QVector2D(-m_usedHalfWidth.value() + qMax(0.0, m_cutBL.value()),
        m_usedHalfHeight.value());
  });
  m_vecLB.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->vecLB();
    return QVector2D(-m_usedHalfWidth.value(),
        m_usedHalfHeight.value() - qMax(0.0, m_cutBL.value()));
  });
  m_vecLT.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->vecLT();
    return QVector2D(-m_usedHalfWidth.value(),
        -m_usedHalfHeight.value() + qMax(0.0, m_cutTL.value()));
  });

  // —— ④ maxShrinkDistance（12 候选 min，O(1) 无二分；cuts 读取介入——
  // ref 模式经 ref 读取；used 已介入）——
  // 对偶 LP 推导：8 法线恰成 4 对相反，平衡组合只有
  // 平行对（4 个）与三线组合（8 个）可行——12 候选无冗余无遗漏；
  // 非负性由 used ≥ 对角 cut 和构造性保证。
  m_maxShrinkDistance.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    const qreal clampedCutTL = qMax(0.0,
        ref ? ref->bindable_cutTL().value() : m_cutTL.value());
    const qreal clampedCutTR = qMax(0.0,
        ref ? ref->bindable_cutTR().value() : m_cutTR.value());
    const qreal clampedCutBL = qMax(0.0,
        ref ? ref->bindable_cutBL().value() : m_cutBL.value());
    const qreal clampedCutBR = qMax(0.0,
        ref ? ref->bindable_cutBR().value() : m_cutBR.value());
    const qreal usedWidth = m_usedWidth.value();
    const qreal usedHeight = m_usedHeight.value();
    static constexpr qreal kSqrt2 = 1.4142135623730951; // √2
    const qreal d1 = usedHeight / 2; // N/S 平行对
    const qreal d2 = usedWidth / 2;  // W/E 平行对
    const qreal d3 = (usedWidth + usedHeight - clampedCutTL - clampedCutBR)
        / (2 * kSqrt2); // TL斜 vs BR斜
    const qreal d4 = (usedWidth + usedHeight - clampedCutTR - clampedCutBL)
        / (2 * kSqrt2); // TR斜 vs BL斜
    const qreal d5 = (usedWidth + usedHeight - clampedCutBR)
        / (2 + kSqrt2); // E+N+BR斜
    const qreal d6 = (usedWidth + usedHeight - clampedCutTL)
        / (2 + kSqrt2); // W+S+TL斜
    const qreal d7 = (usedWidth + usedHeight - clampedCutBL)
        / (2 + kSqrt2); // W+N+BL斜
    const qreal d8 = (usedWidth + usedHeight - clampedCutTR)
        / (2 + kSqrt2); // E+S+TR斜
    const qreal d9 = (usedWidth + 2 * usedHeight - clampedCutBR - clampedCutBL)
        / (kSqrt2 * (2 + kSqrt2)); // N+BR斜+BL斜
    const qreal d10 = (usedWidth + 2 * usedHeight - clampedCutTL
                          - clampedCutTR)
        / (kSqrt2 * (2 + kSqrt2)); // S+TL斜+TR斜
    const qreal d11 = (2 * usedWidth + usedHeight - clampedCutTL
                          - clampedCutBL)
        / (kSqrt2 * (2 + kSqrt2)); // W+TL斜+BL斜
    const qreal d12 = (2 * usedWidth + usedHeight - clampedCutTR
                          - clampedCutBR)
        / (kSqrt2 * (2 + kSqrt2)); // E+TR斜+BR斜
    // 链式 min（不用 std::min({...})——花括号逗号会分割宏参数）
    qreal result = d1;
    result = qMin(result, d2);
    result = qMin(result, d3);
    result = qMin(result, d4);
    result = qMin(result, d5);
    result = qMin(result, d6);
    result = qMin(result, d7);
    result = qMin(result, d8);
    result = qMin(result, d9);
    result = qMin(result, d10);
    result = qMin(result, d11);
    result = qMin(result, d12);
    return result;
  });

  // —— ⑤ shrinkDistance（d 层面钳制——保交集永不空；maxShrinkDistance 为
  // 形状参数连续函数；负 border 自动走外扩分支：min(负, maxShrinkDistance)
  // = 负）——
  m_shrinkDistance.setBinding([&] {
    return qMin(m_borderWidth.value(), m_maxShrinkDistance.value());
  });

  // —— ⑥ insetLineConstants（8 条平移线常量，Ax+By=C；cuts 读取介入）——
  // 平移线公式：每条边沿法线内错 shrinkDistance——shrink 语义 = 边平移
  m_insetLineConstants.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    const qreal clampedCutTL = qMax(0.0,
        ref ? ref->bindable_cutTL().value() : m_cutTL.value());
    const qreal clampedCutTR = qMax(0.0,
        ref ? ref->bindable_cutTR().value() : m_cutTR.value());
    const qreal clampedCutBL = qMax(0.0,
        ref ? ref->bindable_cutBL().value() : m_cutBL.value());
    const qreal clampedCutBR = qMax(0.0,
        ref ? ref->bindable_cutBR().value() : m_cutBR.value());
    const qreal usedWidth = m_usedWidth.value();
    const qreal usedHeight = m_usedHeight.value();
    const qreal insetDistance = m_shrinkDistance.value();
    static constexpr qreal kSqrt2 = 1.4142135623730951; // √2
    // append 序列（不用 QList<qreal>{...}——花括号逗号会分割宏参数）
    QList<qreal> constants;
    constants.reserve(8);
    constants.append(-usedHeight / 2 + insetDistance); // 0 顶
    constants.append(usedHeight / 2 - insetDistance);  // 1 底
    constants.append(-usedWidth / 2 + insetDistance);  // 2 左
    constants.append(usedWidth / 2 - insetDistance);   // 3 右
    constants.append(-usedWidth / 2 - usedHeight / 2 + clampedCutTL
        + insetDistance * kSqrt2); // 4 左斜
    constants.append(usedWidth / 2 + usedHeight / 2 - clampedCutTR
        - insetDistance * kSqrt2); // 5 右斜
    constants.append(usedWidth / 2 + usedHeight / 2 - clampedCutBR
        - insetDistance * kSqrt2); // 6 右底斜
    constants.append(-usedWidth / 2 - usedHeight / 2 + clampedCutBL
        + insetDistance * kSqrt2); // 7 左底斜
    return constants;
  });

  // —— ⑦ intersectionVertices（24 对非平行线交点满足全部 8 半平面者 =
  // 交集顶点，几何真值；shrinkDistance ≤ maxShrinkDistance 保证非空）——
  m_intersectionVertices.setBinding([&] {
    const QList<qreal> constants = m_insetLineConstants.value();
    QList<QPointF> verts;
    for (int i = 0; i < 8; ++i) {
      for (int j = i + 1; j < 8; ++j) {
        if (is_parallel(i, j)) continue;
        const QPointF p = line_intersect(i, j, constants);
        if (satisfies_all(p, constants)) verts.append(p);
      }
    }
    return verts;
  });

  // —— ⑧ shrink×8（每点 = 身份候选交点有效取之 / 失效归入最近交集顶点，
  // 再 − vecA 得位移；QVector2D 自由位移向量）——
  // 专项注释：8 个命名点是 8 个不同对象，各自依赖正确
  // 的来源线对（身份候选 = 相邻平移线对交点，勿与 135° 位移表混淆）；
  // 候选与交集顶点用同一 insetLineConstants 求值 ⟹ 有效候选精确
  // ∈ 交集顶点（浮点一致）
#define SETUP_SHRINK(_N_, _I_, _J_)                                   \
  m_shrink##_N_.setBinding([&] {                                      \
    const QList<qreal> constants = m_insetLineConstants.value();      \
    const QList<QPointF> verts = m_intersectionVertices.value();      \
    const QPointF candidate = line_intersect(_I_, _J_, constants);    \
    const QPointF p = satisfies_all(candidate, constants)             \
                          ? candidate                                 \
                          : nearest_vertex(candidate, verts);         \
    return QVector2D(p) - m_vec##_N_.value();                         \
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
  m_origin.setBinding([&] {
    const auto ref = bindable_referenceBox().value();
    if (ref) return ref->origin();
    const auto control = bindable_control().value();
    return control ? control->bindable_center().value() : QPointF(0, 0);
  });

  // —— ⑩ point×8（唯一锚定处：origin + offset + vecA + shrinkA；
  // offset 介入在消费点直接分支，不引入 effectiveOffset 中间量）——
  // offset 在消费点合成 QVector2D（自由位移向量——QML 面仍为
  // offsetX/offsetY 标量），与 vec/shrink 同为向量系；锚定处统一
  // 转回 QPointF（加法顺序 origin→offset→vec→shrink 与旧实现逐位一致）
#define SETUP_POINT(_N_)                                                  \
  QBINDABLE_SET_BINDING(point##_N_, [&] {                                 \
    const auto ref = bindable_referenceBox().value();                     \
    const qreal ox = ref ? ref->bindable_offsetX().value()                \
                         : m_offsetX.value();                             \
    const qreal oy = ref ? ref->bindable_offsetY().value()                \
                         : m_offsetY.value();                             \
    return m_origin.value() + QVector2D(ox, oy).toPointF()                \
        + m_vec##_N_.value().toPointF()                                   \
        + m_shrink##_N_.value().toPointF();                               \
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
