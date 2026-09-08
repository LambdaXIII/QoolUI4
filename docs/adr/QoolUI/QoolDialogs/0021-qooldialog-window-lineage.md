# QoolDialog 独立窗口血统与命名契约（Qool.Dialogs 基座）

Qool.Dialogs 的对话窗口件 **QoolDialog 不继承 QtQuick.Controls 的 T.Dialog**，而是独立的 `Window`（`Qt.Dialog | Qt.CustomizeWindowHint | Qt.FramelessWindowHint`，color transparent）；对话框外观收敛为**容器无关的表面件 DialogSurface**（Item + QoolBGBox 背景 + header/content/footer 三槽骨架），QoolDialog 只是预置了 Surface 的薄窗口壳。命名上，裸名 `Dialog` 保留给将来「T.Dialog 接口完全兼容的换皮件」，本件用 Qool 前缀。

## 考证（血统与 flag 死结）

- **T.Dialog（QtQuick.Controls 2.1 / Qt 5.8 起；Controls 模块本身 5.7 起）是 Popup 血统**，从来不是 Window；基类 Popup 的 `popupType`（6.8 起，Dialog 继承）让它「也能」呈现为窗口。但 Qt 源码写死：`QQuickDialogPrivate::popupWindowType()` 返回裸 `Qt::Dialog`（无 `FramelessWindowHint`；6.8 源码中为虚函数，6.11 起重构为 `windowFlags` 成员，行为一致）；`QQuickPopupWindow` 仅对 `flags & Qt::Popup` 设透明背景。flag 属私有实现，公开 API 无法补齐。
- 因此 T.Dialog 的 Window 形态在**所有平台**拿不到 QoolBox 形态：Windows 上带标题栏/系统边框（无 FramelessWindowHint 即走平台默认装饰）；macOS 装饰形态未逐项查证，但方向一致，且 macOS 对常规无边框顶层窗口默认施加圆角剪裁（平台行为，社区/Electron 文档佐证，非透明性所致），实现期可在实机确认。
- **QtQuick.Dialogs 1.x 的 Dialog（5.3 起，Qt 6 已移除）本就是对话框窗口**：QObject 包壳 + 内部以 `Qt::Dialog` flag 的 QQuickWindow 呈现（无多窗口平台回落为场景内伪窗口装饰）；modality 默认 `Qt.WindowModal`、standardButtons 一排、contentItem 默认属性、尺寸反推内容、Esc/关窗 → rejected()。本架构回到这一血统，并用现代组件手法（表面件可拆出、QoolBox 皮肤）升级它——两条 Dialog 血统（窗口型 / Popup 型）在此合流。

## Considered Options

- **T.Dialog 基座 + 锁 popupType: Item**——被拒：Item 形态不专门提供是定案；锁 Item 等于放弃窗口对话框语义。
- **T.Dialog 基座 + popupType: Window（双形态 + 外观特化）**——被拒：flag 死结（见考证），QoolBox 形态全平台失守；「外观特化」只能特化成系统窗口的圆角矩形，失去 QoolBox 身份。
- **继承 QQuickDialog 覆写私有 `popupWindowType()` 虚函数**——被拒：需链 Qt 私有头文件，跨小版本随时碎，且违背「最大化符合 Qt 设计」的定调。
- **Window 薄壳 + DialogSurface 表面件（采纳）**：窗口语义自主（flag 自选）、外观件容器无关、槽位骨架自主（DummyItem 三槽，见 KD2），魔改路径全部不需要。
- **复用/继承 QoolWindowBasic（近亲方案）——被拒**：QML 组件间无法继承派生，只能组合或平行实现；且 QoolWindowBasic 携带窗口编辑器语义（五槽 DummyItem 骨架、关闭按钮、拖拽缩放、`visible: true` 硬编码、minimum 200×200 直接可见），与对话框「内容驱动、无装饰、按需出现」的形态相斥。仅 flags/color/token 形态与 DummyItem 槽位手法可借——后者以三槽独立实现，不带编辑器语义。

## Key Decisions

1. **QoolDialog = Window**：flags `Qt.Dialog | Qt.CustomizeWindowHint | Qt.FramelessWindowHint`，color transparent；modality 默认 `Qt.WindowModal`；无关闭按钮、无拖动、无交互 resize 设施；Esc 与系统关闭请求 → `reject()`；`open()/close()` 薄转发，`accepted`/`rejected` 自建信号，`accept()`/`reject()` 为内容侧调用面。公开面另有 `header`/`content`/`footer` 三个槽位别名（转发到预置 surface）；**无默认属性重定向**——裸子元素进 `Window.data`（成为窗口 contentItem 的子项），不参与 surface 槽位布局。尺寸：`width/height` 绑 `max(最小尺寸, surface 隐式尺寸)`（裸 Window 无 implicit 尺寸，只能直接绑 width/height），显式赋值即断开绑定生效；**最小尺寸 = 背景件切角 + 边框之和**（`cutSpaceOnLeft + cutSpaceOnRight + borderWidth × 2`，纵向同理）——低于此值 QoolBox 形状退化，故不再用固定 200 下限、也不再用 `minimumWidth: width`（后者与内容驱动的 width 形成绑定循环）；`maximumWidth/Height` 跟随当前尺寸（窗口不可被放大）。
2. **DialogSurface = Item + QoolBGBox 背景 + 三槽 DummyItem 骨架**（不继承 BasicControl / T.Control）：背景为 QoolBGBox，settings 默认 dialog token 组——`cutSizeTL: Style.dialogCutSize`、`borderWidth: Style.dialogBorderWidth`、`borderColor: Style.accent`、`fillColor: Style.window`；切角**仅 TL 单角**，跟随仓库现有视觉语言。`header`/`content`/`footer` 三槽以 DummyItem 纵向排布（QoolWindow 手法）填满背景件报告的内容区：header 顶、footer 底、content 取中段，间距 `spacing = Style.windowElementSpacing`；槽位项被 reparent 到 surface 并按槽位矩形定位（content 另取剩余高度，header/footer 用自身 height）。title/titleItem 经背景件的标题槽暴露（title 空则隐藏标签；自定义 titleItem 自行定位，切角安全边距只随默认标题件）。implicit 尺寸由背景件与三槽的隐式尺寸推导（content 的 implicitHeight 驱动高度）；`containmentMask` = 背景件。**无默认属性**——裸子元素为普通可视子项，不参与槽位布局。
3. **命名契约：同名 = 接口合同**。裸名 `Dialog` 只授予与 T.Dialog 接口完全兼容的换皮件；基于 Window 的本件撑不起 Popup 合同（dim/enter/exit/closePolicy 等），必须用 Qool 前缀。撞名歧义不是顾虑——同名自然替代是本仓库的设计哲学（Qool.Controls 的 Button 先例），接口不兼容才是。同规则应用于组件内部：QoolDialog **不重声明 `title`**（遮蔽 Window.title 语义混乱，Qt 官方不建议唯一命名），**标题入口即 `Window.title`**，预置 surface 的 `title` 跟随之（任务栏与画面标题同源）；surface 的 `titleItem` 不经 QoolDialog 暴露——需要自定义标题渲染时直接用 DialogSurface。
4. **范围边界**：ButtonBox / standardButtons 为后续刀（已落定：ADR-0022。**QoolDialog 对应接口改判为无需**——盒到对话框的接线按接口显式完成，见 0022 KD3）；header/footer 已随 DialogSurface 三槽骨架落地；Item 形态不预包装——使用者自拼 `Popup + DialogSurface`（Popup 提供 dim/closePolicy/动效）。

## Consequences

- QoolDialog 是全仓**首个窗口模态件**：仓库现有代码零 modality/transientParent 先例（已核查），QML Window 的 transientParent 自动归属行为需在实现时验证。
- macOS 系统圆角对 TL 单角切的尖角有轻微裁切，v1 接受不做特化；前提条件（窗口自主）已成立，需要时可加。
- DialogSurface 依赖 Qool.Controls.Components（QoolBGBox 所在）与 Qool（Style / QoolBoxSettings 所在），Qool.Dialogs 模块声明这两个导入；QoolDialog 只依赖 Qool（经背景件 settings 推导最小尺寸）。
- QoolDialog（Window 壳）上没有 dim / closePolicy / popupType 属性；T.Dialog 的这些属性始终存在，只是其 Window 形态下 dim/closePolicy 无 overlay 语义、popupType 恰是切形态的开关——本件以独立 Window 固化 Window 形态，非能力缺失。
- 窗口可被系统缩小至背景件几何下限、不可被放大（`maximum` 跟随当前尺寸）；对话框无 resize 设施，正常使用中尺寸只随内容与显式赋值变化。

## 决策状态

已定案（2026-09-08，grilling 讨论收敛）。实现待 spec。
修订（2026-09-08，spec 发布前四子代理并行 rehearsal）：考证版本归属精确化（Dialog since 5.8、popupType 属 Popup 基类、6.11 flag 实现重构注记）；macOS 圆角表述收窄为平台默认行为；补 QoolWindowBasic 近亲方案排除项；Key Decision 1 增补 accept()/reject() 调用面与尺寸下限、Key Decision 3 增补 title 不重声明。
修订（2026-09-08，DialogSurface 去 BasicControl 化）：DialogSurface 由 BasicControl 子类改为 Item + QoolBGBox 背景 + 三槽 DummyItem 骨架（KD2 重写）；QoolDialog 公开面改为 header/content/footer 三槽别名，去掉 `surface` 只读别名与默认属性重定向（KD1）；标题入口定为 `Window.title`、预置 surface 的 title 跟随（KD3）；最小尺寸改为「背景件切角 + 边框」推导、`maximum` 跟随当前尺寸（KD1），消除 `minimumWidth: width` 的绑定循环。
修订（2026-09-08，DialogButtonBox 落定）：KD4 中「届时补齐 QoolDialog 的对应接口」改判为**无需**——accepted/rejected 到 accept()/reject() 的接线按接口显式完成（onAccepted/onRejected），QoolDialog 公开面保持 KD1 不变；理由与判例见 ADR-0022（接口一致的组件不允许行为分叉，marker/扫描接线判死）。
