# Style 体系：附加属性 + 主题值类型的分层设计

> 机制备忘录与行为契约。设计原理、技术选型理由与亮点用法见
> [Style 设计原理：从控件配色到主题传播树](style-design.md)。

## 分层

1. `Style`：QML 附加属性（C++ `QQuickAttachedPropertyPropagator`
   子类），按状态分组（60+ 属性 × 3 组），供 QML 侧统一取用
   （如 `root.Style.accent`）。
2. `Theme`：值类型，携带五组数据（Constants/Active/Inactive/
   Disabled + 元数据），描述一套完整外观。
3. `SystemTheme` / ThemeDB：主题来源——系统调色板
   （Active/Inactive/Disabled 三组真实状态色）与主题数据库
   （进程级 C++ 全局单例，App 级共享数据）。
4. `ThemeHQ`：主题的 QML 面（QML 单例，每 QQmlEngine 独立实例），
   转发 ThemeDB 的查询/安装/前景对比色接口——多 engine 场景下
   各 engine 使用各自的 ThemeHQ 对象，数据仍是同一份。

## 数据流全链

```
XML 主题文件 / 系统调色板
        │  DefaultThemeLoader 插件（XMLThemeLoader 解析）
        ▼
ThemeDB（进程级单例，QAbstractListModel）
        │  installTheme → themes 有序表；theme(name) 未知名回退首主题
        ▼
Style.theme 变更 → when_themeChanged：按三组 flatMap 重新解析
        │  （跳过宿主修改键）+ propagate_theme 向下传播
        ▼
各 Style 实例的 m_activeData / m_inactiveData / m_disabledData
        │  currentGroup 由宿主状态推导（ItemTracker bindable 绑定）
        ▼
Style.accent 等 typed 属性 → QML 绑定消费
```

关键点：`inherit` 传播的是**已解析值**（flatMap 合并结果），不是
主题键。子树在自身 `theme` 未变更时不回查 ThemeDB——传播是纯值
拷贝，成本低、无数据库依赖。`Theme.flatMap(group)` 的合并序：
Constants + Active（group 非 Active 时）+ group 自身 + Custom
（group 非 Constants 时）。

## 继承与传播机制

`QQuickAttachedPropertyPropagator` 沿 item 树（含 popup/window）建立
附加属性树。Style 在构造时 `initialize()` 挂接；`attachedParentChange`
时从新父级继承。`inherit(other)` 的行为：

- 拷贝父级 `theme` 名；
- 逐组遍历父级数据，**跳过本地已修改的键**（`is_modified`），
  其余 `set_value` 写入；
- 全程包在 `begin/endPropertyUpdateGroup` 内——批量通知合并，
  QML 引擎对同组属性变化只发一次完整刷新；
- 随后 `propagate_theme()` 继续向下传播。

`theme` 属性变更（宿主在根节点绑定 `Style.theme` 注入）走
`when_themeChanged`：从 ThemeDB 按名取 Theme、三组 flatMap 重新
解析、跳过修改键、再向下传播。这是**唯一的数据库回查路径**。

## 当前组推导（currentGroup）

`m_currentGroup` 是 `Q_OBJECT_BINDABLE_PROPERTY`（bindable 成员），
构造时用 lambda 绑定：

```cpp
m_currentGroup.setBinding([&] {
    const auto item = m_itemTracker->bindable_item().value();
    const bool enabled = m_itemTracker->bindable_itemEnabled().value();
    if (item && ! enabled) return Disabled;
    const bool active = m_itemTracker->bindable_windowActived().value();
    if (! active) return Inactive;
    return Active;
});
```

用 bindable 而非手写信号 connect，是为了让绑定表达式建立**依赖
追踪**：ItemTracker 的 item/itemEnabled/windowActived 任一变化都会
使绑定重求值（无变化不发信号）。`ItemTracker` 追踪宿主 item 的
有效 enabled（`isEnabled`，含祖先链 flow-on）与窗口激活状态
（无窗口视为激活）。组切换时 `when_curentGroupChanged` 重发全部
typed 属性信号，使 QML 绑定重读新组的值。

## 修改追踪与宿主注入契约

Style 的可写属性（60+ 属性 × 3 组）构成与宿主的稳定契约面。
写入语义刻意设计为：

- **typed setter**（`Style.accent = x`）：写**全部三组** + 三组都
  `mark_modified`——值在任意状态生效，且主题变更/父级继承都不会
  覆盖它（继承与重解析都跳过修改键）；
- **组面 setter**（`Style.inactive.accent = x`，经 `StyleGroupAgent`）：
  只写单组 + 该组 mark_modified——只影响特定状态的覆盖；
- **读取**：typed getter 读当前组；组面 getter 读指定组。

这套「非 const 接口即宿主注入入口」是刻意设计：组件库不持久化，
任何属性随时可被宿主改写注入，契约面稳定、不在版本间随意增删。

## 通知机制

组数据变化经 `valueChanged(group, key)` 信号扇出：

- `check_changes`：仅当变化发生在**当前组**时补发对应 typed 属性的
  `xxxChanged`（非当前组的变化不发，等组切换时统一补发）；
- `StyleGroupAgent::when_parentValueChanged`：组面属性信号按组过滤
  重发（`Style.active.accent` 的绑定只随 Active 组变化刷新）；
- `follow`：`Style.follow = other` 后，`other` 的 `valueChanged` 被
  实时拷贝（跳过本地修改键）——popup 委托用它跟随宿主控件。

## animationEnabled 的独立通道

`animationEnabled` 是独立成员（默认 true），**不走组数据**——主题
常量里的同名键是遗留数据，typed 属性通道不消费它。设置它只沿
附加属性树**向下**传播（`set_animationEnabled` 遍历 attachedChildren
递归覆盖），无向上回退。语义是「高性能模式 vs 完整效果」开关，
与其它样式属性平等：需要响应处直接读 `Style.animationEnabled`。

## 持久化分层（宿主注入）

组件库刻意不做主题持久化。宿主在 QML 根节点绑定 `Style.theme`
注入主题，构建期一次生效、无闪烁；需要在启动前决策主题的宿主
可操作 ThemeDB（C++ 侧）预置数据，QML 侧经 `ThemeHQ` 查询与安装
主题。

## 三组语义

Active/Inactive/Disabled 三组与 QPalette 对齐且刻意保持组间数据
不同：窗口激活、失活、控件禁用时分别取用，使 UI 状态色真实反映
系统调色板（见 `SystemTheme`）。`QoolPalette` 是跨桥组件：把 Style
三组映射进 QtQuick `Palette`（Text/TextField 等原生组件的调色板
契约），`root.theme` 注入 `Style.theme`（`Style.theme: root.theme`）。

## 行为契约（测试锚定）

以下契约是 Style 体系的可证伪行为定义，与测试用例一一对应（QML 批次
`tst_qool_qml/tst_style.qml`、C++ 直编 `tst_style_core.cpp`、C++ 驱动
QML 场景 `tst_style_theme_switch.cpp`）。文档与测试同步演进——契约变化
必须同时改文档与测试。

| # | 契约 | 断言要点 | 测试 |
|---|---|---|---|
| C1 | theme 注入沿附加树生效 | 根设 `Style.theme`，子树节点读到的数据/主题名与根一致 | tst_style.qml `test_themeInjection` |
| C2 | 覆盖持久 | 节点显式 `Style.accent = x` 后主题切换：accent 保留 x（节点设计意图），未覆盖属性跟随新主题 | theme_switch `test_overrideSurvivesThemeSwitch` |
| C3 | 主题边界 | 显式设置 theme 的节点成为子树**主题源**（`m_explicitTheme`）：祖先 theme 变化不穿透，区域保持自身主题；源节点无「恢复继承」路径 | theme_switch `test_themeBoundary` |
| C4 | 相等赋值不刷新 | 赋相同值不产生任何属性信号/传播（set_value 相等守卫） | tst_style.qml `test_equalAssignNoRefresh`；core `set_value_guard` |
| C5 | 覆盖不传播 | typed 覆盖只影响本节点（单实例粒度），子孙读 theme 默认 | tst_style.qml `test_overrideNotPropagated` |
| C6 | 组切换 | 宿主禁用/窗口失活时属性读对应组值（Active/Inactive/Disabled） | tst_style.qml `test_groupSwitch` |
| C7 | 附加树连通 | 未声明 Style 的中间节点透明跳过，传播不断 | tst_style.qml `test_untypedNodePassthrough` |
| C8 | 修改键按组独立 | mark_modified/is_modified 三组互不影响 | core `modified_keys_per_group` |
| C9 | Theme 查找优先级 | `Custom > 组自身 > Active 兜底 > Constants > 默认值`；flatMap 合并序正确 | core `theme_lookup_precedence` |
| C10 | ThemeDB 契约 | 重名/空名拒绝；未知名回退首主题；installTheme 发 themeInstalled + rowsInserted | core `theme_db_contract` |
| C11 | follow 跟随 | 跟随目标值变化；本地修改键不被覆盖 | core `follow_contract` |
| C12 | 组面读写 | StyleGroupAgent 读指定组；写单组 + 该组修改标记 | tst_style.qml `test_groupFaceReadWrite` |

**测试环境约束**（影响用例设计）：QML 测试批次无主题插件（仅 system
主题），且 `Theme` 值类型不可从 QML 构造——需要多主题/主题切换的契约
（C2/C3）由 C++ 驱动 QML 场景测试覆盖（`QQmlEngine` + context property
注入 Theme + `ThemeHQ.installTheme`），单主题可测契约走 QML 批次。

## 已知缺口与陷阱

- **`QoolPalette` 引用 `Style.active.brightText`，但 `brightText` 未
  在 Style/StyleGroupAgent 声明**——该绑定恒为 undefined，Palette
  的 brightText 无效（其余角色正常）。修复需在两组类中补声明或
  移除该行。
- **`system` 主题常量不含 `infoColor`**——`theme: "system"` 下读
  `Style.infoColor` 得到无效 QColor；midnight 等 XML 主题定义了它。
- **`find_children` 返回值只含直接子级**——递归累加写入了局部
  `result` 却返回了 `childs`，递归分支是死代码；`dumpAllChildren`
  只显示一层。属调试工具缺陷，不影响样式功能。
- **组面属性信号**：`StyleGroupAgent` 的属性信号由父 Style 的
  `valueChanged` 驱动重发，仅当变化发生在该组时触发——组间切换
  不会重发组面信号（组面绑定的是固定组，值不随组切换变化）。
- **`Style.active.background` 不存在**——示例页曾误用
  `Style.active.background`（应为 `Style.active.base`），StyleGroupAgent
  没有 background 属性；引用不存在的属性是 QML undefined 警告源。
