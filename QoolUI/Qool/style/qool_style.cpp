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

  m_active = new StyleGroupAgent(this);
  m_inactive = new StyleGroupAgent(this);
  m_disabled = new StyleGroupAgent(this);

  __setup_properties();

  // connect(this, &Style::animationEnabledChanged, this,
  //   &Style::__propagate_animationEnabled);

  setTheme("system");

  initialize();
}

Style::~Style() {
}

Style* Style::qmlAttachedProperties(QObject* object) {
  return new Style(object);
}

QString Style::theme() const {
  return m_currentTheme.name();
}

void Style::setTheme(const QString& name) {
  m_currentTheme = ThemeDatabase::instance()->theme(name);
  __spread_theme_values();
  __propagate_theme();
  emit themeChanged();
}

void Style::resetTheme() {
  auto a = qobject_cast<Style*>(attachedParent());
  if (a) {
    Qt::beginPropertyUpdateGroup();
    m_currentTheme = a->m_currentTheme;
    emit themeChanged();
    m_active->inherit(a->m_active);
    m_inactive->inherit(a->m_inactive);
    m_disabled->inherit(a->m_disabled);
    Qt::endPropertyUpdateGroup();
  }
}

void Style::dumpInfo() const {
  xDebugQ << xDBGYellow "Theme:" xDBGBlue << theme() << xDBGReset;
  xDebugQ << xDBGYellow "Parent:" xDBGBlue << parent() << xDBGReset;

  QList<QQuickAttachedPropertyPropagator*> parents;
  QQuickAttachedPropertyPropagator* item = attachedParent();
  while (item) {
    parents << item;
    item = item->attachedParent();
  }

  xDebugQ << xDBGYellow "AttachedParents:" xDBGPink << xDBGList(parents)
          << xDBGReset;
  xDebugQ << xDBGYellow "AttachedChildren:" xDBGPink
          << xDBGList(attachedChildren()) << xDBGReset;
  xDebugQ << xDBGYellow "Properties:" xDBGReset << xDBGQPropertyList;
}

void Style::__setup_properties() {
  m_currentAgent.setBinding([&] {
    const bool p_enabled =
      m_itemTracker->bindable_itemEnabled().value();
    if (p_enabled == false)
      return m_disabled;
    const bool w_actived =
      m_itemTracker->bindable_windowActived().value();
    if (w_actived == false)
      return m_inactive;
    return m_active;
  });
#define __HANDLE__(N)                                                  \
  m_##N.setBinding([&] {                                               \
    auto agent = m_currentAgent.value();                               \
    return agent->bindable_##N().value();                              \
  });

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

void Style::__spread_theme_values() {
  Qt::beginPropertyUpdateGroup();
  m_active->setData(m_currentTheme.flatMap(Theme::Active));
  m_inactive->setData(m_currentTheme.flatMap(Theme::Inactive));
  m_disabled->setData(m_currentTheme.flatMap(Theme::Disabled));
  Qt::endPropertyUpdateGroup();
}

void Style::attachedParentChange(
  QQuickAttachedPropertyPropagator* newParent,
  QQuickAttachedPropertyPropagator* oldParent) {
  disconnect(oldParent);
  Style* style = qobject_cast<Style*>(newParent);
  if (style) {
    inherit(style);
  }
}

void Style::inherit(Style* other) {
  Q_ASSERT(other);
  Qt::beginPropertyUpdateGroup();
  m_currentTheme = other->m_currentTheme;
  emit themeChanged();
  m_active->inherit(other->m_active);
  m_inactive->inherit(other->m_inactive);
  m_disabled->inherit(other->m_disabled);
  __copy_values(other);
  __inherit_animationEnabled(other);
  Qt::endPropertyUpdateGroup();
  __propagate_theme();
}

void Style::__propagate_theme() {
  const auto childs = attachedChildren();
  for (const auto& child : childs) {
    auto style = qobject_cast<Style*>(child);
    if (! style)
      continue;
    style->inherit(this);
  }
}

void Style::__copy_values(Style* other) {
  Q_ASSERT(other);
#define __HANDLE__(N)                                                  \
  if (! m_##N.hasBinding())                                            \
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

bool Style::animationEnabled() const {
  return m_animationEnabled;
}

void Style::__inherit_animationEnabled(Style* other) {
  if (! other)
    return;
  if (m_animationEnabledCustomed
      || m_animationEnabled == other->m_animationEnabled)
    return;
  m_animationEnabled = other->m_animationEnabled;
  emit animationEnabledChanged();
}

void Style::__propagate_animationEnabled() {
  const auto childs = attachedChildren();
  for (const auto& child : childs) {
    Style* a = qobject_cast<Style*>(child);
    if (a)
      a->__inherit_animationEnabled(this);
  }
}

void Style::set_animationEnabled(const bool& x) {
  if (m_animationEnabled == x)
    return;
  m_animationEnabled = x;
  m_animationEnabledCustomed = true;
  __propagate_animationEnabled();
  emit animationEnabledChanged();
}

QOOL_NS_END
