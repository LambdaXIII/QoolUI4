# RangeCounter（QoolCommon）

整数步进计数器（UI 等宽覆盖场景：以 step 为最小刻度的离散计数）。

以 `first()`/`last()` 为区间端点（含端点）、`step_length` 为最小
刻度的离散区间模型。`count()` = (last-first)/step 为整数步数
（C++ 整数除法，向下取整）；区间跨度为 step 的非整数倍时，
步数 ≠ 覆盖元素数（如 [0,10] step=3 → count=3，元素 0/3/6/9
共 4 个）。`contained_last()` = last - step：最后一个完整步的
起点（"步内包含的末元素"），用于等宽分格时计算末格位置。
`fromSteps(start, steps)` 以 start 为起点、步数推导终点
（end = start + steps*step，含端点的区间为 [start, end]）。
构造时端点乱序自动交换（first ≤ last）。

刻意设计：count 的整数截断与 contained_last 的 last-step 语义是
"等宽步进覆盖"的原始意图（UI 分格），非缺陷，勿按"元素数"修改。

模板参数 `N`：端点与步长的数值类型（建议整型）。
模板参数 `step_length`：最小刻度步长，默认 1。

## 构造函数

### `template <typename N, N step_length> qoolui::math::RangeCounter<N, step_length>::RangeCounter(N first, N last)`

构造区间为 `[min(first,last), max(first,last)]` 的计数器
（端点乱序自动交换，保证 first ≤ last）。

### `template <typename N, N step_length> qoolui::math::RangeCounter<N, step_length> qoolui::math::RangeCounter<N, step_length>::fromSteps(N start, int steps)`

以 `start` 为起点、`steps` 步推导终点构造计数器。

终点 `end` = start + steps*step_length，含端点的区间为
[start, end]。

## 成员函数

### `template <typename N, N step_length> N qoolui::math::RangeCounter<N, step_length>::first() const`

返回区间起点（含端点）。

### `template <typename N, N step_length> N qoolui::math::RangeCounter<N, step_length>::last() const`

返回区间终点（含端点）。

### `template <typename N, N step_length> N qoolui::math::RangeCounter<N, step_length>::contained_last() const`

返回最后一个完整步的起点（`last() - step()`）。

用于等宽分格时计算末格位置。

### `template <typename N, N step_length> N qoolui::math::RangeCounter<N, step_length>::step() const`

返回最小刻度步长。

### `template <typename N, N step_length> int qoolui::math::RangeCounter<N, step_length>::count() const`

返回区间内的整数步数：(last-first)/step，C++ 整数除法向下取整。

- 注意：步数 ≠ 覆盖元素数（语义说明见类文档）。
