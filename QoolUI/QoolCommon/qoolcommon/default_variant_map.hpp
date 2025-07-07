#ifndef DEFAULT_VARIANT_MAP_HPP
#define DEFAULT_VARIANT_MAP_HPP

#include "_property_helpers.hpp"
#include "qoolns.hpp"

#include <QReadWriteLock>
#include <QVariantMap>

QOOL_NS_BEGIN

class DefaultVariantMap {
protected:
  QVariantMap m_defaults, m_currents;
  QReadWriteLock* m_lock;
  inline static void _insert_value(
    const QString& key, const QVariant& v, QVariantMap& map) {
    if (v.isNull())
      map.remove(key);
    else
      map.insert(key, v);
  }

public:
  DefaultVariantMap()
    : m_lock { new QReadWriteLock } {}
  explicit DefaultVariantMap(const QVariantMap& def)
    : m_lock { new QReadWriteLock }
    , m_defaults { def } {}
  DefaultVariantMap(
    const QVariantMap& currentMap, const QVariantMap& defaultMap)
    : m_lock { new QReadWriteLock }
    , m_currents { currentMap }
    , m_defaults { defaultMap } {};
  DefaultVariantMap(const DefaultVariantMap& other)
    : m_lock { new QReadWriteLock }
    , m_defaults { other.m_defaults }
    , m_currents { other.m_currents } {};
  virtual ~DefaultVariantMap() {
    if (m_lock)
      delete m_lock;
  }

  bool contains(const QString& key) const {
    QReadLocker locker(m_lock);
    return m_defaults.contains(key) || m_currents.contains(key);
  }

  QVariant value(
    const QString& key, const QVariant& defaultValue = {}) const {
    QReadLocker locker(m_lock);
    if (m_currents.contains(key))
      return m_currents.value(key);
    return m_defaults.value(key, defaultValue);
  }

  void set_value(const QString& key, const QVariant& v) {
    QWriteLocker locker(m_lock);
    if (m_defaults.contains(key))
      _insert_value(key, v, m_currents);
    else {
      m_currents.remove(key);
      _insert_value(key, v, m_defaults);
    }
  }

  template <typename T>
  inline T value(
    const QString& key, _QL_PARAM_TYPE_(T) defaultValue = {}) const {
    if (! contains(key))
      return defaultValue;
    return value(key).value<T>();
  }

  template <typename T>
  inline void set_value(const QString& key, _QL_PARAM_TYPE_(T) v) {
    set_value(key, QVariant::fromValue<T>(v));
  }

  // Default Value Manipulations

  QVariant defaultValue(const QString& key) const {
    QReadLocker locker(m_lock);
    return m_defaults.value(key);
  }

  void set_defaultValue(const QString& key, const QVariant& v) {
    QWriteLocker locker(m_lock);
    _insert_value(key, v, m_defaults);
  }

  template <typename T>
  inline T defaultValue(const QString& key) {
    return defaultValue(key).value<T>();
  }

  template <typename T>
  inline void set_defaultValue(
    const QString& key, _QL_PARAM_TYPE_(T) v) {
    set_defaultValue(key, QVariant::fromValue<T>(v));
  }

  // Functions

  void insert(const QVariantMap& other) {
    if (other.isEmpty())
      return;
    QWriteLocker locker(m_lock);
    for (auto iter = other.constBegin(); iter != other.constEnd();
      ++iter) {
      const auto key = iter.key();
      const auto v = iter.value();
      if (v.isNull())
        continue;
      if (m_defaults.contains(key))
        m_currents.insert(key, v);
      else {
        m_currents.remove(key);
        m_defaults.insert(key, v);
      }
    }
  }

  void insertCurrents(const QVariantMap& other) {
    if (other.isEmpty())
      return;
    QWriteLocker locker(m_lock);
    m_currents.insert(other);
  }

  void insertDefaults(const QVariantMap& other) {
    if (other.isEmpty())
      return;
    QWriteLocker locker(m_lock);
    m_defaults.insert(other);
  }

  void setCurrents(const QVariantMap& other) {
    QWriteLocker locker(m_lock);
    m_currents = other;
  }

  void setDefaults(const QVariantMap& other) {
    QWriteLocker locker(m_lock);
    m_defaults = other;
  }

  void reset() {
    QWriteLocker locker(m_lock);
    m_currents.clear();
  }

  void reset(const QString& key) {
    QWriteLocker locker(m_lock);
    m_currents.remove(key);
  }

  void remove(const QString& key) {
    QWriteLocker locker(m_lock);
    m_defaults.remove(key);
    m_currents.remove(key);
  }

  void clear() {
    QWriteLocker locker(m_lock);
    m_defaults.clear();
    m_currents.clear();
  }

  QVariantMap::size_type size() const {
    QReadLocker locker(m_lock);
    return qMax(m_currents.size(), m_defaults.size());
  }

  QStringList keys() const {
    QReadLocker locker(m_lock);
    QSet<QString> keys;
    for (const auto& k : m_defaults.keys())
      keys << k;
    for (const auto& k : m_currents.keys())
      keys << k;
    return { keys.cbegin(), keys.cend() };
  }

  QStringList currentKeys() const {
    QReadLocker locker(m_lock);
    return m_currents.keys();
  }
  QStringList defaultKeys() const {
    QReadLocker locker(m_lock);
    return m_defaults.keys();
  }

  QVariantMap collapse() const {
    QReadLocker locker(m_lock);
    auto result = m_defaults;
    result.insert(m_currents);
    return result;
  }

  operator QVariantMap() const { return collapse(); }

}; // DefaultVariantMap

QOOL_NS_END

#endif // DEFAULT_VARIANT_MAP_HPP
