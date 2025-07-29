#include "qool_stylegroupagent.h"

#include "qool_style.h"
#include "qoolcommon/macro_foreach.hpp"

QOOL_NS_BEGIN

StyleGroupAgent::StyleGroupAgent(int group, Style* parent)
  : QObject { parent }
  , m_group(group)
  , m_parentStyle(parent) {
  connect(m_parentStyle, &Style::valueChanged, this,
    &StyleGroupAgent::when_parentValueChanged);
}

void StyleGroupAgent::when_parentValueChanged(int group, QString key) {
  if (group != m_group)
    return;
#define __HANDLE__(N)                                                  \
  if (key == QStringLiteral(#N))                                       \
    emit N##Changed();
  QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, maroon,
    yellow, olive, lime, green)
  QOOL_FOREACH_10(__HANDLE__, aqua, cyan, teal, blue, navy, fuchsia,
    purple, orange, brown, pink)
  QOOL_FOREACH_3(__HANDLE__, positive, negative, warning)
  QOOL_FOREACH_3(
    __HANDLE__, controlBackgroundColor, controlBorderColor, infoColor)
  QOOL_FOREACH_10(__HANDLE__, accent, light, midlight, dark, mid,
    shadow, highlight, highlightedText, link, linkVisited)
  QOOL_FOREACH_10(__HANDLE__, text, base, alternateBase, window,
    windowText, button, buttonText, placeholderText, toolTipBase,
    toolTipText)
  QOOL_FOREACH_8(__HANDLE__, textSize, titleTextSize, toolTipTextSize,
    importantTextSize, decorativeTextSize, controlTitleTextSize,
    controlTextSize, windowTitleTextSize)
  QOOL_FOREACH_3(
    __HANDLE__, instantDuration, transitionDuration, movementDuration)
  QOOL_FOREACH_5(__HANDLE__, menuCutSize, buttonCutSize, controlCutSize,
    windowCutSize, dialogCutSize)
  QOOL_FOREACH_3(__HANDLE__, controlBorderWidth, windowBorderWidth,
    dialogBorderWidth)
  QOOL_FOREACH_3(
    __HANDLE__, windowElementSpacing, windowEdgeSpacing, papaWords)
#undef __HANDLE__
}

#define IMPL(T, N)                                                     \
  T StyleGroupAgent::N() const {                                       \
    return m_parentStyle->get_value(m_group, QStringLiteral(#N))       \
      .value<T>();                                                     \
  }                                                                    \
  void StyleGroupAgent::set_##N(const T& v) {                          \
    static const QString key { QStringLiteral(#N) };                   \
    const QVariant value = QVariant::fromValue<T>(v);                  \
    const bool result = m_parentStyle->set_value(m_group, key, value); \
    if (result)                                                        \
      m_parentStyle->mark_modified(m_group, key);                      \
  }

#define __HANDLE__(N) IMPL(QColor, N)
QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, maroon,
  yellow, olive, lime, green)
QOOL_FOREACH_10(__HANDLE__, aqua, cyan, teal, blue, navy, fuchsia,
  purple, orange, brown, pink)
QOOL_FOREACH_3(__HANDLE__, positive, negative, warning)
QOOL_FOREACH_3(
  __HANDLE__, controlBackgroundColor, controlBorderColor, infoColor)
QOOL_FOREACH_10(__HANDLE__, accent, light, midlight, dark, mid, shadow,
  highlight, highlightedText, link, linkVisited)
QOOL_FOREACH_10(__HANDLE__, text, base, alternateBase, window,
  windowText, button, buttonText, placeholderText, toolTipBase,
  toolTipText)
#undef __HANDLE__

#define __HANDLE__(N) IMPL(int, N)
QOOL_FOREACH_8(__HANDLE__, textSize, titleTextSize, toolTipTextSize,
  importantTextSize, decorativeTextSize, controlTitleTextSize,
  controlTextSize, windowTitleTextSize)
#undef __HANDLE__

#define __HANDLE__(N) IMPL(qreal, N)
QOOL_FOREACH_3(
  __HANDLE__, instantDuration, transitionDuration, movementDuration)
QOOL_FOREACH_5(__HANDLE__, menuCutSize, buttonCutSize, controlCutSize,
  windowCutSize, dialogCutSize)
QOOL_FOREACH_3(
  __HANDLE__, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
QOOL_FOREACH_2(__HANDLE__, windowElementSpacing, windowEdgeSpacing)
#undef __HANDLE__

IMPL(QStringList, papaWords)

#undef IMPL

QOOL_NS_END
