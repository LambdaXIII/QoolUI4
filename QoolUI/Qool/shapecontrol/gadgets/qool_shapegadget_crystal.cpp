#include "qool_shapegadget_crystal.h"

QOOL_NS_BEGIN

/*!
    \qmltype CrystalGadget
    \inqmlmodule Qool
    \nativetype qoolui::CrystalGadget
    \brief 水晶六边形预制点（Gadget）：四角排除的八点模型。

    挂载于标准 \l ShapeControl 之下（ShapeControl 子对象自动关联 control），
    以自身 \c target 的几何为输入（\c x/y/width/height 绑定 target），提供
    八点（\c TL/TC/TR/RT/RB/BC/LB/LT）与 \c cutSize（shortEdge/2）中间量。
    同一模型覆盖三种形态：

    \list
        \li \c width > \c height：六边形（顶/底边 + 左右斜边 + 左右直边缩为点）；
        \li \c width = \c height：菱形（旋转 45° 的正方形——四点重合收缩，
            路径自然闭合）；
        \li \c width < \c height：瘦六边形（上下尖点 TC/BC + 左右直边——
            可直接作为竖直滑块背景；TL/TR/LB/LT 等点共线于直边，路径合法）。
    \endlist

    设计为单层外轮廓模型（无内缩边框环）——消费方（Crystal 组件）只使用
    外轮廓点与细描边，不存在 QoolBoxShapeControl 双层模型在切角极限（顶点
    重合）时内边缘反向三角形的问题。轨道/手柄同模型（宽条六边形 / 方形
    菱形），斜边斜率一致天然对齐。

    \section2 性能

    中间量直接链基类 ShapeControl 的 bindable（\c halfWidth/halfHeight/
    \c shortEdge——不重复计算 \c w/2、\c min(w,h)），八点绑定只引用中间量
    与 \c width/\c height（bindable 缓存）；依赖按依赖图按需触发。基类
    已有的量（halfWidth/halfHeight）经本 gadget 透传引用（绑定在 control
    设置后经依赖追踪自动生效）。

    \section2 易误解点
    \list
    \li 八点路径 \c TL→TC→TR→RT→RB→BC→LB→LT→闭合 对三种形态统一有效——
        重合/共线点是合法冗余（如菱形时 TL=TC=TR），无需路径分支。
    \li 几何全部链 \c control（x/y/width/height 与中间量都取自基类 ShapeControl
        ——不重复从 target 获取）；无需显式设置 \c target（control 的 target
        由 ShapeControl 基类在组件完成时自动取父）。
    \endlist
*/
CrystalGadget::CrystalGadget(QObject* parent)
  : ShapeControlGadget(parent) {
  // 几何直接链 control（基类 ShapeControl 已有 x/y/width/height——绑定
  // control 的 target——gadget 不重复从 target 获取；setBinding 激活时
  // 立即求值一次——此时 control 尚未设置（appendChild 在构造后）——
  // 必须守卫 null（control 设置后经 bindable 依赖自动重求值））
  QBINDABLE_SET_BINDING(x, [&] {
    const auto c = bindable_control().value();
    return c ? c->bindable_x().value() : 0.0;
  });
  QBINDABLE_SET_BINDING(y, [&] {
    const auto c = bindable_control().value();
    return c ? c->bindable_y().value() : 0.0;
  });
  QBINDABLE_SET_BINDING(width, [&] {
    const auto c = bindable_control().value();
    return c ? c->bindable_width().value() : 0.0;
  });
  QBINDABLE_SET_BINDING(height, [&] {
    const auto c = bindable_control().value();
    return c ? c->bindable_height().value() : 0.0;
  });

  // 中间量直接链基类（ShapeControl 已有 halfWidth/halfHeight/shortEdge——
  // 不重复计算；gadget 构造时 control 尚未设置（appendChild 在构造后），
  // 故用 setBinding + 守卫 + bindable 依赖追踪（等价 bindTo 链，control
  // 设置后依赖触发自动重求值））
  m_halfWidth.setBinding([&] {
    const auto c = bindable_control().value();
    return c ? c->bindable_halfWidth().value() : 0.0;
  });
  m_halfHeight.setBinding([&] {
    const auto c = bindable_control().value();
    return c ? c->bindable_halfHeight().value() : 0.0;
  });
  m_cutSize.setBinding([&] {
    const auto c = bindable_control().value();
    return c ? c->bindable_shortEdge().value() / 2 : 0.0;
  });

  // 顶边三点（TL/TR 为斜边交点、TC 为顶边中点——w < h 时三者重合于尖点）
  QBINDABLE_SET_BINDING(TLx, [&] { return m_cutSize.value(); });
  QBINDABLE_SET_BINDING(TLy, [&] { return 0.0; });
  QBINDABLE_SET_BINDING(TCx, [&] { return m_halfWidth.value(); });
  QBINDABLE_SET_BINDING(TCy, [&] { return 0.0; });
  QBINDABLE_SET_BINDING(TRx, [&] { return bindable_width().value() - m_cutSize.value(); });
  QBINDABLE_SET_BINDING(TRy, [&] { return 0.0; });
  // 右边两端：RT = 右边距上 cut（w >= h 时 cut = h/2 恰为中点——右尖；
  // w < h 时右直边顶——位置关系稳定）；RB **跨边**——w >= h：下边距右
  // cut（底边右端）；w < h：右边距下 cut（右直边底）
  // （位置关系推演见 .scratch/slider/crystal-geometry.md——无条件定义曾致
  // w>h 时底边两端缺失、形状塌成 5 边形"钻石"）
  QBINDABLE_SET_BINDING(RTx, [&] { return bindable_width().value(); });
  QBINDABLE_SET_BINDING(RTy, [&] { return m_cutSize.value(); });
  QBINDABLE_SET_BINDING(RBx, [&] {
    return bindable_width().value() >= bindable_height().value()
        ? bindable_width().value() - m_cutSize.value()
        : bindable_width().value();
  });
  QBINDABLE_SET_BINDING(RBy, [&] {
    return bindable_width().value() >= bindable_height().value()
        ? bindable_height().value()
        : bindable_height().value() - m_cutSize.value();
  });
  // 底边三点（BC = 下边中点——稳定；w < h 时 BC 为底尖）
  QBINDABLE_SET_BINDING(BCx, [&] { return m_halfWidth.value(); });
  QBINDABLE_SET_BINDING(BCy, [&] { return bindable_height().value(); });
  // 左边两端：LT = 左边距上 cut（w >= h 时恰为中点——左尖；w < h 时左直边
  // 顶——位置关系稳定）；LB **跨边**——w >= h：下边距左 cut（底边左端）；
  // w < h：左边距下 cut（左直边底）
  QBINDABLE_SET_BINDING(LBx, [&] {
    return bindable_width().value() >= bindable_height().value()
        ? m_cutSize.value()
        : 0.0;
  });
  QBINDABLE_SET_BINDING(LBy, [&] {
    return bindable_width().value() >= bindable_height().value()
        ? bindable_height().value()
        : bindable_height().value() - m_cutSize.value();
  });
  QBINDABLE_SET_BINDING(LTx, [&] { return 0.0; });
  QBINDABLE_SET_BINDING(LTy, [&] { return m_cutSize.value(); });

#define SETUP(NAME)                                                       \
  QBINDABLE_SET_BINDING(NAME,                                             \
      [&] { return QPointF(m_##NAME##x.value(), m_##NAME##y.value()); });
  QOOL_FOREACH_8(SETUP, TL, TC, TR, RT, RB, BC, LB, LT)
#undef SETUP
}

/*!
    \qmlmethod bool CrystalGadget::contains(point point)
    \brief 精确命中判定：外接矩形内除四角切角域外全部命中。

    算法（与 HalfCrystal 掩码同族）：外接矩形粗判 + 四角等腰直角三角形
    排除——直角边 = \c cutSize（shortEdge/2）、斜边 \c{dx+dy < cutSize}
    （开集语义：斜边与八点顶点命中）。point 为组件本地坐标
    （引擎已逆变换，无 x/y 偏移依赖）。
*/
bool CrystalGadget::contains(const QPointF& point) const {
  // ① Rect 粗判（整外接矩形——含边界）
  const qreal w = m_width.value();
  const qreal h = m_height.value();
  if (!QRectF(0, 0, w, h).contains(point))
    return false;

  // ② 四角域统一排除（内部正方形四角各一直角等腰三角形）
  //    角域直角顶点在正方形角、直角边沿坐标轴、斜边斜率 -1；
  //    判定 dx >= 0 && dy >= 0 && dx + dy < cutSize（< 保证斜边命中）
  const qreal cut = m_cutSize.value(); // shortEdge / 2

  // 左上角域：原点 (0,0)
  if (cut - point.x() >= 0 && cut - point.y() >= 0
      && (cut - point.x()) + (cut - point.y()) < cut)
    return false;

  // 右上角域：原点 (w-cut, 0)
  if (point.x() - (w - cut) >= 0 && cut - point.y() >= 0
      && (point.x() - (w - cut)) + (cut - point.y()) < cut)
    return false;

  // 右下角域：原点 (w-cut, h-cut)
  if (point.x() - (w - cut) >= 0 && point.y() - (h - cut) >= 0
      && (point.x() - (w - cut)) + (point.y() - (h - cut)) < cut)
    return false;

  // 左下角域：原点 (0, h-cut)
  if (cut - point.x() >= 0 && point.y() - (h - cut) >= 0
      && (cut - point.x()) + (point.y() - (h - cut)) < cut)
    return false;

  return true;
}

QOOL_NS_END
