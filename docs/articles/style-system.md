# Style 体系：附加属性 + 主题值类型的分层设计

## 分层

1. `Style`：QML 附加属性，按控件类型分组（60+ 属性 × 3 组），
   供 QML 侧统一取用（如 `root.Style.accent`）。
2. `Theme`：值类型，携带五组数据（Constants/Active/Inactive/
   Disabled + 元数据），描述一套完整外观。
3. `SystemTheme` / ThemeDB：主题来源——系统调色板
   （Active/Inactive/Disabled 三组真实状态色）与主题数据库
   （进程级 C++ 全局单例，App 级共享数据）。
4. `ThemeHQ`：主题的 QML 面（QML 单例，每 QQmlEngine 独立实例），
   转发 ThemeDB 的查询/安装/前景对比色接口——多 engine 场景下
   各 engine 使用各自的 ThemeHQ 对象，数据仍是同一份。

## 持久化分层（宿主注入）

组件库刻意不做主题持久化。宿主在 QML 根节点绑定
`Style.theme` 注入主题，构建期一次生效、无闪烁；需要在启动前
决策主题的宿主可操作 ThemeDB（C++ 侧）预置数据，QML 侧经
`ThemeHQ` 查询与安装主题。

## 非 const 接口即宿主注入入口

Style 的可写属性（60+ 属性 × 3 组）构成与宿主的稳定契约面：
这些接口刻意保持非 const，因为组件库不持久化——任何属性都随时
可被宿主改写注入。该契约面稳定，不在版本间随意增删。

## 三组语义

Active/Inactive/Disabled 三组与 QPalette 对齐且刻意保持组间数据
不同：窗口激活、失活、控件禁用时分别取用，使 UI 状态色真实反映
系统调色板（见 `SystemTheme`）。
