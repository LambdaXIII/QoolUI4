#include "qool_themevaluegroupagent.h"

#include "qool_theme_database.h"

#include <QBindable>
#include <QColor>

QOOL_NS_BEGIN

ThemeValueGroupAgent::ThemeValueGroupAgent(QObject* parent)
  : QObject { parent } {
}

ThemeValueGroupAgent::ThemeValueGroupAgent(
  Theme::Groups group, QObject* parent)
  : QObject { parent }
  , m_currentGroup { group } {
}

QVariant ThemeValueGroupAgent::value(
  const QString& key, const QVariant& defvalue) const {
  return m_data.value(key, defvalue);
}

void ThemeValueGroupAgent::setValue(
  const QString& key, const QVariant& value) {
  const auto old = m_data.value(key);
  if (old == value)
    return;
  m_data.set_value(key, value);
  when_value_changed({ key });
}

void ThemeValueGroupAgent::set_data(const QVariantMap& datas) {
  QStringList changed_keys;
  changed_keys.append(m_data.keys());
  m_data.setDefaults(datas);
  changed_keys.append(datas.keys());
  when_value_changed(changed_keys);
}

void ThemeValueGroupAgent::reset(const QString& key) {
  if (key.isEmpty())
    return;
  if (! m_data.contains(key))
    return;
  m_data.reset(key);
  when_value_changed({ key });
}

void ThemeValueGroupAgent::reset() {
  const QStringList changed_keys = m_data.currentKeys();
  if (changed_keys.isEmpty())
    return;
  m_data.reset();
  when_value_changed(changed_keys);
}

void ThemeValueGroupAgent::inherit(ThemeValueGroupAgent* other) {
  const auto keys = m_data.defaultKeys();
  m_data = other->m_data;
  when_value_changed(keys);
}

void ThemeValueGroupAgent::when_value_changed(const QStringList& keys) {
  const QSet<QString> _keys { keys.constBegin(), keys.constEnd() };
  Qt::beginPropertyUpdateGroup();
  for (const auto& key : _keys) {
    emit valueChanged(key);

#define CHECK(N)                                                       \
  if (key == #N)                                                       \
    emit N##Changed();
    QOOL_FOREACH_3(CHECK, positive, negative, warning)
    QOOL_FOREACH_10(CHECK, accent, light, midlight, dark, mid, shadow,
      highlight, highlightedText, link, linkVisited)
    QOOL_FOREACH_10(CHECK, text, base, alternateBase, window,
      windowText, button, buttonText, placeHolderText, toolTipBase,
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
  } // for
  Qt::endPropertyUpdateGroup();
} // when_value_changed

/****** PROPERTIES *******/

#define IMPL(T, N)                                                     \
  T ThemeValueGroupAgent::N() const {                                  \
    if (m_data.contains(#N))                                           \
      return m_data.value(#N).value<T>();                              \
    return ThemeDatabase::instance()                                   \
      ->anyValue(m_currentGroup, #N)                                   \
      .value<T>();                                                     \
  }                                                                    \
  void ThemeValueGroupAgent::set_##N(const T& v) {                     \
    const auto old = m_data.value(#N);                                 \
    const auto value = QVariant::fromValue<T>(v);                      \
    if (old == value)                                                  \
      return;                                                          \
    m_data.set_value(#N, value);                                       \
    emit N##Changed();                                                 \
    emit valueChanged(#N);                                             \
  }                                                                    \
  QBindable<T> ThemeValueGroupAgent::bindable_##N() {                  \
    return QBindable<T>(this, #N);                                     \
  }

#define __COLOR(N) IMPL(QColor, N)
QOOL_FOREACH_3(__COLOR, positive, negative, warning)
QOOL_FOREACH_10(__COLOR, accent, light, midlight, dark, mid, shadow,
  highlight, highlightedText, link, linkVisited)
QOOL_FOREACH_10(__COLOR, text, base, alternateBase, window, windowText,
  button, buttonText, placeHolderText, toolTipBase, toolTipText)
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

IMPL(bool, animationEnabled)
IMPL(QStringList, papaWords)

#undef IMPL

QOOL_NS_END
