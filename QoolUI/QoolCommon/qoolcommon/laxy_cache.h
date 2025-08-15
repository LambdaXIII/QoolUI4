#ifndef LAXY_CACHE_H
#define LAXY_CACHE_H

#include "qoolns.hpp"
#include <functional>
#include <memory>
#include <mutex>
#include <optional>

QOOL_NS_BEGIN

template<typename T> class LazyCache {
  static inline std::function<T()> default_updater = []() {
    return T();
  };

  T* m_data = new T;
  bool m_dirty{true};
  std::function<T()> m_updater{default_updater};
  std::mutex* m_mutex = new std::mutex();

public:
  LazyCache() = default;
  explicit LazyCache(T defaultValue) {
    *m_data = defaultValue;
    m_dirty = false;
  }
  explicit LazyCache(std::function<T()> updater)
    : m_updater{std::make_optional(updater)} { }

  ~LazyCache() {
    if (m_data) delete m_data;
    m_data = nullptr;
  }

  void setValue(const T& value) {
    std::lock_guard locker(m_mutex);
    *m_data = value;
    m_dirty = false;
  }

  T value() const {
    if (m_dirty) {
      std::lock_guard locker(m_mutex);
      if (m_dirty) *m_data = m_updater();
    }
    return *m_data;
  }

  void update() {
    std::lock_guard locker(m_mutex);
    *m_data = m_updater();
    m_dirty = false;
  }

  void setUpdater(std::function<T()> updater) {
    if (updater == m_updater) return;
    std::lock_guard locker(m_mutex);
    m_updater = updater;
    m_dirty = true;
  }
};

QOOL_NS_END

#endif // LAXY_CACHE_H
