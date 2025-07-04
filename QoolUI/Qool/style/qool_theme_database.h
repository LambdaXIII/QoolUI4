#ifndef QOOL_THEME_DATABASE_H
#define QOOL_THEME_DATABASE_H

#include "qool_theme.h"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QAbstractListModel>
#include <QColor>
#include <QMutex>
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class ThemeDatabase: public QAbstractListModel {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  QOOL_SIMPLE_SINGLETON_DECL(ThemeDatabase)
  QOOL_SIMPLE_SINGLETON_QML_CREATE(ThemeDatabase)

public:
  ~ThemeDatabase();
  Q_INVOKABLE Theme theme(const QString& name) const;
  Q_INVOKABLE void installTheme(const Theme& theme);
  Q_SIGNAL void themeInstalled(const QString& name);

  enum Roles {
    NameRole = Qt::UserRole + 100,
    ThemeRole,
    MetadataRole,
    ConstantsRole,
    ActiveRole,
    InactiveRole,
    DisabledRole,
    CustomRole
  };
  QHash<int, QByteArray> roleNames() const override;
  int rowCount(
    const QModelIndex& parent = QModelIndex()) const override;
  QVariant data(const QModelIndex& index,
    int role = Qt::DisplayRole) const override;

  Q_INVOKABLE QVariant anyValue(Theme::Groups group, const QString& key,
    const QVariant& defvalue = {}) const;
  Q_INVOKABLE QVariant anyValue(
    const QString& key, const QVariant& defvalue = {}) const;

  Q_INVOKABLE static qreal visualBrightness(QColor color);
  Q_INVOKABLE static QColor recommendForeground(const QColor& bgColor,
    const QColor& light = { "white" },
    const QColor& dark = { "black" });

protected:
  QMap<QString, Theme> m_themes;
  QStringList m_themeNames;
  QMutex* m_mutex;
  void auto_install_themes();

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_DECL(QStringList, themes)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_DECL(int, count)
};

QOOL_NS_END

#endif // QOOL_THEME_DATABASE_H
