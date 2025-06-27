#ifndef QOOL_STYLE_AGENT_H
#define QOOL_STYLE_AGENT_H

#include "qool_style_agent_group.h"
#include "qool_theme_package.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class StyleAgent: public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(Style)
public:
  explicit StyleAgent(QObject* parent = nullptr);
  Q_INVOKABLE ThemePackage themePackage() const;
  Q_INVOKABLE void dumpInfo() const;

  Q_SIGNAL void valueChanged(const QString& key, const QVariant& value);

private:
  QOOL_BINDABLE_MEMBER(StyleAgent, ThemePackage, themePackage)
  Q_SLOT void updateValueGroups();
  void setupBindings();

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    StyleAgent, QString, theme)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(StyleAgentGroup*, active, nullptr)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(
    StyleAgentGroup*, inactive, nullptr)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(
    StyleAgentGroup*, disabled, nullptr)

  // Default Properties
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(
    StyleAgent, bool, animationEnabled)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(
    StyleAgent, QStringList, papaWords)

#define DECL_COLOR(NAME)                                               \
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(                    \
    StyleAgent, QColor, NAME)

  QOOL_FOREACH_10(DECL_COLOR, window, windowText, base, alternateBase,
    toolTipBase, toolTipText, placeholderText, text, button, buttonText)
  QOOL_FOREACH_5(DECL_COLOR, light, midlight, dark, mid, shadow)
  QOOL_FOREACH_3(DECL_COLOR, highlight, accent, highlightedText)
  QOOL_FOREACH_2(DECL_COLOR, link, linkVisited)
  QOOL_FOREACH_3(DECL_COLOR, positive, negative, warning)
#undef DECL_COLOR

#define DECL_REAL(NAME)                                                \
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(                    \
    StyleAgent, qreal, NAME)

  QOOL_FOREACH_5(DECL_REAL, windowCutSize, controlCutSize, menuCutSize,
    dialogCutSize, buttonCutSize)
  QOOL_FOREACH_2(DECL_REAL, transitionDuration, movementDuration)
#undef DECL_REAL

#define DECL_INT(NAME)                                                 \
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(                    \
    StyleAgent, int, NAME)

  QOOL_FOREACH_5(DECL_INT, titleTextSize, toolTipTextSize,
    controlTextSize, importantTextSize, decorativeTextSize)
#undef DECL_INT
};

QOOL_NS_END

#endif // QOOL_STYLE_AGENT_H