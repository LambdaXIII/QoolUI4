# QoolDialog 独立窗口血统与命名契约（Qool.Dialogs 基座）

Qool.Dialogs 的对话窗口件 **QoolDialog 不继承 QtQuick.Controls 的 T.Dialog**，而是独立的 `Window`（`Qt.Dialog | Qt.CustomizeWindowHint | Qt.FramelessWindowHint`，color transparent）；对话框外观收敛为**容器无关的表面件 DialogSurface**（BasicControl 子类），Dialog 只是预置了 Surface 的薄窗口壳。命名上，裸名 `Dialog` 保留给将来「T.Dialog 接口完全兼容的换皮件」，本件用 Qool 前缀。

## 考证（血统与 flag 死结）

- **T.Dialog（QtQuick.Controls 2.1 / Qt 5.8 起；Controls 模块本身 5.7 起）是 Popup 血统**，从来不是 Window；基类 Popup 的 `popupType`（6.8 起，Dialog 继承）让它「也能」呈现为窗口。但 Qt 源码写死：`QQuickDialogPrivate::popupWindowType()` 返回裸 `Qt::Dialog`（无 `FramelessWindowHint`；6.8 源码中为虚函数，6.11 起重构为 `windowFlags` 成员，行为一致）；`QQuickPopupWindow` 仅对 `flags & Qt::Popup` 设透明背景。flag 属私有实现，公开 API 无法补齐。
- 因此 T.Dialog 的 Window 形态在**所有平台**拿不到 QoolBox 形态：Windows 上带标题栏/系统边框（无 FramelessWindowHint 即走平台默认装饰）；macOS 装饰形态未逐项查证，但方向一致，且 macOS 对常规无边框顶层窗口默认施加圆角剪裁（平台行为，社区/Electron 文档佐证，非透明性所致），实现期可在实机确认。
- **QtQuick.Dialogs 1.x 的 Dialog（5.3 起，Qt 6 已移除）本就是对话框窗口**：QObject 包壳 + 内部以 `Qt::Dialog` flag 的 QQuickWindow 呈现（无多窗口平台回落为场景内伪窗口装饰）；modality 默认 `Qt.WindowModal`、standardButtons 一排、contentItem 默认属性、尺寸反推内容、Esc/关窗 → rejected()。本架构回到这一血统，并用现代组件手法（表面件可拆出、QoolBox 皮肤）升级它——两条 Dialog 血统（窗口型 / Popup 型）在此合流。

## Considered Options

- **T.Dialog 基座 + 锁 popupType: Item**——被拒：Item 形态不专门提供是定案；锁 Item 等于放弃窗口对话框语义。
- **T.Dialog 基座 + popupType: Window（双形态 + 外观特化）**——被拒：flag 死结（见考证），QoolBox 形态全平台失守；「外观特化」只能特化成系统窗口的圆角矩形，失去 QoolBox 身份。
- **继承 QQuickDialog 覆写私有 `popupWindowType()` 虚函数**——被拒：需链 Qt 私有头文件，跨小版本随时碎，且违背「最大化符合 Qt 设计」的定调。
- **Window 薄壳 + DialogSurface 表面件（采纳）**：窗口语义自主（flag 自选）、外观件容器无关、T.Control 原生机制承载布局，魔改路径全部不需要。
- **复用/继承 QoolWindowBasic（近亲方案）**——被拒：QML 组件间无法继承派生，只能组合或平行实现；且 QoolWindowBasic 携带窗口编辑器语义（五槽 DummyItem 骨架、关闭按钮、拖拽缩放、`visible: true` 硬编码、minimum 200×200 直接可见），与对话框「内容驱动、无装饰、按需出现」的形态相斥。仅 flags/color/token 形态可照抄。

## Key Decisions

1. **QoolDialog = Window**：flags `Qt.Dialog | Qt.CustomizeWindowHint | Qt.FramelessWindowHint`，color transparent；modality 默认 `Qt.WindowModal`；不可交互 resize（minimum=maximum 跟随当前尺寸）；无关闭按钮；无拖动；Esc 与系统关闭请求 → `reject()`；`open()/close()` 薄转发，`accepted`/`rejected` 自建信号，`accept()`/`reject()` 为内容侧调用面。窗口尺寸由预置的 DialogSurface 驱动（隐式尺寸内容反推，下限 200×200 照 QoolWindowBasic 先例；显式尺寸时 T.Control 原生切分行为）。
2. **DialogSurface = BasicControl 子类**：仅覆写 `backgroundSettings` 默认值为 dialog token 组——`cutSizeTL: Style.dialogCutSize`、`borderWidth: Style.dialogBorderWidth`、`borderColor: Style.accent`、`fillColor: Style.window`。切角**仅 TL 单角**，跟随仓库现有视觉语言（QoolWindow/QoolBGBox 同款）。title/titleItem 沿用 BasicControl（经背景件 QoolBGBox 的标题槽），contentItem/implicit sizing/containmentMask 为 T.Control 原生机制——均直接继承，不自建。**不引入 DummyItem 骨架**——对话框只有 title + content 两层，五槽骨架是窗口编辑器场景的复杂度。
3. **命名契约：同名 = 接口合同**。裸名 `Dialog` 只授予与 T.Dialog 接口完全兼容的换皮件；基于 Window 的本件撑不起 Popup 合同（dim/enter/exit/closePolicy 等），必须用 Qool 前缀。撞名歧义不是顾虑——同名自然替代是本仓库的设计哲学（Qool.Controls 的 Button 先例），接口不兼容才是。同规则应用于组件内部：QoolDialog **不重声明 `title`**（遮蔽 Window.title 语义混乱，Qt 官方不建议唯一命名），标题入口为 `surface.title`/`surface.titleItem`。
4. **范围边界**：ButtonBox / standardButtons / header / footer 为后续刀；Item 形态不预包装——使用者自拼 `Popup + DialogSurface`（Popup 提供 dim/closePolicy/动效）。

## Consequences

- QoolDialog 是全仓**首个窗口模态件**：仓库现有代码零 modality/transientParent 先例（已核查），QML Window 的 transientParent 自动归属行为需在实现时验证。
- macOS 系统圆角对 TL 单角切的尖角有轻微裁切，v1 接受不做特化；前提条件（窗口自主）已成立，需要时可加。
- DialogSurface 依赖 Qool.Controls.Components（BasicControl 所在），Qool.Dialogs 模块声明该导入。
- QoolDialog（Window 壳）上没有 dim / closePolicy / popupType 属性；T.Dialog 的这些属性始终存在，只是其 Window 形态下 dim/closePolicy 无 overlay 语义、popupType 恰是切形态的开关——本件以独立 Window 固化 Window 形态，非能力缺失。

## 决策状态

已定案（2026-09-08，grilling 讨论收敛）。实现待 spec。
修订（2026-09-08，spec 发布前四子代理并行 rehearsal）：考证版本归属精确化（Dialog since 5.8、popupType 属 Popup 基类、6.11 flag 实现重构注记）；macOS 圆角表述收窄为平台默认行为；补 QoolWindowBasic 近亲方案排除项；Key Decision 1 增补 accept()/reject() 调用面与尺寸下限、Key Decision 3 增补 title 不重声明。
