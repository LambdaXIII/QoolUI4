#ifndef LAXY_CACHE_H
#define LAXY_CACHE_H

#include "qoolns.hpp"
#include <functional>
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
    : m_updater{updater} { }

  // Rule of Five：裸指针成员（m_data/m_mutex）必须显式定义拷贝与移动，
  // 否则隐式拷贝导致 double free、隐式移动导致悬垂。
  LazyCache(const LazyCache& other) {
    copy_from(other);
  }
  LazyCache& operator=(const LazyCache& other) {
    if (this != &other)
      copy_from(other);
    return *this;
  }
  LazyCache(LazyCache&& other) noexcept {
    move_from(std::move(other));
  }
  LazyCache& operator=(LazyCache&& other) noexcept {
    if (this != &other)
      move_from(std::move(other));
    return *this;
  }

  ~LazyCache() {
    if (m_data)
      delete m_data;
    m_data = nullptr;
    // m_mutex 为 new 分配，必须显式释放（此前泄漏）
    if (m_mutex)
      delete m_mutex;
    m_mutex = nullptr;
  }

  void setValue(const T& value) {
    std::lock_guard locker(*m_mutex);
    *m_data = value;
    m_dirty = false;
  }

  T value() const {
    // 全锁读取：外层 m_dirty 预判与返回 *m_data 若在锁外，将与
    // setValue/update 并发构成数据竞争（UB）
    std::lock_guard locker(*m_mutex);
    if (m_dirty)
      *m_data = m_updater();
    return *m_data;
  }

  void update() {
    std::lock_guard locker(*m_mutex);
    *m_data = m_updater();
    m_dirty = false;
  }

  void setUpdater(std::function<T()> updater) {
    std::lock_guard locker(*m_mutex);
    m_updater = updater;
    m_dirty = true;
  }

  void markDirty() {
    std::lock_guard locker(*m_mutex);
    m_dirty = true;
  }

private:
  void copy_from(const LazyCache& other) {
    // 深拷贝：值/脏标志/更新器复制，锁与数据指针各自独立
    std::lock_guard locker(*m_mutex);
    std::lock_guard other_locker(*other.m_mutex);
    *m_data = *other.m_data;
    m_dirty = other.m_dirty;
    m_updater = other.m_updater;
  }

  void move_from(LazyCache&& other) noexcept {
    // 移动：转移数据指针与更新器，other 置空（析构安全）
    std::lock_guard locker(*m_mutex);
    std::lock_guard other_locker(*other.m_mutex);
    delete m_data;
    m_data = other.m_data;
    other.m_data = nullptr;
    m_dirty = other.m_dirty;
    m_updater = std::move(other.m_updater);
    other.m_updater = default_updater;
    other.m_dirty = true;
  }
};

QOOL_NS_END

#endif // LAXY_CACHE_H
