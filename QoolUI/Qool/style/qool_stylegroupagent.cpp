#include "qool_stylegroupagent.h"

#include "qool_style.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/macro_foreach.hpp"

QOOL_NS_BEGIN

StyleGroupAgent::StyleGroupAgent(Style* parent)
  : QObject { parent } {
  setParentStyle(parent);
}

void StyleGroupAgent::setData(const QVariantMap& data) {
  m_data.insert(data);
  if (m_customed)
    return;
  Qt::beginPropertyUpdateGroup();

  for (auto iter = data.constBegin(); iter != data.constEnd(); ++iter) {
#define __CHECK__(T, N)                                                \
  if (iter.key() == #N) {                                              \
    if (! m_##N##Customed)                                             \
      m_##N.setValue(iter.value().value<T>());                         \
    continue;                                                          \
  }

#define __HANDLE__(N) __CHECK__(QColor, N)
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
#undef __HANDLE__

#define __HANDLE__(N) __CHECK__(int, N)
    QOOL_FOREACH_8(__HANDLE__, textSize, titleTextSize, toolTipTextSize,
      importantTextSize, decorativeTextSize, controlTitleTextSize,
      controlTextSize, windowTitleTextSize)
#undef __HANDLE__

#define __HANDLE__(N) __CHECK__(qreal, N)
    QOOL_FOREACH_3(
      __HANDLE__, instantDuration, transitionDuration, movementDuration)
    QOOL_FOREACH_5(__HANDLE__, menuCutSize, buttonCutSize,
      controlCutSize, windowCutSize, dialogCutSize)
    QOOL_FOREACH_3(__HANDLE__, controlBorderWidth, windowBorderWidth,
      dialogBorderWidth)
    QOOL_FOREACH_2(__HANDLE__, windowElementSpacing, windowEdgeSpacing)
#undef __HANDLE__

    __CHECK__(QStringList, papaWords)

#undef __CHECK__
  } // for

  Qt::endPropertyUpdateGroup();
}

void StyleGroupAgent::setParentStyle(Style* s) {
  m_parentStyle = s;
}

Style* StyleGroupAgent::parentStyle() const {
  return m_parentStyle;
}

void StyleGroupAgent::inherit(StyleGroupAgent* other) {
  m_data = other->m_data;
#define __HANDLE__(N)                                                  \
  if (! m_##N##Customed)                                               \
    m_##N.setValue(other->N());
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
  QOOL_FOREACH_2(__HANDLE__, windowElementSpacing, windowEdgeSpacing)
  __HANDLE__(papaWords)
#undef __HANDLE__
}

#define IMPL(T, N)                                                     \
  T StyleGroupAgent::N() const {                                       \
    return m_##N.value();                                              \
  }                                                                    \
  void StyleGroupAgent::set_##N(const T& v) {                          \
    m_##N = v;                                                         \
    m_##N##Customed = true;                                            \
  }                                                                    \
  QBindable<T> StyleGroupAgent::bindable_##N() {                       \
    return &m_##N;                                                     \
  }                                                                    \
  void StyleGroupAgent::reset_##N() {                                  \
    m_##N = m_data.value(#N).value<T>();                               \
    m_##N##Customed = false;                                           \
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
