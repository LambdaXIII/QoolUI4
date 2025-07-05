#ifndef QOOL_STYLE_H
#define QOOL_STYLE_H

#include "qool_theme.h"
#include "qool_themevaluegroupagent.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros.hpp"
#include "qoolns.hpp"

#include <QBindable>
#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QQuickAttachedPropertyPropagator>
#include <QQuickItem>

QOOL_NS_BEGIN

class Style: public QQuickAttachedPropertyPropagator {
  Q_OBJECT
  QML_ELEMENT
  QML_ATTACHED(QOOL_NS::Style)

public:
  explicit Style(QObject* parent = nullptr);
  ~Style() = default;

  static Style* qmlAttachedProperties(QObject* object);

  Q_INVOKABLE QVariant value(
    const QString& key, const QVariant& defvalue = {}) const;
  Q_INVOKABLE void setValue(const QString& key, const QVariant& value);

  Q_SIGNAL void valueChanged(QString);

protected:
  bool m_customed { false };
  QHash<Theme::Groups, ThemeValueGroupAgent*> m_agents;
  QOOL_BINDABLE_MEMBER(Style, Style*, attachedParent);
  QOOL_BINDABLE_MEMBER(Style, QQuickItem*, parentItem);
  QOOL_BINDABLE_MEMBER(Style, bool, windowActived);
  Q_SLOT void update_windowActived();

  QOOL_BINDABLE_MEMBER(Style, bool, parentEnabled);
  Q_SLOT void update_parentEnabled();

  void attachedParentChange(QQuickAttachedPropertyPropagator* newParent,
    QQuickAttachedPropertyPropagator* oldParent) override;
  bool event(QEvent* e) override;

  void set_parentItem(QObject* x);
  void set_attachedParent(QObject* x);

  void setup_properties();
  Q_SLOT void reload_theme();

  void propagateTheme();
  void inherit(Style* other);

  QOOL_BINDABLE_MEMBER(Style, Theme::Groups, currentGroup)
  QOOL_BINDABLE_MEMBER(Style, Theme, currentTheme);

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(
    Style, QString, theme)
  QOOL_PROPERTY_CONSTANT_DECL(ThemeValueGroupAgent*, active)
  QOOL_PROPERTY_CONSTANT_DECL(ThemeValueGroupAgent*, inactive)
  QOOL_PROPERTY_CONSTANT_DECL(ThemeValueGroupAgent*, disabled)
  QOOL_PROPERTY_CONSTANT_DECL(ThemeValueGroupAgent*, constants)
  QOOL_PROPERTY_CONSTANT_DECL(ThemeValueGroupAgent*, custom)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    Style, bool, animationEnabled)

#define DECL(T, N)                                                     \
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(Style, T, N)

#define __COLOR(N) DECL(QColor, N)
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
    windowText, button, buttonText, placeHolderText, toolTipBase,
    toolTipText)
#undef __COLOR

#define __INT(N) DECL(int, N)
  QOOL_FOREACH_8(__INT, textSize, titleTextSize, toolTipTextSize,
    importantTextSize, decorativeTextSize, controlTitleTextSize,
    controlTextSize, windowTitleTextSize)
#undef __INT

#define __REAL(N) DECL(qreal, N)
  QOOL_FOREACH_3(
    __REAL, instantDuration, transitionDuration, movementDuration)
  QOOL_FOREACH_5(__REAL, menuCutSize, buttonCutSize, controlCutSize,
    windowCutSize, dialogCutSize)
  QOOL_FOREACH_3(
    __REAL, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
  QOOL_FOREACH_2(__REAL, windowElementSpacing, windowEdgeSpacing)
#undef __REAL

  DECL(QStringList, papaWords)

#undef DECL
};

QOOL_NS_END

#endif // QOOL_STYLE_H
