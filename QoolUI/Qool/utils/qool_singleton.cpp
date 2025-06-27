#include "qool_singleton.h"

QOOL_NS_BEGIN

QoolSingleton::QoolSingleton(QObject* parent)
  : SmartObject(parent)
  , m_positions { new Extension_Positions(this) }
  , m_style { new StyleAgent(this) } {
}

QOOL_NS_END