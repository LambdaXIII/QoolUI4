#include "qool_theme.h"

#include "qoolcommon/debug.hpp"

#include <utility>

QOOL_NS_BEGIN

#define LOCK_DATA QMutexLocker locker(m_mutex);

const std::array<Theme::Groups, 5> Theme::GROUPS {
  Theme::Groups::Constants, Theme::Groups::Active,
  Theme::Groups::Inactive, Theme::Groups::Disabled,
  Theme::Groups::Custom
};

/* 为指定的group设置查找优先级 */
QList<Theme::Groups> ORDERED_GROUPS_FOR(Theme::Groups group) {
  QList<Theme::Groups> result { Theme::Groups::Disabled,
    Theme::Groups::Inactive, Theme::Groups::Active };
  if (result.contains(group)) {
    result.removeAll(group);
    result.prepend(group);
  }
  result.prepend(Theme::Groups::Custom);
  result.append(Theme::Groups::Constants);
  return std::move(result);
}

Theme::Theme()
  : m_mutex { new QMutex } {
  for (const auto& x : GROUPS) {
    m_data[x] = QVariantMap();
  }
}

Theme::Theme(const QString& name, const QVariantMap& constants,
  const QVariantMap& active, const QVariantMap& inactive,
  const QVariantMap& disabled, const QVariantMap& custom)
  : Theme() {
  m_data[Groups::Constants].insert(constants);
  m_data[Groups::Active].insert(active);
  m_data[Groups::Inactive].insert(inactive);
  m_data[Groups::Disabled].insert(disabled);
  m_data[Groups::Custom].insert(custom);
  setName(name);
}

Theme::Theme(const QVariantMap& metadatas, const QVariantMap& constants,
  const QVariantMap& active, const QVariantMap& inactive,
  const QVariantMap& disabled, const QVariantMap& custom)
  : Theme() {
  m_metadata = metadatas;
  m_data[Groups::Constants].insert(constants);
  m_data[Groups::Active].insert(active);
  m_data[Groups::Inactive].insert(inactive);
  m_data[Groups::Disabled].insert(disabled);
  m_data[Groups::Custom].insert(custom);
}

Theme::Theme(const Theme& other)
  : m_mutex { new QMutex }
  , m_metadata { other.m_metadata }
  , m_data { other.m_data } {
}

// Theme::Theme(Theme&& other)
//   : m_mutex { new QMutex }
//   , m_metadata { std::move(other.m_metadata) }
//   , m_data { std::move(other.m_data) } {
// }

// Theme& Theme::operator=(const Theme& other) {
//   LOCK_DATA
//   m_metadata = other.m_metadata;
//   m_data = other.m_data;
//   return *this;
// }

// Theme& Theme::operator=(Theme&& other) {
//   LOCK_DATA
//   m_metadata = std::move(other.m_metadata);
//   m_data = std::move(other.m_data);
//   return *this;
// }

Theme::~Theme() {
  if (m_mutex) {
    if (m_mutex->tryLock())
      m_mutex->unlock();
    delete m_mutex;
    m_mutex = nullptr;
  }
}

QString Theme::name() const {
  return m_metadata.value("name").toString();
}

bool Theme::setName(const QString& value) {
  if (value.isEmpty())
    return false;
  if (m_metadata.value("name").toString() == value)
    return false;
  LOCK_DATA
  m_metadata.insert("name", value);
  return true;
}

QStringList Theme::keys() const {
  QSet<QString> all_keys;
  std::for_each(GROUPS.cbegin(), GROUPS.cend(), [&](Groups x) {
    const auto ks = this->m_data[x].keys();
    for (const auto& k : ks)
      all_keys << k;
  });
  return { all_keys.constBegin(), all_keys.constEnd() };
}

QVariant Theme::value(
  Groups group, const QString& key, const QVariant& defvalue) const {
  if (! m_data.contains(group))
    return defvalue;

  const auto _groups = ORDERED_GROUPS_FOR(group);

  for (const auto& g : _groups) {
    if (m_data[g].isEmpty())
      continue;
    if (m_data[g].contains(key))
      return m_data[g][key];
  }

  return defvalue;
}

QVariant Theme::value(
  const QString& key, const QVariant& defvalue) const {
  return value(Active, key, defvalue);
}

bool Theme::setValue(
  Groups group, const QString& key, const QVariant& value) {
  if (! m_data.contains(group))
    return false;

  LOCK_DATA

  auto& map = m_data[group];

  if (map.value(key) == value)
    return false;

  if (value.isNull())
    map.remove(key);
  else
    map.insert(key, value);

  return true;
}

bool Theme::setCustomValue(const QString& key, const QVariant& value) {
  if (m_data[Groups::Custom].value(key) == value)
    return false;
  LOCK_DATA
  if (value.isNull())
    m_data[Groups::Custom].remove(key);
  else
    m_data[Groups::Custom].insert(key, value);
  return true;
}

QVariant Theme::metadata(
  const QString& key, const QVariant& defvalue) const {
  return m_metadata.value(key, defvalue);
}

bool Theme::set_metadata(const QString& key, const QVariant& value) {
  if (m_metadata.value(key) == value)
    return false;
  LOCK_DATA
  if (value.isNull())
    m_metadata.remove(key);
  else
    m_metadata.insert(key, value);
  return true;
}

bool Theme::contains(Groups group, const QString& key) const {
  if (! m_data.contains(group))
    return false;
  return m_data[group].contains(key);
}

bool Theme::contains(const QString& key) const {
  for (const auto& x : GROUPS) {
    if (m_data[x].contains(key))
      return true;
  }
  return false;
}

bool Theme::containsMetadata(const QString& key) const {
  return m_metadata.contains(key);
}

void Theme::insert(Groups group, const QVariantMap& datas) {
  LOCK_DATA
  m_data[group].insert(datas);
}

void Theme::insert(const Theme& other) {
  LOCK_DATA
  m_metadata.insert(other.m_metadata);
  for (const auto& x : GROUPS) {
    m_data[x].insert(other.m_data[x]);
  }
}

void Theme::insertMetadatas(const QVariantMap& datas) {
  LOCK_DATA
  m_metadata.insert(datas);
}

bool Theme::isEmpty() const {
  for (const auto& x : GROUPS) {
    if (! m_data[x].isEmpty())
      return false;
  }
  return true;
}

bool Theme::operator==(const Theme& other) const {
  return m_metadata == other.m_metadata && m_data == other.m_data;
}

bool Theme::operator!=(const Theme& other) const {
  return ! operator==(other);
}

QVariantMap Theme::flatMap(Groups group) const {
  QVariantMap result;

  const auto _groups = ORDERED_GROUPS_FOR(group);

  std::for_each(_groups.crbegin(), _groups.crend(),
    [&](Groups group) { result.insert(m_data[group]); });

  return result;
}

void Theme::dumpInfo() const {
  xDebugQ << "METADATA" << xDBGMap(m_metadata);
  for (const auto& group : GROUPS) {
    xDebugQ << "GROUP" << group << xDBGMap(m_data[group]);
  }
}

#undef LOCK_DATA

QOOL_NS_END
