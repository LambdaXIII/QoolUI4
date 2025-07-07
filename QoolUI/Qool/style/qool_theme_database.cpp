#include "qool_theme_database.h"

#include "qool_interface_themeloader.h"
#include "qool_system_theme.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/plugin_loader.hpp"

QOOL_NS_BEGIN

QOOL_SIMPLE_SINGLETON_QT_IMPL(ThemeDatabase)

ThemeDatabase::ThemeDatabase()
  : QAbstractListModel(nullptr)
  , m_mutex { new QMutex } {
  installTheme(*SystemTheme::instance());
  auto_install_themes();
}

ThemeDatabase::~ThemeDatabase() {
  if (m_mutex)
    delete m_mutex;
}

Theme ThemeDatabase::theme(const QString& name) const {
  const auto key =
    m_themeNames.contains(name) ? name : m_themeNames.constFirst();
  return m_themes[key];
}

QHash<int, QByteArray> ThemeDatabase::roleNames() const {
  static QHash<int, QByteArray> names;
  if (names.isEmpty()) {
    names = QAbstractListModel::roleNames();
    names[NameRole] = "name";
    names[ThemeRole] = "theme";
    names[MetadataRole] = "metadata";
    names[ConstantsRole] = "constants";
    names[ActiveRole] = "active";
    names[InactiveRole] = "inactive";
    names[DisabledRole] = "disabled";
    names[CustomRole] = "custom";
  }
  return names;
}

int ThemeDatabase::rowCount(const QModelIndex& parent) const {
  return m_themes.count();
}

QVariant ThemeDatabase::data(const QModelIndex& index, int role) const {
  if (! index.isValid() || index.row() >= m_themes.count())
    return {};

  const int row = index.row();
  const QString& name = m_themeNames.at(row);

  switch (role) {
  case Qt::DisplayRole:
  case NameRole:
    return name;
    break;
  case ThemeRole:
    return QVariant::fromValue(m_themes.value(name));
    break;
  case ConstantsRole:
    return QVariant::fromValue(
      m_themes[name].flatMap(Theme::Constants));
    break;
  case ActiveRole:
    return QVariant::fromValue(m_themes[name].flatMap(Theme::Active));
    break;
  case InactiveRole:
    return QVariant::fromValue(m_themes[name].flatMap(Theme::Inactive));
    break;
  case DisabledRole:
    return QVariant::fromValue(m_themes[name].flatMap(Theme::Disabled));
    break;
  case CustomRole:
    return QVariant::fromValue(m_themes[name].flatMap(Theme::Custom));
    break;
  }
  return {};
}

QVariant ThemeDatabase::anyValue(Theme::Groups group,
  const QString& key, const QVariant& defvalue) const {
  for (auto i = m_themes.constBegin(); i != m_themes.constEnd(); ++i) {
    if (i.value().contains(group, key))
      return i.value().value(group, key);
  }
  return defvalue;
}

QVariant ThemeDatabase::anyValue(
  const QString& key, const QVariant& defvalue) const {
  for (auto i = m_themes.constBegin(); i != m_themes.constEnd(); ++i) {
    if (i.value().contains(key))
      return i.value().value(Theme::Active, key);
  }
  return defvalue;
}

qreal ThemeDatabase::visualBrightness(QColor color) {
  static QHash<QString, qreal> cache;
  color = color.toRgb();
  const auto name = color.name().toUpper();
  if (! cache.contains(name))
    cache[name] = color.redF() * 0.299 + color.greenF() * 0.587
                  + color.blueF() * 0.114;
  return cache[name];
}

QColor ThemeDatabase::recommendForeground(
  const QColor& bgColor, const QColor& light, const QColor& dark) {
  const qreal brightness = visualBrightness(bgColor);
  const qreal b_dark = visualBrightness(dark);
  const qreal b_light = visualBrightness(light);
  if (b_dark <= b_light)
    return brightness >= 0.6 ? dark : light;
  return brightness >= 0.4 ? light : dark;
}

void ThemeDatabase::auto_install_themes() {
  auto plugins = PluginLoader<ThemeLoader>::loadInstances();
  if (plugins.isEmpty()) {
    xWarningQ << "No ThemeLoader installed -- which is impossible, "
                 "because the qool_default_theme_loader should be "
                 "installed at least. QoolUI might appear strangely.";
    return;
  }

  for (auto iter = plugins.constBegin(); iter != plugins.constEnd();
    ++iter) {
    const QList<ThemeLoader::Package> themes = iter.value()->themes();
    xDebugQ << "Plugin" << xDBGGreen << iter.key() << xDBGReset
            << "provides" << xDBGYellow << themes.length() << xDBGReset
            << "theme(s).";
    for (const auto& t : themes) {
      Theme theme(t.metadata, t.constants, t.active, t.inactive,
        t.disabled, t.custom);
      installTheme(theme);
    } // for themes
  } // for plugins

  xInfoQ << "Pluigins loaded." << xDBGYellow << m_themes.count()
         << xDBGReset << "theme(s) installed.";
}

void ThemeDatabase::installTheme(Theme theme) {
  const QString name = theme.name();

  if (name.isEmpty() || m_themeNames.contains(name)) {
    xDebugQ << "\"" << name << "\""
            << "is not a qualified name, can not install it.";
    return;
  }

  QMutexLocker locker(m_mutex);
  const int lastRow = m_themeNames.length();

  beginInsertRows({}, lastRow, lastRow);
  m_themes.insert(name, theme);
  m_themeNames.append(name);
  endInsertRows();
  xDebugQ << "Theme installed:" << xDBGGreen << name << xDBGReset;
  emit themeInstalled(name);
}

QStringList ThemeDatabase::themes() const {
  return m_themeNames;
}

int ThemeDatabase::count() const {
  return m_themeNames.length();
}

QOOL_NS_END
