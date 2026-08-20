# RangeSlider 三层重构：整体前景取代双手柄

RangeSlider 原为"双 HalfCrystal 手柄 + 平切已选段"结构（T.RangeSlider 模板
handle 机制），存在外观缺陷（手柄斜边与轨道斜边不吻合、部件分离视觉差），
且逐项修补被证明是几何死结（平边贴已选段端面 + 45° 斜边 + 收缩设计 ⇒ 尖角
恒缩进 (root.height − preferredHeight)/2）。决策：重构为三层结构——静态背景
轨道（Crystal）+ RangeHandle（独立公开组件：区间逻辑与三区域交互）+ surface
（外观插拔件，默认 Crystal 前景）——前景为一个整体形状（左尖角 + 中段填充 +
右尖角），两端点重合时退化为水晶型；不再定义 first/second handle delegate，
保留 T.RangeSlider 模板与 API（值语义/键盘/setValues）。

## Considered Options

- **双手柄 + 平切已选段（原结构）**：被拒——手柄/轨道斜边吻合不可达（收缩
  设计下尖角缩进为几何必然），部件分离感来自"平边固定、尖角缩回"的非对称
  收缩；高度数值虽恒等，视觉不统一。
- **逐项修补**（尺寸补偿/贴边锚定/已选段联动放大）：被拒——补偿打破平边契
  约，联动放大引入家族不一致（Slider 轨道不随 hover 放大），不解决整体问题。
- **整体前景 + 分区交互（采纳）**：单一 Crystal 形状承载整个区间视觉，斜边
  同族（45°）天然成立，"重合即水晶"由 cut = min(宽,高)/2 自动合理化，窄区间
  无需特判；中段拖动整体滑移是模板没有的增值交互。
- **交互归属**：早期方案在 surface 内部——上移到 RangeHandle。三层分离的
  意义是"逻辑稳定、外观可换"；交互留在 surface 则宿主替换外观即丢失交互，
  退化为两层。
- **点击行为**：模板跳转/整体滑移点击均被拒——全部点击无操作，交互纯粹化
  （只有拖动），避免窄区间/端点重叠区的跳转歧义。
- **位置 vs 值输入**：RangeHandle 收位置（firstPosition/secondPosition），
  值→位置映射留在 RangeSlider（它有 leftPadding/availableWidth 行程公式）——
  RangeHandle 保持"纯逻辑容器"职责，不复制模板行程语义。

## Consequences

- 新增公开组件 `Qool.Controls.RangeHandle`（可独立实例化，与 RangeSlider 配
  套；接口面实现后再梳理，本决策不锁死属性/信号细节）。
- surface 布局由 surface 自行负责（RangeHandle 只设 parent；默认实例
  anchors.fill 区间盒）——最低要求：任意简单 Item 替换并自行布局即填充区
  间；默认 Crystal 前景尖角外溢区间盒（额外宽度 = 自身高，中央直边区 =
  区间）。
- 交互模型：三区域分区拖动（左拖 first / 右拖 second / 中拖整体滑移，区间宽
  不变、边界钳制整体停），三区物理分区（左/右端点热区 + 中段行程区，基于
  本组件几何推导——height 为手柄基准，与 surface 尺寸无关）；键盘保留模板
  行为。
- 测试契约全部重写：tst_rangeslider 的手柄几何/颜色/锁存断言失效，改为前景
  几何（中央 = 区间、尖角外溢）、分区交互、整体滑移契约。
- 砍项与本决策同批落地：动画位移（#2/#3）、cursorShape 暴露（#4）取消；
  VerticalSlider 重构（#5）延后专项。

## 实现演进（2026-08-20 接口面落地）

接口面实现后与决策原文的差异（决策动机与"为什么"不变，此处记录落地形态）：

- **位置 vs 值输入（结构演进）**：原文决策"RangeHandle 收位置
  （firstPosition/secondPosition）、发结果位置信号"——落地改为**不收任何
  位置输入、不发结果位置**：三区仅发意图信号
  `wannaMoveFirstX`/`wannaMoveSecondX`/`wannaMoveRangeX`，载荷为像素增量
  位移（相对上次事件，DragMoveArea 增量语义）；值→位置映射
  （`availableWidth × position` 区间盒）、位移→值换算、端点钳制全部在宿主。
  原"纯逻辑容器不复制模板行程语义"的动机保留，且更纯粹——RangeHandle 连
  位置语义都不持有。
- **区间盒几何**：RangeSlider 侧 `dummyRangeBox` 计算区间盒
  x/y/width/height（`x = availableWidth × first.position + leftPadding`、
  `width = availableWidth × (second − first)`），经 Binding 组施加——
  **rangeHandle 的几何即区间盒**，不再需要两个端点位置输入。
- **surface 布局责任（结构演进）**：原文"RangeHandle 统一施加 surface 布
  局"——落地改为 surface 自布局（RangeHandle 仅设 parent），默认 surface
  `anchors.fill` 区间盒；"任意简单 Item 替换即填充区间"的最低要求由"替换
  后自行布局"承接。
- **三区几何（细节演进）**：原文"分区边界基于值几何（W = 控件高/2）"——
  落地为物理分区：`handleHSpace = min(宽/2, 高/2)`（端点热区宽）、
  `rangeHSpace = 宽 − 高`（中段行程区），端点区按 `height` 外溢
  （`firstMouseZoneExtension`/`secondMouseZoneExtension`，默认 2；RangeSlider
  默认实例 height/2）。三区无缝（w ≥ h 时 left [−ext, h/2]、center
  [h/2, w−h/2]、right [w−h/2, w+ext]）。
- **交互数据流**：`DragMoveArea`（Qool 基础件）承担拖动——autoBind 显式关
  闭（否则拖动物理移动 rangeHandle 与区间盒 Binding 双重驱动，端点可越过
  对方；同 QoolWindowBG/RectResizer 句柄漂移教训）。钳制在值域：
  `first ∈ [from, second.value]`、`second ∈ [first.value, to]`（可重合不交
  叉）、整体滑移 `[from − first.value, to − second.value]`（不变形、边界整
  体停）。
- **锁存分化**：`justMoved` → `firstJustMoved`/`secondJustMoved`（两端独立
  500ms 窗口，互不影响）。
- **外观通道**：`color`（前景填充）、`backgroundColor`（轨道背景，默认
  75% 透明渲染）、`borderColor`（前景/轨道描边，默认基于 backgroundColor
  自动对比推荐）；前景与轨道同为 Crystal，尖角外溢（`width = parent.width +
  height`，直边区 = 区间/控件宽）。
- **测试**：重写为新契约——区间盒几何、前景尖角外溢/收缩/展开、三区几何与
  热区扩展、wannaMove 增量换算与钳制、整体滑移边界、锁存分化、surface 替
  换（自布局）、倒置范围。真实鼠标交互不在 QML 批次自动化范围（offscreen
  不注入合成事件），以信号级换算测试 + 示例页人工验收覆盖。
- **Slider 同步（2026-08-20）**：`bgColor` 更名 `backgroundColor`（属性即
  轨道背景色，语义精确）；外观通道扩展至 Slider（轨道渐变左端 =
  `backgroundColor` 75% 透明——同轨道半透明语义，手柄采样不透明化）；
  `preferredHeight` 公开属性移除——收缩偏移量内化 pCtrl（默认 handle 与
  background 的内部配套约定，只缓存偏移量不缓存高度）；background 尺寸改
  外部 Binding 施加（root − insets，替换后新实例同样受控——内联绑定随默认
  实例替换丢失，插拔安全）；`encountered` 更名 `expanded`（与 RangeSlider
  surface 命名统一）。

## 实现演进（2026-08-20 模板 handle 回归）

RangeHandle 体系落地后暴露根本缺陷：自建交互路径与模板私有状态机**并行但
永不激活**——`first.handle`/`second.handle` 从未设置，三区 DragMoveArea 消
费了区间内全部事件，模板的 handlePress/handleMove/handleRelease 从不触发；
而模板把 snap 与 live 实现在该私有拖动链里（positionAt → snapPosition →
valueAt → setValue），`QQuickRangeSliderNode::setValue`（QML 赋值/setValues
入口）本身无 snap。结果：宿主设置 `snapMode`/`stepSize`/`live` 在鼠标拖动
路径下全部失效——三个模板交互属性形同虚设。本演进撤销 RangeHandle 体系、
回归模板 handle：

- **决策反转**：删除 `RangeHandle.qml`、`rangeHandle` 属性、三区意图信号
  （wannaMoveFirstX/SecondX/RangeX）、热区扩展、`down`/`hovered` 聚合、
  `pixelToValueDelta` 换算与自建钳制、`dummyRangeBox` 对 rangeHandle 的
  Binding 组、`surface` 属性、`firstJustMoved`/`secondJustMoved` 锁存。
  组件内设置 `first.handle`/`second.handle` 默认 handle——模板状态机复活，
  **snap/live/键盘/nearest/端点钳制全部免费获得**（零自建）。
- **为何撤销"交互与外观解耦"论证**：原三层论证是"交互上移 RangeHandle，
  宿主替换外观不丢交互"。但该独立性以**第二套交互路径**为代价——与模板私
  有状态机并行的自建拖动必然失去模板交互属性（snap/live）。模板交互经
  handle 体系已与前景天然解耦（前景只读模板 position/visualPosition，不参
  与交互），中间层无必要。
- **handle 窄条 + 不相交定位**：默认 handle = 窄条（`width = availableHeight
  / 2`），定位行程 = `availableWidth − width×2`（扣除两个 handle 宽——first
  从 0、second 从 width，**任意值下两 handle 永不相交**），按
  `visualPosition` 映射（RTL/垂直感知，与模板一致）；`z:10` 盖在 contentItem
  之上（拖动命中不受前景遮挡）。行为插拔 = 替换 `first.handle`/`second.handle`
  （模板 handle 契约，定位自写——模板不注入）。
- **前景入 contentItem**：`surface` 属性**删除**——前景（Crystal）直接置于
  contentItem 内 `rangeBox` 区间盒：`x` 随 first 视觉位、`width` = 区间视觉
  宽 + 自身高（多出 height 作尖角外溢/对齐余量），左缘 = first handle 左缘、
  右缘 = second handle 右缘。**hover 展开**由 HoverHandler + `ItemAnimatedResizer`
  驱动（from = 区间盒 − 收缩量 / to = 区间盒全尺寸，动画门控
  `animationEnabled`——关闭时跳变）。
- **展开反馈**：锁存移除——前景展开只响应 hover（HoverHandler），无
  pressed/锁存路径。
- **整体滑移取消**：模板没有中段整体滑移——不做默认实现；文档注明宿主自
  建路径（contentItem 内 MouseArea 同步操作两端，钳制/吸附仍由模板承担）。
- **几何模型**：从"直映射（无 handle 偏移）"变为"rangeBox 区间盒 + 不相交
  handle"——区间盒左缘 = first handle 左缘、右缘 = second handle 右缘；
  handle 拖动映射经模板 positionAt（offset = hw/2）。
- **测试**：tst_rangeslider.qml 重写——窄条 handle 不相交、区间盒几何、前
  景常态收缩、键盘步进（increase/decrease 公开可调）、程序化赋值不吸附
  （setValues 无 snap）、端点钳制、倒置范围、handle 插拔；hover 展开为模板
  不可达（合成鼠标/只读 hovered）人工验收。
- **API 破坏**：`rangeHandle` 属性、`RangeHandle` 类型、`surface` 属性、
  `firstJustMoved`/`secondJustMoved` 全部删除；行为插拔点 =
  `first.handle`/`second.handle`；RangeHandle.md 删除、RangeSlider.md 重写、
  示例页更新（删 surface 示例改外观通道、HandleKnob 窄条不相交、QoolTip
  更新）；整体滑移与"点击无操作"契约变化（点击轨道走模板 nearest）。

## 实现演进（2026-08-20 锁存回归 / enabled 门控 / Slider 架构对齐）

模板 handle 回归后到 Slider 架构对齐期间的演进（ADR 上次同步于 e911e05）：

- **前景锁存回归（2395c55）**：推翻"锁存移除"——RangeSlider 前景恢复
  TimerLatch（interval 500ms，onValueChanged 单触发，任一 handle 值变化
  触发），`resized = hoverer.hovered || latch.active`。动机：仅 hover 展开
  时，拖动/键盘/程序化改值瞬间前景收缩再展开闪动；锁存窗口（连续变化内
  持续保持）消除闪动。与 Slider 锁存内化同源。
- **enabled 门控（40010d2）**：cResizer 接 `enabled: root.enabled`——禁用时
  前景冻结（含程序化写入展开取消——禁用视觉静态化）；hover/光标同受
  root.enabled 控制。
- **Slider 架构对齐（9119c9f）**：Slider 对齐 RangeSlider 模板 handle 回归
  后的形态——(a) 标准 background 驱动尺寸：推翻"外部 Binding"，改自写
  implicit 公式 + background 显式 implicit **150×25** + Control 自动布局
  （替换新 background 同样受控，插拔安全不降级）；(b) handle 内
  ItemAnimatedResizer 控制 Crystal 缩放（替换 BasicNumberBehavior on
  height——两方向动画独立模板 + 锁定 Binding 目标跟随）；(c) 锁存内化
  handle（TimerLatch 单触发 onValueChanged）；(d) 轨道定位
  anchors.centerIn → y 显式；(e) handle 高 root.height → availableHeight；
  (f) crystalShrinkSize → shrinkSize；(g) RangeSlider 默认尺寸统一 150×25
  （原 200×22）。
- **API 破坏（9119c9f）**：Slider 公开接口移除 `justMoved`/`valueVelocity`
  （连同 NumberNotifier）——宿主"刚移动"感知经手柄展开反馈呈现（无独立
  接口）；行为插拔点不变（模板 handle 契约）。

## 实现演进（2026-08-21 配色统一走 Style + VerticalSlider 移除）

- **三色实例属性删除（Slider/RangeSlider 同步）**：`color`/`backgroundColor`/
  `borderColor` 三个实例色属性删除——配色统一走统一样式接口 Style（附着传
  播换色，`Style.accent`/`Style.buttonText` 挂本实例或任意祖先，粒度单实例
  到全局）；轨道 = `Style.buttonText` 75% 透明（Qt palette 名、实义 control
  前景色）→ 前景 = `Style.accent` 对照着色，描边 =
  `ThemeHQ.recommendForeground(Style.buttonText)` 自动对比推荐。Slider 手柄
  采样改 `Connections` 监听 `Style.valueChanged`（key = accent/buttonText）
  驱动重采样（colorAt 为 C++ 方法、QML 绑定不追踪方法体内 stops 访问——
  实例属性信号不可用后，哨兵绑定与下划线属性 onChanged 均不可靠，Style
  信号监听为正解）。
- **VerticalSlider 完全移除**：#5 重构专项取消——独立实现（T.Slider 根 +
  自建 picker 交互 + 独立 color 属性）与 Slider 家族架构（模板 handle、
  Style 配色统一）割裂，维护成本与一致性代价高于保留价值；删除源文件、模
  块注册、参考文档、index 登记。竖直需求由 Slider `orientation: Qt.Vertical`
  正交适配承担（ADR-0010）。
