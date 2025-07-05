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
  m_valueCustomed = false;

  m_currentTheme = ThemeDatabase::instance()->theme("system");
  connect(this, &Style::themeChanged, this, &Style::propagateTheme);

  m_currentGroup.setBinding([&] {
    const bool enabled = m_sidekick->bindable_parentEnabled().value();
    if (enabled == false) {
      return Theme::Disabled;
    }
    const bool actived = m_sidekick->bindable_windowActived().value();
    if (! actived) {
      return Theme::Inactive;
    }
    return Theme::Active;
  });

  m_currentGroupNotifier = m_currentGroup.addNotifier(
    [&] { this->when_currentGroup_changed(); });

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
  bool result = m_currentTheme.setValue(group, key, value);
  if (! result)
    return;
  m_valueCustomed = true;
  when_values_changed({ group }, { key });
}

// void Style::update_currentGroup() {
//   const auto old_group = m_currentGroup;
//   Theme::Groups new_group = Theme::Active;
//   if (m_sidekick->parentEnabled() == false)
//     new_group = Theme::Disabled;
//   else if (m_sidekick->windowActived() == false)
//     new_group = Theme::Inactive;
//   if (old_group == new_group)
//     return;
//   xDebugQ << "current group changed to:" << new_group;
//   m_currentGroup = new_group;
//   when_values_changed({ old_group, m_currentGroup }, {});
// }

void Style::dispatchValueSignals(QSet<QString> keys) {
  if (keys.isEmpty()) {
    const auto all_keys = m_currentTheme.keys();
    keys = QSet<QString> { all_keys.constBegin(), all_keys.constEnd() };
  }

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
    CHECK(papaWords)
#undef CHECK
  } // for
  Qt::endPropertyUpdateGroup();
}

void Style::when_values_changed(
  QSet<Theme::Groups> groups, QSet<QString> keys) {
  if (groups.isEmpty()) {
    groups =
      QSet<Theme::Groups>(Theme::GROUPS.cbegin(), Theme::GROUPS.cend());
  }

  if (keys.isEmpty()) {
    QStringList all_keys;
    std::for_each(
      groups.cbegin(), groups.cend(), [&](const Theme::Groups& x) {
        all_keys.append(m_currentTheme.keys(x));
      });
    keys = QSet<QString>(all_keys.constBegin(), all_keys.constEnd());
  }

  for (const auto& group : std::as_const(groups))
    m_agents[group]->dispatchValueSignals(keys);

  if (groups.contains(m_currentGroup))
    dispatchValueSignals(keys);

  emit values_changed_internally(groups, keys);
}

void Style::when_parent_vales_changed_internally(
  QSet<Theme::Groups> groups, QSet<QString> keys) {
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
  for (const auto& group : groups)
    for (const auto& key : keys) {
      const auto value = source->value(group, key);
      m_currentTheme.setValue(group, key, value);
    }
  when_values_changed(groups, keys);
}

void Style::attachedParentChange(
  QQuickAttachedPropertyPropagator* newParent,
  QQuickAttachedPropertyPropagator* oldParent) {
  disconnect(oldParent);
  Style* style = qobject_cast<Style*>(newParent);
  if (style)
    connect(style, &Style::values_changed_internally, this,
      &Style::when_parent_vales_changed_internally);
  inherit(style);
}

void Style::inherit(Style* other) {
  if (other == nullptr)
    return;
  if (! m_valueCustomed) {
    m_currentTheme = other->m_currentTheme;
    emit themeChanged();
  }
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

  m_valueCustomed = true;

  auto all_keys = m_currentTheme.keys();
  m_currentTheme = ThemeDatabase::instance()->theme(name);
  all_keys.append(m_currentTheme.keys());

  QSet<QString> keys { all_keys.constBegin(), all_keys.constEnd() };
  when_values_changed({}, keys);

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
  when_values_changed({ m_currentGroup }, { "animationEnabled" });
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
    { "CurrentGroup", m_currentGroup.value() },
    { "CUSTOMED", m_valueCustomed } };
  xDebugQ << "BASIC_INFO" << xDBGMap(info);
  xDebugQ << "PROPERTIES" << xDBGQPropertyList;
  // m_currentTheme.dumpInfo();
}

void Style::when_currentGroup_changed() {
  xDebugQ << "Group changed:" << m_currentGroup.value();
  when_values_changed({}, {});
}

QOOL_NS_END
