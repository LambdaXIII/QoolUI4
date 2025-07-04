#include "qool_style.h"

#include <QQuickWindow>

QOOL_NS_BEGIN

Style::Style(QObject* parent)
  : QQuickAttachedPropertyPropagator(parent) {
  initialize();
  for (const auto x : Theme::GROUPS) {
    m_agents[x] = new ThemeValueGroupAgent(x, this);
    connect(m_agents[x], SIGNAL(valueChanged(QString)), this,
      SIGNAL(valueChanged(QString)));
  }

  connect(this,
    SIGNAL(parentItemChanged()),
    this,
    SLOT(update_parentEnabled()));

  connect(this,
    SIGNAL(parentItemChanged()),
    this,
    SLOT(update_windowActived()));

  m_currentGroup.setBinding([&] {
    if (! m_parentEnabled.value())
      return Theme::Disabled;
    if (! m_windowActived.value())
      return Theme::Inactive;
    return Theme::Active;
  });
}

QVariant Style::value(
  const QString& key, const QVariant& defvalue) const {
  return m_agents[m_currentGroup.value()]->value(key, defvalue);
}

void Style::setValue(const QString& key, const QVariant& value) {
  custom()->setValue(key, value);
}

void Style::update_windowActived() {
  m_windowActived = m_parentItem->window()->isActive();
}

void Style::update_parentEnabled() {
  m_parentEnabled = m_parentItem->isEnabled();
}

void Style::attachedParentChange(
  QQuickAttachedPropertyPropagator* newParent,
  QQuickAttachedPropertyPropagator* oldParent) {
  if (oldParent == newParent)
    return;
  Q_UNUSED(oldParent);
  set_attachedParent(newParent);
}

bool Style::event(QEvent* e) {
  if (e->type() == QEvent::ParentChange) {
    set_parentItem(parent());
  } else if (e->type() == QEvent::WindowStateChange
             || e->type() == QEvent::ParentWindowChange) {
    update_windowActived();
  }
  return QQuickAttachedPropertyPropagator::event(e);
}

void Style::set_parentItem(QObject* x) {
  auto old_parent = m_parentItem.value();
  disconnect(old_parent);
  QQuickItem* a = qobject_cast<QQuickItem*>(x);
  connect(
    a, SIGNAL(enabledChanged()), this, SLOT(update_parentEnabled()));
  connect(a,
    SIGNAL(windowChanged(QQuickWindow*)),
    this,
    SLOT(update_windowActived()));
  m_parentItem = a;
}

void Style::set_attachedParent(QObject* x) {
  Style* a = qobject_cast<Style*>(x);
  m_attachedParent = a;
}

void Style::setup_properties() {
#define SETUP(N)                                                       \
  m_##N.setBinding([&] {                                               \
    return m_agents[m_currentGroup.value()]->bindable_##N().value();   \
  });
  QOOL_FOREACH_3(SETUP, positive, negative, warning)
  QOOL_FOREACH_10(SETUP, accent, light, midlight, dark, mid, shadow,
    highlight, highlightedText, link, linkVisited)
  QOOL_FOREACH_10(SETUP, text, base, alternateBase, window, windowText,
    button, buttonText, placeHolderText, toolTipBase, toolTipText)
  QOOL_FOREACH_8(SETUP, textSize, titleTextSize, toolTipTextSize,
    importantTextSize, decorativeTextSize, controlTitleTextSize,
    controlTextSize, windowTitleTextSize)
  QOOL_FOREACH_3(
    SETUP, instantDuration, transitionDuration, movementDuration)
  QOOL_FOREACH_5(SETUP, menuCutSize, buttonCutSize, controlCutSize,
    windowCutSize, dialogCutSize)
  QOOL_FOREACH_3(
    SETUP, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
  QOOL_FOREACH_2(SETUP, windowElementSpacing, windowEdgeSpacing)
  SETUP(animationEnabled)
  SETUP(papaWords)
#undef SETUP
} // setup_properties

#define IMPL_AGENT(a, b)                                               \
  ThemeValueGroupAgent* Style::a() const {                             \
    return m_agents[b];                                                \
  }

IMPL_AGENT(active, Theme::Active)
IMPL_AGENT(inactive, Theme::Inactive)
IMPL_AGENT(disabled, Theme::Disabled)
IMPL_AGENT(constants, Theme::Constants)
IMPL_AGENT(custom, Theme::Custom)

#undef IMPL_AGENT

QOOL_NS_END
