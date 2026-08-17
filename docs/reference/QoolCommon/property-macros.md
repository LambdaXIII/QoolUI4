# 属性宏体系（QoolCommon）

QML/Qt 属性声明的宏族：QOBJECT / QBINDABLE / QGADGET 三族 + QOOL_FOREACH_N 批量生成。

本页记述 QoolCommon 属性宏体系的定位、签名、用法与陷阱。
属性宏体系禁止手写 Q_PROPERTY + getter/setter 样板，按场景选宏族。

## 宏族定位

- `QOBJECT_*`——QObject 类属性：一条宏 = 信号 + getter + setter +
  成员 + Q_PROPERTY（NOTIFY 语义，setter 显式相等守卫）。
- `QBINDABLE_*`——QObject bindable 属性：成员为
  `Q_OBJECT_BINDABLE_PROPERTY`，值变化经 bindable 通知（setter
  不写守卫是刻意的——`operator=` 内置相等守卫），并生成
  `bindable_xxx()`（`QBindable{&member}`）供 Q_PROPERTY 的
  `BINDABLE` 关键字（QML 引擎走 bindable 接口而非信号）。
- `QGADGET_*`——Q_GADGET 值类型属性：getter + setter + 成员 +
  Q_PROPERTY 注册，无 NOTIFY（值类型无信号能力）。

## 签名与参数

三族均有 `DECLARE` 后缀版（仅声明信号/getter/setter/Q_PROPERTY，
不生成成员——成员与实现归类/类外手写，适用于派生计算属性等场景）。

- `QOBJECT_*_PROPERTY(T, N, D, ...)`——`D` 默认值必填
- `QBINDABLE_*_PROPERTY(C, T, N, ...)`——**无默认值参数**
- `QGADGET_*_PROPERTY(T, N, D, ...)`——`D` 默认值必填
- `DECLARE` 版一律 `(T, N, ...)`——无默认值参数

**陷阱**：`...` 是 Q_PROPERTY 附加选项通道（CONSTANT/FINAL 等）。
DECLARE 版与 QBINDABLE 族误传默认值（如
`QOBJECT_WRITABLE_PROPERTY_DECLARE(int, x, 0)`）时，`0` 静默进入
Q_PROPERTY 尾部，moc 报晦涩 Parse error（错误指向宏定义处而非调用处）。

## 批量属性生成

同型属性清单（如 20 个 QColor）用 `QOOL_FOREACH_N`
体系批量生成：对每个属性名展开局部宏 `__HANDLE__`，用完 `#undef`。

```
#define __HANDLE__(N) QOBJECT_WRITABLE_PROPERTY(QColor, N, Qt::transparent)
QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, green, blue, cyan, magenta, yellow)
#undef __HANDLE__
```

同一属性清单跨类复用（`Style` / `StyleGroupAgent` 各持一份）时，
.cpp 用相同 FOREACH 结构生成 emit 保持同步。

## 参数类型约定

setter 参数类型自动选择：指针按值传 `T*`，其余传 `const T&`。
宏固定命名：成员 `m_xxx`、setter 参数 `new_xxx`、getter 无前缀
`xxx()`、bindable `bindable_xxx()`。

## 批量属性变更

多属性原子变更用 `Qt::beginPropertyUpdateGroup()` /
`endPropertyUpdateGroup()` 包裹，多次 emit 原子化。

---

## 宏字典

### `QOBJECT_WRITABLE_PROPERTY(T, N, D, ...)`

QObject 可写属性：NOTIFY 信号 + 相等守卫 setter。

生成 `N##Changed()` 信号、`N()` getter、`set_N()` setter（相等
守卫 + emit）、成员 `m_N{D}`、Q_PROPERTY（WRITE + NOTIFY）。

```
class Demo : public QObject {
    Q_OBJECT
    QOBJECT_WRITABLE_PROPERTY(int, value, 0)
};
```

### `QOBJECT_READONLY_PROPERTY(T, N, D, ...)`

QObject 只读属性：NOTIFY 信号 + getter（无 setter）。

setter 由类内实现（protected 成员可直接写 `m_N`）。

### `QOBJECT_CONSTANT_PROPERTY(T, N, D, ...)`

QObject 常量属性：getter + Q_PROPERTY(CONSTANT)，无信号。

值在构造后不变（引擎按常量处理，不监听变化）。

### `QOBJECT_WRITABLE_PROPERTY_DECLARE(T, N, ...)`

可写属性声明版：不生成成员与实现。

大文件声明/定义分离用——头文件仅声明，.cpp 用同宏实现或手写
setter（含相等守卫 + emit）。默认值由实现处成员初始化给定。

### `QOBJECT_READONLY_PROPERTY_DECLARE(T, N, ...)`

只读属性声明版：不生成成员与实现。

### `QOBJECT_CONSTANT_PROPERTY_DECLARE(T, N, ...)`

常量属性声明版：不生成成员与实现。

### `QBINDABLE_WRITABLE_PROPERTY(C, T, N, ...)`

QObject bindable 可写属性：Q_OBJECT_BINDABLE_PROPERTY 成员 + BINDABLE。

生成 `N##Changed()` 信号、getter、setter（赋值成员，相等守卫由
`operator=` 内置——不写守卫是刻意的，勿补勿删）、`bindable_N()`
（`QBindable{&m_N}`）、Q_PROPERTY（WRITE + NOTIFY + BINDABLE）。

```
class Demo : public QObject {
    Q_OBJECT
    QBINDABLE_WRITABLE_PROPERTY(Demo, int, value)
public:
    QBindable<int> bindableValue() const; // 宏生成（非 const 版本）
};
```

QML 引擎对 BINDABLE 属性用 bindable 接口做绑定与变更追踪，不依赖
信号。`setValue()` 移除绑定、`setBinding()` 立即求值一次——
见 Qt 的 QProperty/QBindable 文档。

### `QBINDABLE_READONLY_PROPERTY(C, T, N, ...)`

QObject bindable 只读属性：bindable 成员 + BINDABLE，无 setter。

setter 经 `QBINDABLE_SET_VALUE` / `QBINDABLE_SET_BINDING` 或直接
写成员（protected 可见）。

### `QBINDABLE_WRITABLE_PROPERTY_DECLARE(C, T, N, ...)`

bindable 可写属性声明版：不生成成员与实现（声明分离用）。

### `QBINDABLE_READONLY_PROPERTY_DECLARE(C, T, N, ...)`

bindable 只读属性声明版：不生成成员与实现。

### `QOOL_BINDABLE_MEMBER(C, T, N)`

bindable 成员声明原语：信号 + Q_OBJECT_BINDABLE_PROPERTY 成员。

宏族内部组合件，通常不单独使用。

### `QOOL_MAKE_PROPERTY_BINDABLE(T, N)`

给非宏体系的普通 Q_PROPERTY 补 bindable 访问。

生成 `bindable_N()`（`QBindable{this, "N"}` 形态——包装属性名，
属性须有 notify 信号）。用于绑定表达式读取（须经
`QBindable::value()` 建立依赖追踪）；**不可用于实现 BINDABLE**——
`QBindable{obj, name}` 构造不支持依赖追踪（Qt 文档明示）。

### `QBINDABLE_SET_VALUE(N, V)`

bindable 成员赋值：`m_N.setValue(V)`（移除绑定）。

### `QBINDABLE_SET_BINDING(N, V)`

bindable 成员绑定：`m_N.setBinding(V)`（立即求值一次）。

### `QGADGET_WRITABLE_PROPERTY(T, N, D, ...)`

Q_GADGET 值类型可写属性：getter + setter + 成员 + Q_PROPERTY。

无 NOTIFY（值类型无信号能力）。setter 无相等守卫（值类型通常整值
替换）；需要守卫的场景手写 setter。

```
struct Demo {
    Q_GADGET
public:
    QGADGET_WRITABLE_PROPERTY(int, value, 0)
};
```

### `QGADGET_READONLY_PROPERTY(T, N, D, ...)`

值类型只读属性：getter + 成员 + Q_PROPERTY。

### `QGADGET_CONSTANT_PROPERTY(T, N, D, ...)`

值类型常量属性：getter + Q_PROPERTY(CONSTANT)。

### `QGADGET_WRITABLE_PROPERTY_DECLARE(T, N, ...)`

值类型可写属性声明版：不生成成员与实现。

### `QGADGET_READONLY_PROPERTY_DECLARE(T, N, ...)`

值类型只读属性声明版。

### `QGADGET_CONSTANT_PROPERTY_DECLARE(T, N, ...)`

值类型常量属性声明版。

### `QOOL_FOREACH_N`

同型属性清单批量生成（N 上限版，行为确定）。

`QOOL_FOREACH_2` 至 `QOOL_FOREACH_10`：对每个元素展开 `_M(a)`。
与已弃用的 `QOOL_MACRO_FOREACH`（变参递归版，不可用/未完成/过度
复杂，见 macro_foreach_x.hpp）区别：本体系 N 显式上限、无递归、
展开行为确定。

```
#define __HANDLE__(N) QOBJECT_WRITABLE_PROPERTY(QColor, N, Qt::black)
QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, green, blue, cyan, magenta, yellow)
#undef __HANDLE__
```
