#include "qool_shapecontrol.h"
#include "qool_shapecontrol_gadget.h"
#include "qoolcommon/debug.hpp"

#include <QTimer>

QOOL_NS_BEGIN

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
// 隐式尺寸拓扑的已知表现）。信号连接 → 写缓存 QProperty →
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
  // 绑定在同栈重算 → 重入成环（隐式尺寸拓扑）。延迟到事件循环
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
