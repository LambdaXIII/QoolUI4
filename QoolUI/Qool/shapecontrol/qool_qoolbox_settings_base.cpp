#include "qool_qoolbox_settings_base.h"

QOOL_NS_BEGIN

QoolBoxSettingsBase::QoolBoxSettingsBase(QObject* parent)
  : QObject { parent } {
  // 默认值保持旧 QoolBoxSettings 语义（cut* 由 qreal 默认 0；curved 默认
  // false 由 bool 默认——显式设置以明示契约）。borderColor/fillColor 的
  // 红/黄是 C++ 常量兜底：fallback 定案下 Style 默认由消费方（QoolBox 等）
  // 在实例化处显式绑定覆盖，未绑定前的瞬时值沿用旧类行为。
  QBINDABLE_SET_VALUE(offsetX, 0);
  QBINDABLE_SET_VALUE(offsetY, 0);
  QBINDABLE_SET_VALUE(borderWidth, 0);
  QBINDABLE_SET_VALUE(borderColor, Qt::red);
  QBINDABLE_SET_VALUE(fillColor, Qt::yellow);
  QBINDABLE_SET_VALUE(curved, false);
}

QOOL_NS_END
