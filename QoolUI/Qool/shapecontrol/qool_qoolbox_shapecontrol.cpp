#include "qool_qoolbox_shapecontrol.h"

#include "gadgets/qool_shapegadget_qoolbox.h"

#include <QQuickItem>

QOOL_NS_BEGIN

QoolBoxShapeControl::QoolBoxShapeControl(QObject* parent)
  : ShapeControl { parent } {
  // settings 属性变化（实例替换/引擎绑定更新）→ 重连字段信号并同步。
  connect(this, &QoolBoxShapeControl::settingsChanged, this,
      [this] { connect_settings(); });
  setup_gadgets();
  connect_settings();
  setup_point_bindings();
  setup_helper_bindings();
}

QoolBoxShapeControl::~QoolBoxShapeControl() {
  // 断链顺序（QProperty 析构通知语义——依赖方必须早于被依赖方析构，
  // 否则被依赖方析构时通知依赖方绑定重算、读取已析构对象导致崩溃）：
  // 1) 断开 control→gadget 的全部转发绑定（依赖 gadget 的 QProperty）；
  // 2) inner 依赖 outer（referenceBox）——inner（依赖方）先删。
  take_forward_bindings();
  m_inner->setParent(nullptr);
  delete m_inner;
  m_outer->setParent(nullptr);
  delete m_outer;
}

void QoolBoxShapeControl::setup_gadgets() {
  m_outer = new QoolBoxGadget(this);
  m_inner = new QoolBoxGadget(this);

  // 双实例描边链（ADR-0006）：outer = 外轮廓（borderWidth 0）、inner =
  // 内缩环（borderWidth = settings.borderWidth；referenceBox 指 outer——
  // 5 介入点 ref 优先 null 回退，inner 的 used/vec/cut 全部跟随 outer）。
  m_inner->set_referenceBox(m_outer);

  // gadget 几何基座：从本 control 读期望尺寸/中心（ShapeControl target 链）。
  m_outer->set_control(this);
  m_inner->set_control(this);

  // outer 恒为外轮廓。
  m_outer->set_borderWidth(0);
}

// settings → gadget 输入同步（信号连接而非 QProperty 绑定）：
// QProperty 绑定会注册对 settings 字段 QProperty 的依赖——settings 对象
// 析构时（字段 QProperty 先于 ~QObject 析构）触发绑定重算，读取已析构
// 对象崩溃。信号连接在 settings 析构时由 QObject 自动断开——settings
// 生命周期短于本对象是安全的（spec D1「绑定/信号连接」选信号连接）。
void QoolBoxShapeControl::connect_settings() {
  // 先断开旧实例连接（记录在 m_connectedSettings——settings 属性变化时
  // bindable_settings() 已返回新值，不能从新值反查旧连接）。
  if (m_connectedSettings) {
    disconnect(m_connectedSettings, nullptr, this, nullptr);
    m_connectedSettings = nullptr;
  }
  const auto s = bindable_settings().value();
  if (!s) {
    sync_settings_to_gadgets();
    return;
  }
  m_connectedSettings = s;
  const auto sync = [this] { sync_settings_to_gadgets(); };
  connect(s, &QoolBoxSettings::cutSizeTLChanged, this, sync);
  connect(s, &QoolBoxSettings::cutSizeTRChanged, this, sync);
  connect(s, &QoolBoxSettings::cutSizeBLChanged, this, sync);
  connect(s, &QoolBoxSettings::cutSizeBRChanged, this, sync);
  connect(s, &QoolBoxSettings::borderWidthChanged, this, sync);
  connect(s, &QoolBoxSettings::offsetXChanged, this, sync);
  connect(s, &QoolBoxSettings::offsetYChanged, this, sync);
  sync_settings_to_gadgets();
}

void QoolBoxShapeControl::sync_settings_to_gadgets() {
  const auto s = bindable_settings().value();
  const qreal tl = s ? s->cutSizeTL() : 0.0;
  const qreal tr = s ? s->cutSizeTR() : 0.0;
  const qreal bl = s ? s->cutSizeBL() : 0.0;
  const qreal br = s ? s->cutSizeBR() : 0.0;
  const qreal ox = s ? s->offsetX() : 0.0;
  const qreal oy = s ? s->offsetY() : 0.0;
  m_outer->set_cutTL(tl);
  m_outer->set_cutTR(tr);
  m_outer->set_cutBL(bl);
  m_outer->set_cutBR(br);
  m_outer->set_offsetX(ox);
  m_outer->set_offsetY(oy);
  m_inner->set_cutTL(tl);
  m_inner->set_cutTR(tr);
  m_inner->set_cutBL(bl);
  m_inner->set_cutBR(br);
  m_inner->set_offsetX(ox);
  m_inner->set_offsetY(oy);
  m_inner->set_borderWidth(s ? s->borderWidth() : 0.0);
}

void QoolBoxShapeControl::setup_point_bindings() {
  // ext* = outer 外轮廓点、int* = inner 内缩环点；分量 = 点属性再投影
  //（依赖整个点——单轴变化多触发一次加法，属性面简洁优先）。
#define CONNECT_EXT(_N_)                                                      \
  m_ext##_N_.setBinding([&] { return m_outer->point##_N_(); });               \
  m_ext##_N_##x.setBinding([&] { return m_ext##_N_.value().x(); });           \
  m_ext##_N_##y.setBinding([&] { return m_ext##_N_.value().y(); });
  QOOL_FOREACH_8(CONNECT_EXT, TL, TR, RT, RB, BR, BL, LB, LT)
#undef CONNECT_EXT

#define CONNECT_INT(_N_)                                                      \
  m_int##_N_.setBinding([&] { return m_inner->point##_N_(); });               \
  m_int##_N_##x.setBinding([&] { return m_int##_N_.value().x(); });           \
  m_int##_N_##y.setBinding([&] { return m_int##_N_.value().y(); });
  QOOL_FOREACH_8(CONNECT_INT, TL, TR, RT, RB, BR, BL, LB, LT)
#undef CONNECT_INT
}

void QoolBoxShapeControl::setup_helper_bindings() {
  // 承载尺寸 = 外环 used（inner 经 referenceBox 链与 outer 一致）。
  m_usedWidth.setBinding([&] { return m_outer->usedWidth(); });
  m_usedHeight.setBinding([&] { return m_outer->usedHeight(); });

  // *Space（ADR-0002 定案公式）：max(0, max(相邻 cut) − (used − 期望)/2)。
  // top/bottom 取垂直轴（usedHeight vs height）、left/right 取水平轴
  //（usedWidth vs width）；相邻 cut 按边取两角（top = TL/TR 等）。cut 为
  // 硬参数——溢出时内容盒从 used 系换算回期望系（每侧减溢出/2）；钳 0
  // 因 *Space 是排版参考值，负值徒增消费复杂度。
  // cut 读数取 outer gadget 的 cut 输入（信号同步更新，settings 析构
  // 安全——不直接依赖 settings 字段 QProperty；析构序内受
  // take_forward_bindings 覆盖）。
  m_topSpace.setBinding([&] {
    const qreal cut = qMax(m_outer->bindable_cutTL().value(),
        m_outer->bindable_cutTR().value());
    return qMax(0.0,
        cut - (m_outer->usedHeight() - bindable_height().value()) / 2.0);
  });
  m_bottomSpace.setBinding([&] {
    const qreal cut = qMax(m_outer->bindable_cutBL().value(),
        m_outer->bindable_cutBR().value());
    return qMax(0.0,
        cut - (m_outer->usedHeight() - bindable_height().value()) / 2.0);
  });
  m_leftSpace.setBinding([&] {
    const qreal cut = qMax(m_outer->bindable_cutTL().value(),
        m_outer->bindable_cutBL().value());
    return qMax(0.0,
        cut - (m_outer->usedWidth() - bindable_width().value()) / 2.0);
  });
  m_rightSpace.setBinding([&] {
    const qreal cut = qMax(m_outer->bindable_cutTR().value(),
        m_outer->bindable_cutBR().value());
    return qMax(0.0,
        cut - (m_outer->usedWidth() - bindable_width().value()) / 2.0);
  });
}

void QoolBoxShapeControl::take_forward_bindings() {
  // 断开全部依赖 gadget 的转发绑定（析构序：被依赖方 gadget 稍后析构，
  // 若此处不先断开，gadget 析构时通知这些绑定重算——读取已析构的
  // gadget 崩溃）。
#define TAKE_POINT(_N_)              \
  m_##_N_.takeBinding();             \
  m_##_N_##x.takeBinding();          \
  m_##_N_##y.takeBinding();
  QOOL_FOREACH_8(TAKE_POINT, extTL, extTR, extLT, extLB, extRT, extRB, extBL,
      extBR)
  QOOL_FOREACH_8(TAKE_POINT, intTL, intTR, intLT, intLB, intRT, intRB, intBL,
      intBR)
#undef TAKE_POINT
  m_usedWidth.takeBinding();
  m_usedHeight.takeBinding();
  m_topSpace.takeBinding();
  m_bottomSpace.takeBinding();
  m_leftSpace.takeBinding();
  m_rightSpace.takeBinding();
}

bool QoolBoxShapeControl::contains(const QPointF& point) const {
  // 命中判定委托 outer gadget（外轮廓语义；gadget contains 接受 target
  // 内部坐标系点，内部已做 origin/offset 逆变换——与旧 control 行为等价）。
  return m_outer->contains(point);
}

QOOL_NS_END
