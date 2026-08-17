# LazyCache（QoolCommon）

线程安全的惰性求值缓存：首次访问时用更新器生成值，之后缓存直到被标记脏。

持有 `T` 类型值、脏标志与更新器（`std::function<T()>`）。
`value()` 在脏时调用更新器重建值并缓存；`markDirty()` 与
`setUpdater()` 置脏，下次 `value()` 重新求值；`setValue()`
直接写入并清除脏标志。所有公开操作全锁执行（内部持有
`std::mutex`），线程安全。

刻意设计：
- `value()` 全锁读取——若在锁外做 m_dirty 预判与返回
  *m_data，将与 setValue/update 并发构成数据竞争（未定义
  行为），故读路径也须持锁。
- Rule of Five：类拥有裸指针成员（m_data/m_mutex），隐式
  拷贝导致 double free、隐式移动导致悬垂。拷贝为深拷贝
  （值/脏标志/更新器复制，锁与数据指针各自独立）；移动
  转移数据指针与更新器并把源对象置空（析构安全）。

模板参数 `T`：缓存值的类型，要求可拷贝构造与拷贝赋值。

## 构造函数

### `template <typename T> qoolui::LazyCache<T>::LazyCache()`

默认构造：缓存值初始化为 `T()`、脏标志置真（首次 `value()`
用默认更新器求值）。

### `template <typename T> qoolui::LazyCache<T>::LazyCache(T defaultValue)`

以 `defaultValue` 初始化缓存值并清除脏标志（此后 `value()`
直接返回该值，不再调用更新器）。

### `template <typename T> qoolui::LazyCache<T>::LazyCache(std::function<T()> updater)`

以 `updater` 作为更新器构造，脏标志保持置真（首次 `value()`
即调用求值）。

### `template <typename T> qoolui::LazyCache<T>::LazyCache(const LazyCache& other)`

拷贝构造：深拷贝 `other` 的值、脏标志与更新器，锁与数据指针
各自独立。

### `template <typename T> qoolui::LazyCache<T>::LazyCache(LazyCache&& other)`

移动构造：转移 `other` 的数据指针与更新器，源对象置空
（析构安全）。

## 赋值与析构

### `template <typename T> qoolui::LazyCache<T>& qoolui::LazyCache<T>::operator=(const LazyCache& other)`

拷贝赋值：深拷贝 `other`（自赋值直接返回）。

### `template <typename T> qoolui::LazyCache<T>& qoolui::LazyCache<T>::operator=(LazyCache&& other)`

移动赋值：释放自身数据后转移 `other`（自赋值直接返回）。

### `template <typename T> qoolui::LazyCache<T>::~LazyCache()`

析构：显式释放 m_data 与 m_mutex（均为 new 分配）。

## 成员函数

### `template <typename T> void qoolui::LazyCache<T>::setValue(const T& value)`

直接写入缓存值并清除脏标志（此后 `value()` 返回该值直到再次
置脏）。

### `template <typename T> T qoolui::LazyCache<T>::value() const`

返回缓存值；若脏则先用更新器重建再返回。

全锁读取（线程安全，理由见类文档的刻意设计）。

### `template <typename T> void qoolui::LazyCache<T>::update()`

立即用更新器重建缓存值并清除脏标志。

### `template <typename T> void qoolui::LazyCache<T>::setUpdater(std::function<T()> updater)`

替换更新器并置脏（下次 `value()`/`update()` 用新更新器求值）。

### `template <typename T> void qoolui::LazyCache<T>::markDirty()`

置脏：下次 `value()` 重新调用更新器求值。
