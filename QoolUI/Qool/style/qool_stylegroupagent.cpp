#include "qool_stylegroupagent.h"

#include "qool_style.h"

QOOL_NS_BEGIN

StyleGroupAgent::StyleGroupAgent(Theme::Groups group, Style* parent)
  : QObject { parent }
  , m_group { group }
  , m_parentStyle { parent } {
  connect(m_parentStyle, &Style::internalValuesChanged, this,
    [&](Theme::Groups group, const QSet<QString>& keys) {
      // if (group != m_group)
      //   return;
      dispatchValueSignals(keys);
    });
}

QVariant StyleGroupAgent::value(
  const QString& key, const QVariant& defvalue) const {
  return m_parentStyle->value(m_group, key, defvalue);
}

void StyleGroupAgent::setValue(
  const QString& key, const QVariant& value) {
  setParentValue(key, value);
}

void StyleGroupAgent::setParentValue(
  const QString& key, const QVariant& value) {
  if (! m_parentStyle)
    return;
  m_parentStyle->setValue(m_group, key, value);
}

void StyleGroupAgent::dispatchValueSignals(QSet<QString> keys) {
  Qt::beginPropertyUpdateGroup();
  for (const auto& key : std::as_const(keys)) {
    emit valueChanged(key);

#define CHECK(N)                                                       \
  if (key == #N)                                                       \
    emit N##Changed();
    QOOL_FOREACH_10(CHECK, white, silver, grey, black, red, maroon,
      yellow, olive, lime, green)
    QOOL_FOREACH_10(CHECK, aqua, cyan, teal, blue, navy, fuchsia,
      purple, orange, brown, pink)
    QOOL_FOREACH_3(CHECK, positive, negative, warning)
    QOOL_FOREACH_3(
      CHECK, controlBackgroundColor, controlBorderColor, infoColor)
    QOOL_FOREACH_10(CHECK, accent, light, midlight, dark, mid, shadow,
      highlight, highlightedText, link, linkVisited)
    QOOL_FOREACH_10(CHECK, text, base, alternateBase, window,
      windowText, button, buttonText, placeholderText, toolTipBase,
      toolTipText)
    QOOL_FOREACH_8(CHECK, textSize, titleTextSize, toolTipTextSize,
      importantTextSize, decorativeTextSize, controlTitleTextSize,
      controlTextSize, windowTitleTextSize)
    QOOL_FOREACH_3(
      CHECK, instantDuration, transitionDuration, movementDuration)
    QOOL_FOREACH_5(CHECK, menuCutSize, buttonCutSize, controlCutSize,
      windowCutSize, dialogCutSize)
    QOOL_FOREACH_3(
      CHECK, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
    QOOL_FOREACH_2(CHECK, windowElementSpacing, windowEdgeSpacing)
    CHECK(animationEnabled)
    CHECK(papaWords)
#undef CHECK
  }
  Qt::endPropertyUpdateGroup();
}

#define IMPL(T, N)                                                     \
  T StyleGroupAgent::N() const {                                       \
    return value(#N).value<T>();                                       \
  }                                                                    \
  void StyleGroupAgent::set_##N(const T& x) {                          \
    setValue(#N, QVariant::fromValue<T>(x));                           \
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

#undef IMPL

bool StyleGroupAgent::animationEnabled() const {
  if (m_parentStyle)
    return m_parentStyle->animationEnabled();
  return true;
}

void StyleGroupAgent::set_animationEnabled(const bool& x) {
  if (m_parentStyle)
    m_parentStyle->set_animationEnabled(x);
}

QOOL_NS_END
