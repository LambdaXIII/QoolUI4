#ifndef QOOL_STYLEMANAGER_H
#define QOOL_STYLEMANAGER_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/default_variant_map.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QReadWriteLock>

QOOL_NS_BEGIN

class StyleManager: public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(Style)
  QML_SINGLETON
  QOOL_SIMPLE_SINGLETON_DECL(StyleManager)
  QOOL_SIMPLE_SINGLETON_QML_CREATE(StyleManager)

public:
  using ThemeMap = QMap<QString, QVariantMap>;
  ~StyleManager() = default;
  Q_INVOKABLE void dumpInfo() const;

  Q_INVOKABLE void resetCurrentTheme();
  Q_INVOKABLE QVariantMap allColors() const;

  Q_INVOKABLE void set(const QString& key, const QVariant& value);
  Q_INVOKABLE QVariant get(
    const QString& key, const QVariant& defaultValue = {}) const;

  // static functions
  Q_INVOKABLE static qreal visualBrightness(const QColor& c);
  Q_INVOKABLE static QColor contrastingColor(const QColor& color,
    const QColor& darkColor = { "black" },
    const QColor& lightColor = { "white" });

  Q_SIGNAL void valueChanged(QString key, QVariant value);

protected:
  void auto_install_theme_loaders();
  void install_themes(const ThemeMap& themes);
  ThemeMap m_themes;
  DefaultVariantMap m_currentValues;
  mutable QReadWriteLock m_themesLock;
  Q_SIGNAL void internalValueChanged(QString key, QVariant value);
  Q_SLOT void whenInternalValueChanged(QString key, QVariant value);
  Q_SLOT void whenCurrentThemeChanged();

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_DECL(QStringList, themeKeys)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(
    StyleManager, QString, currentTheme)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(bool, animationEnabled, true)
  // QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QVariantList, papaWords)

#define DECL_COLOR(_N_)                                                \
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QColor, _N_)

  QOOL_FOREACH_10(DECL_COLOR, window, windowText, base, alternateBase,
    toolTipBase, toolTipText, placeholderText, text, button, buttonText)
  QOOL_FOREACH_5(DECL_COLOR, light, midlight, dark, mid, shadow)
  QOOL_FOREACH_3(DECL_COLOR, highlight, accent, highlightedText)
  QOOL_FOREACH_2(DECL_COLOR, link, linkVisited)
  QOOL_FOREACH_3(DECL_COLOR, positive, negative, warning)
  QOOL_FOREACH_2(DECL_COLOR, disabled, disabledText)
#undef DECL_COLOR

#define DECL_REAL(_N_)                                                 \
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(qreal, _N_)

  QOOL_FOREACH_5(DECL_REAL, windowCutSize, controlCutSize, menuCutSize,
    dialogCutSize, buttonCutSize)
  QOOL_FOREACH_2(DECL_REAL, transitionDuration, movementDuration)
#undef DECL_REAL

#define DECL_INT(_N_) QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(int, _N_)
  QOOL_FOREACH_5(DECL_INT, titleTextSize, toolTipTextSize,
    controlTextSize, importantTextSize, decorateTextSize)
#undef DECL_INT
}; // class StyleManager

QOOL_NS_END

#endif // QOOL_STYLEMANAGER_H
