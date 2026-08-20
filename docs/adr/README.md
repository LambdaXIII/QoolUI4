# ADR 索引与分类约定

决策记录按**子项目 > 模块**两级目录存放。

## 分类规则

- 布局：`docs/adr/<子项目>/<模块>/`——子项目（如 `QoolUI`）与模块（如 `Qool`）各一级。
- 跨模块的子项目级决策直接放 `docs/adr/<子项目>/`（如 QML 单例契约属 QoolUI 子项目通用件）。
- 编号为全局流水号 `NNNN-` 前缀：单调递增、允许缺口、删除不补号、不加 `ADR-` 前缀。
- 不设全局 ADR 位：跨子项目决策罕见，出现时归最相关的子项目。

## 当前索引

### QoolUI/（子项目级通用件）

| 编号 | 主题 |
|---|---|
| 0001 | QML 单例契约（DB/HQ/HQModel 三件套、禁止进程级单例经 QML_SINGLETON 暴露） |

### QoolUI/Qool/（QoolBox 形状体系）

| 编号 | 主题 |
|---|---|
| 0002 | `*Space` 布局量：溢出转换与钳 0（control C++ 计算，QoolBox 转发公开） |
| 0003 | 渲染结构：单 Shape 双 ShapePath |
| 0004 | 重写保留 QoolBoxShapeControl（内部 gadget 化，对外契约沿用 ext*/int*） |
| 0005 | QoolBoxSettings 双类型（C++ Base + QML 继承 Style 默认）+ cut 命名规范 |
| 0006 | QoolBoxGadget 内部质量：中间量降权 + 全称命名 + QVector2D |
| 0007 | QoolBox 组件职责划分：control 公开（可替换/共享）+ 变体注入 |
| 0008 | QoolBoxHud：QoolBox 专用调试工具 |

### QoolUI/QoolControls/（Slider 家族）

| 编号 | 主题 |
|---|---|
| 0009 | RangeSlider 模板 handle 回归：窄条 handle + rangeBox 前景（三层重构最终形态，RangeHandle/surface 已撤；含 Slider 架构对齐与接口移除） |
| 0010 | Slider orientation × RTL：默认件对齐 Qt 官方接口（正交统一，visualPosition 承载镜像） |
| 0011 | RangeSlider orientation × RTL：默认件对齐 Qt 官方接口（同 Slider 决策模式；纯色轴对称故 RTL 零处理） |

领域术语见根 `CONTEXT.md`「形状体系（QoolBox）」节。
