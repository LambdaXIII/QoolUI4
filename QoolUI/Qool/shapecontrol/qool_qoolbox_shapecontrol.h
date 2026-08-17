#ifndef QOOL_QOOLBOX_SHAPECONTROL_H
#define QOOL_QOOLBOX_SHAPECONTROL_H

#include "qool_qoolbox_settings.h"
#include "qool_shapecontrol.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QPointer>
#include <QPointF>
#include <QQmlEngine>
#include <QRectF>

QOOL_NS_BEGIN

class QoolBoxGadget;

// QoolBoxShapeControl：八边形几何单元（ShapeControl 子类，gadget 模式）。
//
// 重写说明（ADR-0004/0006/0007）：公开类型保留，内部实现替换为
// 两个 QoolBoxGadget——outer（borderWidth 0，外轮廓）+ inner（borderWidth =
// settings.borderWidth，referenceBox 指 outer——双实例描边内缩环）。本类
// 仅做转发：ext*/int* 16 点 + x/y 分量、usedWidth/usedHeight、四个 *Space、
// contains。几何计算全部在 gadget（算法独立单元，已通过单测）。
//
// 对外契约：几何读法面（ext*/int*/*Space/settings）沿用旧类命名，语法零改；
// 坐标系差异是刻意设计——ext*/int* 由旧版"期望尺寸本地系"（0..W）变为
// "target 坐标系绝对点"（gadget point = origin(control.center) + offset +
// vec + shrink）：消费方（变体 path/掩码/HUD）均挂接在 target（QoolBox）
// 内部，本地系一致。
//
// settings（QoolBoxSettings*，可绑定）：实例替换时 gadget 输入经
// QProperty 依赖追踪自动重挂（绑定 lambda 读 settings 链）；settings 为
// null 时按 0 输入退化计算（点退化为矩形原点，不崩溃）。
class QoolBoxShapeControl : public ShapeControl {
  Q_OBJECT
  QML_ELEMENT

  QBINDABLE_WRITABLE_PROPERTY(
      QoolBoxShapeControl, QoolBoxSettings*, settings)

public:
  explicit QoolBoxShapeControl(QObject* parent = nullptr);
  ~QoolBoxShapeControl() override;

  Q_INVOKABLE bool contains(const QPointF& point) const override;

  // —— 转发面：ext*/int* 16 点 + x/y 分量（gadget point 直通）——
  // 命名规范（与 gadget 一致）：首字母 = 点所在边、次字母 = 该边端点位置
  //（extTL = 外环 Top 边 Left 端点、intLT = 内环 Left 边 Top 端点）。
#define DECL_POINT(_N_)                                           \
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, QPointF, _N_)  \
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, _N_##x) \
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, _N_##y)

  QOOL_FOREACH_8(DECL_POINT, extTL, extTR, extLT, extLB, extRT, extRB,
      extBL, extBR)
  QOOL_FOREACH_8(DECL_POINT, intTL, intTR, intLT, intLB, intRT, intRB,
      intBL, intBR)
#undef DECL_POINT

  // —— 转发面：承载尺寸 / 内容内缩布局量 ——
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, usedWidth, FINAL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, usedHeight, FINAL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, topSpace, FINAL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, bottomSpace, FINAL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, leftSpace, FINAL)
  QBINDABLE_READONLY_PROPERTY(QoolBoxShapeControl, qreal, rightSpace, FINAL)

private:
  QoolBoxGadget* m_outer = nullptr;
  QoolBoxGadget* m_inner = nullptr;
  // 当前已连接字段信号的 settings 实例（QPointer——settings 析构自动置
  // null，disconnect 安全）。
  QPointer<QoolBoxSettings> m_connectedSettings;

  void setup_gadgets();
  void connect_settings();
  void sync_settings_to_gadgets();
  void setup_point_bindings();
  void setup_helper_bindings();
  void take_forward_bindings();
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_SHAPECONTROL_H
