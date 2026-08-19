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
- surface 布局由 RangeHandle 控制（不自行响应值）——最低要求：任意简单 Item
  替换即直接填充区间；默认 Crystal 溢出展示（中央直边区 = 区间、两端尖角外
  伸，溢出量由 RangeHandle 布局参数提供）。
- 交互模型：三区域分区拖动（左拖 first / 右拖 second / 中拖整体滑移，区间宽
  不变、边界钳制整体停），分区边界基于值几何（W = 控件高/2，不绑定 surface
  尺寸）；键盘保留模板行为。
- 测试契约全部重写：tst_rangeslider 的手柄几何/颜色/锁存断言失效，改为前景
  几何（中央 = 区间、尖角溢出）、分区交互、整体滑移契约。
- 砍项与本决策同批落地：动画位移（#2/#3）、cursorShape 暴露（#4）取消；
  VerticalSlider 重构（#5）延后专项。
