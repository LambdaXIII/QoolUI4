#include "qool_shapecontrol.h"
#include "qool_shapecontrol_gadget.h"
#include "qoolcommon/debug.hpp"

#include <QTimer>

QOOL_NS_BEGIN

/*!
    \qmltype ShapeControl
    \inqmlmodule Qool
    \nativetype qoolui::ShapeControl
    \brief 形状控制点计算器基类：以 target 的几何为输入派生形状数据。

    ShapeControl 是 Qool 形状体系的几何派生基类（继承自
    \c SmartObject），绑定一个 \l target（QQuickItem）的几何，
    派生长边、短边、宽高比、中心、半宽半高与外接矩形等基础几何量。
    具体形状（如 \l QoolBoxShapeControl 的八边形）由子类在此基础上
    计算控制点。Gadget 挂载于本类型之下，经 \c control 关联并共享
    同一 target 几何。

    \section1 坐标系语义

    \l x/\l y 与 \l width/\l height 直接绑定 \l target 的对应属性。
    其中 \c width/\c height 是 target 的尺寸；\l x/\l y 是 target 在
    其父坐标系中的位移（位置）。

    \b{约定：形状几何量一律以 target 内部坐标系（原点在 target 左上角，
    范围 0..width/0..height）计算。} 因此 \l center、\l halfWidth、
    \l halfHeight 及子类控制点（如 QoolBoxShapeControl 的 ext* int*）
    均不含 \l x/\l y 偏移。

    \b{若期望 ShapeControl 直接使用 target 内部坐标系，则不应消费
    \l x/\l y 这两个值}——它们描述 target 在父坐标系中的位置，与内部
    坐标无关；内部坐标只需 \c width/\c height（及派生的 center/半宽半高）。
    \l boundingRect 是唯一合并 \l x/\l y 的派生量（父坐标系外接矩形），
    供基类 \l {contains()}{contains()} 兜底判定使用。

    \section1 target 关联

    \l target 缺省为声明父对象（\c componentComplete 时自动设置）；
    显式赋值（含 null）覆盖默认。target 为 null 时 \l x/\l y 取 0，
    \l width/\l height 取 0，派生量随之退化。

    \section1 命中判定扩展点

    \l {contains()}{contains()} 是命中判定的扩展点：基类按外接矩形
    判定，子类覆写为形状精确判定（数值算法，不依赖路径填充）。
    C++ 侧扩展通过子类化本类（或 ShapeControlGadget）实现。

    \section1 信号

    所有属性均经 Qt 自动生成的 \c xxxChanged 信号通知（值守卫：实际
    值变化才发出）。ShapeControl 自身不定义额外信号。
*/

/*!
    \qmlproperty Item ShapeControl::target
    \brief 几何来源 Item。缺省绑定为父对象（componentComplete 时自动
    设置）；显式赋值（含 null）覆盖默认。见「target 关联」。
*/

/*!
    \qmlproperty real ShapeControl::x
    \brief target 在其父坐标系中的水平位移（位置），只读绑定跟随
    \c target.x；target 为空时取 0。

    \b{坐标系注意}：x 是 target 的父坐标位置，不是 target 内部坐标。
    形状几何量（center/半宽半高/控制点）一律以 target 内部坐标系计算，
    不消费本值。若期望 ShapeControl 直接使用 target 内部坐标系，不应
    读取本属性。本值仅参与 \l boundingRect（父坐标系外接矩形）。
*/

/*!
    \qmlproperty real ShapeControl::y
    \brief target 在其父坐标系中的垂直位移（位置），只读绑定跟随
    \c target.y；target 为空时取 0。

    \b{坐标系注意}：同 \l x——y 是 target 的父坐标位置，不是 target
    内部坐标；形状几何量不消费本值，若期望使用 target 内部坐标系
    不应读取本属性。
*/

/*!
    \qmlproperty real ShapeControl::width
    \brief target 宽度，只读绑定跟随 \c target.width；target 为空时
    取 0。形状几何量以内部坐标系计算，本值即内部坐标系横向范围。
*/

/*!
    \qmlproperty real ShapeControl::height
    \brief target 高度，只读绑定跟随 \c target.height；target 为空时
    取 0。形状几何量以内部坐标系计算，本值即内部坐标系纵向范围。
*/

/*!
    \qmlproperty real ShapeControl::longEdge
    \brief 长边，max(width, height)。
*/

/*!
    \qmlproperty real ShapeControl::shortEdge
    \brief 短边，min(width, height)。
*/

/*!
    \qmlproperty real ShapeControl::aspectRatio
    \brief 宽高比，width / height；height 为 0 时取 -1。
*/

/*!
    \qmlproperty point ShapeControl::center
    \brief 中心点 (halfWidth, halfHeight)——target 内部坐标系，不含
    \l x/\l y 偏移。
*/

/*!
    \qmlproperty real ShapeControl::halfWidth
    \brief 半宽，width / 2。
*/

/*!
    \qmlproperty real ShapeControl::halfHeight
    \brief 半高，height / 2。
*/

/*!
    \qmlproperty rect ShapeControl::boundingRect
    \brief 外接矩形 (x, y, width, height)——父坐标系。是唯一合并
    \l x/\l y 的派生量，供基类 \l {contains()}{contains()} 兜底判定使用。
*/

ShapeControl::ShapeControl(QObject* parent)
  : SmartObject(parent) {
  setup_properties();
  connect_target_geometry();
  connect(this, &ShapeControl::targetChanged, this,
      [this] { connect_target_geometry(); });
}

// target 尺寸经信号连接同步（非 QProperty 绑定）：
// 绑定会注册对 target.width/height QProperty 的依赖——控件隐式尺寸拓扑下
//（无显式尺寸）target 尺寸经宿主 padding → *Space → 本对象 *Space/几何的
// 绑定链绕回 target 自身，绑定求值重入成环（QML "Binding loop detected"，
// QoolBGBox/BasicControl 隐式尺寸实例实证）。信号连接 → 写缓存 QProperty →
// 绑定重算 → 尺寸变化 → 信号……是收敛迭代（值稳定后信号不再发），Qt 对
// 赋值循环不报警告；target 析构时 QObject 连接自动断开（settings 同步同款
// 模式，析构安全）。
void ShapeControl::connect_target_geometry() {
  if (m_connectedTarget) {
    disconnect(m_connectedTarget, nullptr, this, nullptr);
    m_connectedTarget = nullptr;
  }
  const auto t = m_target.value();
  if (!t) {
    m_targetWidth = 0.0;
    m_targetHeight = 0.0;
    return;
  }
  m_connectedTarget = t;
  // 延迟同步（QTimer::singleShot(0, this)）：连接器可能在布局/绑定求值栈内
  // 执行（T.Control 自动跟随 setWidth 的 emit 栈）——同步写缓存会触发依赖
  // 绑定在同栈重算 → 重入成环（BasicControl 隐式尺寸实证）。延迟到事件循环
  // 后写入离开求值栈，尺寸变化 → 缓存同步 → 重算 → 再变化 变为收敛迭代；
  // context 对象 this 析构时定时器自动取消（析构安全）。代价：target 尺寸
  // 变化后 control 几何在事件循环内更新（QML 绑定消费方无感知差异）。
  const auto syncWidth = [this] {
    if (auto tt = m_connectedTarget)
      m_targetWidth = tt->width();
  };
  const auto syncHeight = [this] {
    if (auto tt = m_connectedTarget)
      m_targetHeight = tt->height();
  };
  connect(t, &QQuickItem::widthChanged, this, [this, syncWidth] {
    QTimer::singleShot(0, this, syncWidth);
  });
  connect(t, &QQuickItem::heightChanged, this, [this, syncHeight] {
    QTimer::singleShot(0, this, syncHeight);
  });
  syncWidth();
  syncHeight();
}

void ShapeControl::dumpInfo() const {
  xDebugQ << "target: " << target();
  xDebugQ << "boundingRect: " << boundingRect();
}

/*!
    \qmlmethod bool ShapeControl::contains(point)
    判断 \c point（局部坐标）是否落在形状内。

    基类实现按外接矩形判定；形状子类覆写为精确判定
    （如 QoolBoxShapeControl 的八边形线性不等式）。
*/
bool ShapeControl::contains(const QPointF& point) const {
  if (m_target) return m_target->boundingRect().contains(point);
  return boundingRect().contains(point);
}

void ShapeControl::appendChild(QObject* child) {
  SmartObject::appendChild(child);
  if (auto p_child = qobject_cast<ShapeControlGadget*>(child); p_child) {
    if (p_child->control() == nullptr) p_child->set_control(this);
  } else {
    xInfoQ << xDBGRed << child << xDBGReset "is not a ShapeControlGadget";
  }
}

void ShapeControl::componentComplete() {
  SmartObject::componentComplete();
  set_target(qobject_cast<QQuickItem*>(parent()));
}

void ShapeControl::setup_properties() {
  // QBINDABLE_SET_BINDING(target, [&] {
  //   const auto p = bindableParent().value();
  //   return qobject_cast<QQuickItem*>(p);
  // });

  QBINDABLE_SET_BINDING(x, [&] {
    if (auto t = m_target.value(); t) return t->bindableX().value();
    return 0.0;
  });
  QBINDABLE_SET_BINDING(y, [&] {
    if (auto t = m_target.value(); t) return t->bindableY().value();
    return 0.0;
  });
  QBINDABLE_SET_BINDING(width, [&] { return m_targetWidth.value(); }); // TEMP-DIAG
  QBINDABLE_SET_BINDING(height, [&] { return m_targetHeight.value(); }); // TEMP-DIAG

  QBINDABLE_SET_BINDING(longEdge, [&] { return std::max(width(), height()); });
  QBINDABLE_SET_BINDING(shortEdge, [&] { return std::min(width(), height()); });
  QBINDABLE_SET_BINDING(aspectRatio, [&] {
    const qreal h = height();
    return h == 0 ? -1 : width() / height();
  });
  QBINDABLE_SET_BINDING(center,
      [&] { return QPointF(m_halfWidth.value(), m_halfHeight.value()); });
  QBINDABLE_SET_BINDING(halfWidth, [&] { return width() / 2; });
  QBINDABLE_SET_BINDING(halfHeight, [&] { return height() / 2; });
  QBINDABLE_SET_BINDING(
      boundingRect, [&] { return QRectF(x(), y(), width(), height()); });
}

QOOL_NS_END
