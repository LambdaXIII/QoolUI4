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

  setup_properties();

  set_theme("system");

  initialize();
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

Style* Style::qmlAttachedProperties(QObject* object) {
  return new Style(object);
}

void Style::attachedParentChange(
  QQuickAttachedPropertyPropagator* newParent,
  QQuickAttachedPropertyPropagator* oldParent) {
  Q_UNUSED(oldParent)
  Style* style = qobject_cast<Style*>(newParent);
  if (style == nullptr)
    return;
  Qt::beginPropertyUpdateGroup();
  m_active->attachTo(style->m_active);
  m_inactive->attachTo(style->m_inactive);
  m_disabled->attachTo(style->m_disabled);
  Qt::endPropertyUpdateGroup();
}

void Style::setup_properties() {
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

Style* Style::parentStyle() const {
  return qobject_cast<Style*>(attachedParent());
}

QString Style::theme() const {
  if (m_theme.has_value())
    return m_theme.value();
  auto p = parentStyle();
  if (p)
    return p->theme();
  return {};
}

void Style::set_theme(const QString& theme) {
  const auto old = this->theme();
  if (theme == old)
    return;
  m_theme.emplace(theme);
  const auto t = ThemeDatabase::instance()->theme(theme);
  Qt::beginPropertyUpdateGroup();
  m_active->setValues(t.flatMap(Theme::Active));
  m_inactive->setValues(t.flatMap(Theme::Inactive));
  m_disabled->setValues(t.flatMap(Theme::Disabled));
  Qt::endPropertyUpdateGroup();
  emit themeChanged();
}

bool Style::animationEnabled() const {
  return m_animationEnabled;
}

void Style::set_animationEnabled(const bool& x) {
  if (m_animationEnabled == x)
    return;
  m_animationEnabled = x;
  Qt::beginPropertyUpdateGroup();
  const auto childs = attachedChildren();
  for (const auto& child : childs) {
    Style* c = qobject_cast<Style*>(child);
    if (c)
      c->set_animationEnabled(x);
  }
  Qt::endPropertyUpdateGroup();
  emit animationEnabledChanged();
}

#define IMPL(T, N)                                                     \
  T Style::N() const {                                                 \
    return m_##N.value();                                              \
  }                                                                    \
  void Style::set_##N(const T& x) {                                    \
    Qt::beginPropertyUpdateGroup();                                    \
    m_active->set_##N(x);                                              \
    m_inactive->set_##N(x);                                            \
    m_disabled->set_##N(x);                                            \
    Qt::endPropertyUpdateGroup();                                      \
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
