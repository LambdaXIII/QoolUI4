#include "qool_styledb.h"

#include "qool_default_theme.h"
#include "qool_interface_themeloader.h"
#include "qoolcommon/debug.hpp"
#include "qoolcommon/plugin_loader.hpp"

#include <QColor>
#include <QMutex>

QOOL_NS_BEGIN

QOOL_SIMPLE_SINGLETON_QT_IMPL(StyleDB)
StyleDB::StyleDB()
  : QAbstractListModel { nullptr } {
  connect(this,
    SIGNAL(themeInstalled(QString)),
    this,
    SIGNAL(countChanged()));
  connect(this,
    SIGNAL(themeInstalled(QString)),
    this,
    SIGNAL(themesChanged()));

  installTheme(DefaultTheme::copy());
  auto_install_themes();
}

ThemePackage StyleDB::theme(const QString& name) const {
  const auto key = m_themes.contains(name) ? name : m_themes.first();
  return m_packages.value(name);
}

QHash<int, QByteArray> StyleDB::roleNames() const {
  static QHash<int, QByteArray> roles;
  if (roles.isEmpty()) {
    roles = QAbstractListModel::roleNames();
    roles[NameRole] = "name";
    roles[ThemePackageRole] = "theme";
    roles[ActiveRole] = "active";
    roles[InactiveRole] = "inactive";
    roles[DisabledRole] = "disabled";
  }
  return roles;
}

int StyleDB::rowCount(const QModelIndex& parent) const {
  return m_packages.count();
}

QVariant StyleDB::data(const QModelIndex& index, int role) const {
  if (! index.isValid() || index.row() >= m_packages.count()) {
    return QVariant();
  }

  const int row = index.row();
  const QString& name = m_themes.at(row);

  switch (role) {
  case Qt::DisplayRole:
  case NameRole:
    return m_themes.at(row);
    break;
  case ThemePackageRole:
    return QVariant::fromValue(m_packages.value(name));
    break;
  case ActiveRole:
    return { m_packages.value(name).active() };
    break;
  case InactiveRole:
    return { m_packages.value(name).inactive() };
    break;
  case DisabledRole:
    return { m_packages.value(name).disabled() };
    break;
  }
  return {};
}

QVariant StyleDB::anyValue(
  const QString& key, const QVariant& defaultValue) const {
  for (auto iter = m_packages.constBegin();
    iter != m_packages.constEnd();
    ++iter) {
    if (iter.value().contains(key))
      return iter.value().value(key);
  }
  return defaultValue;
  ;
}

qreal StyleDB::visualBrightness(QColor color) {
  color = color.toRgb();
  return color.redF() * 0.299 + color.greenF() * 0.587
         + color.blueF() * 0.114;
}

QColor StyleDB::recommendForeground(
  const QColor& bgColor, const QColor& light, const QColor& dark) {
  const qreal brightness = visualBrightness(bgColor);
  const qreal b_dark = visualBrightness(dark);
  const qreal b_light = visualBrightness(light);
  if (b_dark <= b_light)
    return brightness >= 0.6 ? dark : light;
  return brightness >= 0.4 ? light : dark;
}

void StyleDB::auto_install_themes() {
  auto plugins = PluginLoader<ThemeLoader>::loadInstances();
  if (plugins.isEmpty()) {
    xWarningQ << tr("未找到合法的主题加载器，UI显示可能异常");
    return;
  }

  for (auto iter = plugins.constBegin(); iter != plugins.constEnd();
    ++iter) {
    const auto themes = iter.value()->themes();
    xDebugQ << "Plugin" << xDBGGreen << iter.key() << xDBGReset
            << "provides" << xDBGYellow << themes.length() << xDBGReset
            << "theme(s).";
    for (const auto& t : themes) {
      ThemePackage theme(
        t.name, t.active, t.inactive, t.disabled, t.metadata);
      installTheme(theme);
    } // for themes
  } // for plugins

  xInfoQ << "Pluigins loaded." << xDBGYellow << m_themes.count()
         << xDBGReset << "theme(s) installed.";
}

void StyleDB::installTheme(const ThemePackage& theme) {
  const int last_row = m_themes.count();
  beginInsertRows(QModelIndex(), last_row, last_row);
  m_packages.insert(theme.name(), theme);
  m_themes.append(theme.name());
  endInsertRows();
  xDebugQ << "Theme installed:" << xDBGGreen << theme.name()
          << xDBGReset;
  emit themeInstalled(theme.name());
}

QStringList StyleDB::themes() const {
  return m_themes;
}

int StyleDB::count() const {
  return m_themes.count();
}

QOOL_NS_END
