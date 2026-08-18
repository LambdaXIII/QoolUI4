# math 工具（QoolCommon）

纯函数数值工具集（无状态、无副作用）。

提供数值比较、边界约束、精度控制、线性映射与区间循环等纯函数。
全部为模板，支持整型与浮点混合使用。

QoolCommon 是仅头文件库，头文件注释不承载完整文档——本文件是
`QoolCommon/qoolcommon/math/utils.hpp` 的 sidecar，承载
math 命名空间与其函数的文档。

## 函数

### `template <typename N> bool qoolui::math::is_equal(N a, N b, float epsilon)`

判断 `a` 与 `b` 在 `epsilon` 容差内是否相等。

两值绝对值均小于 `epsilon` 时视为相等（避免相对误差除零）；
否则按相对误差 `|a-b|/max(|a|,|b|)` < `epsilon` 判定。

### `template <typename N> bool qoolui::math::is_zero(N a, float epsilon)`

判断 `a` 的绝对值是否小于 `epsilon`。

### `template <typename N> N qoolui::math::auto_bound(N left, N x, N right)`

将 `x` 约束到 `left` 与 `right` 之间（端点乱序时自动取小大为界）。

### `template <typename N, typename P> N qoolui::math::set_precision(N number, P precision)`

将 `number` 舍入到 `precision` 位小数；`precision` 为 0 时取整。

### `template<typename T, typename U> U qoolui::math::remap(T input, T in_min, T in_max, U out_min, U out_max)`

将 `input` 从输入范围线性映射到输出范围（浮点中间计算，避免整数除法误差）。

### `template <Arithmetic N> constexpr N qoolui::math::cycle_in_range(N min, N value, N max) noexcept`

将 `value` 循环映射到 **左闭右开区间 `[min, max)`**（模数回绕，非钳制）。

#### 与钳制（auto_bound）的区别

钳制把超界值钉在边界上（`auto_bound(0, 12, 10)` → 10）；本函数把
区间视为环，超界值按模数折回（`cycle_in_range(0, 12, 10)` → 2）。
从 `max` 一侧继续向外走会绕回 `min`，反之亦然。

#### 区间语义（左闭右开）

- 下端点 `min` 包含在区间内：`value == min` 原样返回；
- 上端点 `max` 不包含在区间内：`value == max` 折回下端点（→ `min`），
  与浮点/索引用途的「半开环」习惯一致（如色相 `[0, 1)`、槽位 `[0, N)`）。

#### 典型用途

- 角度归一化：任意角度折返到 [-180°, 180°)，如 `cycle_in_range(-180, 540, 180)` → -180
- 循环索引：末位 +1 绕回开头（12 点制时钟 12 时 +1 → 1 时）
- 槽位索引：`[0, N)` 恰好覆盖全部 N 个槽位 0..N-1，末槽不重复

#### 算法

1. 端点排序得 `left` = min(min,max) / `right` = max(min,max)
2. `value` 落在 [`left`, `right`) 内（含左端、不含右端）原样返回
3. 区间外对 `range` = `right` - `left` 取模折返：
   - 浮点：`fmod(value - left, range)`，负余数加 `range` 修正；
   - 整型：以 `std::make_unsigned_t<N>` 计算 `range`/`distance` 规避溢出，
     有符号负值经 `%` 后 `+ range` 修正，无符号依赖无符号算术模特性处理下溢。

端点乱序（`min` > `max`）时自动取小大为界，语义与 `auto_bound` 一致。

示例（min=0, max=10）：5 → 5；12 → 2；-3 → 7；10 → 0（右端点折回）。

- 约束：`N` 须满足 `Arithmetic` 概念（整型或浮点），模板缺省不再约束类型。

### `template<typename N> N qoolui::math::average(std::initializer_list<N> numbers)`

返回初值列表的算术平均值。
