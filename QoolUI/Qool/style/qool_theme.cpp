#include "qool_theme.h"

#include <utility>

QOOL_NS_BEGIN

class QoolThemeData: public QSharedData {
public:
};

QoolTheme::QoolTheme()
  : m_lock { new QReadWriteLock } {
  m_data[ValueGroups::Active] = QVariantMap();
  m_data[ValueGroups::Inactive] = QVariantMap();
  m_data[ValueGroups::Disabled] = QVariantMap();
  m_data[ValueGroups::CustomGroup] = QVariantMap();
}

QoolTheme::QoolTheme(const QString& name, const QVariantMap& active,
  const QVariantMap& inactive, const QVariantMap& disabled)
  : QoolTheme() {
  m_data[ValueGroups::Active] = active;
  m_data[ValueGroups::Inactive] = inactive;
  m_data[ValueGroups::Disabled] = disabled;
  m_data[ValueGroups::CustomGroup] = QVariantMap();
  setName(name);
}

QoolTheme::QoolTheme(const QVariantMap& metadatas,
  const QVariantMap& active, const QVariantMap& inactive,
  const QVariantMap& disabled)
  : QoolTheme() {
  m_data[ValueGroups::Active] = active;
  m_data[ValueGroups::Inactive] = inactive;
  m_data[ValueGroups::Disabled] = disabled;
  m_data[ValueGroups::CustomGroup] = QVariantMap();
  m_metadata = metadatas;
}

QoolTheme::QoolTheme(const QoolTheme& rhs)
  : m_lock { new QReadWriteLock }
  , m_data { rhs.m_data }
  , m_metadata { rhs.m_metadata } {
}

QoolTheme::QoolTheme(QoolTheme&& rhs)
  : m_lock { new QReadWriteLock }
  , m_data { std::move(rhs.m_data) }
  , m_metadata { std::move(rhs.m_metadata) } {
}

QoolTheme& QoolTheme::operator=(const QoolTheme& rhs) {
  if (this != &rhs) {
    QWriteLocker locker(m_lock);
    m_data = rhs.m_data;
    m_metadata = rhs.m_metadata;
  }
  return *this;
}

QoolTheme& QoolTheme::operator=(QoolTheme&& rhs) {
  if (this != &rhs) {
    QWriteLocker locker(m_lock);
    m_data = std::move(rhs.m_data);
    m_metadata = std::move(rhs.m_metadata);
  }
  return *this;
}

QoolTheme::~QoolTheme() {
  m_lock->unlock();
  delete m_lock;
}

QString QoolTheme::name() const {
  return m_metadata.value("name").toString();
}

bool QoolTheme::setName(const QString& value) {
  QReadLocker reader(m_lock);
  const auto old = m_metadata.value("name");
  if (value == old.toString())
    return false;
  reader.unlock();
  QWriteLocker writer(m_lock);
  m_metadata.insert("name", value);
  return true;
}

QStringList QoolTheme::keys() const {
  QSet<QString> keys;
  QReadLocker locker(m_lock);
  for (auto groupIter = m_data.constBegin();
    groupIter != m_data.constEnd();
    ++groupIter) {
    auto& group = groupIter.value();
    for (auto iter = group.constBegin(); iter != group.constEnd();
      ++iter)
      keys << iter.key();
  }
  return { keys.constBegin(), keys.constEnd() };
}

QVariant QoolTheme::value(ValueGroups group, QAnyStringView key,
  const QVariant& defvalue) const {
  QReadLocker locker(m_lock);

  if (! m_data.contains(group))
    return defvalue;

  const QString k = key.toString();

  const auto& data_group = m_data[group];
  if (data_group.contains(k))
    return data_group.value(k);

  if (group != ValueGroups::Active) {
    QList<ValueGroups> _groups { ValueGroups::CustomGroup,
      ValueGroups::Disabled, ValueGroups::Inactive,
      ValueGroups::Active };
    _groups.removeAll(group);

    for (const auto& vg : std::as_const(_groups)) {
      const auto& g = m_data[vg];
      if (g.contains(k))
        return g.value(k);
    }
  }

  return defvalue;
}

bool QoolTheme::setVallue(
  ValueGroups group, QAnyStringView key, const QVariant& value) {
  QReadLocker rLocker(m_lock);

  if (! m_data.contains(group))
    return false;

  const QString k = key.toString();

  auto& g = m_data[group];
  const auto& old_value = g.value(k);

  if (old_value == value)
    return false;

  rLocker.unlock();
  QWriteLocker wLocker(m_lock);

  if (value.isNull())
    g.remove(k);
  else
    g.insert(k, value);

  return true;
}

QVariant QoolTheme::metadata(
  QAnyStringView key, const QVariant& defvalue) const {
  QReadLocker locker(m_lock);
  return m_metadata.value(key.toString(), defvalue);
}

bool QoolTheme::set_metadata(
  QAnyStringView key, const QVariant& value) {
  const QString k = key.toString();
  QReadLocker rLocker(m_lock);
  const auto& old_value = m_metadata.value(k);
  if (old_value == value)
    return false;

  rLocker.unlock();
  QWriteLocker wLocker(m_lock);

  if (value.isNull())
    m_metadata.remove(k);
  else
    m_metadata.insert(k, value);
  return true;
}

bool QoolTheme::contains(ValueGroups group, QAnyStringView key) const {
  QReadLocker locker(m_lock);
  if (! m_data.contains(group))
    return false;
  const QString k = key.toString();
  return m_data[group].contains(k);
}

bool QoolTheme::contains(QAnyStringView key) const {
  static const QList<ValueGroups> _groups { ValueGroups::CustomGroup,
    ValueGroups::Disabled, ValueGroups::Inactive, ValueGroups::Active };

  QReadLocker locker(m_lock);
  const QString k = key.toString();
  for (const auto g : _groups) {
    if (m_data[g].contains(k))
      return true;
  }

  return false;
}

bool QoolTheme::containsMetadata(QAnyStringView key) const {
  QReadLocker locker(m_lock);
  return m_metadata.contains(key.toString());
}

QVariantMap QoolTheme::collapse(ValueGroups group) const {
  const QStringList keys = this->keys();
  QList<ValueGroups> _groups {
    ValueGroups::Active,
    ValueGroups::Inactive,
    ValueGroups::Disabled,
  };
  if (_groups.contains(group)) {
    _groups.removeAll(group);
    _groups.append(group);
  }
  _groups.append(ValueGroups::CustomGroup);

  QReadLocker locker(m_lock);

  QVariantMap result;

  for (const auto& group_name : std::as_const(_groups)) {
    for (const auto& key : keys)
      result.insert(key, m_data[group_name].value(key));
  }

  return result;
}

bool QoolTheme::isEmpty() const {
  QReadLocker locker(m_lock);
  for (auto iter = m_data.constBegin(); iter != m_data.constEnd();
    ++iter) {
    if (! iter.value().isEmpty())
      return false;
  }
  return true;
}

bool QoolTheme::operator==(const QoolTheme& other) const {
  QReadLocker locker(m_lock);
  if (m_metadata != other.m_metadata)
    return false;
  if (m_data != other.m_data)
    return false;
  return true;
}

bool QoolTheme::operator!=(const QoolTheme& other) const {
  return ! operator==(other);
}

QOOL_NS_END
