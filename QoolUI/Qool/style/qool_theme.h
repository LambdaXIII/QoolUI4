#ifndef QOOL_THEME_H
#define QOOL_THEME_H

#include "qoolns.hpp"

#include <QMutex>
#include <QObject>
#include <QPalette>
#include <QQmlEngine>

QOOL_NS_BEGIN

// 主题值类型（QML value type qooltheme）：五组 QVariantMap（Constants/
// Active/Inactive/Disabled/Custom）+ 元数据，描述一套完整外观。
// 取值优先级（value(group, key)）：Custom → group 自身 → Active 兜底
// （group 非 Active 时）→ Constants → defvalue；flatMap(group) 则按
// Constants + Active（group 非 Active）+ group + Custom（group 非
// Constants）合并为单表——Style 实例化时即取各组的 flatMap 拷贝。
// 数据源：SystemTheme（系统调色板）与 XML 主题插件，经 ThemeDB 统一持有。
class Theme {
  Q_GADGET
  QML_VALUE_TYPE(qooltheme)
  QML_STRUCTURED_VALUE

public:
  enum Groups {
    Constants = -999,
    Active = QPalette::Active,
    Inactive = QPalette::Inactive,
    Disabled = QPalette::Disabled,
    Custom = Qt::UserRole + 999
  };
  Q_ENUM(Groups)
  static const std::array<Groups, 5> GROUPS;

  Theme();
  Theme(const QString& name, const QVariantMap& constants,
    const QVariantMap& active, const QVariantMap& inactive,
    const QVariantMap& disabled, const QVariantMap& custom = {});
  Theme(const QVariantMap& metadatas, const QVariantMap& constants,
    const QVariantMap& active, const QVariantMap& inactive,
    const QVariantMap& disabled, const QVariantMap& custom = {});

  Theme(const Theme&);
  Theme(Theme&&);

  Theme& operator=(const Theme&);
  Theme& operator=(Theme&&);

  ~Theme() = default;

  QString name() const;
  bool setName(const QString& value);

  Q_INVOKABLE QStringList keys() const;
  Q_INVOKABLE QStringList keys(Groups group) const;

  Q_INVOKABLE QVariant value(Groups group, const QString& key,
    const QVariant& defvalue = {}) const;
  Q_INVOKABLE QVariant value(
    const QString& key, const QVariant& defvalue = {}) const;
  Q_INVOKABLE bool setValue(
    Groups group, const QString& key, const QVariant& value);
  Q_INVOKABLE bool setCustomValue(
    const QString& key, const QVariant& value);

  Q_INVOKABLE QVariant metadata(
    const QString& key, const QVariant& defvalue = {}) const;
  Q_INVOKABLE bool set_metadata(
    const QString& key, const QVariant& value);

  Q_INVOKABLE bool contains(Groups group, const QString& key) const;
  Q_INVOKABLE bool contains(const QString& key) const;
  Q_INVOKABLE bool containsMetadata(const QString& key) const;

  Q_INVOKABLE void insert(Groups group, const QVariantMap& datas);
  Q_INVOKABLE void insert(const Theme& other);
  Q_INVOKABLE void insertMetadatas(const QVariantMap& datas);

  Q_INVOKABLE bool isEmpty() const;

  bool operator==(const Theme& other) const;
  bool operator!=(const Theme& other) const;

  Q_INVOKABLE QVariantMap flatMap(Groups group) const;
  QHash<int, QVariantMap>& raw();
  const QHash<int, QVariantMap>& raw() const;

  Q_INVOKABLE void dumpInfo() const;

protected:
  QHash<int, QVariantMap> m_data;
  QVariantMap m_metadata;
  // QMutex m_mutex;

  Q_PROPERTY(QString name READ name WRITE setName)
  Q_PROPERTY(QStringList keys READ keys CONSTANT)
};

QOOL_NS_END

#endif // QOOL_THEME_H
