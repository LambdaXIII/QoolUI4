#include "qool_singleton.h"

QOOL_NS_BEGIN

QoolSingleton::QoolSingleton(QObject* parent)
  : SmartObject(parent)
  , m_positions { new Extension_Positions(this) }
  , m_style { new StyleAgent(this) } {
  m_animationEnabled.setBinding(
    [&] { return style()->bindable_animationEnabled().value(); });
}

bool QoolSingleton::animationEnabled() const {
  return m_animationEnabled.value();
}

void QoolSingleton::set_animationEnabled(const bool& enabled) {
  return style()->set_animationEnabled(enabled);
}

QOOL_NS_END