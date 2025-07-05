#include "qool_system_theme.h"

#include <QGuiApplication>
#include <QStringList>

QOOL_NS_BEGIN

QOOL_SIMPLE_SINGLETON_QT_IMPL(SystemTheme)

SystemTheme::SystemTheme()
  : Theme() {
  const auto palette = qGuiApp->palette();

  const QStringList papa { "Qool!", "Qoool!!", "Qoooool!!!" };

#define CONSTANTS(T, N, V)                                             \
  m_data[Constants].insert(#N, QVariant::fromValue<T>(V));

  CONSTANTS(bool, animationEnabled, true)
  CONSTANTS(QStringList, papaWords, papa)
  CONSTANTS(qreal, instantDuration, 100)
  CONSTANTS(qreal, transitionDuration, 200)
  CONSTANTS(qreal, movementDuration, 400)
  CONSTANTS(qreal, menuCutSize, 5)
  CONSTANTS(qreal, buttonCutSize, 5)
  CONSTANTS(int, textSize, 14)
  CONSTANTS(int, titleTextSize, 16)
  CONSTANTS(int, toolTipTextSize, 10)
  CONSTANTS(int, importantTextSize, 28)
  CONSTANTS(int, decorativeTextSize, 10)
  CONSTANTS(qreal, controlCutSize, 10)
  CONSTANTS(qreal, controlBorderWidth, 1)
  CONSTANTS(int, controlTitleTextSize, 10)
  CONSTANTS(int, controlTextSize, 12)
  CONSTANTS(qreal, windowCutSize, 35)
  CONSTANTS(qreal, windowElementSpacing, 5)
  CONSTANTS(qreal, windowEdgeSpacing, 5)
  CONSTANTS(int, windowTitleTextSize, 14)
  CONSTANTS(qreal, windowBorderWidth, 1)
  CONSTANTS(qreal, dialogCutSize, 10)
  CONSTANTS(qreal, dialogBorderWidth, 1)

  CONSTANTS(QColor, white, QColor("white"))
  CONSTANTS(QColor, silver, QColor("silver"))
  CONSTANTS(QColor, grey, QColor("grey"))
  CONSTANTS(QColor, black, QColor("black"))
  CONSTANTS(QColor, red, QColor("red"))
  CONSTANTS(QColor, maroon, QColor("maroon"))
  CONSTANTS(QColor, yellow, QColor("yellow"))
  CONSTANTS(QColor, olive, QColor("olive"))
  CONSTANTS(QColor, lime, QColor("lime"))
  CONSTANTS(QColor, green, QColor("green"))
  CONSTANTS(QColor, aqua, QColor("aqua"))
  CONSTANTS(QColor, cyan, QColor("cyan"))
  CONSTANTS(QColor, teal, QColor("teal"))
  CONSTANTS(QColor, blue, QColor("blue"))
  CONSTANTS(QColor, navy, QColor("navy"))
  CONSTANTS(QColor, purple, QColor("purple"))
  CONSTANTS(QColor, fuchsia, QColor("fuchsia"))
  CONSTANTS(QColor, orange, QColor("orange"))
  CONSTANTS(QColor, brown, QColor("brown"))
  CONSTANTS(QColor, pink, QColor("pink"))

  CONSTANTS(QColor, positive, QColor("green"))
  CONSTANTS(QColor, negative, QColor("red"))
  CONSTANTS(QColor, warning, QColor("pink"))

  CONSTANTS(QColor, controlBackgroundColor,
    palette.color(QPalette::Active, QPalette::Button))
  CONSTANTS(QColor, controlBorderColor,
    palette.color(QPalette::Active, QPalette::AlternateBase))

#undef CONSTANTS

#define ACTIVE(N, F)                                                   \
  m_data[Active].insert(#N, QVariant::fromValue(palette.color(         \
                              QPalette::Active, QPalette::F)));

  ACTIVE(accent, Accent)
  ACTIVE(light, Light)
  ACTIVE(midlight, Midlight)
  ACTIVE(dark, Dark)
  ACTIVE(mid, Mid)
  ACTIVE(shadow, Shadow)
  ACTIVE(highlight, Highlight)
  ACTIVE(highlightedText, HighlightedText)
  ACTIVE(link, Link)
  ACTIVE(linkVisited, LinkVisited)
  ACTIVE(text, Text)
  ACTIVE(base, Base)
  ACTIVE(alternateBase, AlternateBase)
  ACTIVE(window, Window)
  ACTIVE(windowText, WindowText)
  ACTIVE(button, Button)
  ACTIVE(buttonText, ButtonText)
  ACTIVE(placeholderText, PlaceholderText)
  ACTIVE(toolTipBase, ToolTipBase)
  ACTIVE(toolTipText, ToolTipText)

#undef ACTIVE

#define INACTIVE(N, F)                                                 \
  m_data[Active].insert(#N, QVariant::fromValue(palette.color(         \
                              QPalette::Inactive, QPalette::F)));
  INACTIVE(accent, Accent)
  INACTIVE(light, Light)
  INACTIVE(midlight, Midlight)
  INACTIVE(dark, Dark)
  INACTIVE(mid, Mid)
  INACTIVE(shadow, Shadow)
  INACTIVE(highlight, Highlight)
  INACTIVE(highlightedText, HighlightedText)
  INACTIVE(link, Link)
  INACTIVE(linkVisited, LinkVisited)
  INACTIVE(text, Text)
  INACTIVE(base, Base)
  INACTIVE(alternateBase, AlternateBase)
  INACTIVE(window, Window)
  INACTIVE(windowText, WindowText)
  INACTIVE(button, Button)
  INACTIVE(buttonText, ButtonText)
  INACTIVE(placeholderText, PlaceholderText)
  INACTIVE(toolTipBase, ToolTipBase)
  INACTIVE(toolTipText, ToolTipText)
#undef INACTIVE

#define DISABLED(N, F)                                                 \
  m_data[Active].insert(#N, QVariant::fromValue(palette.color(         \
                              QPalette::Disabled, QPalette::F)));
  DISABLED(accent, Accent)
  DISABLED(light, Light)
  DISABLED(midlight, Midlight)
  DISABLED(dark, Dark)
  DISABLED(mid, Mid)
  DISABLED(shadow, Shadow)
  DISABLED(highlight, Highlight)
  DISABLED(highlightedText, HighlightedText)
  DISABLED(link, Link)
  DISABLED(linkVisited, LinkVisited)
  DISABLED(text, Text)
  DISABLED(base, Base)
  DISABLED(alternateBase, AlternateBase)
  DISABLED(window, Window)
  DISABLED(windowText, WindowText)
  DISABLED(button, Button)
  DISABLED(buttonText, ButtonText)
  DISABLED(placeholderText, PlaceholderText)
  DISABLED(toolTipBase, ToolTipBase)
  DISABLED(toolTipText, ToolTipText)
#undef DISABLED

  m_metadata["name"] = QString("system");
  m_metadata["author"] = QString("QoolUI");
  m_metadata["description"] =
    QString("Default theme inherited from system palette.");
}

QOOL_NS_END
