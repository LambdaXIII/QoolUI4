# Changelog

版本号不随常规修改迭代（当前 4.0.0），仅在正式发布时递增；本文件记录每次修改的内容。

## [4.0.0] — 2026-08-05

### 修复

- OctagonExternalShapePath：修正未定义 `root` 引用（`id: strokeShape` 与绑定不一致导致边框层不渲染）
- OctagonInternalShapePath / OctagonExternalShapePath：`pathHints: PahtLinear` 拼写 → `PathLinear`
- CutSizeBinding：BL/BR 绑定误读 `from.cutSizeTR` → 改读各自角
- BasicLabel：`cutSizesLocked: true; cutSize: 4` → `cutSizes: 4`（四角统一圆角）
- SystemTheme：INACTIVE/DISABLED 宏误写入 `m_data[Active]` → 补真实 Inactive/Disabled 调色板
- math::is_equal：零附近相等判定分支 `ab > epsilon` → `<`
- math::cycle_in_range：负模修正 `mod += distance` → `+= range`
- CMake：删除 QoolConstants.qml 悬挂引用、重复 `target_link_libraries(Qt6::Core)`、注释残留

### 新增

- ShapeContainmentMask：containmentMask 包装类型，命中判定委托 `ShapeControl::contains()` 数值算法（O(1) 线性不等式）
- QoolBoxShapeControl::contains：支持 offsetX/offsetY 位移（判定区跟随视觉形状）
- 独立 QDoc 组织文件 `QoolUI/Qool/qool.qdoc`：模块总览、Style 体系与 QoolWindow 配件哲学、属性集中文档、math 命名空间文档
- 本次涉及文件的完整 QDoc 注释（.cpp/.qml 按官方规范落点）

### 文档

- AGENTS.md：增补 QDoc 规范、变更记录规范、核心库瘦身原则
