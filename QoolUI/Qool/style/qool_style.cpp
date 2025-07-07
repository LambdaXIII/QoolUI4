#include "qool_style.h"

#include "qool_stylegroupagent.h"
#include "qool_theme_database.h"
#include "qoolcommon/debug.hpp"

#include <QQuickWindow>

QOOL_NS_BEGIN

Style::Style(QObject* parent)
  : QQuickAttachedPropertyPropagator(parent)
  , m_itemTracker { new ItemTracker(this) } {
  m_itemTracker->set_target(parent);
  m_data[Theme::Active] = new QVariantMap;
  m_data[Theme::Inactive] = new QVariantMap;
  m_data[Theme::Disabled] = new QVariantMap;

  m_agents[Theme::Active] = new StyleGroupAgent(Theme::Active, this);
  m_agents[Theme::Inactive] =
    new StyleGroupAgent(Theme::Inactive, this);
  m_agents[Theme::Disabled] =
    new StyleGroupAgent(Theme::Disabled, this);

  m_currentGroup.setBinding([&] {
    if (m_itemTracker->bindable_itemEnabled().value() == false)
      return Theme::Disabled;
    if (m_itemTracker->bindable_windowActived().value() == false)
      return Theme::Inactive;
    return Theme::Active;
  });

  connect(
    this, &Style::currentGroupChanged, this, [&] { update_values(); });

  set_theme("system");
  initialize();
}

Style::~Style() {
  const auto keys = m_data.keys();
  for (const auto& key : keys)
    delete m_data.take(key);
  m_data.clear();
}

Style* Style::qmlAttachedProperties(QObject* object) {
  return new Style(object);
}

QVariant Style::value(Theme::Groups group, QString key) const {
  Q_ASSERT(m_data.contains(group));
  QVariantMap* data = m_data[group];
  if (data->contains(key))
    return data->value(key);
  auto value = m_currentTheme.value(group, key);
  if (value.isNull())
    value = ThemeDatabase::instance()->anyValue(group, key);
  // if (! value.isNull())
  // data->insert(key, value);
  return value;
}

void Style::setValue(Theme::Groups group, QString key, QVariant value) {
  Q_ASSERT(m_data.contains(group));
  auto data = m_data[group];
  data->insert(key, value);
  update_values({ group }, { key });
  propagate_value(group, key, value);
}

void Style::dumpInfo() const {
  m_currentTheme.dumpInfo();
  for (auto iter = m_data.constBegin(); iter != m_data.constEnd();
    ++iter) {
    xDebugQ << iter.key() << xDBGMap(*iter.value());
  }
  xDebugQ << xDBGQPropertyList;
}

void Style::attachedParentChange(
  QQuickAttachedPropertyPropagator* newParent,
  QQuickAttachedPropertyPropagator* oldParent) {
  // disconnect(oldParent);
  Q_UNUSED(oldParent)
  Style* style = qobject_cast<Style*>(newParent);
  inherit(style);
}

void Style::set_current_theme(const Theme& theme) {
  m_currentTheme = theme;
  QStringList keys = m_currentTheme.keys();
  QStringList customedKeys;
  for (auto iter = m_data.constBegin(); iter != m_data.constEnd();
    ++iter)
    customedKeys << iter.value()->keys();
  keys.removeIf(
    [&](const QString& k) { return customedKeys.contains(k); });
  update_values({}, keys);
  propagate_theme();
}

void Style::update_values(
  QList<Theme::Groups> groups, QStringList keys) {
  if (groups.isEmpty())
    groups = m_data.keys();

  for (const auto& g : std::as_const(groups)) {
    m_agents[g]->update_values(keys);
  }

  const auto group = currentGroup();
  if (! groups.contains(group))
    return;

#define __HANDLE__(T, N) m_##N = value(group, #N).value<T>();

#define __COLOR(N) __HANDLE__(QColor, N)
  QOOL_FOREACH_10(__COLOR, white, silver, grey, black, red, maroon,
    yellow, olive, lime, green)
  QOOL_FOREACH_10(__COLOR, aqua, cyan, teal, blue, navy, fuchsia,
    purple, orange, brown, pink)
  QOOL_FOREACH_3(__COLOR, positive, negative, warning)
  QOOL_FOREACH_3(
    __COLOR, controlBackgroundColor, controlBorderColor, infoColor)
  QOOL_FOREACH_10(__COLOR, accent, light, midlight, dark, mid, shadow,
    highlight, highlightedText, link, linkVisited)
  QOOL_FOREACH_10(__COLOR, text, base, alternateBase, window,
    windowText, button, buttonText, placeholderText, toolTipBase,
    toolTipText)
#undef __COLOR

#define __INT(N) __HANDLE__(int, N)
  QOOL_FOREACH_8(__INT, textSize, titleTextSize, toolTipTextSize,
    importantTextSize, decorativeTextSize, controlTitleTextSize,
    controlTextSize, windowTitleTextSize)
#undef __INT

#define __REAL(N) __HANDLE__(qreal, N)
  QOOL_FOREACH_3(
    __REAL, instantDuration, transitionDuration, movementDuration)
  QOOL_FOREACH_5(__REAL, menuCutSize, buttonCutSize, controlCutSize,
    windowCutSize, dialogCutSize)
  QOOL_FOREACH_3(
    __REAL, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
  QOOL_FOREACH_2(__REAL, windowElementSpacing, windowEdgeSpacing)
#undef __REAL

  __HANDLE__(QStringList, papaWords)
  __HANDLE__(bool, animationEnabled)

#undef __HANDLE__
}

void Style::inherit(Style* other) {
  if (! other)
    return;
  set_current_theme(other->m_currentTheme);

  const auto groups = m_data.keys();
  for (const auto& group : groups) {
    auto customed = other->m_data[group];
    if (customed->isEmpty())
      continue;
    const auto customed_keys = customed->keys();
    QStringList updated_keys;

    for (const auto& k : customed_keys) {
      if (m_data[group]->contains(k))
        continue;
      m_data[group]->insert(k, customed->value(k));
      updated_keys << k;
    }

    update_values({ group }, updated_keys);
  } // for groups

  emit themeChanged();
}

void Style::propagate_theme() {
  const auto childs = attachedChildren();
  for (auto child : childs) {
    auto style = qobject_cast<Style*>(child);
    if (! style)
      continue;
    style->inherit(this);
  }
}

void Style::propagate_value(
  Theme::Groups group, QString key, QVariant value) {
  const auto childs = attachedChildren();
  for (auto child : childs) {
    Style* style = qobject_cast<Style*>(child);
    if (! style)
      style->update_customed_value(group, key, value);
  }
}

void Style::update_customed_value(
  Theme::Groups group, QString key, QVariant value) {
  Q_ASSERT(m_data.contains(group));
  auto data = m_data[group];
  if (data->contains(key))
    return;
  data->insert(key, value);
  update_values({ group }, { key });
}

QString Style::theme() const {
  return m_currentTheme.name();
}

void Style::set_theme(const QString& name) {
  if (theme() == name)
    return;
  const auto theme = ThemeDatabase::instance()->theme(name);
  set_current_theme(theme);
  emit themeChanged();
}

StyleGroupAgent* Style::active() const {
  return m_agents[Theme::Active];
}

StyleGroupAgent* Style::inactive() const {
  return m_agents[Theme::Inactive];
}

StyleGroupAgent* Style::disabled() const {
  return m_agents[Theme::Disabled];
}

#define IMPL(T, N)                                                     \
  T Style::N() const {                                                 \
    return m_##N.value();                                              \
  }                                                                    \
  void Style::set_##N(const T& value) {                                \
    const QVariant v = QVariant::fromValue<T>(value);                  \
    const auto group = currentGroup();                                 \
    setValue(group, #N, v);                                            \
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
