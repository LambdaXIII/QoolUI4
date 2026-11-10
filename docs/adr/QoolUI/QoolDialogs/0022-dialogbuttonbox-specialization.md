# DialogButtonBox 特化换皮、DialogButton 语义件与显式接线（Qool.Dialogs 按钮装配）

Qool.Dialogs 的按钮盒 **DialogButtonBox 继承 QtQuick.Controls 的 T.DialogButtonBox 并以裸名导出**——接口完全兼容的特化换皮件（ADR-0021 KD3 命名合同的正例）：standardButtons/role 机制、平台排序、语言切换、6.11 默认按钮机制全部白送，本件只补 Qool 皮肤。皮肤独立为 **DialogButton**（对话域按钮件，role 驱动语义色：AcceptRole/YesRole → positive、DestructiveRole → negative，落边框+填充）；DialogButtonBox 为薄壳装配（`delegate: DialogButton` + `padding: 0` + 无 background）。**QoolDialog 零新增接口**：盒到对话框的 accepted/rejected 接线由使用者按接口显式完成。

> **基座已于 2026-11-11 改判**：`T.DialogButtonBox` → QtQuick.Controls **Basic 样式**的 `DialogButtonBox`。理由见文末修订——下文「Template 含全部机制」与「样式层零算法」两处前提有误，保留原文以便追溯。

## 考证（Template 含算法，Basic 只含视觉）

- **T.DialogButtonBox 继承 Container**；其 C++ 实现（QQuickDialogButtonBox，Qt 6 位于 qtdeclarative/src/quicktemplates；机制经 5.15 源码全文核实，6.11 API 面经官方文档核实）包含全部算法：
  - `createStandardButton()`——delegate 实例化；文字经 `platformTheme()->standardButtonText()` 注入并去助记符（qtbase 翻译直接生效）；attached `buttonRole`/`standardButton` 在 beginCreate 与 completeCreate 之间注入，delegate 内部绑定可读。
  - `handleClick()`——按 attached role 分发 accepted/rejected/applied/reset/discarded/helpRequested。
  - `updateLayout()`——按平台 buttonLayout 策略 stable_sort 重排；alignment 未设时按钮 `setWidth(itemWidth)` 均分拉伸（「默认填满」是源码级事实）。
  - `itemAdded()`——进入容器的按钮自动连 clicked 并挂 attached；`updateLanguage()`——LanguageChange 时重翻全部标准按钮。
  - **delegate 为空时标准按钮不创建**（`createStandardButton` 直接返回 null）——delegate 是 standardButtons 机制的必要件。
- **Basic 样式的 DialogButtonBox.qml 只有视觉默认**（spacing 1 / padding 12 / 单按钮 AlignRight 特判 / delegate Button / ListView contentItem / Rectangle 背景），零算法——样式层定位即视觉默认层，不是行为层。继承 Basic 需逐项对抗撤销其默认并锚死 Basic style。
- Template 的 `background` 默认 null（透明）——盒子在 DialogSurface 的 QoolBGBox footer 槽中天然隐身，无需背景件。
- Qt 6.11 新增 `defaultButton`/`defaultStandardButton`：默认按钮自动获得 highlighted + focus。
- `positive`/`negative` 是 Style 现成语义色 token（与 warning 同组，system theme 默认 green/red）；**仓库内无 DialogButton、无 role→视觉映射先例**，语义视觉为本刀新立。

## Considered Options

- **自研 Container + Qool 前缀**——被拒：重造 standardButtons/role/信号/平台排序整套机制；撑不起裸名合同（ADR-0021 KD3），成本高收益低。
- **继承 T.DialogButtonBox + Qool 前缀**——被拒：放弃同名自然替代哲学（Qool.Controls 的 Button 先例），无对应收益。
- **QoolDialog 补 standardButtons + 扫描 footer 自动接线**（T.Dialog 行为平价）——被拒：marker/扫描识别造成**同接口组件行为分叉**（本盒自动接线、T 原生盒子不接），直接违反特化合同本身；与 KD1「无默认属性重定向」的显式品味相斥。
- **继承 Basic 样式 DialogButtonBox**——被拒：Basic 是视觉默认薄壳（见考证），算法并不在那层。
- **盒子统一为盒内自拼按钮施加语义色**（读子按钮 attached）——被拒：未经同意改使用者按钮外观，属不可见的静默惊讶；语义改由 DialogButton 自身承载，自拼者换用 DialogButton 即得语义。
- **AcceptRole/YesRole 主按钮强调**——被拒：强调语义归默认按钮（6.11 机制），role 各自抢强调稀释默认按钮辨识度。
- **语义视觉仅描边**——被拒（用户裁定边框+填充）：警示强度不足为本刀核心目的服务；接受「无先例第一例」的审美责任。

## Key Decisions

1. **DialogButtonBox = T.DialogButtonBox 子类 + 裸名**：接口合同内特化。壳内仅 `padding: 0`（盒外间距归 DialogSurface 槽位）、`spacing: 4`（**字面量，暂定**——按钮族行内密度不上主题 token：窗口元素间距与按钮间距是两码事，且不改主题系统；ToolButton padding 字面量 2/4 先例）、无 background、`delegate: DialogButton`；alignment 保持 T 默认（填满）。
2. **DialogButton = 自包含语义按钮**（ToolButton 手法：单文件皮肤，T 根 + QoolBoxSettings/QoolBox 背景 + 三张 cover + 居中文字 contentItem——照 ToolButton 的裸 Text 先例，不照搬 Button 族 BasicButtonText（右对齐），不跨模块继承 QML 组件）：role 经限定名 attached `T.DialogButtonBox.buttonRole` 读取；AcceptRole/YesRole → `positive`、DestructiveRole → `negative`、其余 role 不映射；语义落**边框+填充**两面；语义填充上的前景对比走 `ThemeHQ.recommendForeground`（Q_INVOKABLE static，Crystal.qml/Slider.qml 先例；Style 单例不承载该机制）。强调 cover 的 opacity 源为 `highlighted || hovered`（T.Button 的 highlighted 无默认 hover 绑定，聚合两源共用一条强调通道，承载 hover 反馈与默认按钮强调）。自拼用法（`DialogButton { T.DialogButtonBox.buttonRole: ... }`）与 delegate 用法同一身体。
3. **接线纯接口驱动，QoolDialog 零新增**：使用者在 footer 显式 `onAccepted: root.accept()` 等。判例：**接口一致的组件不允许行为分叉**——marker/扫描接线判死的本质理由不是脏，是它让同接口的组件在同一槽位行为不同。
4. **归属 Qool.Dialogs**：role 语义是对话域词汇；DialogSurface「容器无关仍归 Dialogs」的先例延续；依赖方向无环（Dialogs 已依赖 Qool.Controls.Components，反身不依赖）。
5. **盒子对已存在的按钮零干预**：语义活在件自身（出生皮肤），不写在干预逻辑里；T 原生按钮放入本盒仍可用，只是无语义色。

## Consequences

- 本 DialogButtonBox 是 T.DialogButtonBox 的 drop-in replacement：T.Dialog、QoolDialog、任何 Popup/Page 均可放入，用法一致；反向地，Qt 原生 DialogButtonBox 也可放入 QoolDialog。
- 标准按钮的文案、翻译、平台排序、role 信号、默认按钮机制全部由 Template 层承担，本件零文案代码。
- role→语义色（边框+填充）为仓库第一例，无先例背书；修正成本收敛于 DialogButton 单文件。
- QoolDialog 公开面保持 KD1 不变；ADR-0021 KD4「届时补齐 QoolDialog 的对应接口」改判为「无需」（修订已落 0021）。
- 实现期核实清单（进 spec）：限定名 attached 访问（`T.DialogButtonBox.buttonRole`）与使用者侧同名 attached 解析（T 的 C++ attached vs 本模块 QML 复合件裸名）；根类型 T.Button（倾向，白送 flat/highlighted）vs T.AbstractButton（Button.qml 先例）；机制考证基于 5.15 源码 + 6.11 文档，对 6.11 源码复核一遍（本机 Qt 安装未含 Sources 时走在线 qtdeclarative 源码复核；不可得则降级为 6.11 文档 + 5.15 已考源码为准并记录）。

## 决策状态

已定案（2026-09-08，grilling 讨论收敛）。实现待 spec。
修订（2026-09-08，spec 发布后 rehearsal 修正）：KD1 spacing 预收敛 `Style.windowElementSpacing`；KD2 三处口径修正——contentItem 照 ToolButton 裸 Text（BasicButtonText 属 Button 族且右对齐，不照搬）、前景对比机制改挂 `ThemeHQ.recommendForeground`（Style 不承载，原表述挂错层）、强调 cover 的 opacity 源定为 `highlighted || hovered`（原「零额外代码」不成立：ToolButton 的 cover 绑 hovered，默认按钮强调需聚合源）。
修订（2026-09-08，spacing 复议）：KD1 spacing 改为**新 token `Style.buttonSpacing`（qreal 组，system theme 默认 4，暂定）**——用户裁定「按钮间距和窗口元素间距完全是两码事」，撤销 windowElementSpacing 预收敛；提新 token 入本刀范围（Style 宏族多文件，照既有 qreal token 家族模式加）。
修订（2026-09-08，spacing 终定）：KD1 spacing 定为**字面量 4（暂定）**——用户裁定不改主题系统，撤销上一条「提新 token buttonSpacing」方案；按钮行内密度不进 Style（ToolButton padding 字面量先例），将来若需主题化再议。
修订（2026-09-08，实现期）：KD2 根类型落定 **`T.AbstractButton` + 自声明 `property bool highlighted: false`**（`Button.qml:7,21` 先例）——修正原「T.Button 白送 flat/highlighted」归因：6.11 官方文档核实 `flat`/`highlighted` 是 **Button 类型的属性，AbstractButton 没有**，T.Button 无可白送之物（默认按钮第二重强调本就是被拒项）。T.AbstractButton 是对话域语义按钮的诚实根类型（不冒领通用按钮身份；盒对 delegate 类型无要求）。
修订（2026-11-11，基座改判）：**KD1 的基座改为 QtQuick.Controls Basic 样式的 `DialogButtonBox`，皮肤四件不变**。实测否证了本 ADR 两处前提：（1）「Template 含全部机制」——算法确在 Template，但 **内容宿主 `contentItem` 与按钮排布在样式层**，Template 层不提供；（2）「Basic 只是视觉默认、零算法」——宿主与排布正是它提供的。只继承 Template 的后果：standardButtons 照常实例化、`count` 与 implicit 尺寸全对，但按钮**无父件、永不进入场景图**——屏幕上什么都没有，且既有测试（数数 + 颜色 + implicit 尺寸）全绿。窗口级测试证据：`contentItem == null`、按钮 `parent == null`；换成样式层基座后按钮进入场景图并有非重叠几何。Basic 基座同时锚死风格（皮肤四件已全覆盖），宿主形态不随应用风格漂移。原「继承 Basic 样式」的拒因（"算法并不在那层"）随之失效——算法与宿主分属两层，必须一起继承。
