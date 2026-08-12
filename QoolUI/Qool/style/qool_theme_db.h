#ifndef QOOL_THEME_DB_H
#define QOOL_THEME_DB_H

#include "qool_theme.h"

#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

#include <QAbstractListModel>
#include <QColor>
#include <QMutex>
#include <QObject>

QOOL_NS_BEGIN

// 主题数据库（进程级 C++ 单例）：主题数据、插件加载、查询、写面与
// 模型特性的唯一持有者，C++ 消费面（Style 的 theme 查询）走本类。
// 不暴露 QML——Qt 契约：共享实例经 QML_SINGLETON 暴露只能被一个
// QQmlEngine 访问（多 engine 崩溃）。QML 面由 ThemeHQ（每 engine
// 独立实例）承载并转发，见 qool_theme_hq.h。
class ThemeDB: public QAbstractListModel {
  Q_OBJECT
  QOOL_SIMPLE_SINGLETON_DECL(ThemeDB)

public:
  ~ThemeDB();
  Theme theme(const QString& name) const;
  void installTheme(Theme theme);
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

  QVariant anyValue(Theme::Groups group, const QString& key,
    const QVariant& defvalue = {}) const;
  QVariant anyValue(
    const QString& key, const QVariant& defvalue = {}) const;

  static qreal visualBrightness(QColor color);
  static QColor recommendForeground(const QColor& bgColor,
    const QColor& light = { "white" },
    const QColor& dark = { "black" });

protected:
  QMap<QString, Theme> m_themes;
  QStringList m_themeNames;
  QMutex* m_mutex;
  void auto_install_themes();

  QOBJECT_READONLY_PROPERTY_DECLARE(QStringList, themes)
  QOBJECT_READONLY_PROPERTY_DECLARE(int, count)
};

QOOL_NS_END

#endif // QOOL_THEME_DB_H
