# qt 工具（QoolCommon）

Qt 对象树与容器工具函数集（模板函数）。

提供对象树向上查找、容器全索引查找等纯工具函数。
QoolCommon 是仅头文件库，头文件注释不承载完整文档——本文件是
`QoolCommon/qoolcommon/qt_tools.hpp` 的 sidecar，承载 tools
命名空间与其函数的文档。

## `template <typename T> T* qoolui::tools::find_parent(QObject* x)`

从 `x` 开始向上搜索对象树，返回第一个可转换为 `T*` 的节点。

刻意包含自身：搜索从 `x` 本身开始（ItemTracker 等场景需要
"target 就是所需类型"的命中）。若要跳过自身，先令
`x = x->parent()` 再调用。找不到返回 `nullptr`。

## `template <typename T, typename List> QList<qsizetype> qoolui::tools::find_all_indexes(const T& element, const List& list)`

返回 `element` 在 `list` 中全部出现位置的索引列表（升序）。

空列表直接返回空列表。实现基于 `QList::indexOf` 循环，注意其
`from` 参数包含自身：命中后索引必须 +1 再续查，否则会在同一
位置反复命中（死循环）。

## `template <typename T, typename List, typename Pred> QList<qsizetype> qoolui::tools::find_all_indexes_if(Pred pred, const List& list)`

返回 `list` 中所有满足谓词 `pred` 的元素的索引列表（升序）。

`pred` 接收元素常量引用，返回 bool。
