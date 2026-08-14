# ADR 索引与分类约定

决策记录按**项目板块**分子目录存放。编号全局连续（不随板块重置）。

## 分类规则

- `architecture/` —— 跨模块/架构级决策（单例契约、模块边界、依赖约束等）。
- 其余目录 —— 按功能板块命名（`qoolbox/` = QoolBox 形状体系），对应代码模块/功能领域。
- 新 ADR 归入所属板块目录；跨模块且无板块可归 → `architecture/`。
- 板块目录内文件按编号排序，文件名 = 编号 + 主题 slug。

## 当前索引

### architecture/

| 编号 | 主题 |
|---|---|
| 0001 | QML 单例契约（DB/HQ/HQModel 三件套、禁止进程级单例经 QML_SINGLETON 暴露） |

### qoolbox/（QoolBox 形状体系）

| 编号 | 主题 |
|---|---|
| 0002 | `*Space` 布局量：溢出转换与钳 0（control C++ 计算，QoolBox 转发公开） |
| 0003 | 渲染结构：单 Shape 双 ShapePath |
| 0004 | 重写保留 QoolBoxShapeControl（内部 gadget 化，对外契约沿用 ext*/int*） |
| 0005 | QoolBoxSettings 双类型（C++ Base + QML 继承 Style 默认）+ cut 命名规范 |
| 0006 | QoolBoxGadget 内部质量：中间量降权 + 全称命名 + QVector2D |
| 0007 | QoolBox 组件职责划分：control 公开（可替换/共享）+ 变体注入 |
| 0008 | QoolBoxHud：QoolBox 专用调试工具 |

领域术语见根 `CONTEXT.md`「形状体系（QoolBox）」节。
