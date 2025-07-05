#include "qool_stylegroupagent.h"

#include "qool_style.h"
#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

StyleGroupAgent::StyleGroupAgent(Theme::Groups group, Style* parent)
  : QObject { parent }
  , m_group { group }
  , m_parentStyle { parent } {
  connect(this, &StyleGroupAgent::customedValueChanged, parent,
    &Style::groupCustomedValueChanged);
}

QStringList StyleGroupAgent::inherit_customedValues(
  StyleGroupAgent* other) {
  QStringList keys;
  keys << m_customedValue.keys() << other->m_customedValue.keys();
  m_customedValue = other->m_customedValue;
  return keys;
}

void StyleGroupAgent::set_customedValue(
  const QString& key, const QVariant& value) {
  m_customedValue.insert(key, value);
  emit customedValueChanged(m_group, key, value);
}

#define IMPL(T, N)                                                     \
  T StyleGroupAgent::N() const {                                       \
    if (m_customedValue.contains(#N))                                  \
      return m_customedValue.value(#N).value<T>();                     \
    if (! m_parentStyle)                                               \
      return {};                                                       \
    return m_parentStyle->m_currentTheme.value(m_group, #N)            \
      .value<T>();                                                     \
  }                                                                    \
  void StyleGroupAgent::set_##N(const T& x) {                          \
    const auto old = N();                                              \
    if (old == x)                                                      \
      return;                                                          \
    set_customedValue(#N, QVariant::fromValue<T>(x));                  \
    if (m_parentStyle && m_parentStyle->m_current.value() == this)     \
      m_parentStyle->notify_property_changes({ #N });                  \
  }

#define __COLOR(N) IMPL(QColor, N)
QOOL_FOREACH_10(__COLOR, white, silver, grey, black, red, maroon,
  yellow, olive, lime, green)
QOOL_FOREACH_10(__COLOR, aqua, cyan, teal, blue, navy, fuchsia, purple,
  orange, brown, pink)
QOOL_FOREACH_3(__COLOR, positive, negative, warning)
QOOL_FOREACH_3(
  __COLOR, controlBackgroundColor, controlBorderColor, infoColor)
QOOL_FOREACH_10(__COLOR, accent, light, midlight, dark, mid, shadow,
  highlight, highlightedText, link, linkVisited)
QOOL_FOREACH_10(__COLOR, text, base, alternateBase, window, windowText,
  button, buttonText, placeholderText, toolTipBase, toolTipText)
#undef __COLOR

#define __INT(N) IMPL(int, N)
QOOL_FOREACH_8(__INT, textSize, titleTextSize, toolTipTextSize,
  importantTextSize, decorativeTextSize, controlTitleTextSize,
  controlTextSize, windowTitleTextSize)
#undef __INT

#define __REAL(N) IMPL(qreal, N)
QOOL_FOREACH_3(
  __REAL, instantDuration, transitionDuration, movementDuration)
QOOL_FOREACH_5(__REAL, menuCutSize, buttonCutSize, controlCutSize,
  windowCutSize, dialogCutSize)
QOOL_FOREACH_3(
  __REAL, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
QOOL_FOREACH_2(__REAL, windowElementSpacing, windowEdgeSpacing)
#undef __REAL

IMPL(QStringList, papaWords)
IMPL(bool, animationEnabled)

#undef IMPL

QOOL_NS_END
