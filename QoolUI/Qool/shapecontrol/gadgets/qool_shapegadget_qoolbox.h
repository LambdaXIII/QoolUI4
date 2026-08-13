#ifndef QOOL_QOOLBOX_GADGET_H
#define QOOL_QOOLBOX_GADGET_H

#include "qool_shapecontrol_gadget.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"
#include <QList>
#include <QObject>
#include <QPointF>
#include <QQmlEngine>

QOOL_NS_BEGIN

// QoolBoxGadget：八边形控制点计算器（原 QoolBoxShapeControl 重构）。
//
// 语义（design.md 已定案）：cutSizes 是硬参数——形状由 cut 决定，不因尺寸
// 不足而压缩；width/height 是期望尺寸——极限情况图形从期望中心对称溢出。
// 单一 8 点输出（borderWidth 参数化形态：0 = 外轮廓，> 0 = 边平移内缩，
// shrink = 8 条平移半平面交集——几何真值）；双实例描边 = 宿主实例化两个
// gadget（外环 0 / 内环 d）。
//
// 输入面：ShapeControl 已有的 width/height 经 bindable_control() 读取
// （不声明）；cutTL..BR / borderWidth / offsetX/Y 自有 WRITABLE；referenceBox
// 手写 setter（例外：赋值含校验/清除语义）。
class QoolBoxGadget : public ShapeControlGadget {
  Q_OBJECT
  QML_ELEMENT
  Q_CLASSINFO("ShapeControlGadgetName", "QoolBox")

public:
  explicit QoolBoxGadget(QObject* parent = nullptr);

  bool contains(const QPointF& point) const override;

  // referenceBox：几何参考源（WRITABLE——手写 setter，赋值含校验/清除
  // 语义，一键宏无法表达；理由见 .cpp set_referenceBox 专项注释）。
  // 5 介入点（origin/offset/vec/used/cuts）ref 优先 null 回退。
  QoolBoxGadget* referenceBox() const { return m_referenceBox.value(); }
  void set_referenceBox(QoolBoxGadget* value);
  QBindable<QoolBoxGadget*> bindable_referenceBox() {
    return QBindable<QoolBoxGadget*>(&m_referenceBox);
  }
  Q_SIGNAL void referenceBoxChanged();

  // linesC/intersectVerts：shrink 层中间量（无 Q_PROPERTY——QList<qreal>
  // 非 QML 标准类型；测试与内部使用，QML 不可见）
  QList<qreal> linesC() const { return m_linesC; }
  QList<QPointF> intersectVerts() const { return m_intersectVerts; }

private:
  // —— 输入面（width/height 经 control 读取，不声明）——
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, cutTL, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, cutTR, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, cutBL, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, cutBR, FINAL)
  /*! \qmlproperty real 内缩距离（默认 0 = 外轮廓；双实例描边：内环实例 = d）。
      永不介入 referenceBox（本实例唯一自由输入）。 */
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, borderWidth, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, offsetX, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, offsetY, FINAL)

  // —— referenceBox 成员（Q_PROPERTY 手写；信号见 public 侧声明）——
  Q_OBJECT_BINDABLE_PROPERTY(QoolBoxGadget, QoolBoxGadget*, m_referenceBox,
      &QoolBoxGadget::referenceBoxChanged)
  Q_PROPERTY(QoolBoxGadget* referenceBox READ referenceBox WRITE
          set_referenceBox NOTIFY referenceBoxChanged BINDABLE
          bindable_referenceBox FINAL)

  // —— 派生链（11 级，全部 READONLY + setBinding，逐级依赖追踪）——
  // ① used（ref 介入：ref.used : 自算）
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, usedWidth, FINAL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, usedHeight, FINAL)
  // ② usedHalf
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, usedHalfWidth, FINAL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, usedHalfHeight, FINAL)
  // ④ dStar（12 候选 min）/ ⑤ shrinkD（d 层面钳制）
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, dStar, FINAL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, shrinkD, FINAL)
  // ⑥⑦ shrink 层中间量（QList，无 Q_PROPERTY）
  QOOL_BINDABLE_MEMBER(QoolBoxGadget, QList<qreal>, linesC)
  QOOL_BINDABLE_MEMBER(QoolBoxGadget, QList<QPointF>, intersectVerts)
  // ⑨ origin（ref 介入：ref.origin : control.center）
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, QPointF, origin, FINAL)

// ③ vec×8 / ⑧ shrink×8 / ⑩ point×8 / ⑪ 分量×16
// 命名规范：首字母 = 点所在边、次字母 = 该边端点位置（TL = Top 边 Left
// 端点、LT = Left 边 Top 端点）——8 个命名互不混淆。
#define DECL_POINT(_N_)                                                \
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, QPointF, vec##_N_, FINAL) \
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, QPointF, shrink##_N_, FINAL) \
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, QPointF, point##_N_, FINAL) \
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, point##_N_##x, FINAL) \
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, point##_N_##y, FINAL)

  QOOL_FOREACH_8(DECL_POINT, TL, TR, RT, RB, BR, BL, LB, LT)
#undef DECL_POINT
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_GADGET_H
