# C++ 编码规范

本文记述**项目级**C++编码规范，子版块中可能对这些内容进行补充或覆盖。

本项目中，在C++领域中所说的 **属性** ——特指 Qt 元对象系统中的 PROPERTY，
而非泛指的对象成员。

## 文件名 & Namespace

- [SHOULD] C++代码文件统一命名 `qool_` 前缀，`.h` `.cpp` 作为后缀
- [SHOULD] 独立头文件（头库、配置等）使用 `.hpp` 后缀
- [MUST] `qoolns.hpp` 定义全局命名空间，所有内容应当使用 `QOOL_NS_BEGIN` `QOOL_NS_END` 包裹
- [MUST] 只能使用`QOOL_NS`宏用于在代码中特指真实命名空间（实际内容来自CMakeLists），禁止引入硬编码
- [SHOULD] 文件名全小写

## HEADERS & MACROS

`QoolCommon`是一个纯HEADER 库，其中定义了很多算法函数和宏，
C++ 代码编写时，[SHOULD]尽量复用它们，但不要滥用。
具体用法可参考`docs/reference/QoolCommon`。

[MUST]本项目头文件使用 MACRO GUARD，不使用 pragma once。

---

## 类设计

本项目中的 C++ 类包含两种：`暴露的`和`非暴露的`:
- 暴露的类[MUST]一定是一个 QObject/QGadget，并使用 `QML_ELEMENT` 等宏标记，并将被Qt自动登录到Quick系统中
- 非暴露的类[MAY NOT]不一定是 QObject/QGadget
- 无论哪种[MUST NOT]都不动态导出(export)。
- 
### SmartObject

`SmartObject` 是 Qool 中定义的增强版 **QtObject**，继承自 QObject。
当类**将被用于在QML中使用时**,[SHOULD] 通常应当继承它，而非普通的QObject。

SmartObject 直接提供 QML 树的容器能力，普通的 QObject 不行。

### 单例

QoolCommon 中已有快速定义单例类型的便捷宏。

**不能假定运行时仅有一个 QML 引擎存在**：
`QML_SINGLETON` 暴露的是引擎内单例；
[MUST NOT]禁止以「直接传递 C++ 进程级单例实例」方式实现QML单例（多 engine 场景会崩溃）。

### 初始化
- 所有成员必须[MUST]显式初始化，包括 nullptr/0 等零值，以确保跨平台行为一致
- [SHOULD] 通常在声明处，使用 `{ 值 }` 的形式初始化
- [SHOULD] static 成员在 cpp 中独立初始化
- [SHOULD] 通过 QoolCommon 宏定义的成员，无法在声明处设定初始化值时，在构造函数中初始化赋值
- [MUST] QBINDABLE 属性在构造函数中初始化时，必须用 `QBINDABLE_SET_VALUE` / `QBINDABLE_SET_BINDING` 宏初始化，以强调其 QBINDABLE 身份，字面上与普通值区分。

---

## 成员命名约定

所有成员、方法、属性都[MUST]是 **camelCase**，纯私有静态且非成员的。[MAY]可能是 snake_case。

### 成员命名

- 私有成员（变量&常量、类成员&对象成员）使用 `m_` 前缀
- `p_`前缀用于**私有对象**的指针。注意这里特指内部运转必须的对象，而非上述情况中被持有的指针

### 方法命名

| 情形 | 命名 | 示例 |
|---|---|---|
| QML 暴露 API（Q_INVOKABLE、属性） | camelCase | `valueAt`、`dumpInfo` |
| 内部辅助方法 | snake_case | `get_value`、`initialize_data`、`propagate_theme` |
| 槽函数 | `when` 命名（响应信号） | `whenColorChanged` |
| QQmlListProperty 回调 / 私有辅助（非成员） | `__` 双下划线前缀 | `__appendFunction`、`__auto_insert` |
| bindable 访问器 | `bindable_camelCase` | `bindable_interval` |

其中：
- `bindable_camelCase`风格与Qt默认**不一致**，但这样保证了属性名在各个真实成员之间一致。
- `QXXXX_XX_PROPERTY` 系列宏(QoolCommon)中已经依照此规则命名，使用时可假定一致
- [SHOULD]标识符与注释**一律全称**（`maxShrinkDistance` 而非 dStar、`shrinkDistance` 而非 shrinkD）
- 数学记号（√2、θ/2 等）仅限文档公式与算法注释，不进标识符

### Signals & Slots 命名

signal 和 slot [MUST] 使用 `Q_SINGAL`/`Q_SLOT` 宏声明，
[MUST NOT] 不能使用`public signals` `slots` 这种非标关键字。

信号是瞬时状态变化的宣告，
[SHOULD]应该过去式语义 `somethingHappened`——事件已发生，而不是"更新动作"本身的命名：

- **属性变化（默认）**：无参 `xxxChanged()`，不携带值，对齐 Qt 惯例——**仅值实际变化时触发**
- **属性变化（需承载值）**：另设 `xxxUpdated(newValue, oldValue)`，必带两个值、新值在前（Qt 惯例；单参 handler 自动降级为新值、旧值丢弃）
- **通用信号**：动词过去式（`xxxUpdated`、`xxxEdited`、`xxxRequested`…）——其中动作完成类（如 `currentRowUpdated`）宣告动作完成、不承诺值变化，由动作语义决定是否发出
- **意图请求**：`wannaXxx`（如 `wannaSignIn`、`wannaMove`）——意图/请求信号，与执行槽成对构成实时接口
- **响应信号的槽**：`when` 命名（如 `whenColorChanged`）
- **变化汇聚**：多个变更信号汇聚到一个槽 → `when` 命名：`[xChanged, yChanged]` → `whenPositionChanged`

一种可能的组合链示例（环节可增减，示例非规定）：
`wannaChangeName → whenNameChangeRequested → nameChanged → whenNameChanged`。

### 初始化
- 所有成员必须[MUST]显式初始化，包括 nullptr/0 等零值，以确保跨平台行为一致
- [SHOULD] 通常在声明处，使用 `{ 值 }` 的形式初始化
- [SHOULD] static 成员在 cpp 中独立初始化
- [SHOULD] 通过 QoolCommon 宏定义的成员，无法在声明处设定初始化值时，在构造函数中初始化赋值
- [MUST] QBINDABLE 属性在构造函数中初始化时，必须用 `QBINDABLE_SET_VALUE` / `QBINDABLE_SET_BINDING` 宏初始化，以强调其 QBINDABLE 身份，字面上与普通值区分。

---

## 编码细节

一些应当注意[SHOULD]的细节：

- 调试信息打印使用 `xDebug` / `xDebugQ` 系列宏（QoolCommon 调试工具），不裸用 `qDebug()` / `qWarning()`
- 头文件应尽量减少 include，Qt的头文件中已经包含很多类的直接声明，仅需在 cpp 文件中 include 它们的真实头文件
