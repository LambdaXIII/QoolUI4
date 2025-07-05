#ifndef QOOL_THEMEVALUEGROUPAGENT_H
#define QOOL_THEMEVALUEGROUPAGENT_H

#include "qool_theme.h"
#include "qoolcommon/default_variant_map.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QReadWriteLock>
#include <QVariant>

QOOL_NS_BEGIN

class ThemeValueGroupAgent: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit ThemeValueGroupAgent(QObject* parent = nullptr);
  ThemeValueGroupAgent(Theme::Groups group, QObject* parent = nullptr);
  ~ThemeValueGroupAgent() = default;

  Q_INVOKABLE QVariant value(
    const QString& key, const QVariant& defvalue = {}) const;
  Q_INVOKABLE void setValue(const QString& key, const QVariant& value);

  void set_data(const QVariantMap& datas);

  Q_INVOKABLE void reset(const QString& key);
  Q_INVOKABLE void reset();

  Q_SIGNAL void valueChanged(QString);
  Q_SIGNAL void valueCustomed(); // when user explicitly changed values

  void inherit(ThemeValueGroupAgent* other);

protected:
  DefaultVariantMap m_data;
  void when_value_changed(const QStringList& keys = {});

  /******** Properties *******/
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(
    Theme::Groups, currentGroup, Theme::Active)

#define DECL(T, N)                                                     \
public:                                                                \
  T N() const;                                                         \
  void set_##N(const T& v);                                            \
  Q_SIGNAL void N##Changed();                                          \
  QBindable<T> bindable_##N();                                         \
                                                                       \
private:                                                               \
  Q_PROPERTY(T N READ N WRITE set_##N NOTIFY N##Changed)

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

  DECL(bool, animationEnabled)
  DECL(QStringList, papaWords)

#undef DECL

}; // ThemeValueGroupAgent

QOOL_NS_END
#endif // QOOL_THEMEVALUEGROUPAGENT_H
