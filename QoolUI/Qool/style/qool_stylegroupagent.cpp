#include "qool_stylegroupagent.h"

#include "qool_style.h"
#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

StyleGroupAgent::StyleGroupAgent(Theme::Groups group, Style* parent)
  : QObject { parent }
  , m_group { group }
  , m_parentStyle { parent } {
}

#define IMPL(T, N)                                                     \
  T StyleGroupAgent::N() const {                                       \
    if (! m_parentStyle)                                               \
      return {};                                                       \
    return m_parentStyle->get_value(m_group, #N).value<T>();           \
  }                                                                    \
  void StyleGroupAgent::set_##N(const T& x) {                          \
    const auto old = N();                                              \
    if (old == x || m_parentStyle == nullptr)                          \
      return;                                                          \
    xDebugQ << #N << x;                                                \
    m_parentStyle->set_value(m_group, #N, QVariant::fromValue<T>(x));  \
    if (m_group == m_parentStyle->currentGroup())                      \
      emit m_parentStyle->N##Changed();                                \
    emit N##Changed();                                                 \
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
