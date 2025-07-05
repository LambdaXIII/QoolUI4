#ifndef QOOL_STYLE_H
#define QOOL_STYLE_H

#include "qool_smartobj.h"
#include "qool_theme.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolns.hpp"

#include <QBindable>
#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QQuickAttachedPropertyPropagator>
#include <QQuickItem>

Q_MOC_INCLUDE("qool_stylegroupagent.h")

QOOL_NS_BEGIN

class StyleGroupAgent;
class Style: public QQuickAttachedPropertyPropagator {
  Q_OBJECT
  QML_ELEMENT
  QML_ATTACHED(QOOL_NS::Style)

public:
  explicit Style(QObject* parent = nullptr);
  ~Style();

  static Style* qmlAttachedProperties(QObject* object);

  Q_INVOKABLE QVariant value(
    const QString& key, const QVariant& defvalue = {}) const;
  Q_INVOKABLE void setValue(const QString& key, const QVariant& value);

  Q_INVOKABLE QVariant value(Theme::Groups group, const QString& key,
    const QVariant& defvalue = {}) const;
  Q_INVOKABLE void setValue(
    Theme::Groups group, const QString& key, const QVariant& value);

  Q_SIGNAL void valueChanged(QString);
  Q_INVOKABLE void dumpInfo() const;

protected:
  friend class StyleGroupAgent;

  QHash<Theme::Groups, StyleGroupAgent*> m_agents;
  Theme::Groups m_currentGroup { Theme::Active };
  Theme m_currentTheme;
  SmartObject* m_sidekick;
  bool m_valueCustomed;

  Q_SIGNAL void internalValuesChanged(
    Theme::Groups group, QSet<QString> keys);
  Q_SLOT void dispatchValueSignals(
    Theme::Groups group, QSet<QString> keys);
  bool internalSetValue(
    Theme::Groups group, const QString& key, const QVariant& value);

  void attachedParentChange(QQuickAttachedPropertyPropagator* newParent,
    QQuickAttachedPropertyPropagator* oldParent) override;

  void inherit(Style* other);
  Q_SLOT void inheritValues(Theme::Groups group, QSet<QString> keys);
  void propagateTheme();

  /********** PROPERTIES ***********/

  QOOL_PROPERTY_CONSTANT_DECL(StyleGroupAgent*, active)
  QOOL_PROPERTY_CONSTANT_DECL(StyleGroupAgent*, inactive)
  QOOL_PROPERTY_CONSTANT_DECL(StyleGroupAgent*, disabled)
  QOOL_PROPERTY_CONSTANT_DECL(StyleGroupAgent*, constants)
  QOOL_PROPERTY_CONSTANT_DECL(StyleGroupAgent*, custom)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QString, theme)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(bool, animationEnabled)

#define DECL(T, N) QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(T, N)

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
    windowText, button, buttonText, placeholderText, toolTipBase,
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
