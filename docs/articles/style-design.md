# Style 设计原理：从控件配色到主题传播树

> 本文从「为什么」与「怎么用」两个角度记述 Qool 样式体系的设计原理、
> 实现技术与亮点用法。接口清单见 [Style](../reference/Qool/Style.md)；
> 机制细节与行为契约见 [style-system.md](style-system.md)。

## 一、问题的起点：组件库的配色难题

一个 UI 组件库必须回答三个问题：

1. **60+ 个样式参数**（颜色、字号、切角、动画时长……）从哪来？
2. **状态**（窗口激活/失活、控件禁用）怎么反映到配色？
3. **宿主**（用这个库的人）怎么定制？全局换主题、局部调颜色、单控件覆盖，三种粒度都要。

三种经典答案：

| 方案 | 做法 | 问题 |
|---|---|---|
| 实例属性 | 每个控件暴露 `color`/`backgroundColor`/`borderColor` 等 | 控件越做越胖，每个新样式参数都要设计一个 property；宿主改全局配色得逐个控件改 |
| 全局单例 | `ThemeManager.accent` 谁用谁读 | 单例是引擎级/进程级的诅咒（多 engine 崩溃、无法局部覆盖）；没有传播层级 |
| **附加属性传播** | `Style.accent` 挂在任意 item 上，沿对象树向下传播 | 依赖 Qt 的 `QQuickAttachedPropertyPropagator`——这是 Qool 的选择 |

选第三条的原因：它同时解决三个问题——参数有单一来源（`Theme`），状态经 `currentGroup` 自动映射，宿主可在**任意层级**覆盖（根节点换主题、中间节点建边界、单控件改颜色）。心智模型与 Qt 的 font/palette 传播一致，控件作者和宿主都不需要学习新概念。

## 二、核心设计决策

### 2.1 theme 是「参数更新指令」，不是「传播令牌」

最初容易犯的错误是把 `theme` 当作沿树传递的「主题名」：根节点说 `theme: "midnight"`，子节点拿着名字去数据库查自己的值。

Qool 的设计反过来了：**设置 theme 相当于「用这套参数更新自己，并向下传播」**。`when_themeChanged` 从 `ThemeDB` 取出主题的三组 flatMap（已经是解析好的完整参数表），应用到自己（跳过宿主修改过的键），再沿附加属性树向下传播。子树收到的是**值**，不是名字——它不需要、也不被允许回查数据库。

这个决策带来三个直接收益：

- **传播零数据库依赖**：`inherit` 只是逐键拷贝，成本低、无锁无查询；
- **主题切换原子**：一次 `Style.theme = "midnight"`，整棵子树的数据一致更新（`begin/endPropertyUpdateGroup` 批量通知，引擎只做一次完整刷新）；
- **数据即真相**：任何时刻读 `Style.accent` 得到的就是当前生效的值，不需要理解「这个名字代表什么」。

### 2.2 覆盖持久 = 节点的设计意图

`Style.accent = x` 之后，这个节点对 accent 有了**自己的意图**。意图是持久的：

- 写入时 `set_value` 写**全部三组**（Active/Inactive/Disabled）并 `mark_modified` 三组——覆盖在任意状态生效；
- 之后的任何主题切换、父级传播，都**跳过被标记的键**——主题无权覆盖宿主的设计意图。

这是「组件库不持久化」哲学的推论：既然库不负责保存宿主的选择，那么「宿主显式写过什么」必须被尊重，否则一个主题热切换就把宿主精心调的颜色冲掉了。效果是 **Style 直接成为所有组件的样式接口**——控件无需为每个可配色设计 property，宿主想定制任何东西，`Style.xxx = 值` 即可，粒度从全局到单控件自由。

### 2.3 主题边界：显式设置 = 新主题源

沿 2.2 的哲学再推一步：**显式设置 theme 也是设计意图**——「这个区域用这套主题」。于是：

```
根节点 theme: "midnight"
└── 控件区 theme: "light"     ← 主题源：此区域用 light
    └── 内部控件               ← 传播在边界处断裂，不受祖先影响
```

实现上 `set_theme` 置 `m_explicitTheme` 标记，`inherit` 开头检查：**显式源节点拒绝父级传播**。与 typed 覆盖同构：`Style.theme` 与 `Style.accent` 一样，都是「显式设置截断默认来源」——只是作用域不同，值覆盖是本节点，主题是**本节点加整个子树**（作为新源向下传播）。

注意「主题边界」与「值覆盖」的一个关键差别：typed 覆盖不向下传播（单实例粒度），主题设置**向下传播**（区域粒度）。这正是一个库需要的两层定制能力。

### 2.4 传播已解析值，而非「默认层 + 覆盖层」

另一种常见设计是每个节点存「theme 引用 + override 层」，读取时 `override[key] ?? theme[key]`。Qool 用的是**完整快照**：每个节点持三张解析后的值表，覆盖就地替换快照中的键。

快照模型更简单，代价是被覆盖键的 theme 默认值在快照中消失——但没有关系：**「恢复 theme 默认」不是契约**（覆盖是设计意图，无撤销路径，宿主手动再赋值即改）。这个取舍让实现大幅简化：`inherit` 无需合并两层，`get_value` 无需优先查找，通知系统只需监听一组数据。

### 2.5 状态映射：currentGroup 是推导出来的，不是存出来的

Active/Inactive/Disabled 三组与 QPalette 对齐。当前读哪一组**不存储**，而是从宿主状态实时推导：

```
宿主 item 禁用        → Disabled（isEnabled 含祖先链 flow-on）
宿主窗口失活          → Inactive
否则                  → Active
```

推导本身用 Qt 6 的 **bindable 绑定**实现（见 3.2）——这是「状态是属性」思想的延伸：组切换不是事件，而是依赖追踪下的重求值。

## 三、实现技术

### 3.1 QQuickAttachedPropertyPropagator：附加属性树

Style 继承 `QQuickAttachedPropertyPropagator`（Qt 6.5+，Qt Quick Controls 的样式传播基座）：

- `QML_ATTACHED` 注册为附加类型，`qmlAttachedProperties` 为每个引用 `Style.xxx` 的对象创建实例；
- `initialize()` 在构造时挂接：找到附加父级、触发 `attachedParentChange` → `inherit`；
- `attachedChildren()`/`attachedParent()` 提供附加树遍历——**传播只沿「声明了 Style 的节点」走**，中间未声明的 item 透明跳过（测试 C7 锚定）；
- 附加树穿过 items、popups、windows。

一个容易忽略的细节：**构造时序**。QML 引擎在对象 complete 时安装属性绑定，晚于构造期的 `initialize()` 传播——所以「先被父级传播、后被自己的绑定覆盖」的顺序天然成立，不需要额外处理。

### 3.2 currentGroup 的 bindable 绑定：依赖追踪而非信号

`currentGroup` 是 `Q_OBJECT_BINDABLE_PROPERTY`，构造时用 lambda 设置绑定：

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

选 bindable 而不是「信号 connect + 手动更新」的原因：**绑定表达式对被读的 bindable 建立依赖追踪**——`ItemTracker` 的 item/itemEnabled/windowActived 任一变化，绑定自动重求值；值不变则不重发 `currentGroupChanged`。这与仓库另一条教训（QML 绑定不追踪 C++ 方法体内的属性访问，导致 Slider 采样冻结）是同一枚硬币的两面：**需要追踪的地方，用 bindable 显式声明依赖**。

组切换时 `when_curentGroupChanged` 重发全部 typed 属性信号（包在 `begin/endPropertyUpdateGroup` 里），使所有绑定重读新组的值。

### 3.3 通知：一条信号扇出，两道过滤

组数据变化统一走 `valueChanged(group, key)` 信号：

- `check_changes`：仅当变化发生在**当前组**时补发对应 typed 属性的 `xxxChanged`——非当前组的变化不发，等组切换时统一补发（一次通知覆盖全部）；
- `StyleGroupAgent::when_parentValueChanged`：组面（`Style.active.accent`）的信号按组过滤重发——组面绑定固定组，值不随组切换变化。

两道过滤保证「无关的通知不产生」，绑定只在真正影响它的变化发生时重算。

### 3.4 修改键与主题源：两张「意图登记表」

- **修改键**（`m_*Modified`，按组×键）：typed 覆盖的登记表——`inherit`/`when_themeChanged` 跳过；
- **主题源**（`m_explicitTheme`）：theme 意图的登记表——`inherit` 整体拦截。

两者合起来是「显式设置 = 持久意图」的完整实现：值级意图逐键尊重，主题级意图整区尊重。都没有取消机制——宿主想改，重新显式设置即可（改回即覆盖）。

### 3.5 数据层：值类型 + 进程单例 + 每引擎面（ADR-0001）

主题数据按仓库的 DB/HQ 契约组织（见 [ADR-0001](../adr/QoolUI/0001-qml-singleton-contract.md)）：

| 层 | 类型 | 角色 |
|---|---|---|
| 值类型 | `Theme`（`QML_STRUCTURED_VALUE`） | 五组数据（Constants/Active/Inactive/Disabled/Custom）+ 元数据；查找优先级 `Custom > 组 > Active 兜底 > Constants > 默认值`；`flatMap` 展平 |
| 进程单例 | `ThemeDB`（C++ 全局，不暴露 QML） | 主题存储/安装/查询/插件加载；`QAbstractListModel` |
| QML 面 | `ThemeHQ`（每 engine 单例）/ `ThemeHQModel`（代理模型） | 查询/安装/前景色推荐；主题列表视图 |

多 engine 安全性：进程单例绝不经 `QML_SINGLETON` 暴露（会跨 engine 共享 QObject 崩溃），QML 侧永远经每 engine 独立实例转发。`Theme` 作为值类型按值传递，天然无共享问题。

**主题来源**两条：`SystemTheme`（构造时从系统调色板提取三组真实状态色 + 常量组）与插件（`DefaultThemeLoader` 扫描 XML，`XMLThemeLoaderImpl` 分层求解：constants 为基准，其余组以 constants+active 为引用基准，`copy` 属性支持前向引用多轮循环求解）。

### 3.6 follow：显式跟随，非传播

`Style.follow = other` 是独立于传播的机制：先 `inherit` 一次快照，再连接 `other` 的 `valueChanged` 实时拷贝（跳过本地修改键）。典型场景是 ComboBox 的 popup 委托跟随宿主控件：

```qml
delegate: ItemDelegate {
    Style.follow: combo.Style
}
```

委托与宿主没有父子传播关系（popup 是独立层），`follow` 显式建立数据链路。

## 四、亮点用法

### 4.1 根节点主题注入 + 热切换

```qml
// 应用根：一次设置，整树生效
QoolWindow {
    Style.theme: "midnight"

    // 运行时热切换（演示页的 CHANGE 按钮）
    Button {
        onClicked: root.Style.theme =
            root.Style.theme === "midnight" ? "system" : "midnight"
    }
}
```

`Style.theme` 绑定/赋值 → `when_themeChanged` → 三组重解析 + 传播——**一次赋值，全树原子切换**，无需任何手动刷新。

### 4.2 单实例覆盖：粒度精确到控件

```qml
Slider {
    // 只改这一个控件的前景，主题切换也不覆盖
    Style.accent: "#ff8800"
}
```

写 `Style.accent` 落三组 + 修改键：这个 Slider 从此对 accent 有自己的意图。**不向下传播**（子孙读 theme 默认），粒度精确。

### 4.3 子树门控：animationEnabled 一关全关

```qml
Page {
    // 高性能模式：关掉整个页面的动画与重特效
    Style.animationEnabled: false
}
```

`animationEnabled` 是独立成员（不走组数据），setter 沿附加树向下传播覆盖——祖先设一次，整棵子树的门控生效。控件侧所有动画/特效都读它。

### 4.4 主题边界：局部区域独立主题

```qml
ApplicationWindow {
    Style.theme: "midnight"
    // 编辑器区域用自己的浅色主题，不影响全局
    EditorPane {
        Style.theme: "paper"
    }
}
```

`EditorPane` 显式设置 theme 即成为主题源：祖先主题变化在此断裂，区域内保持 `paper`。适合「深色应用里嵌浅色编辑区」这类需求。

### 4.5 状态定制：禁用/失活态单独设计

```qml
Button {
    Style.active.accent: "#00aa55"      // 正常态
    Style.disabled.accent: "#555555"    // 禁用态
    // Style.inactive.accent 失活态
}
```

组面（`Style.active`/`inactive`/`disabled`）读指定组、写单组——想对特定状态做精细定制时用组面；想全状态统一覆盖用顶层属性。三组映射由 `currentGroup` 自动切换（禁用→Disabled、失活→Inactive），宿主不需要监听任何事件。

### 4.6 原生组件桥：QoolPalette

```qml
// 把 Style 三组映射进 QtQuick Palette（Text/TextField 等原生组件的调色板）
QoolPalette { theme: root.Style.theme }
```

### 4.7 运行时主题安装与选择器

```qml
// 安装运行时主题（数据进进程级 ThemeDB，所有 engine 立即可见）
ThemeHQ.installTheme(myTheme)

// 主题选择器：ThemeHQModel 一行一个主题
ListView {
    model: ThemeHQModel {}
    delegate: Text { text: name }
}
```

## 五、心智模型

```
ThemeDB（进程单例：主题数据）
   │  Style.theme 设置 = 取参数更新自己 + 向下传播
   ▼
传播树（附加属性树：只沿声明 Style 的节点）
   │  每个节点 = 完整快照（theme 解析值 + typed 覆盖）
   │  inherit：父→子拷贝（跳过子节点修改键；显式源节点整体拒绝）
   ▼
currentGroup（宿主状态推导：禁用/失活/激活）→ typed 属性读对应组
```

三条原则：

1. **theme 是参数更新指令**——传播的是值，不是名字；子树不回查数据库。
2. **显式设置 = 持久意图**——值级逐键尊重（修改键），主题级整区尊重（explicit 源标记）；无撤销路径，重新设置即改变。
3. **状态是推导的**——currentGroup 用 bindable 依赖追踪，组切换是重求值而非事件；通知两道过滤，绑定只在被影响时重算。

## 六、演进记录

- **C4 set_value 相等守卫**（2026-08-21）：原实现 `m_activeData == value` 为整表与单值比较恒 false，相等赋值也发信号；修为比较该键当前值。测试：`tst_style_core::set_value_guard`。
- **C3 主题边界**（2026-08-21）：`set_theme` 置 `m_explicitTheme`，`inherit` 拒绝显式源节点的父级传播——子树独立 theme 在祖先 theme 变化时保持。测试：`tst_style_theme_switch::theme_boundary`。
