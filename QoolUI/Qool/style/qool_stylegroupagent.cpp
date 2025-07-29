#include "qool_stylegroupagent.h"

#include "qool_style.h"
#include "qoolcommon/macro_foreach.hpp"

QOOL_NS_BEGIN

StyleGroupAgent::StyleGroupAgent(Style* parent)
  : QObject { parent } {
  set_parentStyle(parent);
}

void StyleGroupAgent::setValues(const QVariantMap& values) {
  const auto old_values = flatMap();
  m_defaultValues = values;
  m_values.clear();
  // m_modified.clear();
  Qt::beginPropertyUpdateGroup();

  for (auto iter = values.constBegin(); iter != values.constEnd();
    ++iter) {
    const QString key = iter.key();
    const QVariant value = iter.value();

#define __CHECK__(T, N)                                                \
  if (value != old_values.value(#N))                                   \
    emit N##Changed(value.value<T>());

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

QVariantMap StyleGroupAgent::flatMap() const {
  QVariantMap result = m_defaultValues;
  result.insert(m_values);
  return result;
}

void StyleGroupAgent::attachTo(StyleGroupAgent* other) {
  Qt::beginPropertyUpdateGroup();

  if (other) {
    setValues(other->flatMap());
  } else {
    setValues({});
  }

  connectTo(other);

  Qt::endPropertyUpdateGroup();
}

void StyleGroupAgent::connectTo(StyleGroupAgent* other) {
  if (other == m_parentAgent)
    return;
  if (m_parentAgent)
    disconnect(m_parentAgent);
  Qt::beginPropertyUpdateGroup();
  m_parentAgent = other;

  if (m_parentAgent) {
#define __HANDLE__(N)                                                  \
  connect(m_parentAgent, &StyleGroupAgent::N##Changed, this,           \
    &StyleGroupAgent::update_##N##_from_parent);

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
  } // if m_parentAgent
  Qt::endPropertyUpdateGroup();
}

#define IMPL(T, N)                                                     \
  T StyleGroupAgent::N() const {                                       \
    if (m_values.contains(#N))                                         \
      return m_values.value(#N).value<T>();                            \
    return m_defaultValues.value(#N).value<T>();                       \
  }                                                                    \
  void StyleGroupAgent::set_##N(const T& v) {                          \
    if (v == N())                                                      \
      return;                                                          \
    m_values.insert(#N, QVariant::fromValue<T>(v));                    \
    m_modified[#N] = true;                                             \
    emit N##Changed(v);                                                \
  }                                                                    \
  QBindable<T> StyleGroupAgent::bindable_##N() {                       \
    return QBindable<T> { this, #N };                                  \
  }                                                                    \
  void StyleGroupAgent::reset_##N() {                                  \
    T def_value = m_defaultValues.value(#N).value<T>();                \
    if (m_parentAgent)                                                 \
      def_value = m_parentAgent->N();                                  \
    m_values[#N] = QVariant::fromValue<T>(def_value);                  \
    m_modified.remove(#N);                                             \
    emit N##Changed(def_value);                                        \
  }                                                                    \
  void StyleGroupAgent::update_##N##_from_parent(const T& v) {         \
    const bool modified = m_modified.value(#N, false);                 \
    if (modified)                                                      \
      return;                                                          \
    m_values[#N] = QVariant::fromValue<T>(v);                          \
    emit N##Changed(v);                                                \
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
