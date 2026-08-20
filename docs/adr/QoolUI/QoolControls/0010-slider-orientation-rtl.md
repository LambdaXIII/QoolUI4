# Slider orientation × RTL：默认件对齐 Qt 官方接口（正交统一）

Qool.Controls.Slider 是 T.Slider 模板子类，模板继承暴露 `orientation`
（Qt.Horizontal/Qt.Vertical）与 RTL 镜像（`visualPosition`/LayoutMirroring）
能力，但默认件（background 轨道 + handle）此前全水平硬编码：handle 只沿 x
轴定位、菱形边长取 `availableHeight`、轨道收缩沿垂直方向、渐变只水平锚定、
background implicit 固定 150×25——宿主设置 `orientation: Qt.Vertical` 或
置于 RTL 环境时视觉与 Qt 官方行为不一致。决策：默认件对齐 Qt 官方
Basic.Slider 的 orientation 与 RTL 行为，且**两维度正交统一设计**，不引入
第二套视觉系统。

## Considered Options

- **逐项打补丁**（垂直时 handle/轨道/渐变各加分支）：被拒——RTL 与垂直
  两维度交叉时补丁叠加（4 种组合）各自为政，维护面 ×4，且易与模板
  visualPosition 镜像语义冲突。
- **完全复用模板维度（采纳）**：orientation 选择主轴（x/y），由模板
  `horizontal` 承载；RTL 沿主轴方向反转，由模板 `visualPosition` 镜像免费
  承载——两维度自由组合，组合正确性由模板保证，默认件零特判。
- **渐变方向 = 值增大方向（采纳）**：渐变两端锚定"值增大视觉端"而非固定
  几何端——与手柄移动方向、采样色天然一致；固定几何端方案在 RTL/垂直下
  与值语义脱节（值增大端不呈现 accent）。

## Key Decisions

- **handle 定位 = 官方双分支公式**：水平 x 由 `visualPosition ×
  (availableWidth − width)` 驱动、y 居中；垂直 y 由 `visualPosition ×
  (availableHeight − height)` 驱动、x 居中。RTL 由 visualPosition 自动镜像
  （vertical + RTL 时 visualPosition 仍反转，跟随 Qt 模板语义——不特判）。
- **法向尺寸抽象**：`side = horizontal ? availableHeight : availableWidth`
  （轨道法向尺寸）——手柄边长 = side（菱形 `width = height`）、shrinkSize、
  轨道收缩、展开全部基于它：横竖对称、镜像无关（法向居中不随镜像变化）。
- **渐变镜像感知**：渐变两端锚定值增大视觉端。水平锚点 `x1 = cut → x2 =
  width − cut`、垂直锚点 `y1 = cut → y2 = height − cut`；RTL 时同轴端点
  对调（水平 `x1 = width − cut → x2 = cut`、垂直 `y1 = height − cut →
  y2 = cut`）。**对调的是 x1/x2（或 y1/y2）坐标，GradientStop 的
  position/色序不变**（position 0 = from 端 bg、position 1 = to 端
  accent，随坐标移动）。`cut = 轨道短边 / 2` 沿用 Crystal 切角几何。
- **Crystal 零改动**：`cut = min(width, height) / 2`（四角恒等）对宽高互换
  旋转对称——水平轨道（横向六边形）与垂直轨道（竖向六边形）同一几何自动
  成立，形状/掩码/渐变通道均不动。
- **implicit 随 orientation 交换**：background 显式 implicit 150×25 ↔
  25×150，对齐官方"垂直默认窄"惯例；implicit 公式本身不变。
- **交互免费**：value 全部经模板交互（拖动/键盘/wheel 按 orientation 映射、
  RTL 经 visualPosition 反算）——零自建，与 ADR-0009 模板 handle 回归同源。

## Consequences

- 行为插拔点不变：background/handle 仍为模板插拔件，替换后自动布局仍生效
  （Control 自动布局），orientation/RTL 适配随默认件。
- 手柄采样色（ColorMapper）在任意 orientation/RTL 组合下等于轨道在值位置
  的色——**采样参数改用 `position`（逻辑位置，不镜像）**，与对调后的渐变
  几何互补（定位用 `visualPosition` 镜像、采样用 `position` 不镜像）。
  注意：现有 `colorAt(visualPosition)` 不是"无需改动"——RTL 下渐变坐标对调
  + `visualPosition` 采样会错位（handle 停值增大端却采 from 端色），须改
  `colorAt(position)`。
- 测试：tst_slider 新增三用例（垂直几何 / RTL 映射 / 垂直+RTL 组合），全部
  几何断言（offscreen 无合成鼠标——交互映射以示例页人工验收，既有惯例）。
- 文档 Slider.md 5 节更新 orientation/RTL 契约；示例页可选加垂直演示。
- RangeSlider 同缺口（orientation/RTL）不在本决策范围——独立票另行评估。
- VerticalSlider 独立组件（自建交互模型 + 既有 FIXME 计划）不受影响。

## 决策状态

- 决策已定案（2026-08-20）；spec：`.scratch/slider-orientation-rtl/spec.md`
  （`ready-for-agent`）——实施按 spec 落地。
- 与 ADR-0009 同源（visualPosition 天然 RTL/垂直感知），无冲突。
