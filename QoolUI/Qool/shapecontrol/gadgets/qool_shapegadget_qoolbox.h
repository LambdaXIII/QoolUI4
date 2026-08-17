#ifndef QOOL_QOOLBOX_GADGET_H
#define QOOL_QOOLBOX_GADGET_H

#include "qool_shapecontrol_gadget.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"
#include <QList>
#include <QObject>
#include <QPointF>
#include <QProperty>
#include <QQmlEngine>
#include <QVector2D>

QOOL_NS_BEGIN

// QoolBoxGadget：八边形控制点计算器（原 QoolBoxShapeControl 重构）。
//
// 语义：cutSizes 是硬参数——形状由 cut 决定，不因尺寸
// 不足而压缩；width/height 是期望尺寸——极限情况图形从期望中心对称溢出。
// 单一 8 点输出（borderWidth 参数化形态：0 = 外轮廓，> 0 = 边平移内缩，
// shrink = 8 条平移半平面交集——几何真值）；双实例描边 = 宿主实例化两个
// gadget（外环 0 / 内环 d）。
//
// 输入面：ShapeControl 已有的 width/height 经 bindable_control() 读取
// （不声明）；cutTL..BR / borderWidth / offsetX/Y 自有 WRITABLE；referenceBox
// 手写 setter（例外：赋值含校验/清除语义）。
//
// 中间量分层（为什么这样改——降权）：vec×8 / shrink×8 / usedHalf×2 /
// maxShrinkDistance / shrinkDistance / origin 是纯内部中间量（无 QML 消费方、
// 无 signal 监听者），从 QBINDABLE_READONLY_PROPERTY（Q_PROPERTY + NOTIFY
// signal + bindable 三件套）降为裸 QProperty 成员 + 普通 getter：Q_PROPERTY
// 与 signal 对纯内部量是死重，QProperty 已提供 setBinding/value/依赖追踪。
// 降权量不用 QOOL_BINDABLE_MEMBER——该宏生成 signal（见
// qbindable_property_macros.hpp 宏定义）；本类中仅 insetLineConstants /
// intersectionVertices 维持该宏（signal 保留属兼容边界，本次不动）。
// 依赖追踪走 QProperty 绑定机制：绑定求值中读其它 QProperty 的 value()
// 即注册依赖，与 Q_PROPERTY 无关。普通 getter 保留供单元测试读取
// （tst_qoolboxgadget.cpp）。
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

  // —— 降权中间量（内部裸 QProperty + 普通 getter；见类注释）——
  // ② usedHalf（used 半量；contains 粗判与 vec 符号表共用）
  qreal usedHalfWidth() const { return m_usedHalfWidth.value(); }
  qreal usedHalfHeight() const { return m_usedHalfHeight.value(); }
  // ④ maxShrinkDistance（12 候选 min）/ ⑤ shrinkDistance（d 层面钳制）
  qreal maxShrinkDistance() const { return m_maxShrinkDistance.value(); }
  qreal shrinkDistance() const { return m_shrinkDistance.value(); }
  // ⑨ origin（ref 介入：ref.origin : control.center）
  QPointF origin() const { return m_origin.value(); }

  // ③ vec×8 / ⑧ shrink×8：自由位移向量（QVector2D——QPointF 是位置类型，
  // 位移向量独立于坐标系表示；QVector2D 有 x()/y() 供测试读取）
#define DECL_INTERNAL_VECTOR_GETTER(_N_)                    \
  QVector2D vec##_N_() const { return m_vec##_N_.value(); } \
  QVector2D shrink##_N_() const { return m_shrink##_N_.value(); }
  QOOL_FOREACH_8(DECL_INTERNAL_VECTOR_GETTER, TL, TR, RT, RB, BR, BL, LB, LT)
#undef DECL_INTERNAL_VECTOR_GETTER

  // insetLineConstants/intersectionVertices：shrink 层中间量（无
  // Q_PROPERTY——QList 非 QML 标准类型；测试与内部使用，QML 不可见；
  // signal 由 QOOL_BINDABLE_MEMBER 生成——兼容边界，保留）
  QList<qreal> insetLineConstants() const {
    return m_insetLineConstants.value();
  }
  QList<QPointF> intersectionVertices() const {
    return m_intersectionVertices.value();
  }

private:
  // —— 输入面（width/height 经 control 读取，不声明）——
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, cutTL, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, cutTR, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, cutBL, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, cutBR, FINAL)
  // 属性 borderWidth（real）：内缩距离（默认 0 = 外轮廓；双实例描边：
  // 内环实例 = d）。永不介入 referenceBox（本实例唯一自由输入）。
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, borderWidth, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, offsetX, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxGadget, qreal, offsetY, FINAL)

  // —— referenceBox 成员（Q_PROPERTY 手写；信号见 public 侧声明）——
  Q_OBJECT_BINDABLE_PROPERTY(QoolBoxGadget, QoolBoxGadget*, m_referenceBox,
      &QoolBoxGadget::referenceBoxChanged)
  Q_PROPERTY(QoolBoxGadget* referenceBox READ referenceBox WRITE
          set_referenceBox NOTIFY referenceBoxChanged BINDABLE
          bindable_referenceBox FINAL)

  // —— 派生链（全部 setBinding，逐级依赖追踪）——
  // ① used（ref 介入：ref.used : 自算）——对外面（QML 输出）
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, usedWidth, FINAL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, usedHeight, FINAL)
  // ② usedHalf（降权内部量）
  QProperty<qreal> m_usedHalfWidth;
  QProperty<qreal> m_usedHalfHeight;
  // ④ maxShrinkDistance（12 候选 min）/ ⑤ shrinkDistance（d 层面钳制）
  QProperty<qreal> m_maxShrinkDistance;
  QProperty<qreal> m_shrinkDistance;
  // ⑥⑦ shrink 层中间量（QList，无 Q_PROPERTY；QOOL_BINDABLE_MEMBER 生成
  // signal——兼容边界，保留）
  QOOL_BINDABLE_MEMBER(QoolBoxGadget, QList<qreal>, insetLineConstants)
  QOOL_BINDABLE_MEMBER(QoolBoxGadget, QList<QPointF>, intersectionVertices)
  // ⑨ origin（ref 介入：ref.origin : control.center）
  QProperty<QPointF> m_origin;

  // ③ vec×8 / ⑧ shrink×8（降权内部量；QVector2D 自由位移向量）
#define DECL_INTERNAL_VECTOR_MEMBER(_N_)   \
  QProperty<QVector2D> m_vec##_N_;         \
  QProperty<QVector2D> m_shrink##_N_;
  QOOL_FOREACH_8(DECL_INTERNAL_VECTOR_MEMBER, TL, TR, RT, RB, BR, BL, LB, LT)
#undef DECL_INTERNAL_VECTOR_MEMBER

  // ⑩ point×8 / ⑪ 分量×16（对外面：QML 输出）
  // 命名规范：首字母 = 点所在边、次字母 = 该边端点位置（TL = Top 边 Left
  // 端点、LT = Left 边 Top 端点）——8 个命名互不混淆。
#define DECL_POINT(_N_)                                                \
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, QPointF, point##_N_, FINAL) \
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, point##_N_##x, FINAL) \
  QBINDABLE_READONLY_PROPERTY(QoolBoxGadget, qreal, point##_N_##y, FINAL)
  QOOL_FOREACH_8(DECL_POINT, TL, TR, RT, RB, BR, BL, LB, LT)
#undef DECL_POINT
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_GADGET_H
