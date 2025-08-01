#include "qool_style.h"

#include "qool_stylegroupagent.h"
#include "qool_system_theme.h"
#include "qool_theme_database.h"
#include "qoolcommon/debug.hpp"

#include <QQuickWindow>

QOOL_NS_BEGIN

Style::Style(QObject *parent)
  : QQuickAttachedPropertyPropagator(parent)
  , m_itemTracker{new ItemTracker(this)} {
  initialize_data();

  m_active = new StyleGroupAgent(Active, this);
  m_inactive = new StyleGroupAgent(Inactive, this);
  m_disabled = new StyleGroupAgent(Disabled, this);

  m_itemTracker->set_target(parent);
  m_currentGroup.setBinding([&] {
    const auto item = m_itemTracker->bindable_item().value();
    const bool enabled = m_itemTracker->bindable_itemEnabled().value();
    if (item && ! enabled) return Disabled;
    const bool active = m_itemTracker->bindable_windowActived().value();
    if (! active) return Inactive;
    return Active;
  });

  connect(
      this, &Style::currentGroupChanged, this, &Style::when_curentGroupChanged);
  connect(this, &Style::valueChanged, this, &Style::check_changes);
  connect(this, &Style::themeChanged, this, &Style::when_themeChanged);

  installEventFilter(this);

  initialize();
  // if (! attachedParent())
  //   manually_attach_to_parentStyle();
}

Style *Style::qmlAttachedProperties(QObject *object) {
  return new Style(object);
}

void Style::dumpInfo() const {
  xDebugQ << xDBGYellow "Theme:" xDBGBlue << theme() << xDBGReset;
  xDebugQ << xDBGYellow "Parent:" xDBGBlue << parent() << xDBGReset;

  QList<QQuickAttachedPropertyPropagator *> parents;
  QQuickAttachedPropertyPropagator *item = attachedParent();
  while (item) {
    parents << item;
    item = item->attachedParent();
  }
  xDebugQ << xDBGYellow "tracking item" xDBGReset << m_itemTracker->item();
  xDebugQ << xDBGYellow "tracking window" xDBGReset << m_itemTracker->window();
  xDebugQ << xDBGYellow "AttachedParents:" xDBGPink << xDBGList(parents)
          << xDBGReset;
  xDebugQ << xDBGYellow "AttachedChildren:" xDBGPink
          << xDBGList(attachedChildren()) << xDBGReset;
  xDebugQ << xDBGYellow "Properties:" xDBGReset << xDBGQPropertyList;
  xDebugQ << xDBGYellow "Modified Active Values" xDBGReset
          << xDBGList(m_activeModified.keys());
  xDebugQ << xDBGYellow "Modified Inactive Values" xDBGReset
          << xDBGList(m_inactiveModified.keys());
  xDebugQ << xDBGYellow "Modified Disabled Values" xDBGReset
          << xDBGList(m_disabledModified.keys());

  if (m_activeData == m_inactiveData && m_activeData == m_disabledData)
    xWarningQ << xDBGRed "All Groups are equal!" xDBGReset;
}

void Style::dumpAllChildren() const {
  xDebugQ << xDBGYellow "All Children:" xDBGReset << xDBGList(find_children());
}

QVariant Style::get_value(
    int group, const QString &key, const QVariant &defValue) const {
  switch (group) {
  case Active:
    return m_activeData.value(key, defValue);
  case Inactive:
    return m_inactiveData.value(key, defValue);
  case Disabled:
    return m_disabledData.value(key, defValue);
  }
  return {};
}

bool Style::set_value(int group, const QString &key, const QVariant &value) {
  if (group == Active) {
    if (m_activeData == value) return false;
    m_activeData.insert(key, value);
    emit valueChanged(Active, key);
    return true;
  }
  if (group == Inactive) {
    if (m_inactiveData == value) return false;
    m_inactiveData.insert(key, value);
    emit valueChanged(Inactive, key);
    return true;
  }
  if (group == Disabled) {
    if (m_disabledData == value) return false;
    m_disabledData.insert(key, value);
    emit valueChanged(Disabled, key);
    return true;
  }
  return false;
}

void Style::mark_modified(int group, const QString &key) {
  switch (group) {
  case Active:
    m_activeModified[key] = true;
    break;
  case Inactive:
    m_inactiveModified[key] = true;
    break;
  case Disabled:
    m_disabledModified[key] = true;
    break;
  }
}

bool Style::is_modified(int group, const QString &key) const {
  switch (group) {
  case Active:
    return m_activeModified.value(key, false);
  case Inactive:
    return m_inactiveModified.value(key, false);
  case Disabled:
    return m_disabledModified.value(key, false);
  }
  return false;
}

void Style::initialize_data() {
  m_theme = QStringLiteral("system");
  m_activeData = SystemTheme::instance()->flatMap(Theme::Active);
  m_inactiveData = SystemTheme::instance()->flatMap(Theme::Inactive);
  m_disabledData = SystemTheme::instance()->flatMap(Theme::Disabled);
}

void Style::propagate_theme() {
  const auto childs = attachedChildren();
  if (childs.isEmpty()) return;

  // xInfoQ << "Propagating theme from" xDBGGreen << this
  //        << xDBGReset "to" xDBGRed << childs.length()
  //        << xDBGReset "children.";

  for (const auto &child : childs) {
    Style *style = qobject_cast<Style *>(child);
    if (style) style->inherit(this);
  }
}

void Style::inherit(Style *other) {
  if (! other) return;

  m_theme = other->m_theme;

  Qt::beginPropertyUpdateGroup();

  for (auto iter = other->m_activeData.constBegin();
      iter != other->m_activeData.constEnd(); ++iter) {
    const bool modified = m_activeModified.value(iter.key(), false);
    if (! modified) set_value(Active, iter.key(), iter.value());
  }
  for (auto iter = other->m_inactiveData.constBegin();
      iter != other->m_inactiveData.constEnd(); ++iter) {
    const bool modified = m_inactiveModified.value(iter.key(), false);
    if (! modified) set_value(Inactive, iter.key(), iter.value());
  }
  for (auto iter = other->m_disabledData.constBegin();
      iter != other->m_disabledData.constEnd(); ++iter) {
    const bool modified = m_disabledModified.value(iter.key(), false);
    if (! modified) set_value(Disabled, iter.key(), iter.value());
  }

  Qt::endPropertyUpdateGroup();

  // xInfoQ << "Inherited from" xDBGGreen << other
  //        << xDBGReset "to" xDBGRed << this << xDBGReset;

  propagate_theme();
}

void Style::when_themeChanged() {
  const auto t = ThemeDatabase::instance()->theme(m_theme);
  xInfoQ << "setting up theme" xDBGBlue << t.name() << xDBGReset "for" xDBGRed
         << this << xDBGReset;

  Qt::beginPropertyUpdateGroup();
  const auto active_values = t.flatMap(Theme::Active);
  for (auto iter = active_values.constBegin(); iter != active_values.constEnd();
      ++iter) {
    const bool m = m_activeModified.value(iter.key(), false);
    if (! m) set_value(Active, iter.key(), iter.value());
  }
  const auto inactive_values = t.flatMap(Theme::Inactive);
  for (auto iter = inactive_values.constBegin();
      iter != inactive_values.constEnd(); ++iter) {
    const bool m = m_inactiveModified.value(iter.key(), false);
    if (! m) set_value(Inactive, iter.key(), iter.value());
  }
  const auto disabled_values = t.flatMap(Theme::Disabled);
  for (auto iter = disabled_values.constBegin();
      iter != disabled_values.constEnd(); ++iter) {
    const bool m = m_disabledModified.value(iter.key(), false);
    if (! m) set_value(Disabled, iter.key(), iter.value());
  }
  Qt::endPropertyUpdateGroup();
  propagate_theme();
}

void Style::check_changes(int group, QString key) {
  if (group != m_currentGroup.value()) return;
#define __SET__(T, N)                               \
  if (key == QStringLiteral(#N)) emit N##Changed();

#define __HANDLE__(N) __SET__(QColor, N)
  QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, maroon, yellow,
      olive, lime, green)
  QOOL_FOREACH_10(__HANDLE__, aqua, cyan, teal, blue, navy, fuchsia, purple,
      orange, brown, pink)
  QOOL_FOREACH_3(__HANDLE__, positive, negative, warning)
  QOOL_FOREACH_3(
      __HANDLE__, controlBackgroundColor, controlBorderColor, infoColor)
  QOOL_FOREACH_10(__HANDLE__, accent, light, midlight, dark, mid, shadow,
      highlight, highlightedText, link, linkVisited)
  QOOL_FOREACH_10(__HANDLE__, text, base, alternateBase, window, windowText,
      button, buttonText, placeholderText, toolTipBase, toolTipText)
#undef __HANDLE__

#define __HANDLE__(N) __SET__(int, N)
  QOOL_FOREACH_8(__HANDLE__, textSize, titleTextSize, toolTipTextSize,
      importantTextSize, decorativeTextSize, controlTitleTextSize,
      controlTextSize, windowTitleTextSize)
#undef __HANDLE__

#define __HANDLE__(N) __SET__(qreal, N)
  QOOL_FOREACH_3(
      __HANDLE__, instantDuration, transitionDuration, movementDuration)
  QOOL_FOREACH_5(__HANDLE__, menuCutSize, buttonCutSize, controlCutSize,
      windowCutSize, dialogCutSize)
  QOOL_FOREACH_3(
      __HANDLE__, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
  QOOL_FOREACH_2(__HANDLE__, windowElementSpacing, windowEdgeSpacing)
#undef __HANDLE__

  __SET__(QStringList, papaWords)
#undef __SET__
}

void Style::when_curentGroupChanged() {
  // const Groups group = m_currentGroup.value();

  // xInfoQ << "Group changed:" xDBGYellow << group << xDBGReset;

  Qt::beginPropertyUpdateGroup();

#define SETUP(T, N) emit N##Changed();

#define __HANDLE__(N) SETUP(QColor, N)
  QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, maroon, yellow,
      olive, lime, green)
  QOOL_FOREACH_10(__HANDLE__, aqua, cyan, teal, blue, navy, fuchsia, purple,
      orange, brown, pink)
  QOOL_FOREACH_3(__HANDLE__, positive, negative, warning)
  QOOL_FOREACH_3(
      __HANDLE__, controlBackgroundColor, controlBorderColor, infoColor)
  QOOL_FOREACH_10(__HANDLE__, accent, light, midlight, dark, mid, shadow,
      highlight, highlightedText, link, linkVisited)
  QOOL_FOREACH_10(__HANDLE__, text, base, alternateBase, window, windowText,
      button, buttonText, placeholderText, toolTipBase, toolTipText)
#undef __HANDLE__

#define __HANDLE__(N) SETUP(int, N)
  QOOL_FOREACH_8(__HANDLE__, textSize, titleTextSize, toolTipTextSize,
      importantTextSize, decorativeTextSize, controlTitleTextSize,
      controlTextSize, windowTitleTextSize)
#undef __HANDLE__

#define __HANDLE__(N) SETUP(qreal, N)
  QOOL_FOREACH_3(
      __HANDLE__, instantDuration, transitionDuration, movementDuration)
  QOOL_FOREACH_5(__HANDLE__, menuCutSize, buttonCutSize, controlCutSize,
      windowCutSize, dialogCutSize)
  QOOL_FOREACH_3(
      __HANDLE__, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
  QOOL_FOREACH_2(__HANDLE__, windowElementSpacing, windowEdgeSpacing)
#undef __HANDLE__

  SETUP(QStringList, papaWords)

#undef SETUP
  Qt::endPropertyUpdateGroup();
}

QList<QQuickAttachedPropertyPropagator *> Style::find_children() const {
  QList<QQuickAttachedPropertyPropagator *> result;
  const auto childs = attachedChildren();
  for (auto x : childs) {
    result << x;
    auto s = qobject_cast<Style *>(x);
    if (s) result.append(s->find_children());
  }
  return childs;
}

void Style::attachedParentChange(QQuickAttachedPropertyPropagator *newParent,
    QQuickAttachedPropertyPropagator *oldParent) {
  Q_UNUSED(oldParent)
  auto style = qobject_cast<Style *>(newParent);
  if (style) inherit(style);
}

bool Style::eventFilter(QObject *object, QEvent *event) {
  if (object != this) return false;
  if (event->type() == QEvent::ParentChange)
    m_itemTracker->set_target(object->parent());
  return QObject::eventFilter(object, event);
}

void Style::follow_value(int group, QString key) {
  Style *other = qobject_cast<Style *>(sender());
  if (! other) return;
  if (is_modified(group, key)) return;
  const auto new_value = other->get_value(group, key);
  set_value(group, key, new_value);
}

bool Style::animationEnabled() const { return m_animationEnabled; }

void Style::set_animationEnabled(const bool &x) {
  if (m_animationEnabled == x) return;
  m_animationEnabled = x;
  const auto childs = attachedChildren();
  for (const auto &c : childs) {
    auto s = qobject_cast<Style *>(c);
    if (s) s->set_animationEnabled(x);
  }
  emit animationEnabledChanged();
}

Style *Style::follow() const { return m_follow; }

void Style::set_follow(Style *other) {
  if (m_follow == other) return;
  if (m_follow) disconnect(m_follow);
  m_follow = other;
  if (m_follow) {
    inherit(m_follow);
    connect(m_follow, SIGNAL (valueChanged(int,QString)), this,
                          SLOT (follow_value(int,QString)));
  }
  emit followChanged();
}

#define IMPL(T, N)                                    \
  T Style::N() const {                                \
    const auto group = m_currentGroup.value();        \
    return get_value(group, #N).value<T>();           \
  }                                                   \
  void Style::set_##N(const T &v) {                   \
    static const QString key{QStringLiteral(#N) };    \
    const auto value = QVariant::fromValue<T>(v);     \
    const bool ok1 = set_value(Active, key, value);   \
    if (ok1) mark_modified(Active, key);              \
    const bool ok2 = set_value(Inactive, key, value); \
    if (ok2) mark_modified(Inactive, key);            \
    const bool ok3 = set_value(Disabled, key, value); \
    if (ok3) mark_modified(Disabled, key);            \
  }

#define __HANDLE__(N) IMPL(QColor, N)
QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, maroon, yellow,
    olive, lime, green)
QOOL_FOREACH_10(__HANDLE__, aqua, cyan, teal, blue, navy, fuchsia, purple,
    orange, brown, pink)
QOOL_FOREACH_3(__HANDLE__, positive, negative, warning)
QOOL_FOREACH_3(
    __HANDLE__, controlBackgroundColor, controlBorderColor, infoColor)
QOOL_FOREACH_10(__HANDLE__, accent, light, midlight, dark, mid, shadow,
    highlight, highlightedText, link, linkVisited)
QOOL_FOREACH_10(__HANDLE__, text, base, alternateBase, window, windowText,
    button, buttonText, placeholderText, toolTipBase, toolTipText)
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
