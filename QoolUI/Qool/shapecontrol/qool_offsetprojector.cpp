#include "qool_offsetprojector.h"

QOOL_NS_BEGIN

//**QoolUI中没有光！**

OffsetProjector::OffsetProjector(QObject* parent)
  : QObject{parent} {
  // 单绑定链：归一化 → 点积 → 退化短路 → 数乘。结果经 QObjectBindableProperty
  // 内置相等守卫——实际值未变不发 offsetChanged（refDistance==0 时方向输入
  // 变化仍重算但恒零向量 → 不传播；恢复非零自动恢复链条）。
  QBINDABLE_SET_BINDING(offset, [&] {
    const QVector2D m = bindable_direction().value().normalized();
    const QVector2D r = bindable_refDirection().value().normalized();
    const qreal d = bindable_refDistance().value();
    if (d == 0)
      return QVector2D();
    const float proj = QVector2D::dotProduct(m, r);
    if (qFuzzyIsNull(proj))
      return QVector2D();
    return m * (float(d) / proj);
  });
}

QBindable<QVector2D> OffsetProjector::bindable_direction() {
  return QBindable<QVector2D>(this, "direction");
}

QBindable<QVector2D> OffsetProjector::bindable_refDirection() {
  return QBindable<QVector2D>(this, "refDirection");
}

QBindable<qreal> OffsetProjector::bindable_refDistance() {
  return QBindable<qreal>(this, "refDistance");
}

QOOL_NS_END
