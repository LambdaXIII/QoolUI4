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
- math::cycle_in_range：负模修正 `mod += distance` → `+= range`；区间内判定 `value <= max` → `value <= right`（端点乱序时语义自洽，不再依赖模分支巧合），并补充用法/算法文档
- math 命名空间 QDoc 从 `Qool/qool.qdoc` 迁至 `QoolCommon/qoolcommon/math/utils.qdoc`（`\inmodule QoolCommon`）：QoolCommon 是独立仅头文件库、可被第三方独立消费，文档不得挂靠 Qool 模块；AGENTS.md 增补归属规则
- CMake：删除 QoolConstants.qml 悬挂引用、重复 `target_link_libraries(Qt6::Core)`、注释残留
- QoolUIExample：声明 `IMPORTS Qool`/`Qool.Chat` + `DEPENDENCIES TARGET Qool QoolChat`，消除 qmlcachegen AOT 统计中的 `Cannot access value for name ThemeDB/Style`（可执行模块缺少编译期模块依赖，跨模块类型回退运行时解析）
- .gitignore：补充 `.omp/`（Oh My Pi harness 项目目录，此前 agent 目录名单漏录）

### 新增

- ShapeContainmentMask：containmentMask 包装类型，命中判定委托 `ShapeControl::contains()` 数值算法（O(1) 线性不等式）
- QoolBoxShapeControl::contains：支持 offsetX/offsetY 位移（判定区跟随视觉形状）
- 独立 QDoc 组织文件 `QoolUI/Qool/qool.qdoc`：模块总览、Style 体系与 QoolWindow 配件哲学、属性集中文档、math 命名空间文档
- 本次涉及文件的完整 QDoc 注释（.cpp/.qml 按官方规范落点）

### 文档

- AGENTS.md：增补 QDoc 规范、变更记录规范、核心库瘦身原则
- AGENTS.md 重写：新增「仓库定位」章节（基础设施性质、C++ 绝不动态导出、QML 引擎类型系统为唯一暴露形式、私有特例规则、接口宽松承诺、示例程序三重角色）；「模块架构」重写（交付形态方向、分层模型、依赖约束 R1–R4、依赖机制三场景、qmldir 开发规范）；「已知陷阱 1」更正为依赖声明机制（运行时=目录存在/部署=qmldir import 行/编译期 AOT=DEPENDENCIES）；CMake 模板注释同步更正
- AGENTS.md：标题改 QoolUI4；技术栈更新（Qt 最新正式 Release 当前 6.11.1、绝不兼容旧版；新增「第三方依赖：无」行）；新增三条硬约束——零第三方依赖（含 Qt5Compat 等兼容模块，不兼容 Qt5/旧版 C++）、版本跟进（只跟进最新正式 Release、不 backport、不用 prerelease/testing）、容器与算法（STL 优先，Qt 容器按需，算法尽量 STL）
- 新增 README.md：品牌门面版——酷酷的UI 定位与口号、QoolBox 核心形状体系、级联样式系统、动画与性能、模块概述（Qool/Controls/Components/Chat/File）、示例程序（QoolUIExample）、许可证、About Me
- AGENTS.md：新增「阅读约定」（子模块/子目录可带模块级 AGENTS，模块内工作必须额外阅读遵循）；QML 组件规范新增「多层插拔」设计原则（View/Delegate/Display 分层、每层可独立替换、可显示组件兼容 Style）；动画条目补 `animationEnabled` 语义（控制一切高开销效果，语义=高性能 vs 完整效果切换）
- 新增 `QoolFile/AGENTS.md`：Qool.File 模块级规范（首个模块级 AGENTS 实例）——多层插拔落地分层表、Display 契约（checked/fileInfo）、行为/样式归属规则、C++ 设施与陷阱
- Qool.File 补 QML 类型 QDoc：FileInfoListView（View 层）/ FileInfoDelegate（Delegate 层）/ BasicFileInfoDisplay（Display 层），各自强调多层插拔配套与替换方式
