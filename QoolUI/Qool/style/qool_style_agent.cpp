#include "qool_style_agent.h"

#include "qool_styledb.h"
#include "qoolcommon/debug.hpp"

#include <QColor>

QOOL_NS_BEGIN

StyleAgent::StyleAgent(QObject* parent)
  : QObject(parent) {
  m_active = new StyleAgentGroup(this);
  m_inactive = new StyleAgentGroup(this);
  m_disabled = new StyleAgentGroup(this);
  m_themePackage.setBinding([&] {
    const QString name = m_theme.value();
    return StyleDB::instance()->theme(name);
  });

  connect(this, SIGNAL(themePackageChanged()), this,
    SLOT(updateValueGroups()));

  setupBindings();
  set_theme("system");
}

void StyleAgent::dumpInfo() const {
  xDebugQ << xDBGQPropertyList;
}

ThemePackage StyleAgent::themePackage() const {
  return m_themePackage.value();
}

void StyleAgent::updateValueGroups() {
  Qt::beginPropertyUpdateGroup();
  m_active->setDefaults(m_themePackage.value().active());
  m_inactive->setDefaults(m_themePackage.value().inactive());
  m_disabled->setDefaults(m_themePackage.value().disabled());
  Qt::endPropertyUpdateGroup();
}

void StyleAgent::setupBindings() {
#define SETUP(NAME)                                                    \
  m_##NAME.setBinding(                                                 \
    [&] { return m_active->bindable_##NAME().value(); });
  SETUP(animationEnabled)
  SETUP(papaWords)

  QOOL_FOREACH_10(SETUP, window, windowText, base, alternateBase,
    toolTipBase, toolTipText, placeholderText, text, button, buttonText)
  QOOL_FOREACH_5(SETUP, light, midlight, dark, mid, shadow)
  QOOL_FOREACH_3(SETUP, highlight, accent, highlightedText)
  QOOL_FOREACH_2(SETUP, link, linkVisited)
  QOOL_FOREACH_3(SETUP, positive, negative, warning)

  QOOL_FOREACH_5(SETUP, windowCutSize, controlCutSize, menuCutSize,
    dialogCutSize, buttonCutSize)
  QOOL_FOREACH_2(SETUP, transitionDuration, movementDuration)
  QOOL_FOREACH_6(SETUP, titleTextSize, toolTipTextSize, controlTextSize,
    importantTextSize, decorativeTextSize, controlTitleTextSize)
#undef SETUP
}

#define IMPL(TYPE, NAME)                                               \
  TYPE StyleAgent::NAME() const {                                      \
    return m_##NAME.value();                                           \
  }                                                                    \
  void StyleAgent::set_##NAME(const TYPE& v) {                         \
    m_active->set_##NAME(v);                                           \
  }

IMPL(QStringList, papaWords)
IMPL(bool, animationEnabled)

#define IMPL_COLOR(NAME) IMPL(QColor, NAME)
QOOL_FOREACH_10(IMPL_COLOR, window, windowText, base, alternateBase,
  toolTipBase, toolTipText, placeholderText, text, button, buttonText)
QOOL_FOREACH_5(IMPL_COLOR, light, midlight, dark, mid, shadow)
QOOL_FOREACH_3(IMPL_COLOR, highlight, accent, highlightedText)
QOOL_FOREACH_2(IMPL_COLOR, link, linkVisited)
QOOL_FOREACH_3(IMPL_COLOR, positive, negative, warning)
#undef IMPL_COLOR

#define IMPL_REAL(NAME) IMPL(qreal, NAME)
QOOL_FOREACH_5(IMPL_REAL, windowCutSize, controlCutSize, menuCutSize,
  dialogCutSize, buttonCutSize)
QOOL_FOREACH_2(IMPL_REAL, transitionDuration, movementDuration)
#undef IMPL_REAL

#define IMPL_INT(NAME) IMPL(int, NAME)
QOOL_FOREACH_6(IMPL_INT, titleTextSize, toolTipTextSize,
  controlTextSize, importantTextSize, decorativeTextSize,
  controlTitleTextSize)
#undef IMPL_INT

#undef IMPL

QOOL_NS_END
