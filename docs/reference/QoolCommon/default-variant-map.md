# DefaultVariantMap（QoolCommon）

带默认值分层的 QVariantMap 容器：defaults 提供默认值、currents 承载覆盖值。

内部维护两张表：`m_defaults`（默认层）与 `m_currents`（当前层）。
`value(key)` 优先读 currents，缺失回退 defaults；
`contains`/`size`/`keys` 均为并集语义（任一表存在即命中）。
`set_value` 按落层规则写入：key 已存在于 defaults 时写入
currents（覆盖默认值），否则写入 defaults（成为新的默认值）。
`reset()` 清空 currents 使所有键回退默认值。
`collapse()`/`operator QVariantMap()` 将两层合并为一张表
（currents 覆盖 defaults）。

线程安全：内部持有 `QReadWriteLock`，读操作取读锁、写操作取
写锁。

刻意设计：
- 模板 value/set_value 的按引用传参（`_QL_PARAM_TYPE_` 宏）：
  非指针类型按 `const T&` 传入、指针类型按值传入，避免
  大对象拷贝。
- size() 统计并集键数而非 qMax(defaults.size, currents.size)
  ——qMax 会少计"仅存在于另一侧"的键；且不能复用 keys()
  （其内部再取读锁，QReadWriteLock 不可重入会死锁）。
- 拷贝赋值显式实现（Rule of Three）：类拥有裸指针成员
  m_lock，隐式赋值会浅拷贝锁指针，导致两实例互锁与析构
  double delete。

## 构造函数

### `qoolui::DefaultVariantMap::DefaultVariantMap()`

默认构造：defaults 与 currents 均为空。

### `qoolui::DefaultVariantMap::DefaultVariantMap(const QVariantMap& def)`

以 `def` 初始化默认层，当前层为空。

### `qoolui::DefaultVariantMap::DefaultVariantMap(const QVariantMap& currentMap, const QVariantMap& defaultMap)`

分别以 `currentMap`、`defaultMap` 初始化当前层与默认层。

### `qoolui::DefaultVariantMap::DefaultVariantMap(const DefaultVariantMap& other)`

拷贝构造：值拷贝两层，锁指针独立分配。

## 赋值与析构

### `qoolui::DefaultVariantMap& qoolui::DefaultVariantMap::operator=(const DefaultVariantMap& other)`

拷贝赋值：值拷贝两层（自赋值直接返回）；显式实现避免锁指针
浅拷贝（原因见类文档）。

### `qoolui::DefaultVariantMap::~DefaultVariantMap()`

析构：显式释放锁（new 分配，防泄漏）。

## 查询

### `bool qoolui::DefaultVariantMap::contains(const QString& key) const`

判断 `key` 是否存在于任一表（defaults 或 currents，并集语义）。

### `QVariant qoolui::DefaultVariantMap::value(const QString& key, const QVariant& defaultValue) const`

返回 `key` 的值：优先读 currents，缺失回退 defaults；
两层均缺失返回 `defaultValue`（缺省为空 QVariant）。

### `template <typename T> T qoolui::DefaultVariantMap::value(const QString& key, typename std::conditional<std::is_pointer<T>::value, T, const T&>::type defaultValue) const`

模板版 `value`：两层均缺失时返回 `defaultValue` 并直接转为
`T`；存在时按 `T` 取值转换。参数按引用传递（指针类型除外）。

### `QVariant qoolui::DefaultVariantMap::defaultValue(const QString& key) const`

返回默认层中 `key` 的值（不查 currents）；不存在返回空
QVariant。

### `template <typename T> T qoolui::DefaultVariantMap::defaultValue(const QString& key)`

模板版 `defaultValue`：默认层取值并转为 `T`。

### `QVariantMap::size_type qoolui::DefaultVariantMap::size() const`

返回两层并集键数（与 `contains` 的并集语义一致）。

实现为对 defaults/currents 的键取集合去重计数；不使用 qMax 与
keys()（原因见类文档的刻意设计）。

### `QStringList qoolui::DefaultVariantMap::keys() const`

返回两层所有键的去重列表。

### `QStringList qoolui::DefaultVariantMap::currentKeys() const`

返回当前层的键列表。

### `QStringList qoolui::DefaultVariantMap::defaultKeys() const`

返回默认层的键列表。

## 写入

### `void qoolui::DefaultVariantMap::set_value(const QString& key, const QVariant& v)`

按落层规则写入 `key`：

1. key 已存在于 defaults → 写入 currents（覆盖默认值）；
2. 否则 → 先从 currents 移除该键（若有），再写入 defaults
   （成为新的默认值）。

值为 null QVariant 时删除对应键（_insert_value 语义）。

### `template <typename T> void qoolui::DefaultVariantMap::set_value(const QString& key, typename std::conditional<std::is_pointer<T>::value, T, const T&>::type v)`

模板版 `set_value`：将 `v` 包装为 QVariant 后按落层规则写入。

### `void qoolui::DefaultVariantMap::set_defaultValue(const QString& key, const QVariant& v)`

直接写入默认层（不落 currents）。

### `template <typename T> void qoolui::DefaultVariantMap::set_defaultValue(const QString& key, typename std::conditional<std::is_pointer<T>::value, T, const T&>::type v)`

模板版 `set_defaultValue`：将 `v` 包装为 QVariant 后写入默认层。

### `void qoolui::DefaultVariantMap::insert(const QVariantMap& other)`

批量合并：逐键按落层规则写入（同 `set_value`），值为 null 的
键跳过。空表直接返回。

### `void qoolui::DefaultVariantMap::insertCurrents(const QVariantMap& other)`

将 `other` 全部并入当前层。

### `void qoolui::DefaultVariantMap::insertDefaults(const QVariantMap& other)`

将 `other` 全部并入默认层。

### `void qoolui::DefaultVariantMap::setCurrents(const QVariantMap& other)`

整体替换当前层。

### `void qoolui::DefaultVariantMap::setDefaults(const QVariantMap& other)`

整体替换默认层。

### `void qoolui::DefaultVariantMap::reset()`

清空当前层：所有键回退默认值。

### `void qoolui::DefaultVariantMap::reset(const QString& key)`

从当前层移除 `key`：该键回退默认值。

### `void qoolui::DefaultVariantMap::remove(const QString& key)`

从两层同时移除 `key`（彻底删除，默认值也不保留）。

### `void qoolui::DefaultVariantMap::clear()`

清空两层（defaults 与 currents 均为空）。

## 转换

### `QVariantMap qoolui::DefaultVariantMap::collapse() const`

合并两层为单张表：以 defaults 为基底，currents 覆盖同键值。

### `qoolui::DefaultVariantMap::operator QVariantMap() const`

隐式转换为 QVariantMap（等价于 `collapse()`）。
