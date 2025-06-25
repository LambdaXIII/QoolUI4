#include "qool_default_theme.h"

#include <QGuiApplication>
#include <QMutex>
#include <QPalette>

QOOL_NS_BEGIN

QOOL_SIMPLE_SINGLETON_QT_IMPL(DefaultTheme)
DefaultTheme::DefaultTheme() {
  const auto palette = qApp->palette();
#define SET_COLOR(NAME, ROLE)                                          \
  m_pData->active[#NAME] =                                             \
    palette.color(QPalette::Active, QPalette::ROLE);                   \
  m_pData->inactive[#NAME] =                                           \
    palette.color(QPalette::Inactive, QPalette::ROLE);                 \
  m_pData->disabled[#NAME] =                                           \
    palette.color(QPalette::Disabled, QPalette::ROLE);

  SET_COLOR(window, Window)
  SET_COLOR(windowText, WindowText)
  SET_COLOR(base, Base)
  SET_COLOR(alternateBase, AlternateBase)
  SET_COLOR(toolTipBase, ToolTipBase)
  SET_COLOR(toolTipText, ToolTipText)
  SET_COLOR(text, Text)
  SET_COLOR(button, Button)
  SET_COLOR(buttonText, ButtonText)
  SET_COLOR(brightText, BrightText)

  SET_COLOR(light, Light)
  SET_COLOR(midlight, Midlight)
  SET_COLOR(dark, Dark)
  SET_COLOR(mid, Mid)
  SET_COLOR(shadow, Shadow)
  SET_COLOR(highlight, Highlight)
  SET_COLOR(highlightedText, HighlightedText)
  SET_COLOR(link, Link)
  SET_COLOR(linkVisited, LinkVisited)

  SET_COLOR(accent, Accent)
#undef SET_COLOR

#define SET_DEF(T, N, V)                                               \
  m_pData->active[#N] = QVariant::fromValue<T>(V);

  SET_DEF(qreal, windowCutSize, 35)
  SET_DEF(qreal, controlCutSize, 10)
  SET_DEF(qreal, menuCutSize, 10)
  SET_DEF(qreal, dialogCutSize, 10);
  SET_DEF(qreal, buttonCutSize, 10);
  SET_DEF(qreal, transitionDuration, 200);
  SET_DEF(qreal, movementDuration, 400);

  SET_DEF(int, textSize, 14)
  SET_DEF(int, toolTipTextSize, 10);
  SET_DEF(int, controlTextSize, 12);
  SET_DEF(int, controlTitleTextSize, 10);
  SET_DEF(int, importantTextSize, 28);
  SET_DEF(int, decorativeTextSize, 10);

#undef SET_DEF

  m_pData->active["papaWords"] =
    QVariant(QStringList { "Pa!", "Pa!!!" });

  m_pData->active["animationEnabled"] = true;
}

QOOL_NS_END