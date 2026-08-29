# Debug（QoolCommon）

调试打印设施：彩色分级日志入口 + 通用容器 dump 包装器，全部经
`qoolcommon/debug.hpp` 提供。25 个消费文件、约 150 个调用点零改动
地覆盖 Qool/QoolChat/QoolColor/QoolFile 等全部模块。

实现已函数化（C++20 concepts/ranges），但**入口必须保留为宏**——只有
宏能在调用点做条件编译（Release 抹除）和文本注入 `this`。这是整个
设施不可函数化的唯一部分。

## 入口宏

| 宏 | 输出 | 通道 |
|---|---|---|
| `xDebug` | `[D]` 绿 | `qDebug()` |
| `xInfo` | `[I]` 蓝 | `qInfo()` |
| `xWarning` | `[W]` 黄 | `qWarning()` |
| `xCritical` | `[C]` 紫 | `qCritical()` |
| `xDebugQ` 等 Q 后缀 | 同上 + 青色 `[类名]` | 同上 |

用法：

```cpp
xDebug << "message" << value;
xDebugQ << "state dumped" << xDBGList(children());  // 自动带类名前缀
```
Q 后缀宏在展开时注入 `this`（取 `staticMetaObject.className()`），
因此**只能在成员函数或成员 lambda 中使用**，与旧版约束一致。
实现按 `staticMetaObject` 取类名而非 QObject 转型——调用点包括
QGADGET 类型（`Theme`、`Message` 等），它们有元对象但不是
QObject 派生。
因此**只能在成员函数或成员 lambda 中使用**，与旧版约束一致。

刻意设计：

- **入口是永久宏，不是过渡 shim**。宏展开为 `QOOL_NS::debug::xDebug()`
  等函数调用，实现可整体演化而调用点不动。
- `xCritical` 修复了旧版路由错误（原来走 `qDebug()`，严重级别信息
  丢失），现在走 `qCritical()`；且不提供抹除开关。
- `xFatal` 已删除：`qFatal()` 会 abort 且不接受流式 `<<`，"fatal +
  流式输出"语义矛盾；删除时全仓库无调用点。

## Release 抹除（门控）

定义以下宏可抹除对应级别的整条输出链（宏层二选一，抹除路径连函数
实例化都不会发生）：

| 门控宏 | 同时尊重的 Qt 宏 | 抹除 |
|---|---|---|
| `XDBG_NO_DEBUG` | `QT_NO_DEBUG_OUTPUT` | `xDebug`/`xDebugQ` |
| `XDBG_NO_INFO` | — | `xInfo`/`xInfoQ` |
| `XDBG_NO_WARNING` | `QT_NO_WARNING_OUTPUT` | `xWarning`/`xWarningQ` |

是否在 Release 构建自动定义（如绑定 `NDEBUG`）由 CMake 构建配置决定，
头文件不擅自接线。

**边界**：抹除只消除格式化与输出，**参数仍会被求值**——流式链是单个
表达式，任何宏展开形式都绕不开。日志参数应当是纯表达式；有副作用或
开销大的调用方须自行 gate。

## 包装器

全部为 `QOOL_NS::debug` 内的函数模板，宏名仅作转发：

- `xDBGToken(token)`：打印青色 `[token]` 前缀。
- `xDBGVariant(variant)`：打印 `类型名(值)`；null 时类型名回退
  `???`、值回退 `NULL`。
- `xDBGQPropertyList`：打印对象自身元属性（`propertyOffset()` 起），
  无参形式，隐式注入 `this`。
- `xDBGList(container)`：一维容器逐项打印，输出 `[List:N]` 索引列表。
- `xDBGMap(map)`：键值容器打印，输出 `[Map:N]`。

`xDBGList` 的门禁是 `Range1D` concept：任何 `forward_range` 且元素
非字符类型（`char`/`QChar`/`wchar_t`）——`QList`、`QSet`、`QStringList`、
`std::vector`、`std::set`、`std::array` 全部可用；字符串容器
（`QString`/`std::string` 等）被刻意排除，否则 `xDBGList("abc")` 会
打印成字符列表。

`xDBGMap` 的门禁是 `MapLike` concept：元素为 pair-like 的 range，或
提供 `asKeyValueRange()` 的容器——`QMap`/`QHash`/`QMultiMap`/
`QMultiHash`/`std::map`/`std::unordered_map`/`QList<QPair>` 全部可用。
值为 `QVariant` 且键为 `QString` 时走对齐美化输出（与旧版一致）。

刻意设计：

- **Qt 6.11 容器迭代器解引用只返回映射值**（`QMap::iterator::value_type
  = T`，非 pair），`for (auto& [k, v] : qmap)` 编译不过。pair 视图必须
  经 `asKeyValueRange()`（Qt 6.4+）。`MapW` 在函数体内 `if constexpr`
  物化该视图，STL 容器则直接迭代。
- **`QKeyValueRange` 不是 `sized_range`**，取长度用
  `ranges::distance` 两遍遍历（`forward_range` 保证可行）。
- **存引用不拷贝**：包装器持有 `const R&`，语句内临时对象（包括
  视图管道）在完整表达式结束前存活，无悬垂。
- **`NoDebug` sink 用 catch-all 模板**：抹除态下连包装器的遍历/
  求长都不执行，只余参数求值本身。

## 颜色宏

`xDBGRed`、`xDBGGreen`、`xDBGReset` 等 30+ 颜色宏保持不变。约 67 处
调用点依赖字面量相邻拼接（`xDBGYellow "text"`），这要求它们必须以宏
形式存在，不能改为 `constexpr` 变量。

注意：ANSI 转义序列无条件输出，写日志文件或非 VT 终端会出现乱码，
本设施只用于开发期控制台输出，不进入正式日志路径。
