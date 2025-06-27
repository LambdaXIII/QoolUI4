#ifndef QOOL_STYLE_DB_H
#define QOOL_STYLE_DB_H

#include "qool_theme_package.h"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QAbstractListModel>
#include <QMutex>
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class StyleDB: public QAbstractListModel {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  QOOL_SIMPLE_SINGLETON_QML_CREATE(StyleDB)
  QOOL_SIMPLE_SINGLETON_DECL(StyleDB)
public:
  Q_INVOKABLE ThemePackage theme(const QString& name) const;
  Q_SIGNAL void themeInstalled(const QString& name);

  enum Roles {
    NameRole = Qt::UserRole + 1,
    ThemePackageRole,
    ActiveRole,
    InactiveRole,
    DisabledRole
  };
  QHash<int, QByteArray> roleNames() const override;
  int rowCount(
    const QModelIndex& parent = QModelIndex()) const override;
  QVariant data(const QModelIndex& index, int role) const override;

private:
  QMap<QString, ThemePackage> m_packages;
  QStringList m_themes;
  QMutex m_mutex;
  void auto_install_themes();
  void installTheme(const ThemePackage& package);

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_DECL(QStringList, themes)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_DECL(int, count)
};

QOOL_NS_END

#endif // QOOL_STYLE_DB_H