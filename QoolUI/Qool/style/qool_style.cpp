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

  connect(
    this, SIGNAL(themeChanged()), this, SLOT(when_theme_changed()));

  connect(this, SIGNAL(currentChanged()), this,
    SLOT(when_current_group_changed()));

  initialize();
}

Style::~Style() {
  if (m_sidekick)
    m_sidekick->deleteLater();
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
  m_currentTheme = ThemeDatabase::instance()->theme(name);
  emit themeChanged();
}

#define IMPL(T, N)                                                     \
  T Style::N() const {                                                 \
    if (m_customedValues.contains(#N))                                 \
      return m_customedValues.value(#N).value<T>();                    \
    return m_current.value()->N();                                     \
  }                                                                    \
  void Style::set_##N(const T& x) {                                    \
    const auto old = N();                                              \
    if (x == old)                                                      \
      return;                                                          \
    const auto v = QVariant::fromValue<T>(x);                          \
    set_customedValue(#N, v);                                          \
    emit customedValueChanged(#N, v);                                  \
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
  xDebugQ << "Customed Values" << xDBGMap(m_customedValues);
}

void Style::attachedParentChange(
  QQuickAttachedPropertyPropagator* newParent,
  QQuickAttachedPropertyPropagator* oldParent) {
  disconnect(oldParent);
  Style* style = qobject_cast<Style*>(newParent);

  inherit_theme(style);
  inherit_customedValues(style);

  if (style) {
    connect(style, &Style::customedValueChanged, this,
      &Style::set_customedValue);
    connect(style, &Style::groupCustomedValueChanged, this,
      &Style::when_groupCustomedValueChanged);
  }
}

void Style::inherit_theme(Style* p) {
  if (p == nullptr)
    return;

  m_currentTheme = p->m_currentTheme;
  emit themeChanged();
}

void Style::inherit_customedValues(Style* p) {
  if (p == nullptr)
    return;
  QStringList keys;
  keys.append(m_customedValues.keys());
  m_customedValues = p->m_customedValues;
  for (const auto& group : Theme::GROUPS) {
    keys << m_agents[group]->inherit_customedValues(p->m_agents[group]);
  }
  notify_property_changes(keys);
}

void Style::propagate_theme() {
  const auto children = attachedChildren();
  for (const auto child : children) {
    Style* s = qobject_cast<Style*>(child);
    if (s == nullptr)
      continue;
    s->inherit_theme(this);
  }
}

void Style::when_theme_changed() {
  QStringList keys = m_currentTheme.keys();
  keys.removeIf(
    [&](const QString& k) { return m_customedValues.contains(k); });
  notify_property_changes(keys);
  propagate_theme();
}

void Style::when_current_group_changed() {
  notify_property_changes({});
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

void Style::set_customedValue(QString key, QVariant value) {
  m_customedValues.insert(key, value);
  notify_property_changes({ key });
}

void Style::when_groupCustomedValueChanged(
  Theme::Groups group, QString key, QVariant value) {
  m_agents[group]->set_customedValue(key, value);
}

QOOL_NS_END
