# 插件接口：接口契约与插件约定

interfaces/ 目录承载 QoolUI 的插件接口头文件。接口是 QoolUI
对外提供的插件契约面（ThemeLoader、FileIconProvider 等），
与库本体物理分离：自带插件仅是参考实现，逻辑与物理上皆可选；
第三方插件按接口自行实现，跟随版本演进（宽松承诺）。

## 插件约定

所有自带插件遵循以下约定，第三方插件建议同样遵守。

### 元数据字段

插件通过 `Q_PLUGIN_METADATA` 携带 json 元数据文件。约定字段：

- `name` —— 插件名称（`PluginLoader` 按名称登记）。
- `author` —— 作者标识。
- `priority` —— 插件优先级（见下节）。

### 优先级（priority）

插件优先级**统一在插件 json 元数据的 `priority` 字段定义**，
由 `PluginLoader` 从插件元数据读取（`pluginMetadata`），
接口不提供 priority 方法。
**所有自带插件 json 必须包含 `priority` 字段，即使接口不需要**
——这是 v4 的约定性规范，非可选。

`priority` 的裁决语义按接口而定，不可一概而论——有的接口是逐层
"覆盖"（高优先级胜出），有的是逐层"补充"（如首个有结果者胜出/并集
汇总）；每个接口的文档必须写明自身的裁决语义。实例：
`ColorNameProvider` 为"补充"型（`ColorNameHQ` 按 priority 升序查询，
首个命中者胜出）。

### 接口头文件

接口头文件（`interfaces/*.h`）仅包含接口声明与简单注释，
不重复本页的约定叙述；文档注释不写入发布头。
