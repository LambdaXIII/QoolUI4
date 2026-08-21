# PropertyProxy：无状态属性代理（value 直通 target.property，双路径同步 + 净化可写性）

QML 绑定无法用字符串指定属性名，PropertyProxy 以 `target`（对象）+ `property`（字符串）桥接任意属性，暴露 `value` 作为该属性的代理。定位与 NumberNotifier（读向速率采样）互补：PropertyProxy 是通用属性代理（读 + 可选写）。

**value 为无状态代理**：getter 现读 `target.property`，setter 直写（可写时），无内部存储、数据源唯一。由此同步无竞态（无缓存可被覆盖），且**没有"回滚"概念**——不可写即 setter 忽略 + qWarning，value 保持 target 真实值。

**双路径同步**（观测建立时读一次为通用前置，常量属性即终值）：有 NOTIFY → 事件驱动（连 notify 发 valueChanged）；无 NOTIFY → 轮询，`interval` 语义：`<0` 不轮询（默认 -1，busy polling 变 opt-in）、`=0` 事件循环周期（零定时器）、`>0` 固定间隔。轮询的**判变快照**（上次采样值）仅用于比较变化，不参与读写。

**净化可写性**：`isWritable` 属性 = 元对象可写且非常量（`isWritable() && !isConstant()`）——写方向守卫单一条件，内部实现与宿主共用同一语义。元对象能力全暴露：isReadable/isWritable/isConstant/isResettable/isBindable（只读，随观测刷新）。

**无效态**：target 为 null / 属性无效 / 不可读 → value 无效、能力属性全 false、不进入任何同步模式。模块归 Qool；不做 `on value` 语法（QQmlPropertyValueSource 是写值源语义，与代理方向冲突）。

**不提取公共轮询基础**：与 NumberNotifier 的轮询语义不同（镜像 vs 速率），公共部分仅"定时器+读值"几行，提取属过早抽象（YAGNI）；领域上共享"轮询观测"概念（见 CONTEXT.md）。
