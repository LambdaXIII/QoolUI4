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
- **外观通道**：`color`（前景填充）、`bgColor`（轨道背景，默认 75% 透明渲
  染）、`borderColor`（前景/轨道描边，默认基于 bgColor 自动对比推荐）；前
  景与轨道同为 Crystal，尖角外溢（`width = parent.width + height`，直边区
  = 区间/控件宽）。
- **测试**：重写为新契约——区间盒几何、前景尖角外溢/收缩/展开、三区几何与
  热区扩展、wannaMove 增量换算与钳制、整体滑移边界、锁存分化、surface 替
  换（自布局）、倒置范围。真实鼠标交互不在 QML 批次自动化范围（offscreen
  不注入合成事件），以信号级换算测试 + 示例页人工验收覆盖。
