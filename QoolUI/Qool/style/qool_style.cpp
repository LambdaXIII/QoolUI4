#include "qool_style.h"

#include "qool_stylegroupagent.h"
#include "qool_theme_database.h"
#include "qoolcommon/debug.hpp"

#include <QQuickWindow>

QOOL_NS_BEGIN

Style::Style(QObject* parent)
  : QQuickAttachedPropertyPropagator(parent) {
  for (const auto x : Theme::GROUPS) {
    m_agents[x] = new StyleGroupAgent(x, this);
  }
  m_sidekick = new SmartObject(parent);

  connect(this, &Style::internalValuesChanged, this,
    &Style::dispatchValueSignals);

  m_currentTheme = ThemeDatabase::instance()->theme("system");
  m_valueCustomed = false;

  initialize();
}

Style::~Style() {
  if (m_sidekick)
    m_sidekick->deleteLater();
}

Style* Style::qmlAttachedProperties(QObject* object) {
  return new Style(object);
}

QVariant Style::value(
  const QString& key, const QVariant& defvalue) const {
  return value(Theme::Custom, key, defvalue);
}

void Style::setValue(const QString& key, const QVariant& value) {
  setValue(m_currentGroup, key, value);
}

QVariant Style::value(Theme::Groups group, const QString& key,
  const QVariant& defvalue) const {
  if (m_currentTheme.contains(group, key))
    return m_currentTheme.value(group, key);
  return ThemeDatabase::instance()->anyValue(group, key, defvalue);
}

void Style::setValue(
  Theme::Groups group, const QString& key, const QVariant& value) {
  bool result = internalSetValue(group, key, value);
  if (result)
    m_valueCustomed = true;
}

void Style::dispatchValueSignals(
  Theme::Groups group, QSet<QString> keys) {
  if (keys.isEmpty()) {
    const auto all_keys = m_currentTheme.keys();
    keys = QSet<QString> { all_keys.constBegin(), all_keys.constEnd() };
  }

  if (group != m_currentGroup)
    return;

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
    CHECK(papaWords)
#undef CHECK
  } // for
}

bool Style::internalSetValue(
  Theme::Groups group, const QString& key, const QVariant& value) {
  bool result = m_currentTheme.setValue(group, key, value);
  if (result)
    emit internalValuesChanged(group, { key });
  return result;
}

void Style::attachedParentChange(
  QQuickAttachedPropertyPropagator* newParent,
  QQuickAttachedPropertyPropagator* oldParent) {
  disconnect(oldParent);
  Style* style = qobject_cast<Style*>(newParent);
  inherit(style);
}

void Style::inherit(Style* other) {
  if (other == nullptr)
    return;
  if (! m_valueCustomed) {
    m_currentTheme = other->m_currentTheme;
    emit themeChanged();
    emit internalValuesChanged(m_currentGroup, {});
    connect(other, &Style::internalValuesChanged, this,
      &Style::inheritValues);
  }
}

void Style::inheritValues(Theme::Groups group, QSet<QString> keys) {
  Style* source = qobject_cast<Style*>(sender());
  if (source == nullptr) {
    xWarningQ
      << "Recieved internalValuesChanged signal from unknown object.";
    return;
  }
  if (m_valueCustomed)
    return;
  if (keys.isEmpty())
    return;
  for (const auto& key : keys) {
    const auto value = source->value(group, key);
    m_currentTheme.setValue(group, key, value);
  }
  dispatchValueSignals(group, keys);
}

void Style::propagateTheme() {
  const auto children = attachedChildren();
  for (auto child : children) {
    Style* sub = qobject_cast<Style*>(child);
    if (! sub)
      continue;
    sub->inherit(this);
  }
}

#define IMPL_AGENT(a, b)                                               \
  StyleGroupAgent* Style::a() const {                                  \
    return m_agents[b];                                                \
  }

IMPL_AGENT(active, Theme::Active)
IMPL_AGENT(inactive, Theme::Inactive)
IMPL_AGENT(disabled, Theme::Disabled)
IMPL_AGENT(constants, Theme::Constants)
IMPL_AGENT(custom, Theme::Custom)

#undef IMPL_AGENT

QString Style::theme() const {
  return m_currentTheme.name();
}

void Style::set_theme(const QString& name) {
  if (m_currentTheme.name() == name || m_valueCustomed)
    return;
  m_currentTheme = ThemeDatabase::instance()->theme(name);
  propagateTheme();
  emit themeChanged();
}

bool Style::animationEnabled() const {
  if (m_valueCustomed)
    return m_currentTheme.value(Theme::Active, "animationEnabled")
      .toBool();
  return m_currentTheme.value(Theme::Custom, "animationEnabled")
    .toBool();
}

void Style::set_animationEnabled(const bool& x) {
  const bool old = animationEnabled();
  if (old == x)
    return;
  m_currentTheme.setValue(Theme::Custom, "animationEnabled", x);
  emit internalValuesChanged(m_currentGroup, { "animationEnabled" });
  emit animationEnabledChanged();
}

#define IMPL(T, N)                                                     \
  T Style::N() const {                                                 \
    return m_currentTheme.value(m_currentGroup, #N).value<T>();        \
  }                                                                    \
  void Style::set_##N(const T& x) {                                    \
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

void Style::dumpInfo() const {
  QVariantMap info { { "Theme", theme() },
    { "CurrentGroup", m_currentGroup },
    { "CUSTOMED", m_valueCustomed } };
  xDebugQ << "BASIC_INFO" << xDBGMap(info);
  xDebugQ << "PROPERTIES" << xDBGQPropertyList;
  // m_currentTheme.dumpInfo();
}

QOOL_NS_END
