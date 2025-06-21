#include "qool_stylemanager.h"

#include "interfaces/qool_interface_themeloader.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/plugin_loader.hpp"

#include <QCache>
#include <QColor>
#include <QMutex>

QOOL_NS_BEGIN

QOOL_SIMPLE_SINGLETON_QT_IMPL(StyleManager)

StyleManager::StyleManager()
  : QObject { nullptr } {
  connect(this, SIGNAL(internalValueChanged(QString, QVariant)), this,
    SLOT(whenInternalValueChanged(QString, QVariant)),
    Qt::AutoConnection);
  connect(this, SIGNAL(currentThemeChanged()), this,
    SLOT(whenCurrentThemeChanged()));
  auto_install_theme_loaders();
  set_currentTheme(m_themes.firstKey());
}

void StyleManager::set(const QString& key, const QVariant& value) {
  const auto old = m_currentValues.value(key);
  if (old == value)
    return;
  m_currentValues.set_value(key, value);
  emit internalValueChanged(key, value);
}

QVariant StyleManager::get(
  const QString& key, const QVariant& defaultValue) const {
  return m_currentValues.value(key, defaultValue);
}

void StyleManager::auto_install_theme_loaders() {
  auto plugins = PluginLoader<ThemeLoader>::loadInstances();
  if (plugins.isEmpty()) {
    xWarningQ << tr("未找到合法的主题加载器，UI显示可能异常");
    return;
  }
  Qt::beginPropertyUpdateGroup();
  for (auto iter = plugins.constBegin(); iter != plugins.constEnd();
    ++iter)
    install_themes(iter.value()->themes());
  Qt::endPropertyUpdateGroup();
}

void StyleManager::install_themes(const ThemeMap& themes) {
  QWriteLocker locker(&m_themesLock);
  const auto names = themes.keys();
  for (const auto& name : names) {
    if (m_themes.contains(name))
      m_themes[name].insert(themes[name]);
    else
      m_themes.insert(name, themes[name]);
    xDebugQ << tr("主题 %1 已安装").arg(name);
  }
  emit themeKeysChanged();
}

qreal StyleManager::visualBrightness(const QColor& color) {
  const auto c = color.toRgb();
  return c.redF() * 0.299 + c.greenF() * 0.587 + c.blueF() * 0.114;
}

QColor StyleManager::contrastingColor(
  const QColor& color, const QColor& dark, const QColor& light) {
  constexpr qreal thresholdDark = 0.4;
  constexpr qreal thresholdLight = 0.6;
  const qreal brightness = visualBrightness(color);
  const qreal brightnessDark = visualBrightness(dark);
  const qreal brightnessLight = visualBrightness(light);
  if (brightnessDark <= brightnessLight)
    return brightness >= thresholdDark ? dark : light;
  return brightness >= thresholdLight ? light : dark;
}

QStringList StyleManager::themeKeys() const {
  QReadLocker locker(&m_themesLock);
  return m_themes.keys();
}

QString StyleManager::currentTheme() const {
  return m_currentTheme.value();
}

void StyleManager::set_currentTheme(const QString& key) {
  QString name = key;
  if (! m_themes.contains(key)) {
    xDebugQ << tr("主题 %1 不存在，将恢复为默认主题").arg(key);
    name = m_themes.firstKey();
  }
  if (name == m_currentTheme.value())
    return;

  QReadLocker locker(&m_themesLock);
  auto new_theme = m_themes.value(name);
  locker.unlock();

  m_currentValues.clear();
  m_currentValues.insertDefaults(new_theme);

  m_currentTheme = name;

  xDebugQ << tr("主题 %1 已加载").arg(name);
}

void StyleManager::whenInternalValueChanged(
  QString name, QVariant value) {
#define CHECK_KEY(_K_)                                                 \
  if (name == #_K_)                                                    \
    emit _K_##Changed();
  QOOL_FOREACH_10(CHECK_KEY, window, windowText, Base, AlternateBase,
    ToolTipBase, ToolTipText, PlaceholderText, Text, Button, ButtonText)
  QOOL_FOREACH_5(CHECK_KEY, light, midlight, dark, mid, shadow)
  QOOL_FOREACH_3(CHECK_KEY, highlight, accent, highlightedText)
  QOOL_FOREACH_2(CHECK_KEY, link, linkVisited)
  QOOL_FOREACH_3(CHECK_KEY, positive, negative, warning)
  QOOL_FOREACH_5(CHECK_KEY, windowCutSize, controlCutSize, menuCutSize,
    dialogCutSize, buttonCutSize)
  QOOL_FOREACH_2(CHECK_KEY, transitionDuration, movementDuration)
  QOOL_FOREACH_5(CHECK_KEY, titleTextSize, toolTipTextSize,
    controlTextSize, importantTextSize, decorateTextSize)
#undef CHECK_KEY
  emit valueChanged(name, value);
} // whenInternalValueChanged

void StyleManager::whenCurrrentThemeChanged() {
  Qt::beginPropertyUpdateGroup();

#define NOTIFY(N) emit N##Changed();

  QOOL_FOREACH_10(NOTIFY, window, windowText, Base, AlternateBase,
    ToolTipBase, ToolTipText, PlaceholderText, Text, Button, ButtonText)
  QOOL_FOREACH_5(NOTIFY, light, midlight, dark, mid, shadow)
  QOOL_FOREACH_3(NOTIFY, highlight, accent, highlightedText)
  QOOL_FOREACH_2(NOTIFY, link, linkVisited)
  QOOL_FOREACH_3(NOTIFY, positive, negative, warning)
  QOOL_FOREACH_5(NOTIFY, windowCutSize, controlCutSize, menuCutSize,
    dialogCutSize, buttonCutSize)
  QOOL_FOREACH_2(NOTIFY, transitionDuration, movementDuration)
  QOOL_FOREACH_5(NOTIFY, titleTextSize, toolTipTextSize,
    controlTextSize, importantTextSize, decorateTextSize)

#undef NOTIFY

  const auto keys = m_currentValues.keys();
  for (const auto& key : keys)
    emit valueChanged(key, m_currentValues.value(key));

  Qt::endPropertyUpdateGroup();
} // whenCurrentThemeChanged

#define IMPL_V(T, N)                                                   \
  T StyleManager::N() const {                                          \
    return m_currentValues.value<T>(#N);                               \
  }                                                                    \
  void StyleManager::set_##N(const T& v) {                             \
    const auto old = N();                                              \
    if (old == v)                                                      \
      return;                                                          \
    QVariant value = QVariant::fromValue<T>(v);                        \
    m_currentValues.set_value(#N, value);                              \
    emit valueChanged(#N, value);                                      \
    emit N##Changed();                                                 \
  }

#define IMPL_COLOR(N) IMPL_V(QColor, N)
QOOL_FOREACH_10(IMPL_COLOR, window, windowText, Base, AlternateBase,
  ToolTipBase, ToolTipText, PlaceholderText, Text, Button, ButtonText)
QOOL_FOREACH_5(IMPL_COLOR, light, midlight, dark, mid, shadow)
QOOL_FOREACH_3(IMPL_COLOR, highlight, accent, highlightedText)
QOOL_FOREACH_2(IMPL_COLOR, link, linkVisited)
QOOL_FOREACH_3(IMPL_COLOR, positive, negative, warning)
#undef IMPL_COLOR

#define IMPL_REAL(N) IMPL_V(qreal, N)
QOOL_FOREACH_5(IMPL_REAL, windowCutSize, controlCutSize, menuCutSize,
  dialogCutSize, buttonCutSize)
QOOL_FOREACH_2(IMPL_REAL, transitionDuration, movementDuration)
#undef IMPL_REAL

#define IMPL_INT(N) IMPL_V(int, N)
QOOL_FOREACH_5(IMPL_INT, titleTextSize, toolTipTextSize,
  controlTextSize, importantTextSize, decorateTextSize)
#undef IMPL_INT
#undef IMPL_V

QOOL_NS_END
