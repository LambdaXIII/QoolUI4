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
  m_sidekick = new ItemTracker(parent);
  m_sidekick->set_target(this->parent());
  m_currentTheme = ThemeDatabase::instance()->theme("system");

  m_currentGroup.setBinding([&] {
    const bool enabled = m_sidekick->bindable_itemEnabled().value();
    if (enabled == false) {
      return Theme::Disabled;
    }
    const bool actived = m_sidekick->bindable_windowActived().value();
    if (! actived) {
      return Theme::Inactive;
    }
    return Theme::Active;
  });

  m_current.setBinding([&] {
    const auto group = m_currentGroup.value();
    return m_agents[group];
  });

  connect(this, &Style::currentGroupChanged, this,
    [&] { notify_property_changes({}); });
  connect(this, &Style::themeChanged, this, &Style::propagate_theme);

  initialize();
}

Style* Style::qmlAttachedProperties(QObject* object) {
  return new Style(object);
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
  if (m_currentTheme.name() == name)
    return;
  const auto theme = ThemeDatabase::instance()->theme(name);
  const auto keys = set_currentTheme(theme);
  notify_property_changes(keys);
  emit themeChanged();
}

#define IMPL(T, N)                                                     \
  T Style::N() const {                                                 \
    const auto group = m_currentGroup.value();                         \
    return get_value(group, #N).value<T>();                            \
  }                                                                    \
  void Style::set_##N(const T& x) {                                    \
    const auto old = N();                                              \
    if (x == old)                                                      \
      return;                                                          \
    const auto group = m_currentGroup.value();                         \
    const auto v = QVariant::fromValue<T>(x);                          \
    set_value(group, #N, v);                                           \
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

void Style::dumpInfo() const {
  xDebugQ << "PROPERTIES" << xDBGQPropertyList;
  xDebugQ << "Customed Values" << m_customedTheme.keys();
}

QVariant Style::get_value(Theme::Groups group, QString key) const {
  QVariant result = m_customedTheme.value(group, key);
  if (! result.isNull())
    return result;
  result = m_currentTheme.value(group, key);
  if (! result.isNull())
    return result;
  result = ThemeDatabase::instance()->anyValue(group, key);
  return result;
}

void Style::set_value(
  Theme::Groups group, QString key, QVariant value) {
  m_customedTheme.setValue(group, key, value);
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
  QStringList keys = set_currentTheme(other->m_currentTheme);
  if (m_customedTheme.isEmpty()) {
    m_customedTheme = other->m_currentTheme;
    keys.append(m_customedTheme.keys());
  }
  notify_property_changes(keys);
  emit themeChanged();
}

void Style::propagate_theme() {
  const auto children = attachedChildren();
  for (const auto child : children) {
    Style* s = qobject_cast<Style*>(child);
    if (s == nullptr)
      continue;
    s->inherit(this);
  }
}

QStringList Style::set_currentTheme(const Theme& t) {
  QStringList keys = t.keys();
  if (! m_customedTheme.isEmpty())
    keys.removeIf(
      [&](const QString& k) { return m_customedTheme.contains(k); });
  return keys;
}

void Style::notify_property_changes(QStringList keys) {
#define __HANDLE__(N)                                                  \
  if (keys.isEmpty() || keys.contains(#N))                             \
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
  QOOL_FOREACH_2(__HANDLE__, windowElementSpacing, windowEdgeSpacing)
#undef __HANDLE__
}

QOOL_NS_END
