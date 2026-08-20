# Changelog

版本号不随常规修改迭代（当前 4.0.0），仅在正式发布时递增；本文件记录每次修改的内容。

## [4.0.0] — 2026-08-20

### 修复（dial-valuecolor-source-follow + rangeslider-foreground-color，Dial 采样色跟随 + RangeSlider 前景色接线）

- **Dial valueColor 源色不跟随**（Dial.qml）：`readonly valueColor: colorAt(position)` 是 C++ 方法绑定——QML 绑定只追踪参数 position、不追踪方法体内对 stops 的访问（同 Slider 缺陷模式）；改 high/mid/low 色不触发重算，按压采样色冻结在旧值。改手动驱动：去掉绑定，`Component.onCompleted` 初始采样（stops 就绪后）+ 信号 connect 四源（positionChanged/highColorChanged/midColorChanged/lowColorChanged → `updateValueColor()`）；colorMapper 加 objectName 供测试定位
- **RangeSlider 前景色未接线**（RangeSlider.qml）：`rangeCrystal` 未绑定 `root.color`——文档承诺 `color` 为前景填充色，但实现未接线，前景恒 Crystal 默认 `Style.accent`、宿主设置 `color` 无效。补 `color: root.color`（属性级绑定，描边 borderColor 依赖本色自动跟随）
- **测试**：新增 `tst_dial.qml`（test_defaults / test_valueColorPosition / test_valueColorFollowsSource——源色变化立即跟随的缺陷回归）；`tst_rangeslider.qml` 新增 `test_foregroundColor`（前景色 = root.color + 改色立即跟随回归）

### 修复（slider-handle-sample-frozen，Slider 手柄采样冻结缺陷）

- **根因**：handle 色 `color: colorMapper.colorAt(position)` 是 C++ 方法调用——QML 绑定不追踪方法体内对 stops 的访问，绑定只依赖 position。初始求值时 stops 未就绪 → handle 冻结在默认黑；之后 backgroundColor/color 变化（主题加载/换色）不触发重算——默认 value:0 时手柄恒黑直到拖动（真实缺陷）
- **修复**（Slider.qml）：Crystal 去掉 color 绑定，改 handle 侧驱动——`Component.onCompleted` 初始采样（stops 已就绪）+ 信号 connect 三源（positionChanged/colorChanged/backgroundColorChanged → `updateColor()`）；初始正确 + 运行时源色变化实时跟随
- **测试**（tst_slider.qml）：新增 `test_handleSampleColorFollowsSource`（初始采样正确 + 改 backgroundColor 立即跟随 + position 变化采样离开 from 端）

### 变更（slider-orientation-rtl，Slider 对齐 Qt 官方 orientation×RTL 正交统一）

- **法向尺寸抽象 `side`**（Slider.qml）：`side = horizontal ? availableHeight : availableWidth`——手柄边长/收缩量/轨道收缩/展开全部基于它（横竖对称、镜像无关）；`shrinkSize` 基准 `root.height` → `side`（含 padding 时语义修正）
- **handle 官方双分支定位**：水平 x 由 `visualPosition` 驱动、y 居中；垂直 y 由 `visualPosition` 驱动、x 居中（完整公式含 padding）——RTL 由模板免费承载（vertical+RTL 跟随 Qt 模板，不特判）
- **轨道双分支**：沿主轴铺满 + 法向收缩居中（水平收缩高、垂直收缩宽）
- **渐变锚定值增大端**：水平 LTR 左→右、RTL 右→左（x 端对调，stop 色序不变）；垂直 from 底→to 顶（Qt 垂直惯例 visualPosition 恒 = 1−position，**不受 RTL 影响**——offscreen 实测确认）
- **采样改 `position`**：`colorAt(visualPosition)` → `colorAt(position)`（不镜像）——与对调渐变几何互补（RTL 下采样错位修复；rehearsal 推演发现）
- **implicit 随 orientation 交换**：background 150×25 ↔ 25×150（对齐官方"垂直默认窄"惯例）
- **光标随轴向**：水平 SizeHorCursor、垂直 SizeVerCursor
- **测试**（tst_slider.qml）：新增 test_verticalGeometry / test_rtlMapping / test_verticalRtlCombined（几何断言；offscreen 实测确认 Qt 垂直 visualPosition 恒反转、垂直+RTL 与 LTR 一致）
- **文档**：Slider.md 更新（概述 orientation/RTL 契约段、渐变值增大端语义、采样 position、垂直示例、光标随轴向）；ADR 0010 追加「实现演进」段（实测修正垂直渐变方向 + 垂直不受 RTL）

### 变更（slider-background-resizer-align，Slider 对齐 RangeSlider 架构演进）

- **Slider 改标准 background 驱动尺寸**（Slider.qml）：删除「root 直接给默认尺寸 80×25」与 background 尺寸外部 Binding——改自写 implicit 公式（`leftInset + implicitBackgroundWidth + rightInset`，模板不自带）+ background 显式 implicit（150×25）；尺寸经 Control 标准自动布局（background 自动 fill 控件 − insets，替换新实例同样受控——插拔安全不降级）
- **RangeSlider 默认尺寸统一 150×25**（RangeSlider.qml）：background implicit 200×22 → 150×25——Slider 与 RangeSlider 默认 implicit 统一
- **Slider handle 改用 ItemAnimatedResizer**（Slider.qml）：删除 handle Crystal 的 `BasicNumberBehavior on height`（width=height 联动）——改 ItemAnimatedResizer 控制 Crystal 宽高缩放（from = 可用高 − 收缩量 / to = 可用高，`resized` 方向开关：hover/按下/锁存三态）——两方向动画独立模板 + 锁定 Binding 目标跟随
- **锁存内化 + 接口移除**（Slider.qml）：删除公开属性 `justMoved`/`valueVelocity` 与 `NumberNotifier`；root 级 movementLatch 双触发改 handle 内 TimerLatch 单触发（`onValueChanged`）——连续变化窗口经滑动保持等价（RangeSlider 验证）；锁存不暴露接口（"刚移动"感知经手柄展开反馈呈现）
- **禁用冻结**（Slider.qml）：cResizer 接 `enabled: root.enabled`——禁用时手柄整体静止（含程序化写入展开取消——禁用视觉静态化，同 RangeSlider 决策）
- **其它对齐**（Slider.qml）：handle 高度 `root.height` → `availableHeight`（有 padding 时正确）；轨道定位 `anchors.centerIn` → `y: halfShrinkSpace` 显式（同 RangeSlider 同构）；`crystalShrinkSize` 更名 `shrinkSize`
- **测试**（tst_slider.qml）：implicit 断言 80×25 → 150×25；删除 test_justMovedLatch（接口移除，锁存行为由 test_handleRestAndExpand 的展开/回落覆盖）；轨道/插拔注释措辞（外部 Binding → 标准自动布局）
- **文档/示例**：Slider.md 重写（移除 valueVelocity/justMoved、标准尺寸公式、禁用冻结语义、锁存内化、resizer 动画）；RangeSlider.md 尺寸文本 200×22 → 150×25；示例页 5 处 QoolTip 同步（锁存内化/禁用冻结/自动布局/默认 150×25）

### 变更（rangeslider-enabled-gate + itemanimatedresizer-docs）

- **RangeSlider 前景 resizer 接 `enabled`**（RangeSlider.qml）：`cResizer` 增加
  `enabled: root.enabled`——禁用时值变化锁存不再展开前景，hover/光标/展开动画
  同受 `enabled` 门控（禁用即整体静止，交互反馈一致性）；正常态行为不变
- **ItemAnimatedResizer 修复后退方向误引用前进模板**：`backwardAni` 的
  easing/duration 原取 `templateFowardAni`（复制笔误）——现改取
  `templateBackwardAni`，`backwardAnimation` alias 真正控制后退节奏；
  `go_backward` 动画门控检查同步改查后退模板 duration（此前后退动画时长
  恒等于前进模板）
- **ItemAnimatedResizer 注释补全**：头部关键注释（resized 方向开关模型/
  enabled 门控语义/动画模板/锁机制目标跟随）；方向锁与锁定 Binding 就地注释；
  删除废弃 from/to 注释占位
- **文档**：新增 `docs/reference/Qool/ItemAnimatedResizer.md`（5 节：概述/
  属性/信号/方法/使用示例）；`index.md` 登记（组件参考 + 工具段）
- **测试**：新增 `tst_itemanimatedresizer.qml`（批次自动发现）——默认态
  from 尺寸/前进后退切换往返/目标跟随（锁定 Binding 持续生效）/enabled 冻结
  与恢复/动画路径（running + 到达）/两方向模板独立定制/动画关跳变

### 变更（rangeslider-template-handle，RangeSlider 回归模板 handle 体系）

- **根因**：RangeHandle 自建三区交互体系（DragMoveArea → 意图信号 → 宿主换算）完全取代模板 handle 体系——`first.handle`/`second.handle` 从未设置，模板私有状态机（handlePress/handleMove/handleRelease）在区间内从不激活；模板把 snap/live 实现在该私有拖动链，而 `QQuickRangeSliderNode::setValue` 本身无 snap——`snapMode`/`stepSize`/`live` 在鼠标拖动路径下全部失效
- **决策反转**：删除 `RangeHandle.qml`/`rangeHandle` 属性/三区意图信号（wannaMoveFirstX/SecondX/RangeX）/热区扩展/`down`/`hovered` 聚合/`pixelToValueDelta` 换算与自建钳制；组件内设置 `first.handle`/`second.handle` 默认 handle 激活模板状态机——snap/live/键盘/nearest/端点钳制全部模板行为（零自建）
- **handle 窄条 + 不相交定位**：默认 handle = 窄条（`width = availableHeight / 2`），定位行程 = `availableWidth − width×2`（first 从 0、second 从 width——**任意值下两 handle 永不相交**）、按 `visualPosition` 映射（RTL/垂直感知）；`z:10` 盖在 contentItem 之上（拖动命中不受前景遮挡）；宿主替换即行为插拔（定位自写）
- **前景入 contentItem**：`surface` 属性**删除**——前景（Crystal）直接置于 contentItem 内 `rangeBox` 区间盒（x 随 first 视觉位、宽 = 区间视觉宽 + 自身高作尖角外溢余量）；**hover 展开**由 HoverHandler + `ItemAnimatedResizer` 驱动（from = 区间盒 − 收缩量 / to = 区间盒全尺寸，动画门控 `animationEnabled`）
- **锁存移除**：`firstJustMoved`/`secondJustMoved` 删除——前景展开只响应 hover（无 pressed/锁存路径）
- **整体滑移取消**：模板无中段整体滑移——不做默认实现，文档注明宿主自建路径（contentItem 内 MouseArea 同步操作两端）
- **API 破坏**：`rangeHandle` 属性、`RangeHandle` 类型、`surface` 属性、`firstJustMoved`/`secondJustMoved` 全部删除；行为插拔点 = `first.handle`/`second.handle`（模板 handle 契约）；"点击无操作"契约变化（点击轨道走模板 nearest）
- **测试重写**（tst_rangeslider.qml）：窄条 handle 不相交、区间盒几何、前景常态收缩、键盘步进、程序化不吸附、端点钳制、倒置范围、handle 插拔；hover 展开为模板不可达人工验收
- **文档/示例**：RangeHandle.md 删除、RangeSlider.md 重写（模板 handle + 区间盒前景 + hover 展开）、reference index.md 移除登记；ADR 0009 追加「模板 handle 回归」演进节；示例页更新（删 surface 示例改外观通道、HandleKnob 窄条不相交、QoolTip 更新）

### 变更（slider-align，Slider 对齐 RangeSlider 接口面演进）

- **RangeSlider `bgColor` 更名 `backgroundColor`**（RangeSlider.qml）：语义精确（属性即轨道背景色）；消费处同步——轨道颜色、tst_rangeslider.qml 断言、RangeSlider.md、ADR 0009 外观通道条目
- **Slider 新增外观通道**：`color`（渐变右端色）/`backgroundColor`（渐变左端，轨道以 75% 透明渲染）/`borderColor`（轨道描边，默认 `ThemeHQ.recommendForeground(backgroundColor)` 自动对比推荐）；轨道渐变左端由 `Style.text` 改为 `backgroundColor` 75% 透明（同 RangeSlider 轨道半透明语义）；手柄采样渐变不透明化（实体不透明，同 RangeSlider 前景）
- **`preferredHeight` 公开属性移除**（Slider）：改为默认 handle 与 background 的内部配套约定——收缩偏移量内化 pCtrl（只缓存偏移量不缓存高度，root 变化无 stale）
- **background 尺寸改外部 Binding 施加**（Slider）：root 尺寸 − insets、常态收缩 + 居中——替换 background 后新实例同样受控（插拔安全；内联尺寸绑定随默认实例替换丢失）
- **`encountered` 更名 `expanded`**（Slider）：与 RangeSlider surface 命名统一
- **测试**：新增 tst_slider.qml（批次自动发现）——默认状态/轨道几何与渐变 stops/手柄常态收缩与展开反馈/锁存窗口/采样色不透明化/background 替换插拔/insets 响应
- **展示页同步**（Page_InputControls2.qml）：LoggingHandle 改监听意图信号 `wannaMoveFirstX`/`wannaMoveSecondX`/`wannaMoveRangeX`（修复引用已删结果信号 firstMoved 等的加载隐患）；Slider/RangeSlider 各组 QoolTip 更新（`backgroundColor`/`borderColor` 通道、渐变 0.75 描述、锁存分化、surface 自布局插拔语义）；customSurfaceSlider 的 surface 补 `anchors.fill: parent`（布局责任反转）；Playground 头注释同步（RangeSlider 调试用例）
- **文档**：Slider.md 更新（属性节、渐变描述、反馈节、background 插拔语义）；ADR 0009 实现演进节追加「Slider 同步」

### 变更（rangeslider-interface-landing，RangeSlider/RangeHandle 接口面落地演进）

- **RangeHandle 收敛为纯交互件**（RangeHandle.qml）：删除全部位置/外观输入（firstPosition/secondPosition/cutSize/preferredHeight/externalExpanded/color/animationEnabled/expanded/surfaceHeight/midPosition/zoneWidth）与钳制/分区判定——**不收位置、不发结果位置**；三区各为独立 DragMoveArea，发意图信号 `wannaMoveFirstX`/`wannaMoveSecondX`/`wannaMoveRangeX`（载荷 = 像素增量位移，DragMoveArea 增量语义）；三区物理分区（`handleHSpace = min(宽/2, 高/2)` 端点热区、`rangeHSpace = 宽 − 高` 中段行程区，w ≥ h 时 left [−ext, h/2] / center [h/2, w−h/2] / right [w−h/2, w+ext]）；新增热区扩展（first/secondMouseZoneExtension，默认 2）、光标 alias、`down`/`hovered` 聚合；三区 `autoBind: false`——修复拖动物理移动 rangeHandle 与区间盒 Binding 双重驱动致端点可越过（同 QoolWindowBG/RectResizer 句柄漂移教训）
- **RangeSlider 区间盒几何**（RangeSlider.qml）：值→位置映射收敛为 `dummyRangeBox` 区间盒（`x = availableWidth × first.position + leftPadding`、`width = availableWidth × (second − first)`）经 Binding 组施加——**rangeHandle 的几何即区间盒**，不再需端点位置输入；端点/整体钳制在值域（`first ∈ [from, second.value]`、`second ∈ [first.value, to]` 可重合不交叉、整体滑移 `[from − first.value, to − second.value]` 不变形边界整体停）；`pixelToValueDelta` 为 pCtrl 内部方法（不暴露公开 API）
- **色彩通道 + 外观**：`color`（前景填充）/`bgColor`（轨道背景，默认 75% 透明渲染）/`borderColor`（前景与轨道描边，默认基于 bgColor 自动对比推荐）；前景与轨道同为 Crystal 尖角外溢（`width = parent.width + height`，直边区 = 区间/控件宽），前景常态收缩/展开占满（尖角外溢量随高度变）；surface 自布局（RangeHandle 仅设 parent，默认 `anchors.fill` 区间盒）
- **锁存分化**：`justMoved` → `firstJustMoved`/`secondJustMoved`（两端独立 500ms 窗口，写入哪端锁存哪端）
- **测试契约重写**（tst_rangeslider.qml，批次 29 用例全绿）：区间盒几何/前景尖角外溢与收缩展开/三区几何与热区扩展/独立锁存/倒置范围/wannaMove 增量换算与端点钳制/整体滑移边界/surface 替换（自布局）/RangeHandle 独立实例化
- **文档**：`docs/reference/Qool.Controls/RangeHandle.md` 与 `RangeSlider.md` 重写为新契约（意图信号、区间盒几何、尖角外溢、色彩通道、钳制语义、surface 自布局插拔示例）；ADR 0009 新增「实现演进（2026-08-20）」节（位置 vs 值输入结构演进、surface 布局责任反转、autoBind 教训、锁存分化、外观通道、测试策略）

### 变更（rangeslider-three-layer，RangeSlider 三层重构实现落地）

- **新组件 `Qool.Controls.RangeHandle`**（RangeHandle.qml，Item 基座）：区间逻辑单一归属——输入 firstPosition/secondPosition/cutSize/preferredHeight/externalExpanded/color/animationEnabled；信号 firstMoved(位置)/secondMoved(位置)/rangeMoved(像素位移)（载荷换算归宿主）；派生 expanded/surfaceHeight/midPosition；surface 布局控制（x/y/width/height/color 经动态 Binding 施加——宿主替换 surface 时新实例同样受控）。可独立实例化（implicit 80×25）
- **RangeSlider 重构为三层**（RangeSlider.qml）：模板 + 静态 Crystal 轨道（Style.text、恒常态高、不参与交互反馈）→ 内置 RangeHandle（`rangeHandle` 属性——宿主继承替换即行为插拔；配套绑定与信号换算经动态 Binding/Connections 施加）→ surface（默认 Crystal 整体前景——中央直边区 = 区间、两端尖角 45° 溢出 cutSize = preferredHeight/2、端点重合自动退化水晶菱形；替换任意 Item 即外观插拔，与行为解耦）。值→位置映射留在 RangeSlider（positionToValue/shiftRange）；三区域交互（左拖 first/右拖 second/中拖整体滑移——两端同步、区间宽不变、边界钳制整体停），全部点击无操作，键盘保留模板；端点钳制（行程内、可重合不越界）在拖动路径
- **测试契约重写**（tst_rangeslider.qml 单接缝，29 用例全绿）：默认状态/背景轨道静态/前景几何（中央直边区 = 区间、尖角溢出、重合菱形）/justMoved 锁存/展开反馈（justMoved → surface 高 = 控件全高、窗口落后回常态——动画关闭即时）/倒置范围/信号载荷换算（firstMoved/secondMoved 位置→值、rangeMoved 整体滑移与边界钳制、端点重合退化）/surface 替换最低要求（简单 Rectangle 自动填充区间 × 高度）/RangeHandle 独立实例化
- **示例页**：Page_InputControls2.qml RangeSlider 展示更新（三层结构说明 + 三区域交互 + 外观/行为双插拔演示——自定义 surface Rectangle 与内联派生组件 LoggingHandle）
- **文档**：`docs/reference/Qool.Controls/RangeSlider.md` 重写（三层结构 + 插拔契约）；新增 `docs/reference/Qool.Controls/RangeHandle.md`（输入/信号/派生/布局契约 5 节）；index.md 登记

## [4.0.0] — 2026-08-19

### 变更（rangeslider-three-layer-design，RangeSlider 三层重构设计决策落地）

- **ADR 0009**：`docs/adr/QoolUI/QoolControls/0009-rangeslider-three-layer.md`——RangeSlider 重构决策落定：三层结构（静态背景轨道 + RangeHandle 独立组件 + surface 外观插拔件），整体 Crystal 前景取代双手柄（两端点重合退化水晶型）；三区域分区交互（左拖 first/右拖 second/中拖整体滑移，全部点击无操作）；保留 T.RangeSlider 模板与 API、不定义 handle delegate；surface 布局由 RangeHandle 控制（接口后梳理）。被拒方案记录：双手柄逐项修补（几何死结）、交互入 surface（退化为两层）、点击跳转保留
- **FIXME 清理**：Slider.qml 移除 2 处（非交互动画位移/cursorShape 全局暴露）、RangeSlider.qml 2 处（手柄行为/动画位移）——对应议题经 grill 裁决取消（动画位移与 cursorShape 暴露不做）；VerticalSlider 重构 FIXME 保留（延后专项）
- **后续**：三层结构实现 + tst_rangeslider 契约重写 + RangeSlider/RangeHandle 参考文档，为独立实现专项

## [4.0.0] — 2026-08-19

### 新增（cut-sizes-locker，QoolBoxSettings 四切角统一联动插件）

- **CutSizesLocker（Qool/shapecontrol/qool_qoolboxcutsizeslocker.\*）**：`QoolBoxCutSizesLocker` C++ 类（继承 SmartObject，QML_NAMED_ELEMENT(CutSizesLocker) 注册进 Qool）。作为 `QoolBoxSettings` 专属插件：启用期（`enabled == true` 且 target 有效）四角切角统一为 `cutSize`；停用恢复进入本次锁定前一刻的快照。五条变更路径（locker.cutSize 与 target 四角）汇聚到同一统一逻辑；快照时机 = 进入锁定状态瞬间（enabled false→true 或 enabled 期间换 target 都重新快照）；换 target 时旧 target 恢复其快照、新 target 立即统一；构造时 parent 为 QoolBoxSettings 则自动挂接，否则 target 为 null 安全空转
- **测试（双接缝）**：core 层 `tst_qoolboxcutsizeslocker.cpp` 10 用例——默认值/空转、parent 自动挂接、cutSize 统一、单角联动、停用恢复与停用期自由改、重启用快照时机、停用期 cutSize 不触碰 target、enabled 期换 target（旧恢复/新统一）、target 置 null 恢复旧 target、disabled 换 target 后 enable 快照新值；qml 层 `tst_cutsizeslocker.qml` 冒烟——类型注册、cutSize 绑定响应、单角联动、停用恢复、无 target 空转
- **文档**：`docs/reference/Qool/CutSizesLocker.md`（MUST 5 节）+ index 组件参考登记

## [4.0.0] — 2026-08-17

### 变更（comment-cleanup，全仓库违规注释清理）

- **清理标准**：注释非 ADR/非工作记录/非文档/不替代代码结构（根 AGENTS「注释点状就地、文档成篇完整」分工）——决策史、迁移记录、排错史、验证史、日期、成篇论述（已有 reference 文档承载的重复内容）、v3 对比、spec/票死引用、注释掉的死代码一律移除；合规的设计意图/陷阱约束/易误解点（勿改）与 TODO 保留
- **Qool 核心组件头部精简（HalfCrystal/Crystal/Slider/RangeSlider/VerticalSlider）**：48/35/53/48/30 行成篇论述头部 → 3-5 行定位 + `docs/reference/` 文档指引（几何/掩码/implicit 契约文档已完整承载，属冗余重复）；删除「用户裁决/指令/裁定 2026-08-16」决策史、公式推导、v3 对比；正文保留就地点状设计意图，去「曾误取 vN/vS」「曾致高度恒 0」「2026-08-10 裁定」等排错史/日期措辞
- **QoolColor 迁移记录全清（32 文件）**：`NOTE(迁移) v3 ... 逐字迁移/拍平重写` 头部（依赖替换/Style 对位/拍平内容/不再依赖/与 v3 刻意差异清单）整段删除——迁移结果即当前代码，过程记录不留；「关键行为/关键几何/易误解点（勿改）」陷阱约束保留并去 v3 措辞；`v3 行为照迁/原样/同款/同构` 等 368 处 v3 对比清零（设计传承类改写为当前表述）；`color-migration-spec §7-7`、`T08/T10`、`spec §7-9` 死引用删除（spec 为 .scratch 临时过程文档）；TODO(将来迁移) 保留
- **QoolControls 日期与决策措辞**：ComboBox/EditableText/EditableTextBox/ScrollBar/ScrollIndicator/ScrollView/SpinBox/BasicTextArea/IndexIndicator/QoolBGBox 的「修复 2026-08-10」「实测裁定 2026-08-11」「经验回流」「测试实证修复」「用户裁定」等日期与工作记录删除，保留原因/结论；Octagon 系列与 ProgressBar 去 spec D5 引用；QoolControls/CMakeLists.txt 去 v3 与日期
- **C++ 注释措辞**：qool_qoolbox_settings.h 决策史段删除（ADR-0005 已完整承载双类型→单一类型历程）；qool_shapecontrol.cpp「实证」措辞改写（机制解释保留）；qool_shapegadget_rect.cpp/qool_shapegadget_qoolbox.cpp 去「曾误/曾致/审查 F1」排错史；qool_chatroom.cpp/qool_chatroom_manager.cpp 去「原补发循环已删除/用户裁定」；singleton.hpp 去「曾有过...已删除」排错史（陷阱警告保留）；qool_fileinfolist_model.cpp 删 3 处注释掉的死代码（旧 remove/move/__make_index_range 实现）；xml_theme_loader_impl.cpp 删注释掉的 xDebug 行；qool_colorassistant.h/qool_colorhuecyclemodel.cpp/qool_random_hsv_color_generator.* 去迁移史（防误改警告与当前公式保留）
- **QoolUITests**：tst_hover_e2e/tst_rectgadget/tst_halfcrystal 去「用户裁决/用户 2026-08-16」决策史与「曾误绑」排错史（回归防护语义保留）；tst_qoolbox_hit 删「注册（主代理执行）」工作记录段；全部 spec D*/票引用删除（ADR 引用保留）；qool_test.hpp 去「实证/T05 实测 2026-08-12」；CMakeLists 与 qml_test_main.cpp 去「原 spec 5.x/6.x」引用；`\c{}` QDoc 标记残留清除；tst_halfcrystal effInset 死引用清除（该概念已随重做移除）
- **QoolUIExample**：Page_InputControls2/Page_Playground 去日期；Page_HalfCrystal 去票引用；Page_Color 去 v3 措辞
- **验证**：终验 grep/glob 全仓 `用户裁决/裁定/指令`、`2026-`、`实证`、`曾误/曾致`、`NOTE(迁移)`、`逐字迁移/照迁`、`spec D*`、`票 *`、`color-migration-spec`、`\c{` 等零残留（`qool_colorname_db.cpp`「provider 裁决」为业务语义保留）；v3 注释引用 368 → 0；build 285/285 成功；测试 18/18 全绿

### 变更（norms-system-landing，规范体系重设计落地）

- **根 AGENTS.md 重写为 12 节**：文档地图（置顶，各设施一句）/定位/模块架构/技术栈约束/构建命令/编码规范（C++）/QML 组件规范/注释与文档规范（Markdown）/测试/工作流约定/已知陷阱/变更记录。全篇术语「官方插件」→「自带插件」；QDoc 规范节、依赖机制三场景表、已知陷阱 1/4、关键文件路径表删除；已知陷阱仅留「不能假定仅有一个 QML 引擎存在」一条
- **ADR 迁移到严格模块粒度**：`docs/adr/qoolbox/0002-0008`（7 篇）→ `docs/adr/QoolUI/Qool/`；`docs/adr/architecture/0001` → `docs/adr/QoolUI/`（子项目级通用件）；空目录删除；`docs/adr/README.md` 重写（两级布局 + 全局流水号约定 + 新索引）；CONTEXT.md 形状体系 ADR 路径同步
- **QDoc → Markdown 迁移**：13 个 `.qdoc` 全部删除，转换 14 个目标文件——`docs/reference/Qool/index.md`、`docs/reference/Qool.Color/index.md`、`docs/reference/QoolCommon/` 8 篇（property-macros/std-tools/qt-tools/lazy-cache/default-variant-map/math-utils/range-counter/math-geometry）、`docs/articles/` 4 篇（style-system/window-parts/qoolbox-geometry/plugin-interfaces）；正文逐句保留，仅术语修正
- **docs/agents 三件套更新**：issue-tracker.md 状态字段清单合并（spec 级三态 + 票级开放字段清单）；domain.md 重写为单 context 形态（ADR 读取路径改 `docs/adr/<子项目>/<模块>/`）；triage-labels.md 不动
- **子/模块 AGENTS**：QoolUITests/AGENTS.md 新增「工作流」节（测试工作流 SHOULD / 摩擦求助 MUST / 摩擦反馈回路 SHOULD）+ 引用修正 + 元语境清理；QoolUI/QoolFile/AGENTS.md 多层插拔标题改指向根规范；新建 QoolUI/QoolDebug/AGENTS.md（Debug 边界暴露原则唯一归属）；新建 QoolUIExample/AGENTS.md（页面组织）
- **源码注释引用修正**：HalfCrystal.qml/OctagonShape.qml/qool_qoolbox_shapecontrol.cpp 删除「AGENTS.md 已知陷阱 5」引用（注释本体保留）；singleton.hpp 引用改「根 AGENTS.md 已知陷阱（QML 引擎唯一性）」；colornameprovider/CMakeLists.txt「插件约定」引用保持（新根第 3 节仍含）
- **验证**：configure + build（68/68）+ 测试 18/18 全绿；终验 grep/glob 全部 0 匹配（qdoc 空、旧 ADR 路径空、陷阱 5 引用空、Scripts 大写空、AGENTS 产物元语境空）

### 变更（qdoc-residue-cleanup，源码 QDoc 注释块全面迁移）

- **源码 QDoc 注释块迁移（107 文件全清）**：源码内嵌 `/*! ... */` QDoc 注释块（`\qmltype`/`\qmlproperty`/`\qmlsignal`/`\qmlmethod`/`\inqmlmodule`/`\nativetype`/`\section` 等命令）全部移除——公开类型的成篇文档内容完整迁移为 `docs/reference/<模块>/<类型>.md`（**英文、Qt 官方文档风格、MUST 5 节**：Overview/Properties/Signals/Methods/Usage Example，与源码核实后重写，非映射式转换）；_private 私有件与纯 C++ 内部类（无 reference）的 QDoc 块转为普通简体中文注释（内容逐句保留、仅去 QDoc 命令标记）
- **reference 文档新增 68 篇**：Qool 25（BasicLabel/BasicRotationBehavior/Crystal/CutSizeBinding/DragMoveArea/Floater/HalfCrystal/Octagon×6/QoolBox/TimerLatch/ShapeControl/QoolBoxSettings/QoolBoxShapeControl/OffsetProjector/QoolBoxGadget/RectGadget/ThemeHQ/ThemeHQModel/ItemTracker/PositionTracker）、Qool.Chat 5（Beeper/ChatRoom/Message/MsgChannelSet/MessageLogger）、Qool.Color 15（9 QML + 6 C++）、Qool.Controls 15（11 主目录 + 4 Components）、Qool.Debug 3（ColorButton/QoolBoxHud/RectResizer）、Qool.File 8（3 QML + 5 C++）；每篇含属性/信号/方法与源码声明逐项核实（实例：RandomHSVColorGenerator 以恢复后的 v3 名 minimumHue 等与只读 previous 为准、Message 拷贝生成新身份契约、EditableText 双层编辑会话/判定信号、QoolBox 退行与命中判定）
- **模块 index 补齐**：Qool.Chat/Qool.Controls/Qool.Debug/Qool.File 新建 index.md；Qool/Qool.Color index 追加组件参考链接清单
- **悬空引用清理**：4 个宏头文件「详细文档见 property_macros.qdoc」→ `docs/reference/QoolCommon/property-macros.md`；Floater/HalfCrystal/ComboBox 等 13 处源码注释「见 QDoc」→「见 reference 文档」；math-utils.md/qt-tools.md/plugin-interfaces.md 的 QDoc 体系表述改为 Markdown 文档表述；Scripts/qoolui_build_common.py「qdoc 文档包」→「Markdown 文档包」
- **公开类型源码注释规范对齐**：迁移后公开类型文件头不留成篇中文文档（内容已进 reference），保留点状就地注释（设计意图/非显然行为/陷阱）+ reference 路径指引，符合根 AGENTS「注释点状就地、文档成篇完整」分工
- **验证**：grep 全仓 `/*!`、`\qml*`、`\section`、`\list`、`\brief`、`\class` 等 QDoc 命令零残留（含 QoolUI/QoolUITests/docs/Scripts/Example）；build 全量成功；测试 18/18 全绿

### 修复（halfcrystal-style-channel-implicit-loop，Shape 作 contentItem 的收敛反馈环）

- **Page_HalfCrystal「样式通道」QoolControl 绑定循环 + 压扁**：`QQuickControlPrivate::resizeContent()` 无条件把 contentItem 重设为内容区尺寸（qquickcontrol.cpp:376-381）→ Shape(HalfCrystal) 路径绑定自身尺寸 → 引擎 `setImplicitSize(路径边界)` → BasicControl.implicitHeight（读 implicitContentHeight）反馈回控件高度 → 收敛环。ε=0（strokeWidth 0）不发散，但收敛到 `contentItem ≈ 2×padding`：styled 100×100 被压成 10px 高、控件高 12，并报 `Binding loop detected for property implicitHeight`（仅此段触发——全仓库唯一「尺寸绑定型 Shape 直接作 contentItem」处，`QoolWindowCloseButton` 路径绑固定尺寸无 C 条件，安全）
- **修复**：contentItem 改为定尺寸 Item（implicit 100×100），HalfCrystal 作其子项 `anchors.fill` 跟随内容区（保留原 contentItem 响应控件尺寸的语义）——控件读 Item 稳定 implicit 而非 Shape 动态 implicit，环在接缝断开
- **验证**：QML 编译通过；harness（tst_qoolcontrols_qml offscreen）实测修复后 `styled` 100×100、控件高 102、无循环；响应性等价（ctl 宽 320→400 时 styled 宽 304→384 跟随）；修复前对照 `styled.height=10`、控件高 12

## [4.0.0] — 2026-08-14

### 新增（rangeslider，Qool.Controls.RangeSlider 区间滑块）

- **RangeSlider 组件（用户指令 2026-08-16——基于 HalfCrystal、仿照 Slider；与 Slider 的区别：轨道非渐变，Style.accent 填充已选区域）**：`T.RangeSlider` 模板根（交互官方默认——点击跳转最近手柄、拖动连续、键盘步进，接口兼容 QtQuick.Templates.RangeSlider）。视觉（v3 Color 滑块视觉族区间扩展）：轨道 = Crystal 六边形基底（Style.text——Slider 渐变左端色，**无渐变**）；已选段 = 平切矩形（color 默认 Style.accent，两端贴手柄平边）；**手柄 = HalfCrystal 三角形**（first direction W 尖朝左 / second direction E 尖朝右——平边相对夹已选段，尖角朝外指向各自未选段；HalfCrystal 三角形态平边 = 组件中线 = 手柄中心线——已选段端面天然对齐）。手柄段色采样（Slider 渐变采样在纯色两段下的特化）：first = Style.text（基底段）、second = color（已选段）。展开反馈照 Slider 核心（hover/按下/justMoved 锁存 500ms → 展开到控件全高，常态 = preferredHeight = Qore.bound(3, 高×25%, 25)；三角形尖角常态缩进轨道内、展开顶到轨道端——反馈位移比菱形更明显）；animationEnabled 链式门控 + CurveRenderer 切换同 Slider。锁存 = TimerLatch + 双 Connections（first/second valueChanged）——**不暴露 valueVelocity**（Slider 的 NumberNotifier 挂单一 value，RangeSlider 双值无单一载体——justMoved 窗口由每次 valueChanged 滑动保持，用户可见行为等价）。已选段几何：x/右缘 = 两手柄中心线（width = secondCenter − firstCenter ≥ 0 恒成立——模板保证 first.position ≤ second.position，正/倒置范围数学恒等，无需防御）；值相等退化 = 宽 0 + 两三角平边重合成完整菱形（水晶语言自洽）。默认值 = 官方模板（first 0 / second 1——满幅区间）
- **测试（tst_rangeslider.qml，tst_qoolcontrols_qml 批次 9 用例）**：默认状态（implicit 80×25、second 默认 1）、手柄形态与段色（direction W/E、first text / second color）、已选段/轨道几何（中心线公式、多值点跟随）、justMoved 锁存窗口（first/second 双触发、500ms 滑动）、展开反馈（锁存窗口内全高、落后回常态）、倒置范围（已选段仍正向）、值相等退化（宽 0）。注：模板鼠标交互不在 QML 批次测——环境限制（探针实测官方 T.RangeSlider 与 Qool Slider 点击/拖动均无效果），交互回归靠示例页人工验收
- **示例页**：Page_InputControls2 加「RangeSlider 区间滑块」组（基础 + 实时值显示 + 程序化写入锁存演示——setValues 演示官方循环依赖契约用法）；页面 note 与 PageListModel 同步更新


### 变更（spinbox-halfcrystal-indicator，SpinBox 指示器换 HalfCrystal + BasicArrow 删除）

- **SpinBox up/down 指示器：BasicArrow → HalfCrystal**（用户指令）：属性映射 fillColor→color、borderWidth 0（不描边）不变、direction E/W 不变（HalfCrystal 四向三角形覆盖 SpinBox 的左右向）；显式 12×12（HalfCrystal 默认 20×20 超出半高按钮——与原指示器同尺寸，位置公式不变）；`import Qool.Controls.Components` 移除（EditableText 走 Qool.Controls 前缀——Components import 仅服务 BasicArrow）
- **BasicArrow 删除（用户指令）**：组件文件 + QoolControlsComponents CMake 注册清理；Qore.Directions 注释去 BasicArrow 引用（八向枚举本身保留——HalfCrystal/方向组件通用）；BasicRotationBehavior 零内部引用但保留（Qool 公开类型——公开即承诺）

### 变更（halfcrystal-shape-redesign，HalfCrystal 重做 + Crystal 描边属性公开）

- **HalfCrystal 重做（用户裁决 2026-08-16）**：根组件由「Item + 内部 Shape + 双 RectGadget 画布链 + HalfCrystalGadget 掩码 + pCtrl 四点」改为 **Shape 根**（显式 width/height 20 默认逻辑尺寸——implicit 声明被引擎覆盖的机制同 Crystal）——pCtrl 升级为 ShapeControl 实例（target 自动 = 根），内建三个内描边中间量（直角内缩 = √2·b、尖角内缩x = (1+√2)·b、尖角内缩y = b——环宽均匀推导；effInset 钳制防反卷）+ 八点模型（外四点 pN/pS/pW/pE = 内接矩形四边中点、内四点 iN/iS/iW/iE = 外点 + 形态相关内缩向量，ShapePath 直接消费）。渲染 = 双层内描边模型（外路径 borderColor 描边环 + 内路径 color 填充面，strokeWidth 0——ε=0）。**五种形态经 states（when: direction 条件）定义**——菱形（非 NSWE）为默认状态（默认绑定即菱形，零 State），N/S/W/E 四态各仅绑定 4 个差异值（一对隐藏点：对侧外点落中心 + 其内点；2 个尖角内点）——公式绑定进各 State，表达式不含 direction。Transition 动画（NumberAnimation，Style.movementDuration/animationEnabled 门控）——仅方向变化呈现动画（尺寸变化直接跳变，Behavior 时代无此精确性）
- **implicit 不承诺（Crystal 同哲学）**：Shape 引擎在路径变化时强制 setImplicitSize(路径边界)——三角形态下 implicit 报告半组件（如 N 态 20×10）；显式默认 width/height 20 不被引擎触碰，布局一律用显式尺寸。初版曾加「伴生透明全矩形路径钉 implicit」防御（透明路径计入 boundingRect 的实证），经讨论撤销——显式 w/h 已兜底，额外路径开销无必要
- **HalfCrystalGadget 删除（公开类型移除，用户裁决——4.0.0 未发布）**：源文件 + Qool 模块 CMakeLists 注册 + tst_halfcrystalgadget + QoolUITests core CMakeLists/README 条目全量清理
- **命中掩码 = gB（用户裁决——禁止的是 FillContains 判定，非掩码本身）**：根 containmentMask = gB（RectGadget——数值矩形 contains，非路径填充面判定，无 FillContains 性能代价）；命中 = 内接画布矩形（三角外左右条带排除；精确三角判定不提供——RectGadget 仅矩形 contains）；宿主 MouseArea 精确 hover 需显式挂载（Qt hover 分发不检查祖先掩码——AGENTS.md 陷阱 5）；tst_hover_e2e 改写为掩码契约（非方形 120×80 验证条带排除）；AGENTS.md 陷阱 5 HalfCrystal 补入带掩码组件示例；Page_HalfCrystal hover 演示改掩码对照（vs Crystal 八边形精确掩码）
- **Crystal/HalfCrystal 公开属性调整（用户裁决）**：`strokeColor` → `borderColor`（语义不变：内描边环色，ThemeHQ.recommendForeground 自动对比）；新增 `borderWidth`（默认 1——原固定值公开化，Crystal settings 跟随绑定；HalfCrystal 内描边宽度）
- **borderWidth < 1 不描边（用户裁决——阈值语义）**：effInset 在 borderWidth < 1 时取 0（内四点 = 外四点——fillPath 覆盖 borderPath，纯色填充；负数同样落 0，顺带消除反向描边反卷）
- **RectGadget x/y 取消默认绑定 target 位置（修复）**：x/y 固定 0（QBINDABLE_SET_VALUE）——派生矩形（九点/半区/maxInnerSquareRect 等）不再含父容器位移，一律本地画布坐标；gB 由四元平移绑定简化为一步 `rect: gA.maxInnerSquareRect`（QDoc 同步）
- **测试**：tst_halfcrystal.qml 重写（默认状态/显式尺寸契约/五形态几何/内描边/borderWidth 跟随与 <1 阈值/非方形画布语义/掩码存在性——渲染路径经 objectName 读取）；tst_crystal.qml 断言更新（borderColor/borderWidth 跟随契约）；tst_hover_e2e 改写（掩码契约——内接画布矩形 hover 域）
- **RectGadget 派生几何单一数据源契约（用户规范 2026-08-16）**：派生量（九点/四半区矩形/maxInnerSquareRect/minOutterSquareRect/shortEdge/longEdge/isSquare/halfWidth/halfHeight）统一基于 rect（m_rect 为唯一数据源）计算——修复「rect 被外部绑定（如 QML 绑定 gB.rect = gA.maxInnerSquareRect，替换合成绑定）时，contains 判定域（基于 rect）与其余派生几何（基于 x/y/w/h 残留值）脱钩」；x/y/w/h 保持联动分量语义（写入口，设置即覆盖绑定——含初始化 target 绑定）。无外部绑定时行为逐位等价（rect 即四分量拼装），坐标基准语义不变；九点分量绑定直接读 rect（m_left/m_top/m_right/m_bottom/m_hcenter/m_vcenter 中间量层删除——依赖一跳）
- **测试（RectGadget 契约锁定）**：tst_rectgadget 新增 5 用例——target 尺寸跟随（绑定 width/height 而非 boundingRect——位置/变换不影响）、target 绑定覆盖（设置分量只覆盖自身绑定，其余保留）、set_rect 覆盖全部初始化绑定、分量粒度联动（设置 x 只改 x）、rect 外部绑定单一数据源（核心契约——重构前实测失败暴露脱钩，重构后通过）
- **HalfCrystal 内部恢复 RectGadget gB + 测试修复**：dummy SmartObject 残留删除（用户换回 `RectGadget { rect: gA.maxInnerSquareRect }` 后死代码）；内描边无边框分支笔误修复（b < 1 时内四点曾误取位移向量 vN/vS/vW——fillPath 塌缩到原点附近；改取外点 pN/pS/pW——与 iE 一致，内=外纯色填充）；tst_halfcrystal 全部 expected 路径数组补闭合点（路径 = start + 4 PathLine 共 5 点，断言此前 4 点恒失败）+ 调试探针清理；头注释/QDoc 同步当前算法（内缩量 = √2·b / (1+√2)·b / b 线性推导，无收缩极限钳制——用户裁决弃 effInset；Transition 动画未启用）；tst_qool_qml 94/94、tst_qool_hover_e2e 3/3（掩码契约随 RectGadget gB 恢复）、全量 18/18 绿
- **Transition 动画移除（用户裁决 2026-08-16）**：HalfCrystal 不提供方向切换动画——point 属性（pN 等）经 PropertyAnimation 插值不可靠（point 为多分量值属性），试验不正常后裁定直接去除；transitions 块删除、QDoc 动画段改写（states 直接切换——中间态恒为菱形）、测试头注释同步

### 变更（build-dir-parent，构建目录归置 build/ 之下）

- **构建目录归置 `build/` 之下**：编译产物目录由仓库根的 `build-<kit>-<Type>/` 移入 `build/build-<kit>-<Type>/`（如 `dev-msvc-debug` → `build/build-msvc-Debug`）。机制两处硬改动：`CMakePresets.json` 六处 preset 的 `binaryDir`（`${sourceDir}/build/build-<kit>-<Type>`）；`Scripts/qoolui_build_common.py` 的 `build_dir()`（`REPO / "build" / f"build-{kit}-{Type}"`）——脚本全部命令经此函数定位构建目录，自动跟随。文档同步：根 `AGENTS.md`（构建命令注释 / kit×type 矩阵 / 插件路径示意 / 缓存清理命令）、`QoolUITests/AGENTS.md` 与 `README.md`（运行通道 / 输出树 / import path / 调试路径）全部 `build-<kit>-<Type>` → `build/build-<kit>-<Type>`；CMake 与测试源码注释中残留的旧 `build/` 泛称（历史遗留，实际已为 `build-<kit>-<Type>`）一并修正为准确路径。`.gitignore` 的 `/build*/` 已覆盖 `build/` 无需改动；旧根级构建目录为 gitignored 遗留（未删除）。

### 变更（crystal-octagonshape-refactor，Crystal 重构为 OctagonShape 特化）

- **Crystal 重构（spec `.scratch/crystal-octagonshape-refactor`）**：根组件由「Item + 内部 Shape + ShapeControl + CrystalGadget 单层外轮廓模型」改为 **OctagonShape 特化**——内部注入 QoolBoxShapeControl（target = 自身）+ QoolBoxSettings 特化（四角 cut 恒绑定 shortEdge/2、borderWidth=1 内缩描边环、borderColor=strokeColor、fillColor=color）；三形态（宽六边形/菱形/瘦六边形）即 QoolBoxGadget cut = shortEdge/2 特化（半平面交集模型下退化形态合法——旧"切角极限反向三角形"警告基于已删除的 pCtrl 内弧算法，已证伪并清除全部残留表述：Crystal.qml/Slider.qml/VerticalSlider.qml 注释、HalfCrystalGadget QDoc 引用改写）。公开面：color/strokeColor/fillGradient/fillItem/掩码契约保留；**cutSize 不作公开接口**（内部 QtObject pCtrl 中间量单点定义，settings 四角绑定共享——切角是几何契约非可配置状态）；默认逻辑尺寸 = width/height 显式 20（implicit 声明被引擎覆盖的机制替代）；Shape 根使 preferredRendererType 等渲染器面开放（Slider 手柄 CurveRenderer 用法恢复生效）。Crystal 不暴露 settings（文档契约）；control 可替换（高级用法，QoolBox 同哲学）
- **fillGradient 补面（遗漏修复）**：OctagonShape/OctagonCurvedShape 补 `fillGradient` alias（转发 fillShape——Shape 无此属性，是 ShapePath 面）；QoolBox 补 `fillGradient` 公开属性（类型 ShapeGradient——ShapePath.fillGradient 官方要求新渐变 API，旧 Gradient 类型不可用，属性类型与转发目标一致）并将退行排除条件扩展为 `!fillItem && !fillGradient`（Rectangle 渐变与 Shape 渐变不兼容，退行形态保持"无填充通道"语义边界）。附带修复：Slider 轨道渐变（LinearGradient）在旧 Crystal `property Gradient` 转发链上类型不匹配而失效的隐藏缺陷——重构后直连 ShapeGradient 类型生效
- **CrystalGadget 删除（公开类型移除，用户裁决——4.0.0 未发布）**：源文件 + Qool 模块 CMakeLists 注册 + tst_crystalgadget + QoolUITests core CMakeLists/README 条目全量清理；掩码契约由 QoolBoxShapeControl::contains 承接（同族算法，数学等价）
- **测试**：tst_qoolboxgadget 补 `shrink_diamond_limit` 用例（菱形切角极限 + borderWidth>0 内缩——oracle 真值断言，本次重构的几何信任基石）；tst_crystal.qml 重写（掩码对象换 QoolBoxShapeControl、四角 cut 恒等契约替代 cutSize 派生断言、默认逻辑尺寸、fillGradient/fillItem 通道）；tst_qoolbox.qml 补 fillGradient 退行排除用例

### 变更（qoolbox-shapecontrol-redesign 执行，spec D1-D8）

- **QoolBoxShapeControl 重写（gadget 化，ADR-0004/0006/0007）**：公开类型保留，内部替换为两个 QoolBoxGadget（outer borderWidth 0 + inner borderWidth=settings.borderWidth、referenceBox 指 outer）；转发 ext*/int* 16 点 + x/y 分量（坐标系刻意变化：由旧"期望尺寸本地系"变为"target 内部坐标系绝对点"——center 锚定，消费方均挂接 target 内本地系一致）、usedWidth/usedHeight、*Space（新公式 max(0, max(相邻 cut) − (used − 期望)/2)，ADR-0002）、contains。settings 属性类型改 QoolBoxSettings*（单一类型，ADR-0005 修订）；**settings 同步用信号连接**（QProperty 绑定会注册对 settings 字段 QProperty 的依赖——settings 先析构时绑定重算读已析构对象崩溃；信号连接析构自动断开）；显式析构断链（转发绑定 takeBinding + inner 先于 outer 删除——QProperty 析构通知语义，依赖方须早于被依赖方析构）。删除旧面：safe*/safeBorderWidth/borderShrinkSize、intOffsetX/Y、intPolygon/extPolygon、dumpInfo 覆写（继承基类）
- **settings 收敛为单一类型（QoolBoxSettings，ADR-0005 修订）**：初始双类型（QoolBoxSettingsBase 属性定义处 + QoolBoxSettings 继承）经两轮实证收敛——**构建期实证**：QML 文件以 QML_UNCREATABLE 类型为根继承被 Qt 6.11 引擎拒绝（qmlcachegen 编译期通过、运行时报 "Type unavailable ... is a probe base type"），"QML 类型继承 Base 绑 Style 默认"主路径不可行；Base 唯一派生场景死亡后抽象层失去存在意义，**删除 Base、收敛为单一 C++ 类**（QML_ELEMENT 可实例化），`QoolBoxShapeControl::settings` 属性类型直接为 QoolBoxSettings*（类型完全匹配，无 Base 类型解析问题，QoolBoxSettingsBase 不再出现在 QML 类型系统）。类型默认值 = C++ 常量（保持旧语义 red/yellow），Style 默认由 QoolBox 实例化处显式绑定；旧便捷面删除（cutSizes/intOffsetX/Y/isAllCutSizesEquals/set_cutSizes/dumpInfo）
- **QoolBox 公开面**：settings（QoolBoxSettings）、control（QoolBoxShapeControl，可替换/共享）、*Space 四属性（转发 control）、fillItem、animatingHint；撤销 cutSize/curved 别名（经 settings 访问）；pCtrl 纯内部；退行 rectShape 内联（原生圆角矩形，四角独立 radius；fillItem 非空排除退行）；变体组件内直接绑定 control/fillItem（required control 在创建时满足——Loader 后置 Binding 注入与 required 检查死锁）
- **变体改造（低级组成件）**：OctagonShape/OctagonCurvedShape（原 OctagonRoundedShape 改名对齐 settings.curved，配套 OctagonCurvedExternal/InternalShapePath）`required property control` 注入、不持有几何；直角变体 containmentMask: control（QObject 掩码，ShapeContainmentMask 删除）；圆角变体 FillContains + 外弧 = settings.cut*、内弧 = 内环相邻点弦长/√2（退化 0）
- **QoolBoxGadget 内部质量小改（ADR-0006 执行）**：中间量全称命名（dStar→maxShrinkDistance、shrinkD→shrinkDistance、linesC→insetLineConstants、intersectVerts→intersectionVertices）、vec*/shrink* 定型 QVector2D（自由位移向量；float 精度 ~1e-5，测试容差 1e-4）、降权裸 QProperty + 普通 getter（无 Q_PROPERTY/无 signal）；geometry QDoc 公式段同步
- **消费方迁移**：ProgressBar（OctagonCurvedShape 两处 + 自建 control 注入，settings 收纳 fillColor/四角 cut）；BasicLabel/Button/ComboBox/QoolColor（ColorNameList/CycleChoice）/QoolUIExample（QoolTipPanel）cutSizes 便捷面全部改四角显式（QoolTipPanel 字符串按旧解析序 TL/TR/BR/BL 展开）；QoolBGBox/QoolWindow/cover 三件套核对零改（新类型面齐全）
- **QoolBoxHud（Qool.Debug，原 OctagonShapeHud 重定位，ADR-0008）**：`property QoolBox box: parent`（须直接作 QoolBox 子项），读 box.control 的 ext*/int* 16 点（公开面，objectName/findChild 白盒方案撤销）；Example Page_QoolBox 同步（HUD 直接子项、curved 经 settings——Example 不在兼容范围，改动处注释标记）
- **删除项**：ShapeContainmentMask（掩码由 control 直接承载）、_private/OctagonRectangleShape.qml（内联）、旧 QoolBoxSettings 便捷面、QoolBox cutSize/curved 别名
- **AGENTS.md 规范补充**：内部中间量裸 QProperty + 普通 getter 约定（ADR-0006 固化）；命名全称少缩写
- **QoolBGBox 标签可见性修复（测试暴露的既有缺陷）**：`label` 属性对象未显式挂 parent——QML 属性对象不自动成为声明对象的子项，无 parent 时 effective 可见性恒 false，"有标签形态"（topSpace=标签高+边框宽、left/rightSpace 收紧）从未生效——显式 `parent: root` 修复；QDoc bottomSpace 描述与实现相反同步修正
- **测试补全（spec 硬性要求）**：新增 core 单测 `tst_qool_qoolboxshapecontrol`（settings 信号同步/替换重挂/16 点对照 gadget/*Space 公式/contains/referenceBox 链/null 退化/析构安全 8 用例）；QML 批次扩展 `tst_qoolboxsettings.qml`（属性契约/绑定/动画/实例替换/共享引用/默认 wiring 11 用例）与 `tst_qoolbox.qml`（公开面/退行边界/变体渲染/圆角半径 13 用例）；C++ 端到端命中 `tst_qool_box_hit`（直角掩码/offset 跟随/圆角 FillContains 真实鼠标）；新增 Qool.Controls 批次 `tst_qoolcontrols_qml`（QoolBGBox/BasicLabel space 语义 11 用例）；全量 20/20 绿

### 变更（qoolui-example-qoolbox-adapt，QoolUIExample QoolBox 适配）

- **QoolUIExample 正式适配 QoolBox 形状体系**（上游重构 `.scratch/qoolbox-shapecontrol-redesign` 完成后补做；spec `.scratch/qoolui-example-qoolbox-adapt`）：
  - **修复静默回归**：QoolTipPanel 顶层 `curved: true` 指向已撤销的 QoolBox 别名——QML 顶层未知属性赋值创建动态属性（无警告、构建期亦不检测），`curved` 值落到动态属性上、渲染不读它，提示浮层圆角意图丢失（直角）——移入 `settings` 块（`settings.curved`），恢复圆角设计
  - **注释清理**：删除 3 处"不在兼容范围/同步修改/迁移解析顺序"修改历史注释（元语境渗漏）；Page_QoolBox 顶部 `OctagonShapeHud` 类型名更新为 `QoolBoxHud`，顶部"（修复说明）"字样清理
  - **TODO 记录**：Page_QoolBox 补 fillItem 演示 TODO（fillItem 为公开属性但 Example 从未演示）；QoolTip.qml/QoolTipPanel.qml 补 QoolTip 机制全面重设计 TODO（当前仅保证无明显非法、可使用，遮蔽 Bug 见既有 TODO）；QoolBoxShapeControlPanel lockCorners 按钮补实现 TODO（死按钮保留；勿用 CutSizeBinding——其语义为双对象间四角同步，非单对象联动）
  - **AGENTS.md 规范**：编码规范新增「注释与文档」条目——注释/文档不体现修改历史（修改历史归 CHANGELOG）；执行范围 = 本次涉及文件，不排查全仓库
  - 验证：构建通过 + 运行冒泡无 QML 属性警告；外观用户人工验收；未提交（用户验收后定）

### 修复（ShapeControl target 尺寸同步去绑定化——QoolBox 系绑定环）

- **ShapeControl target 尺寸经信号连接同步（基类去绑定化）**：`width/height` 原为 QProperty 绑定 `target.width/height`——ADR-0002 `*Space` 公式含期望尺寸依赖后，隐式尺寸拓扑（控件无显式尺寸）下经宿主控件 padding → *Space → 本对象几何绑定链绕回 target 自身，绑定求值重入成环（QML "Binding loop detected"；QoolBGBox/BasicControl 隐式尺寸实例 + Example 启动日志实证）。改为：target 尺寸经信号连接写入缓存 QProperty（`targetChanged` 时重连 `widthChanged/heightChanged`；**延迟到事件循环写入**——连接器可能在布局/绑定求值栈内执行，同步写缓存触发同栈重算重入；`QTimer::singleShot(0, this)` context 析构自动取消，析构安全）；`width/height` 绑定改读缓存，`x/y` 保持绑定（无环证据）。代价：target 尺寸变化后 control 几何在事件循环内更新（QML 绑定消费方无感知差异）；C++ 测试 fixture 的 `setSize` 补 `QCoreApplication::processEvents()` flush 适配（同步断言语义）。
- 验证：QML 批次隐式尺寸拓扑（BasicControl/BasicButton 无/有标签）零 Binding loop 警告；Example 启动日志干净；全量 20/20 绿。

### 文档

- **QoolBoxGadget 算法独立 qdoc 文章**（`qool_qoolbox_geometry.qdoc`，\page qoolbox-geometry.html）：点定位与内缩算法的详细论述——几何模型（三层单向依赖：派生 used 标量 → 向量层 vec/shrink → 锚定层）、used 派生（max 构造性保证/角间零交互）、向量符号表规律（cut 注入轴 = 斜边法线轴）、锚定（期望中心对称溢出，used 无矩形实体）、**shrink 原理与推导**（边平移定义 → 8 条平移半平面交集几何真值 → 命名点身份候选/归入极值收敛 → d\* 临界距离与 d_eff 钳制）、**d\* 解析式对偶线性规划推导**（8 法线 4 对相反 → 平行对 4 + 三线组合 8 = 12 候选，无冗余无遗漏）、**解析公式蕴含的边界条件**（非负性构造保证/边消失与溢出/退化链与临界区形态——三线瓶颈 = 点、平行对瓶颈 = 线段/直角角归入 = 角平分线精确 d√2/负 border 外扩/浮点注意）
- **QoolBoxGadget 类型文档精简为用法导向**（语义契约/输入接线/命名规范/referenceBox 用法/命中判定契约，算法细节链接文章）；contains \qmlmethod 注释同步精简；代码注释清理不可解析的 .scratch 设计文档引用（关键理由内联自足——半平面判定勿写 +C、命名点身份候选勿与 135° 位移表混淆、归入勿无条件钳制等保留为专项注释）

### 新增

- **QoolBoxGadget（QML 类型，`Qool` 模块，八边形控制点计算器——原 QoolBoxShapeControl 重构设计落地）**：gadget 模式（挂载于标准 ShapeControl 之下，对齐 CrystalGadget）。**语义**（spec `qoolbox-shapecontrol-redesign` 定案）：cutSizes 为硬参数（形状由 cut 决定，不因尺寸不足而压缩）、width/height 为期望尺寸（极限情况图形从期望中心对称溢出而非压缩 cut）；负 cut 归零直角点；全部退化状态（矩形/菱形/三角形/凸多边形/点重合/线段）为定义良好的合法极限形态。**单一 8 点输出**（`pointTL..pointLT` + 每点 x/y 分量——首字母 = 所在边、次字母 = 端点位置，TL ≠ LT），由 `borderWidth` 参数化形态（0 = 外轮廓 / >0 = 边平移内缩 / <0 = 外扩）；双实例描边 = 宿主实例化两个 gadget（外环 0 / 内环 d），"内点"概念与 ext/int 双套弃用。**shrink 层 = 几何真值**：8 条平移半平面交集（24 对非平行线交点满足全部 8 半平面），命名点 = 身份候选（相邻平移线对交点）有效取之 / 失效归入最近交集顶点（极值收敛），d_eff = min(border, d\*) 钳制交集永不空（d\* = 12 候选 O(1) 解析式，对偶 LP 推导，vs 二分基准 3000 组 max_err 9.6e-10）；直角角自动归入角平分线精确内缩 d√2（宽度精确化，无需特判）。**架构**：三层单向（输入 → 派生 used 标量 → 向量层 vec/shrinkA → 锚定层 pointA = origin + offset + vecA + shrinkA），11 级 bindable 链逐级缓存（O(1) 常数总成本），全程不读宿主几何。**referenceBox**（几何参考源，手写 setter 例外）：5 介入点（origin/offset/vec/used/cuts）ref 优先 null 回退，仅 borderWidth + shrink 层自行处理；赋值校验单层保证（目标已有 reference → 警告 + 置 null，链式与环同阻）。**contains**：O(1) 线性不等式（used 矩形粗判 + 四角切角三角形排除，开集语义，border 不影响判定；旧 BL 行误用 safeTL 疑点随公式模板推导自动消解）。**旧 `QoolBoxShapeControl`/safe 链原样保留**（消费端接线与旧版处理不在本次范围，另行 spec）。测试：core `tst_qool_qoolboxgadget`（18 用例——used/vec/point 锚定/边消失不漂移/退化形态；**oracle 正确点坐标算法**：测试内置独立几何真值实现（平移边 → 24 对求交 → 过滤），d\* 用二分独立求解不复制实现公式，逐点坐标断言；临界区档位 d=0.99/0.999/1.0/1.5·d\*（d\* 处交集退化——点/线段瓶颈两种收敛态，退化场景集合归属断言）+ 负 border 外扩 + 退化链线段态（长度 71.7 = 2×(50−10√2)）+ contains 矩阵（含 cut 溢出象限门反例）+ referenceBox 跟随/单层保证 + bindable 传播）；`dstar_parity` 随机 200 组 vs 二分 < 1e-6）

## [4.0.0] — 2026-08-13

### 变更

- **QML 单例契约修复（系统性违规改造，spec singleton-design 8 tickets）**：进程级 C++ 单例经 `QML_SINGLETON` 暴露在**多 QQmlEngine** 场景崩溃（实测 0xc0000005，栈顶 `QV4::Value::fromHeapObject`——Qt 契约：共享实例暴露为 singleton 只能被一个 engine 访问）。4 个违规类（ThemeDatabase/ColorNameDatabase/FileIconDB/FileInfoDB）按**单例组件设计模式**（DB/HQ/HQModel 三件套）拆分：DB（改名 XxxDB，C++ 全局单例）保留全部方法/状态/逻辑并摘除 QML 注册与 Q_INVOKABLE 标记；HQ（新类 XxxHQ，QML 单例，`create()` 每 engine 独立实例，parent = engine）转发原暴露接口（实例方法/static/属性/信号），实现调 DB::instance()；接口双侧保留、逻辑单份在 DB、数据 App 级共享恢复（跨 engine 一致）。具体：
  - **Theme 域**：ThemeDatabase → **ThemeDB**（文件名 `qool_theme_database.*` → `qool_theme_db.*`），模型特性保留（QAbstractListModel，被 ThemeHQModel 消费）；**ThemeHQ** 新建（转发 theme/anyValue/themes/count/installTheme/themeInstalled 重发/recommendForeground/visualBrightness static）；**ThemeHQModel** 新建（普通类型 `QML_ELEMENT` 非单例，`QIdentityProxyModel` 构造时 C++ 侧挂接 ThemeDB::instance()——全套模型变更原生转发，DB 不进 QV4 值系统）。仓库内 14 文件 ThemeDB 引用迁移 ThemeHQ（11 处调用 + 注释/qdoc/示例）；Style（C++ 消费者）跟随类名改用 ThemeDB::instance() 零行为变化
  - **ColorName 域**：ColorNameDatabase → **ColorNameDB**（文件名同步 `qool_colorname_db.*`，provider 表/nameCache/5 查询方法保留）；**ColorNameHQ** 新建（转发 names/color/categories/hasColor/name）；4 组件 ColorDB 引用迁移
  - **FileIcon 域**：FileIconDB 摘 QML 暴露（provider 表 + requestPath/requrestUrl 保留，FileIconImageProvider 路由零改动）；**FileIconHQ** 新建（iconUrl = FileIconImageProvider::compileUrl 静态，不经 DB——转发边界例外）
  - **FileInfo 域**：FileInfoDB 摘 QML 暴露（QCache + getFileInfo ×2 保留，FileInfo 值类型缓存查询零改动）；**FileInfoHQ** 新建（转发 getFileInfo ×2，命中共享缓存）；example Page_QoolFile 引用迁移
  - `QOOL_SIMPLE_SINGLETON_QML_CREATE` 宏从 `singleton.hpp` 删除（违规模式载体，防回归；DECL/IMPL 保留）；AGENTS.md「单例」节改写为模式固化（三选一形态 + 三件套规范 + 硬约束，删除 QML_CREATE+QML_SINGLETON 组合推荐）；QML 模块注册节 C++ 单例指引同步修订
  - QDoc：4 个 HQ/HQModel 新类型文档（生命周期"进程级 QML 单例"→ 每 engine 实例 + App 级共享数据）；ColorDB QDoc 迁移 ColorNameHQ；qool.qdoc style-system page 补 ThemeHQ 分层与持久化说明；QoolFile 模块 AGENTS.md 更新
  - **验证**：新增 4 个测试单元全绿（`tst_qool_singleton_contract` 跨 engine 契约——4 HQ 参数化：engine1 加载→析构→engine2 重建不崩+值一致；`tst_qool_singleton_write` QML 写面+信号转发；`tst_qool_singleton_model` ThemeHQModel 模型契约+rowsInserted 转发+双实例一致；`tst_qool_singleton_db` 4 个 DB 接口保留+HQ 转发等价）；ctest 14/14 全绿（9 既有 + 4 新 + QML 批次多 engine 生态回归）；grep 验收 `ThemeDB.`/`ColorDB.`/`FileInfoDB.` QML 面点调用零残留

### 新增

- **OffsetProjector（QML 类型，`Qool` 模块）**：位移映射节点——输入位移方向 `direction`/距离度量方向 `refDirection`/沿度量方向的移动距离 `refDistance`，输出实际位移向量 `offset`（`v = direction_unit × refDistance / (direction_unit · refDirection_unit)`，满足 `offset ∥ direction_unit` 且 `offset·refDirection_unit == refDistance`）。凸多边形内描边场景的通用位移折算（Crystal 内描边方向对数据属各 gadget，消费端另行实现）；输入 QOBJECT 族宏 + 输出 QBINDABLE 绑定链（CirclePoint 先例），单绑定 lambda 内归一化/点积/退化短路。退化契约：零向量输入、refDistance==0、两方向正交 → offset 零向量（qFuzzyIsNull 容差）；输出值相等守卫——结果不变不传播通知。符号规则不校验（点积必须 > 0，配错症状 = offset 反向，QDoc 调试指引）。QoolCommon 零改动（全部计算用 Qt 原生 QVector2D）；测试落库：core `tst_qool_offsetprojector`（投影/退化/短路/符号 14 断言）+ QML 批次 `tst_offsetprojector.qml`（实例化/绑定响应/退化/短路 4 用例）

- **单例组件设计模式固化**（AGENTS.md「单例」节 + ADR-0001 + 根 CONTEXT.md）：形态三选一（纯 QML 文件单例 / C++-only 单例 / 三件套 DB+HQ+HQModel）；硬约束——禁止进程级 C++ 单例经 QML_SINGLETON 暴露、接口双侧保留、模型非单例化、插件/数据 App 级集束。设计产物归档：`docs/adr/architecture/0001-qml-singleton-contract.md`（定案版含实施验证结论）、根 `CONTEXT.md`（术语表：全局单例/QML 单例/违规模式/HQ/消费者-提供者关系等）
- 主题总览列表模型 **ThemeHQModel**（QML 类型，`Qool` 模块）：roles 与源模型一致（name/theme/metadata/constants/active/inactive/disabled/custom）；installTheme 后 rowsInserted 实时转发；多视图各自实例化数据一致；`metadata` role 当前源模型 data() 无 case（取空）——视图需要元数据时经 theme role 的 Theme.metadata() 读取（QDoc 已记录）

### 修复

- **HalfCrystal 掩码 hover 误判（测试页掩码演示实证）**：鼠标在组件内三角外区域（如下半）时 `containsMouse` 仍为 true——**Qt 6.11 的 QHoverEvent 分发（QQuickDeliveryAgent::deliverHoverEventRecursive）只检查 item 自身的 contains，不检查祖先 Item 的 containmentMask**：组件 root 上的掩码只约束 QPointerEvent（点击/按下）路径，宿主 MouseArea 的 hover 走自身 contains（无掩码 = 矩形判定）。修复 = 宿主 MouseArea 显式挂载组件掩码（坐标基准一致：anchors.fill 时 MouseArea 本地即组件本地）：`MouseArea { containmentMask: 组件id.containmentMask }`——测试页掩码演示（HalfCrystal + Crystal 对照）按此用法更新；HalfCrystal/Crystal QDoc「命中掩码」节补 hover 挂载契约说明。回归：新增 C++ 端到端 hover 测试 `tst_qool_hover_e2e`（真实窗口 + QTest::mouseMove——QML 测试批次 TestCase.mouseMove 在 offscreen 平台不注入事件）；`qoolui_add_cpp_test` 宏支持 `QOOLUI_TEST_ARGS_<target>` 变量（ctest 与 run-tests 双通道注入测试参数——与 qml/ 批次同名同义），hover_e2e 声明 `-platform offscreen` 无头运行（聚合运行时不再闪现真实窗口；目视渲染直接跑 exe 无参）；QML 测试 `tst_halfcrystal.qml` 增 `test_maskEngineEntry`（QQuickItem::contains 引擎接线含掩码）。**期望 WARN 处理**：测试环境无主题插件（qoolplugins/ 随 example 部署）→ ThemeDB 初始化必出 "No ThemeLoader installed" WARN（回退 system 主题，断言不受影响）——经 QML `ignoreWarning`（tst_crystal.qml 首个触发点）与 C++ `QTest::ignoreMessage`（hover_e2e）吞除并验证出现性（未出现即提示，防环境变化静默）。诊断过程：直接调用 contains 与引擎路径对照 + 探针掩码打印引擎坐标，确认掩码判定本身正确（META invoke (60,90)=false）、误判源自 hover 分发路径不查祖先掩码
- **多 QQmlEngine 场景 SEGFAULT（0xc0000005）**：进程级 C++ 单例（ThemeDatabase 等 4 类）经 `QML_SINGLETON` 暴露被多个 engine 的 QV4 上下文共享使用——QML 测试框架（每文件独立 engine）与多窗口/多视图宿主必现。按契约重构为 DB（C++ 全局单例，不暴露 QML）+ HQ（QML 单例每 engine 实例）+ HQModel（非单例代理模型）后不再崩溃，单 engine 行为不变（见「变更」节详述）

### 文档

- AGENTS.md：「单例」节模式固化（三件套规范与硬约束——违规模式警示）；QML 模块注册节同步修订；QoolFile 模块 AGENTS.md 的 FileInfoDB/FileIconDB 描述更新（进程级 C++ 单例 + QML 面走 HQ）
- QDoc：ThemeHQ（主题 QML 面：查询/安装/前景对比色 + 生命周期）、ThemeHQModel（roles 表/实时性/metadata 缺口说明）、ColorNameHQ（查询语义迁移自 ColorDB 文档 + 生命周期改写）、FileIconHQ（iconUrl 与协议说明）、FileInfoHQ（缓存与失效/单线程契约）

### 新增

- **构建工具脚本（`Scripts/qoolui_build_*.py`，Windows 可用 / Unix 骨架）**：统一构建/测试/部署入口——`common.py`（共享逻辑：kit×type preset 映射、命令实现 configure/build/test/run/install/deploy/release、输出双写落盘）+ `windows.py`（MSVC 经 vswhere→vcvars64 环境解析注入——避免 cmd /c 嵌套引号转义坑；MinGW/Clang 经 PATH 前置 Qt 工具链）+ `macos.py`/`linux.py`（骨架）。**平台概念约定**：命名以编译方式（kit=msvc/clang/gcc）区分（对齐 Qt 安装器布局 msvc2022_64/mingw_64），不以操作系统命名；脚本结构按操作系统拆分（分支逻辑聚簇处）。约定内置（preset 映射/目录命名/offscreen/deploy=install+zip 归档），个性化参数输入（--qt/--jobs/--prefix/--version/透传）。**kit×type 构建矩阵**：`CMakePresets.json` 展开为 6 preset（`dev-<kit>-<type>`，默认 type=debug——开发期默认，xDebug 输出可见），构建目录 `build-<kit>-<Type>`（替换原单一 `build/`）；`scripts/win_build_test.ps1` 被替代删除。AGENTS.md 构建命令节、已知陷阱目录示意、QoolUITests 运行通道表同步更新
  - **msvc + mingw 双路径实测修复（2026-08-12）**：① `_qt_tool_bin` Tools 定位层级——Qt 官方安装器工具链在 `C:\Qt\Tools\mingw*/`（安装根下，非版本目录），需 parent.parent；② qt_dir 归一化传递——main 统一 `qt_kit_dir` 后传入 kw，修复 mingw 首跑 configure 时未归一化 Qt 根覆盖 QT_DIR（CMAKE_PREFIX_PATH 指向无 Qt6Config 的目录）；③ dispatch 的 install/run/deploy/release 漏传注入 env——run 无 Qt 运行时（DLL 缺失秒退 255）、install 无 windeployqt；④ 透传参数解析——argparse `nargs="*"` 不吞 `--` 后参数、REMAINDER 全吞选项、`parse_known_args` 把 `--` 也进 unknown 传给了 Qt 程序，最终剥离 `--`；⑤ `run_app` 注入 Qt 运行时环境（PATH 前置 Qt bin + QT_PLUGIN_PATH + QML_IMPORT_PATH——开发模式 exe 依赖 Qt 前缀注入，QtCreator 行为由脚本补足）；⑥ `run_cmd` stdout EOF 后补 `proc.wait()`——EOF 不等于进程退出，returncode=None 时 `sys.exit(None)` 静默变退出码 0（deploy 的 zip 归档从未执行）。验证：msvc/mingw 双路径 configure/build/test（7/7）/run（进程存活）/install/deploy/release（zip 72.7MB）全命令实测
- **抽查测试单元（测试设施扩容，全绿 204 断言）**：`common/tst_property_macros.cpp`（属性宏体系契约——QOBJECT/QBINDABLE/QGADGET 三宏族 + QOOL_FOREACH_N 批量：默认值/相等守卫/NOTIFY 语义/bindable setBinding/setter 参数类型 static_assert/DECLARE 分离版；10 断言）、`core/tst_qool_polar2d.cpp`（Polar2D 极坐标值类型：构造/转换/运算/相等/属性注册；17 断言）、`core/tst_qool_multirowselectionmodel.cpp`（多行选择状态机：单选清空/已选取消/forceSelect/多选切换/范围选择回退/全选/信号契约/越界与空模型；15 断言）、QML 批次新增 `tst_positionlocker.qml`（锚点/间距符号/偏移/开关/动态跟随）、`tst_cutsizebinding.qml`（四角同步/模式/门控/缺属性/重定向）、`tst_dummyitem.qml`（boundingRect/contains 几何）；QML 侧 36 断言
- **测试设施（Qt Test + Qt Quick Test 双栈，QoolUI/tests/）**：分层与被测面一一对应——`common/`（QoolCommon 纯 C++ 模板库，QCoreApplication）、`core/`（Qool 核心 C++ 类型，直接编译被测 .cpp——Qool 为 DLL 且遵循「绝不动态导出」，测试无法链接其符号）、`qml/`（Qt Quick Test harness，QUICK_TEST_MAIN_WITH_SETUP 注入 Qool 模块 import path）。三条运行通道同一批标准 exe：`cmake --build build --target run-tests`（聚合 target，日常首选）/ `ctest --preset dev`（CI/筛选）/ 直接运行。首套用例 134 断言全绿（math 92 数据驱动 + Vector2D 17 + NumberRanger 17 + TimerLatch QML 8）。使用手册与 Windows/MSVC 平台经验见 `QoolUI/tests/README.md`
- `CMakePresets.json`（dev preset：Ninja + Release + BUILD_TESTING，CMAKE_PREFIX_PATH 取 `$env{QT_DIR}`）；`scripts/win_build_test.ps1`（Windows/MSVC 一键配置+构建+测试：vswhere 定位 VS → vcvars64 → qt-cmake --preset → run-tests；平台限定命名，其它平台用 preset 原生流程）
- 测试环境策略（Windows 特有，全部 `if(WIN32)` 包裹）：POST_BUILD 用 `$<TARGET_RUNTIME_DLLS>` 部署 Qt DLL 到 exe 目录 + 复制 `platforms` 插件目录；运行通道注入 `QT_PLUGIN_PATH`/`QML_IMPORT_PATH`（DLL 部署使 Qt 前缀推导失效的补偿）；CTest 用 `ENVIRONMENT_MODIFICATION`（`ENVIRONMENT` 设 PATH 在 Windows 按 `;` 拆分损坏——已知陷阱）
- **Crystal/HalfCrystal 测试单元（测试设施扩容）**：core 层 3 个——`tst_qool_crystalgadget`（八点几何三形态 + contains 精确命中契约）、`tst_qool_halfcrystalgadget`（contains 全方向契约：无源恒不命中/N·S·W·E 半区+角域排除/菱形形态/direction 与几何变化跟随）、`tst_qool_rectgadget`（九点/四半区矩形/内接外接正方形派生几何/rect 同步/contains 边界）；QML 批次 2 个——`tst_crystal.qml`（默认状态/cutSize 派生/掩码契约组件级）、`tst_halfcrystal.qml`（direction 切换/四向+菱形+非正方形掩码契约）。**逮住 3 个问题（修复归组件任务，此处只记录）**：CrystalGadget::contains 四角排除条件写反（角域与内部判定互换——C++/QML 双侧实证）；Crystal 组件 implicitWidth/implicitHeight 不等于声明值（Shape 根 implicit 被引擎覆盖——HalfCrystal 注释已预告的同机制隐患实证）；QML 批次顺序执行时 HalfCrystal 实例化 SEGFAULT（Crystal 掩码测试执行后触发，栈顶 qmlcachegen lambda_24，触发条件二分确认）。HalfCrystal/RectGadget 契约全绿

### 变更

- **测试设施落地定案（架构讨论两轮合并 spec 实施）**：测试目录迁移 `QoolUI/tests/` → **顶级 `QoolUITests/`**（与 QoolUI/ 平级，自包含——不继承 QoolUI 的 qt_standard_project_setup 作用域，AUTOMOC/project()/include(CTest) 自行声明）；共享宏族 `qool_test.hpp`（`QOOL_TEST_CASE` = `private: Q_SLOT void _N_()`，类体内内联；禁 `private slots:` 区入宏——moc 不收集）+ INTERFACE 库 `QoolUITestSupport`；现有 C++ 测试全部改写为宏族（行为不变，126 C++ 断言全绿）；删除识别实验文件（tst_macro_probe/ttt_macro_test）；**QT_MOC 实测不可用**（`QT_MOC` 是 qmake 的 moc 处理机制；CMake AUTOMOC 为独立实现——文本扫描只识别字面 `#include "xxx.moc"`/`#include <xxx.moc>` 模式，不理解宏标识符，含 Q_OBJECT 却无字面 moc include 时直接报错；CMake 4.4.2 文档全程无 QT_MOC 支持——保留显式 moc include）；QML 测试按**批次模型**组织（每 Qool 模块一个 QML 测试批次 = 一个 harness target `tst_<模块>_qml`，共享 `qml_test_main.cpp` 模板，批次目录 + `assets/` 约定，`assets/` 内不得 tst_ 前缀）；**Windows Qt 前缀解析改 qt.conf 自包含方案**（core/qml 层 configure 期生成 exe 旁 qt.conf，`Prefix = Qt 安装前缀`——QLibraryInfo 读取覆盖 DLL 复制导致的推导失效，任何运行通道零环境注入、源码零安装路径；common 层纯 QCoreApplication 不需要；qml 层 DLL 集补 Qool target 依赖链——Qoolplugin.dll 从 build/qml 加载需 Qool.dll 与 QuickControls2/Xml 等在其搜索路径）；CMake 组织：输出树下沉 `build/QoolUITests/{common,core,qml}`、构建开关 `QOOL_BUILD_TESTS`/`QOOL_BUILD_EXAMPLEAPP`（默认 ON，定义于 load_qoolui_standard_options）、测试 target 加入默认构建 all（落地修正：原「EXCLUDE_FROM_ALL 不构建测试」被 QtCreator 面板通道实测推翻——面板运行前构建 all，被排除测试的 exe 缺失全红；单测进 all 后绿确认根因）、`include(CTest)` 顶层条件化（`if(QOOL_BUILD_TESTS)` 内——enable_testing 必须顶层调用，ctest --preset dev 才在 build/ 找到 CTestTestfile.cmake；落地实测修正：原「内聚到测试树」方案全新 configure 后 ctest 找不到测试）、`project(QoolUITests)` 独立声明；规范载体 **`QoolUITests/AGENTS.md`**（术语表 9 条/测试方法规范/测试策略/CMake 组织定案）+ 根 AGENTS 一句介绍；落地后测试全通道全绿（run-tests/ctest/直跑，134 断言）
- 顶层 CMakeLists 加 `include(CTest)`（CTest 必须顶层启用，否则 build/CTestTestfile.cmake 不生成、ctest 找不到测试）；QoolUI/CMakeLists.txt 按 `BUILD_TESTING` 条件加入 `tests/`（-DBUILD_TESTING=OFF 整体关闭）
- 新增 `docs/agents/`（agent 工程技能设施配置）：issue-tracker.md（本地 markdown tracker：`.scratch/<feature-slug>/` 结构、spec.md + 编号票 + wayfinder 操作）/ triage-labels.md（默认五标签映射）/ domain.md（单 context 领域文档消费规则）；AGENTS.md 追加 `## Agent skills` 节指向三者；`.scratch/` 清空历史内容（家目录保留，gitignore 已覆盖）
- Qool.Controls.Components.ScrollBar、Qool.Controls.Components.BasicScrollView → **移入 Qool.Controls 并改名**（BasicScrollView → **ScrollView**——滚动条/滚动视图为控件层成员、非基础原件，去 Basic 前缀；依赖方向符合 R4：Qool.Controls 由 Components 与 Qool 主题组合；滚动组件归位控件层，与 ScrollIndicator 同层）。EditableTextBox 依赖同步（ScrollView 同模块隐式可见；BasicTextArea 仍在 Components——`import Qool.Controls.Components` 保留）；FileInfoListControl、QoolUIExample 消费方 import 已覆盖（均有 `import Qool.Controls`），无需改
- Qool.Controls.Components.Crystal → **移入 Qool 模块**（基础形状件归位——与 HalfCrystal 同层，`import Qool` 即可用）；移除 `control` 属性（单层简单组件不暴露几何——与 QoolBox 系列的多层公用场景区分，ShapeControl + CrystalGadget 内联为 Shape 子对象）；Slider/VerticalSlider 移除对 Qool.Controls.Components 的依赖（其仅依赖 Crystal，归位后经 Qool 可用），QDoc 链接更新（`{Qool::Crystal}`）；手柄 MouseArea 注释更新（Crystal 掩码已精确，手柄仍不设 containmentMask 是刻意的——NoButton 仅光标反馈、hover 域宽松）
- **core 层 include 机制统一（测试设施）**：新增 `QOOL_SRC_PRIVATE_INCLUDES` 变量（Qool 模块 PRIVATE include 全清单，与 `Qool/CMakeLists.txt` 同步）——直接编译被测源时 target 必须补齐（被测头内部可能引用 shapecontrol/gadgets/utils/qore 等目录的头，Qool target 的 PRIVATE include 不传播，漏一层断一层——gadget 测试曾连断 3 层）；全部 7 个 core 测试统一 PRIVATE include

### 修复

- **QML 测试静默加载旧组件（LINK_DEPENDS 补依赖边）**：Qool 模块 QML 源码修改后，QML 测试 exe 旁的 Qool.dll 副本过期（POST_BUILD 复制只在 exe 构建时执行；exe 依赖 Qool.lib 导入库——MSVC 导出符号未变时导入库不更新 → exe 不重链 → 副本不更新）→ 引擎从副本 qrc 加载旧组件，测试全绿但测的是旧代码。修复：`QoolUITests/qml/CMakeLists.txt` 给 tst_qool_qml 加 `LINK_DEPENDS "$<TARGET_FILE:Qool>"`（Qool.dll 本体为链接规则实依赖）——DLL 更新 → exe 重链 → POST_BUILD 复制重跑 → 副本自动同步（实测：touch QML → 构建 → exe 与副本同刻更新）
- **Polar2D 标量乘除语义错误（测试逮住）**：`operator*`/`operator/` 曾实现为 `radius + r` / `radius - r`——乘除符号下做加减（与 Vector2D 的 operator* 缩放语义不一致；零缩放不得零向量）。修复为 `radius * r` / `radius / r`（方向不变）
- **PositionLocker 动态跟随失效（测试逮住）**：lockTo 移动后 target 不重定位——根因：`basePos` 用 `axisItem.mapFromItem(lockTo, …)`，函数调用内部读取的 lockTo 变换（x/y）不建立 QML 绑定依赖，lockTo 位置变化不触发重算。修复：显式读取 lockTo.x/y 参与计算（const 未使用声明会被 qmlcachegen AOT 优化消除，无法建依赖——实测）；语义前提补注释：lockTo 为 axisItem 直接子项（PointIndicator 中 marker 与 target 均满足）
- **Vector2D 拷贝构造笔误（测试设施逮住）**：`m_vector{other.m_from}`——拷贝后向量被起点取代（与拷贝赋值 operator= 不一致；QPointF 隐式转 QVector2D 使笔误编译通过）。QML 值类型按值传递直接受害
- **NumberRanger::format 字符串替换分支不可达（测试设施逮住）**：QString 恒 `canConvert<qreal>`，数值分支先命中，正则替换逻辑成死代码——「字符串内数字按精度替换」承诺从未生效（"v=1.23456" 整体转数值失败得 "0"）。修复：字符串分支前置；同时修正其 `'g', decimals` 精度语义错误（'g' 精度是有效数字而非小数位，1.23 被截成 "1.2"）——decimalfy 已规整，改默认格式输出
- **HalfCrystal 绑定循环与尺寸增长（bugfix）**：非方形实例持续触发 `Binding loop detected for property "eastX"/"southY"` 且形状不断变大——根因：Qt 6.6+ Shape 引擎在路径变化时强制 `setImplicitSize(路径边界 + 描边扩展)`（qquickshape.cpp `_q_shapePathChanged`），implicit 尺寸被布局（QQuickControl contentItem setSize / Qt Quick Layouts preferred）回写为组件尺寸 → 尺寸 → gA → gB → pCtrl → 路径 → implicit 正反馈环（三角形占满高度方向 k=1，描边扩展每轮 +0.7071 恒发散）。修复：root 改为 Item + 内部 Shape anchors.fill（引擎 implicit 更新只作用于内部 Shape，root implicit 固定 20×20 不参与布局，环断开）——组件 API/渲染/掩码不变。Qt Quick Layouts 中 implicit>0 优先于显式 width/height（qquicklayout.cpp GATHER PREFERRED SIZE HINTS）为 Qt 既定行为——页面非方形实例改用 `Layout.preferredWidth/Height` 显式指定；文件头注释记录结构决策与 Crystal 同机制隐患（无 QML 绑定层故不报循环警告，宿主置于隐式布局容器时同样会被放大——待评估同构修复）
- **CrystalGadget 补精确命中掩码（bugfix——历史遗漏，非行为变更）**：`contains()` C++ 覆写——外接矩形粗判 + 四角切角域排除（角域为开集：斜边与八点顶点命中）；Crystal 组件挂 `containmentMask: gadget`——独立使用时命中域与可见八点形状一致（此前为外接矩形，四角误命中）
- RectGadget 构造期 target null 守卫（setBinding 立即求值对未就绪 target 解引用崩溃——CrystalGadget 同款守卫模式；零使用者从未暴露）+ **半区几何缺陷修复**（halfWidth/halfHeight 曾误绑中心坐标 m_hcenter/m_vcenter（= x+width/2）而非半长 width/2，且 rightHalfRect 误用半宽作 x——x/y 非零时四半区矩形全部错误；RectGadget 零使用者从未暴露，HalfCrystal 画布串联触发）——半区矩形现基于自身几何、任意偏移正确（本地画布坐标语义）
- **QML 测试 QtQuick.Shapes 插件加载失败（测试设施）**：qmlshapesplugin 依赖 Qt6QuickShapesd.dll，不在任何 target 的 `$<TARGET_RUNTIME_DLLS>`（非链接依赖，QML import 时才加载）——测试首次 import QtQuick.Shapes（Crystal/HalfCrystal 引入）时插件加载失败 "Cannot load library"。修复：`QoolUITests/qml/CMakeLists.txt` `find_file` 按构建类型定位 + 条件 POST_BUILD 复制（模板可复用，新增 QML 插件模块测试时必查）
- **CrystalGadget::contains 四角排除条件写反（测试逮住）**：四个角域判定 `(cut-dx)+(cut-dy) < cut`（⟺ `dx+dy > cut`）排除的是斜边**外侧**（形状内部）三角形，应排除斜边**内侧**（矩形角）角域——形状内误排除、角域错误命中。修复：不等号反向（`<`→`>`，排除 `dx+dy > cut` 角域；斜边开集语义保持 `dx+dy == cut` 命中）。HalfCrystalGadget 同族算法正确可对照
- **Crystal implicit 尺寸陷阱实证与同构修复（测试逮住）**：Crystal 以 Shape 为根组件，Qt 6.6+ Shape 引擎在路径变化时强制 setImplicitSize(路径边界)——implicitWidth/Height 实际为路径边界而非声明值 20。修复：root 改 Item + 内部 Shape anchors.fill（HalfCrystal 同构——引擎 implicit 更新只作用于内部 Shape，root implicit 固定 20×20 不参与布局，断开尺寸→路径→implicit→尺寸正反馈环）；文件头注释记录结构决策（HalfCrystal 注释预告的"待评估同构修复"落地）

### 文档

- **属性宏体系文档化**：`QoolCommon/qoolcommon/property_macros.qdoc`（独立 qdoc——三宏族定位/签名对照（哪个族有 _D_ 默认值、DECLARE 版无、`...` 是 Q_PROPERTY 附加选项通道）/用法示例/陷阱（误传默认值 → moc 晦涩 Parse error）/批量生成）；4 个宏头文件（qobject/qbindable/qgadget_property_macros + macro_foreach）补文件头简单注释；`macro_foreach_x.hpp`（QOOL_MACRO_FOREACH 变参版）确认零仓库使用者，维持 deprecated，不写文档
- RectGadget 补 QDoc（\qmltype——`rect` 覆盖默认 target 绑定行为（setValue 移除绑定——刻意设计供画布串联，非缺陷）；九点/半区矩形/内部最大正方形/contains 一览；任意位置偏移正确的本地画布语义）
- CrystalGadget QDoc 补 contains 方法说明（Rect 粗判 + 四角切角域排除算法）
- Crystal QDoc 更新（模块归属、掩码精确化、移除 control 说明）；HalfCrystal QDoc（四点模型/方向语义/菱形保留态/样式通道/动画门控/掩码算法与边界语义）
- **测试设施文档同步与消重（spec 委派推演闭环）**：三份文档（`QoolUITests/README.md`/`QoolUITests/AGENTS.md`/根 `AGENTS.md`）同步到 kit×type 构建体系并消解重复定义——README=使用手册（架构树补全 10 个测试单元（6 C++ target + 4 QML 文件）与 CTest 7 注册测试关系、价值记录两栏化（5 个测试逮住的产品缺陷 vs LINK_DEPENDS 设施修复）、Windows 一键三次调用唯一事实源（修复斜杠连写不可执行写法）、新增 C++ 测试 common 层 GLOB 零配置 vs core 层显式注册区分（消除与 GLOB 重复注册的确定性错误）、ctest 筛选示例修正（`tst_qoolcommon` 前缀已不存在；CTest 正则无 `|` 交替）、Windows 经验唯一清单（AGENTS 5 条并入去重）、平台差异/调试技巧路径更新）；AGENTS=规范（运行通道表单一事实源、一键段改一行引用、已知经验节改一行引用、旧 token 5 处清零）；根 AGENTS（offscreen 归因修正——由测试注册机制保证非脚本约定 + 工作流规范句 + install/deploy 概念边界句 + run 命令 QT_DIR 依赖注记——裸跑 run 无 Qt 运行时注入秒退，实测确认）；脚本 docstring offscreen 归因同步（注释级，零行为变更）；grep 精确 token 零残留（`build/`/`--build build`/`--preset dev[^-]`/`win_build_test`/小写 `scripts/`——`configure/build/test` 命令枚举与 `--build build-` 新内容均精确排除）+ 文档命令逐条实测（configure/build/test 7/7/ctest 筛选匹配数 1 与 5/直跑 exe 14 断言/run 进程存活）

- **测试设施文档同步（README 扩容）**：目录树补 5 个新测试单元、规模口径更新（15 单元/CTest 10 个）；「如何新增测试」C++ 节补 include 补齐义务（`QOOL_SRC_PRIVATE_INCLUDES` 引用）；QML 节补窗口访问注意（TestCase 无 `window` 属性——`Window.window` 附加属性；`QQuickWindow::itemAt` 非 Q_INVOKABLE，引擎 hit-test 端到端不可行，掩码契约直接调 `contains()`）；Windows 经验补 QML 插件依赖 DLL 条目（第 9 条）
## [4.0.0] — 2026-08-11

### 新增

- Qool.Controls.BasicScrollView（带 Qool 主题滚动条的滚动视图基底）：官方成品 QC.ScrollView 根（附加滚动条 position/size 转发、内容让位机制全免费——T.ScrollView 实测不转发 position/size、无样式让位，弃用）+ 内置 Qool ScrollBar（垂直/水平，非 Qt 默认样式；几何按官方 ScrollView 样式公式 parent/x/y/availableHeight + active 双条联动——官方样式层公式上移为内置）+ 显式内容让位（rightPadding/bottomPadding = effectiveScrollBar 尺寸 + padding——跨样式一致，官方 Basic 样式无此设置，不显式则 Basic 样式下滚动条遮内容）；宿主零配置获得 Qool 主题滚动（拖动/滚轮/主题外观），不改变官方 ScrollView 行为（API 全兼容）
- Qool.Controls.EditableTextBox（多行文本输入框成品）：BasicTextArea（Components 基底）+ 滚动（BasicScrollView——官方成品 QC.ScrollView + 预设 Qool 主题滚动条；T.ScrollView 不转发 position/size 给附加滚动条、无样式让位——实测裁定弃用）；文本 API 经 property alias 直通（text/readOnly/color/selectionColor/selectedTextColor/wrapMode/textFormat/selectByMouse；placeholderText 不暴露——输入提示属编辑相关功能；font 不转发——基座 Control.font final 无法重声明，内层默认 Style.controlTextSize）+ textEdited/editingFinished 信号转发（无参——EditableText 系列一致语义）；滚动条为 BasicScrollView 预设 Qool 主题件（垂直/水平均 ScrollBar，非 Qt 默认样式；水平 AsNeeded——默认 Wrap 折行下不出现；几何公式与内容让位内置 BasicScrollView，2026-08-11 实测裁定）；无背景（透明视觉——BasicTextArea 契约）；默认尺寸 240×120（固定视口）
- QoolUIExample：Page_Playground 设置 EditableTextBox 展示用例（可编辑/readOnly 两例——多行输入、垂直滚动、Qool 主题滚动条）
- Qool.Controls.Components.BasicTextArea（多行文本域基底）：QC.TextArea（QtQuick.Controls，非 T.TextArea——T 版在 ScrollView/Flickable 中无滚动能力，实测裁定）主题化——标准行为 + Qool 主题（文本三色 Style.text/highlight/highlightedText、Style.controlTextSize 字号、wrapMode 默认 Wrap、AlignTop 显式声明），不掺入行为决策；与 BasicTextField 对称（单行 ↔ 多行基底），宿主可直接作为多行文本域使用，亦可作未来多行编辑会话的编辑层基底；无背景（透明——显式 background: null 压掉 QC Basic 样式默认灰底，同 BasicTextField 约定）、Esc 不下沉、editingFinished/textEdited 信号不占用、不自带滚动（官方行为——置于 ScrollView 时官方集成自动接驳）；成品 Qool.Controls.TextArea 推迟（无消费方，保守路线）
- QoolUIExample：EditableText 密码回显用例自 Playground 测试场迁入 Page_InputControls 正式展示页（单 QoolControl 分组——掩码 + 真实值对照，去除内部 displayText 派生展示；Password/NoEcho/PasswordEchoOnEdit/passwordCharacter/readOnly+Password/插拔后密码化六场景）；Playground 恢复测试场空壳
- Qool.Controls.TextField → **Qool.Controls.EditableText 改名**（名字说真话：可编辑的 Text——非 TextField 兼容层，不承诺官方 API 面；QDoc 定位声明取代「契约差异」章节；BasicTextField 保留原名=真 TextField 基底；ComboBox/SpinBox 编辑域引用与注释、Page_InputControls 随改名更新）
- Qool.Controls.EditableText 新增 echoMode 密码回显：echoMode（官方 4 枚举 Normal/Password/NoEcho/PasswordEchoOnEdit）+ passwordCharacter（默认透传平台主题、展示层为空时 fallback 固定字符——两处默认可能不一致需显式设置）+ passwordMaskDelay；displayText 密码化派生（作用于插拔 displayTextFromText 结果之后——插拔点保留）；编辑层转发三属性、copy/cut 禁用（TextInput 内建——非 Normal 回显下无效）；readOnly + echoMode 非编辑态同样掩码

- Qool.PositionTracker（2D 位置追踪器）：追踪 target 局部点 point 的场景坐标/屏幕坐标——逐层监听 target 祖先链（坐标/缩放/旋转/变换原点/父级/窗口），任意层变化自动重算；**帧内合并**（几何信号只置脏、事件循环批次统一 flush——坐标变化通知按批次合并、延迟至多一帧）+ **值去重**（结果未变不发信号，阻断下游无意义传播）；target 缺省 = 声明父（构造快照，显式赋值含 null 自然覆盖，不持续跟随）；保底语义（target null 透传 point 原值、无窗口时 globalPos = scenePos、currentWindow 输出）；`update()` 强制重算（覆盖 transform 列表无信号盲区）
- Qool.Floater：`noVisibleSync` / `noEnabledSync` 开关（默认 false——替身契约保持全量同步，使用方零影响；开启后契约放弃对应属性同步，content 回到 Qt 默认机制——可自行绑定/显式设置；代价为父级对 root 对应属性的操作不再传递到 content，契约缺口已文档化；仅这两个属性有开关——其余属性在 Qt 默认行为中本就独立，契约绑定即本体）

### 修复

- Qool.Controls.ScrollBar 规范对齐：补 `visible: policy !== ScrollBar.AlwaysOff` 策略绑定（官方 Basic 样式同款——AlwaysOff 时完全隐藏；挂 Flickable/ScrollView 时影响 effectiveScrollBarWidth/Height 的内容区让位计算）；minimumSize 保持固定 0.1（裁定不按方向化）
- Qool.Floater 位置机制改造（PositionTracker 驱动）：三组 Connections（自身/直接父级/target 的坐标信号）替换为两个 PositionTracker（root 原点 + target）——**祖先链高层平移盲区消除**（旧机制只监听 root.parent 一层，祖父及以上平移不触发重算，需宿主手动 refresh 补偿——RectResizer 6 手柄即用此补偿）；坐标通道改用场景坐标（mapFromItem——不依赖窗口位置）；target 运行时切换经 tracker 绑定自动迁移；refresh() 保留并委托 tracker 强制重算；width/height 冗余监听随旧机制移除（位置计算不消费尺寸——mapToGlobal/mapFromItem 只依赖坐标与变换）
- QoolDebug.RectResizer 冗余补偿清理：`Connections { target: root.parent }` 与 `refreshHandles()`（6 处 refresh 调用）移除——PositionTracker 祖先链逐层监听已覆盖（含增强：root.parent 缩放/旋转现自动跟随，旧实现不监听仅偶然刷新）；content 内 6 处 `width/height: xxxFloater.width/height` 死代码移除（替身契约 Binding 已接管尺寸）
- Qool.Floater 自动位置更新失效修复：`Connections` 误用 `enabled: Component.completed`（Component 无 completed 属性，求值 undefined → 连接永久禁用，位置从不自动更新；此前被 RectResizer 手动补偿掩盖，清理补偿后暴露）——移除门控，tracker 首次 flush 经 singleShot(0) 落在事件循环批次、组件必已完成，初始位置由 onCompleted 兜底；同步修复 QoolDebug.ColorButton 同类误用（Binding `when: Component.completed` → 背景色从不跟随 value）
- Qool.Floater 移除 `refresh()` 公开方法（追踪契约边界修正：PositionTracker 只对 QML 属性变化——Q_PROPERTY/notify 体系——负责；transform 列表非 QProperty 属性，不在契约内，为其设计的兜底 API 属范畴错误——宿主修改祖先链 transform 列表后浮层位置不自动更新为契约外行为，不再声明例外）；PositionTracker.`update()` 保留，语义更新为批次合并的同步入口（原「transform 盲区」表述随概念修正移除）
- Qool.DragMoveArea 拖动增量基准修复：局部坐标（mouseX/mouseY）基准在本组件被外部移动时受污染（Floater 位置更新把 content 拉回新位置 → 增量 = 鼠标位移 − 组件位移，走-停-走反复跳动、不跟手——RectResizer 手柄拖动即此现象）——基准改场景坐标（mapToItem(null)——mapToScene 非 QML 方法，qmllint/运行时均不可用），增量与组件自身移动解耦；基准初始化从 onPressed 处理器移入 Connections（监听 pressedChanged）——使用处覆盖 onPressed（QoolWindowBG 的 startSystemMove，Windows 下失败走 fallback 增量路径）时基准仍建立，fallback 路径恢复可用

### 文档

- Qool.PositionTracker 补 QDoc（\qmltype——链路监听/批次合并/值去重/透传语义/混合场景与 transform 列表边界；属性/信号/方法块入 qool.qdoc）
- Qool.Floater 补 QDoc（\qmltype——替身契约、target 可配置、z 消歧、事件不代理、refresh 语义、可见性语义、双开关含契约缺口、content 替换善后声明、opacity 值同步中性假设）
- Qool.ItemTracker 补实现注释与 QDoc（find_parent 语义、flow-on 捷径——监听自身 enabledChanged 即覆盖祖先链、window 为 null 时属性取默认 true）
- Qool.DragMoveArea 补 QDoc（\qmltype——增量语义/场景坐标基准/系统拖动配合；target/autoBind/hovered 属性与 wannaMove 信号块）
- QoolDebug.RectResizer、QoolDebug.ColorButton 补 QDoc（\qmltype + 属性/方法块——QoolDebug 模块首批类型文档）
- qool.qdoc 补 ItemTracker 属性块（target/item/window/itemEnabled/windowActived）

## [4.0.0] — 2026-08-10

### 新增

- Qool.Controls.VerticalSlider（Slider 竖直化，独立轴交换实现——禁止 rotate）：轨道瘦六边形（上下尖 + 左右直边）、手柄垂直移动、**底部为 from**（值增大向上）；参考轴交换（preferredWidth = width - bound(3, 宽度×25%, 25)）；交互垂直化（T.Slider 鼠标映射为水平语义不可用——全区域 picker MouseArea 垂直映射 y → value 取代模板交互，pressed 反馈改由 picker 承担）；键盘 Up/Down 步进（模板 Left/Right 保留）；其余与 Slider 同源（水晶模型/渐变采样/展开反馈/TimerLatch 锁存/CurveRenderer 动画期切换）
- Qool.Controls.Slider（v3 Color 滑块视觉族通用化）：六边形渐变轨道 + 水晶菱形手柄（**同一八点模型**——斜边斜率一致天然对齐）；轨道默认 `text→color` 水平渐变（`color` 属性 = 渐变右端色、锚定切角内侧——`fillGradient`/`fillItem` 双通道透传，fillColor 兜底渐进降级）；手柄常态色 = 轨道渐变在当前值位置的采样色（ColorMapper.colorAt——渐变锚定段与手柄中心行程对齐，`colorAt(visualPosition)` 精确）；悬停/按下/刚移动三态展开（v3 ColorCursor 核心）+ pressed/程序化锁存提亮（TimerLatch + NumberNotifier——"值被写入即亮"）；尺寸反向排版（root 默认 80×20——模板不自带 implicit 公式；轨道显式绑定 root 尺寸——background 自动 fill 对带 size 绑定的 Crystal 不生效）；手柄跟随控件高度（crystalSize = 默认高度）；倒置/禁用/键盘为官方行为；手柄溢出边界为刻意效果（反 clip 声明）
- Qool.Controls.Components.Crystal（八点模型六边形色块）：Qool 切角体系 Gadget 实现（`shapecontrol/gadgets/qool_shapegadget_crystal`——标准 ShapeControl + CrystalGadget 预制点）——统一 8 点路径覆盖宽六边形（w>h）/菱形（w=h，旋转 45° 正方形）/瘦六边形（w<h——上下尖 + 左右直边，可直接作竖直滑块背景）；**单层外轮廓模型**（无内缩——规避 OctagonShape 双层模型在切角极限的反向三角形 bug，性能亦轻）；RB/LB 跨边条件绑定（位置关系推演三形态校对，见 .scratch/slider/crystal-geometry.md）；中间量链基类 bindable（不重算 w/2/min）；命中域为外接矩形（无精确菱形掩码——Slider 场景手柄不交互、掩码无意义，独立使用宽松命中已声明）
- QoolUIExample：Page_InputControls2（Slider + Dial 展示页——用例自 Playground 梳理合并：反馈/官方行为/尺寸形态分组，QoolTip 详尽说明行为/属性/注意点；Dial 补正式展示）；Page_Playground 清空为测试场空壳（Slider 调试用例迁移展示页，页面保留供后续调试）

### 修复

- CrystalGadget：构造时 setBinding 立即求值对 null target/control 解引用崩溃（QML 属性赋值在构造之后）→ 守卫 + bindable 依赖追踪（control 设置后自动重求值）；几何链 control（不重复从 target 获取——基类 ShapeControl 已有 x/y/width/height，snake_case bindable 访问器）；中间量链基类 bindable
- Crystal 八点几何：RB/LB 无条件定义致 w>h 时底边两端缺失（形状塌成 5 边形"钻石"）→ 跨边条件绑定（w≥h：底边距 cut；w<h：侧边距下 cut）——位置关系推演（三形态校对，边界 w=h 归 ≥ 分支）
- Slider 轨道尺寸：background 自动 fill 在 Crystal（带 size 绑定）上未生效（轨道缩成 20×20 菱形在左上角）→ 轨道显式绑定 root 尺寸
- Slider 渐变通道：fillGradient 经子对象 id 引用/三目内联对象失败（绑定时机/语法）→ 属性默认值内联对象 + 直接绑定（fillColor 兜底——渐变失效时轨道仍可见）

### 文档

- Slider/Crystal QDoc（八点模型三形态、单层模型与反 clip 声明、命中域外接矩形声明、crystalSize 语义、fillGradient 替换近似说明）；CrystalGadget QDoc（位置关系推演、性能——中间量链基类、易误解点）

### 其他

- ScrollBar/ScrollIndicator 淡出延迟机制由 DelayTimer 改用 TimerLatch（锁存窗口 `active` 声明式驱动两态——trigger 重置倒计时，与 DelayTimer restart 同构）；删除 Qool.DelayTimer 类型（无消费方后移除，4.0.0 未发布无宿主负担）
- Slider 手柄/轨道展开语义调整：展开态水晶占满控件高度（不超出边界）；轨道与水晶常态同高 = 新公开属性 `preferredHeight`（root.height - bound(3, 高度×25%, 25)）、轨道垂直居中三心对齐——贴斜边关系保持、放大视觉差不变；取消 v3"菱形顶出轨道"刻意效果（clip 不再影响反馈）；默认高度 20 → 25（implicitHeight）
- Slider/Crystal/TimerLatch 新版调整（工作区裁定）：TimerLatch 改名（becameActive/becameInactive → activated/deactivated、activate → trigger）并内联 Timer；Crystal 移除 size/leftPoint/rightPoint（implicit 20×20，宿主 width/height 自由控制）；Slider API 收缩（fillGradient/fillItem/crystalSize 移除——渐变内联默认、换色走 color、尺寸走 width/height 覆盖）、手柄 MouseArea 修复（acceptedButtons: NoButton 不拦截模板拖动 + enabled 绑定 + 删除无效 containmentMask）、colorAt 采样改 visualPosition（笔误修复）、pressed/锁存提亮取消（只留展开反馈）、锁存窗口 1s → 500ms（valueChanged 即时 + velocityChanged 采样级重置双触发源）、新增 animationEnabled/valueVelocity/justMoved 公开属性
- OctagonShape fillGradient 别名回滚（无使用方——轨道改 Crystal 后）
- 展示梳理：Slider 用例自 Playground 迁移 Page_InputControls2（合并分组 + QoolTip 充实）；Playground 清空为测试场空壳

- Qool.Controls.SpinBox（L1 裸控件）：T.DoubleSpinBox 基座，int/double 一体步进——透明尺寸背景（implicit 100×35）、点击覆盖式编辑（Text 常显 + Loader 激活 BasicTextField）、左右全高指示器占位（参照官方 Basic 实现坐标）、inputMethodHints 改 ImhFormattedNumbersOnly；无壳层视觉（壳层由宿主 QoolControl 包装）；Playground 展示页
- Qool.Controls.TextField 双层强化版（v3 传统覆盖模式演进，系列可编辑控件编辑域消费基底）：
  - 双层定位：展示层（displayItem 常驻——默认 Text 经 displayTextFromText 派生）+ 编辑会话（editing 开关——点击/聚焦进入、Loader 懒加载 BasicTextField 呈现、结束卸载恢复）
  - 编辑模型（judge——常驻隐藏 TextInput）：会话文本/validator（root alias 直通）/acceptableInput 单点事实源——判定不依赖编辑层生命周期；编辑层不挂 validator（accepted/editingFinished 无条件发——结束尝试全识别）
  - accepted/rejected 独立信号（判定结果——非内部转发）：接受（text = textFromEditText + accepted）/拒绝（不写 + rejected）；输入与当前 text 一致 = 无处理不触发；editingFinished 对齐 TextInput 语义（判定结果信号之前——接受时 text 已写入）
  - 插拔三件套：displayTextFromText/textFromEditText（独立语义——分属展示/收尾过程——不假设互为逆、互逆可行非契约）/displayItem
  - 官方 API 兼容：textEdited（转发编辑层用户编辑）/inputMask/inputMethodHints/wrapMode（转发编辑层）
  - 裸控件定位（与 SpinBox 同）；隐式尺寸显式公式（T.Control 默认不传播——官方 Basic/Control.qml 同款）
- Qool.Controls.Components.BasicTextField 还原纯净：撤销 rejected 下沉（onEditingFinished + !acceptableInput 判定删除）——定位回归"主题化默认 TextField"；editingFinished 信号释放给上层（编辑层实例挂统一收尾——实例 handler 覆盖组件定义）
- Qool.Controls.Components.BasicArrow（方向箭头组件）：等腰直角三角形（顶角 90°——SW 基准、直角边对齐坐标轴）——direction 八方向（Qore 的 N/S/W/E/NW/NE/SW/SE——Directions 枚举于 qool_literals.h；Unknown 默认不绘制）；图形逻辑 ShapeControl 体系（CircleGadget + 双 TriangleGadget——理想大小 + 微缩版内缩映射）；叠放双 Shape（边框层/填充层——无边框路径隐藏背景、前景跳转满尺寸；ShapePath 显式禁描边）；内层画布旋转（root 稳定留给宿主）+ 前景坐标 Behavior 动画（borderWidth 平滑过渡）；命中 = 画布内切圆判定（小尺寸箭头宽松化——刻意简化）；默认 12×12、旋转不越界（外接圆 = 内切圆）
- Qool.BasicRotationBehavior（角度属性 Behavior）：旋转动画沿最近路径过渡（等价角判定——270→0 实际走 270→360，到达后静默跳回目标值，避免大圈旋转）；拦截时经 targetValueChanged 同步动画起点（真属性保持旧值/中间值——中断场景从中间角度继续）；BasicArrow 方向切换采用（SpinBox 指示器方向切换走最短弧）
- Qool.Controls.SpinBox：指示器替换为 BasicArrow（右条 ▶ / 左条 ◀——左右方向；三态色逻辑保留）
- QoolUIExample：SpinBox 示例组整合到 Page_InputControls（整数/小数/可编辑/wrap 回环/自定义格式/禁用态——SpinBox 组作为一个 section，SectionBar 分段）
- Qool.Controls.ComboBox / SpinBox 编辑域迁移到 TextField（双层强化版——编辑域状态机单一化）：
  - 两控件删除各自的 Loader 识别缺口补偿（手动 editText 回写/手动提交回退/手动信号补发）
  - ComboBox：常驻 TextField（readOnly 绑定控制 editable）——currentText ↔ text 命令式同步（用户裁定：属性绑定会被收尾内部写回 text 打断）；accepted/rejected 透传（rejected 为 Qool 扩展新信号）；editText/validator/inputMethodHints/selectTextByMouse 透传；编辑失败统一结束并宣告（契约差异：官方失败保持编辑——本类型结束 + rejected）
  - SpinBox：常驻 TextField——value → textFromValue 喂入显示（命令式）；accepted 读收尾后 text 映射 value（值变补 valueModified）/拒绝透传（新信号）；编辑中按指示器先收尾再步进；displayTextOverride 移除（自定义显示经覆写 textFromValue/valueFromText 配对）
  - TextField 增量：新增 selectByMouse 转发属性；readOnly 语义扩展（中途变 true 统一收尾进行中会话、不进 Tab 焦点链、纯行为开关——不触发样式变化）

### 修复

- Qool.Controls.TextField：编辑会话文本残留（Binding 组件回写 judge 的恢复时序（delayed + restoreMode）在编辑层卸载时不可靠——下次会话初始显示上次输入）→ 弃用 Binding 组件改手动同步（onTextEdited 回写 + 非编辑期 Connections 同步 + 收尾显式恢复基准）
- Qool.Controls.TextField：编辑层初始空文本（Binding 组件创建时首次求值以编辑层空 text 污染 judge）→ onTextEdited 方案（程序化赋值不发 textEdited——初始无污染）
- Qool.Controls.TextField：收尾递归重复（internalEditing 最后置 false 后，editing=false 触发 onEditingChanged 桥接再次收尾——editingFinished 重发）→ finishing 标志防重
- Qool.Controls.TextField：悬空 editTextChanged 调用（alias 不生成信号——信号移除后残留调用 TypeError）→ 删除
- Qool.Controls.TextField：MouseArea 悬停光标未响应 readOnly → enabled: !readOnly

### 文档

- Qool.Controls.TextField 补全 QDoc（\qmltype——双层结构/编辑会话/判定信号语义/插拔函数/契约差异）
- QoolUIExample：Page_Playground TextField 调试示例（名字输入/Validator 支持/自定义输出格式）整合到 Page_InputControls 最前
- ComboBox/SpinBox QDoc 更新（编辑域说明/accepted-rejected 新信号/契约差异）；TextField QDoc 补 selectByMouse 与 readOnly 语义扩展

### 其他

- IndexIndicator 圆点列垂直居中（ComboBox 指示器偏上 3.5px 修复）；ComboBox delegate 宽度改 ListView.view.width（右缘 1-2px 裁剪修复）
- qool_vector2d.h 的 QML_VALUE_TYPE 去引号（与其余值类型注册风格统一）
- Playground 清理（displayOverrideEx 未用 id 删除；变换示例补"恶作剧"说明注释）
- TextField 文件头待验证段补 popup 焦点归还可能性记录；IndexIndicator 补大型模型性能 TODO
- Playground：SpinBox 示例扩展为一组（整数/小数/可编辑/wrap 回环/自定义格式/禁用态——同组示例间加分隔线）

## [4.0.0] — 2026-08-09

### 修复

- Qool.Controls：ComboBox editable 按 Enter 后结束编辑——Qt 默认在提交动作（accepted）发出后焦点仍留在文本域，编辑状态只能靠失焦结束，外部没有其它焦点对象时编辑状态悬挂、无法退出；现于 BasicTextField 的 onAccepted 中调用 root.accepted() 激活 ComboBox 的 accepted 信号（宿主 onAccepted 入口与 Qt 官方语义一致：经 find(editText) 处理输出数值；Qt 内部模型匹配/currentIndex 更新不随此调用执行，由宿主自行处理），随后释放焦点（focus=false）结束编辑。另补 onTextEdited 把编辑文本反向同步回 editText（模板层按 contentItem 类型识别文本域，Loader 包裹结构下 editText 不自动同步）。popup 打开时焦点在列表上，Enter 仍是激活高亮项，不经过此路径

- AGENTS.md：技术栈节新增"以官方文档为准，不探查 Qt 源码"——使用 Qt 通常不查看其源代码，行为语义以官方文档为准；仅当怀疑 Qt 本身存在 bug 时才探查源码验证；推断 Qt 未文档化行为须标注未验证
- AGENTS.md：文档规范（QDoc）节新增"QML 类型文档内容规范"——参照 Qt 官方 QML 类型页格式：文档叙述用法而非开发笔记（机制归代码注释）、结构对齐官方页（概述/属性/信号/方法/主题章节）、逐属性说明（类型/默认值/语义）、继承官方模板或控件的类型声明接口兼容性、与 Qt 官方行为不同的契约明示；以 ComboBox QDoc 重写为实例

### 移除

- Qool.Controls：删除 QoolComboBox——`qoolboxsettings remake`（0f0d2b1）重构时旧版 ComboBox 的存档副本误入公开注册：创建即零消费方（历史与现状均无实例化），功能为 ComboBox 真子集（无 popupDirection/对齐配置/editable 懒加载/backgroundSettings 宿主覆写，popup 背景手抄 settings 字段），冻结一年未演进（2026-08-06 审查曾补 QDoc 与 Style.follow 但未清理）。同步移除 CMakeLists 注册（qmldir 条目随 QML_FILES 移除自动消失），ComboBox.qml 两处 QoolComboBox 对照说明改写为独立表述

## [4.0.0] — 2026-08-07

### 修复

- `.cmake-format.py` 全面调教：`additional_commands` 声明 Qt 6 CMake API（qt_add_qml_module/qt_add_resources/qt_standard_project_setup/qt_add_translations/qt_add_plugin/qt_add_executable/qt_add_library/qt_generate_deploy_qml_app_script）与 QoolUI 自定义命令（append_qml_dir/dump_list/load_qoolui_standard_options/copy_qml_modules_for/convert_paths_to_relative/qoolui_collect_assets/qoolui_scan_assets_to）的关键字结构——此前仅占位 `foo`，所有 Qt 命令被当纯位置参数、只能逐行垂直堆叠；声明后 kwarg 与值同行、重复 SOURCES/QML_FILES 分组保留
- 布局参数定案（嵌套方案）：`max_prefix_chars` 10（Qt 命令一律嵌套、固定 2 空格缩进）+ `max_lines_hwrap` 2（拒绝未嵌套多行布局）+ `min_prefix_chars` 10（set/if/message 等短命令保持参数同行）——产出接近 Qt Creator 生成风格的紧凑布局
- `enable_markup` 关闭：markup 注释重排按英文断词规则合并中文注释行，破坏手写注释结构
- `enable_sort` 关闭：QML_FILES/SOURCES 按目录分组、顺序有语义，不可排序
- lint 命名模式放宽兼容项目风格：macro_pattern 支持小写宏（load_qoolui_standard_options）、local_var_pattern 支持大写局部变量（ASS_DIR 等）、argument_var_pattern 支持下划线参数（_V_/_T_ 等）
- qool_qml_project_setup.cmake：删除 convert_paths_to_relative（唯一调用方 qoolui_collect_assets 改用 `file(GLOB_RECURSE ... RELATIVE ...)` 一步产出相对路径，绕弯消除）；qoolui_collect_assets 的 warning 分支 `PARENT_SCOPE}` 笔误修复（多字符面量导致 assets 缺失时输出变量不生效到父作用域）；.cmake-format.py 同步删除 convert_paths_to_relative/qoolui_scan_assets_to 两个已不存在的命令声明
- QoolUIExample：`qoolui_collect_assets(appQoolUIExample)` 参数与引用变量不匹配（函数设置变量 appQoolUIExample、引用 ${QOOL_ASSETS} 未定义 → 示例资源静默为空）→ `qoolui_collect_assets(QOOL_ASSETS)`；重构验证：vcvars 环境下 configure + 构建 302 目标全绿，qrc_qoolexample_assets.cpp 正常生成
- QoolControls：`_private/DialRangeArc.qml` 曾裸注册进 QML_FILES（无 internal 标记、无 qrc 机制 → qmldir 注册、宿主可见，违反私有件机制二选一约定）→ 改为 QoolColor 同款 qrc 私有件机制（不进 QML_FILES，GLOB + qt_add_resources 打进 /qt/qml/Qool/Controls/_private/）；Dial.qml 原有 `import "_private"` 无需改动；验证：qmldir 不再含 DialRangeArc、模块公开 qrc 已移除、私有 qrc 生成（qrc 模式无 AOT 缓存，已知可接受代价）
- **插件按接口分包（AGENTS.md 插件约定新增）**：同一接口的多个插件组织在同一包（目录）中，以不同 CMake target 共存；例外——插件本身复杂或属非默认行为的特化功能时可独立成包。践行：`plugins/colornameprovider_default/` 与 `plugins/colornameprovider_commonzh/` 合并为 `plugins/colornameprovider/`（两插件 target 共存，default priority 0 / commonzh priority -1，产物名不变：QoolUIColorNameProviderDefault.dll / QoolUIColorNameProviderCommonZh.dll，构建验证通过）

## [4.0.0] — 2026-08-06

### 修复

- QoolCommon（QoolCommon/qoolcommon/）：
  - math::average：累加器初始值 `0`（int）→ `N(0)`（浮点列表不再被整数除法截断）；空列表显式返回 `N(0)`（此前 0/0 为 UB/NaN）
  - tools::find_all_indexes：`indexOf` 的 from 参数含自身，未 +1 导致同位置反复命中（死循环）
  - tools::generate_random_string：取样上限 `sizeof(charset)`（std::string 对象大小）→ `charset.size()-1`（越界读）；空字符集防御
  - LazyCache：updater 构造 `std::make_optional` 类型不匹配（编译失败）；补 Rule of Five（裸指针成员拷贝/移动语义，此前 double free/悬垂）；析构补 `delete m_mutex`（泄漏）；`value()` 全锁读（此前无锁预判与返回为数据竞争）
  - singleton.hpp：STL_IMPL `lock_guard(&mutex)` 指针参数（编译失败）→ 两个 IMPL 改 magic statics（函数内 static，C++11 线程安全，消除 DCL 无锁读竞争）
  - math::normalize_degrees：负角 fmod 保留符号导致结果落在 [-360°, 0) → 补 360° 归位，与 normalize_radians 对称
  - DefaultVariantMap：`size()` 取 qMax → 并集键数（contains 是并集语义）；补拷贝赋值（隐式赋值浅拷贝锁指针，double delete）
  - QGADGET_READONLY_PROPERTY_DECLARE：删除错误的 setter 声明（与 READONLY 语义矛盾，与定义版宏对齐）
- Qool.Controls：
  - ComboBox：background opacity 引用 `textField` 经 Loader 组件边界不可见（ReferenceError）→ Loader 加 id + `item?.activeFocus` 可空访问（QoolComboBox 因 contentItem 直连无边界，两结构注释说明差异）
  - PaPaWall：refresh() 引用不存在的枚举成员（RespectFontSize/LargetTextSize，ReferenceError 致功能失效）→ DependsOnFontSize/LargerTextSize，三模式语义闭环
  - ScrollIndicator：onStarted/onFinished 直接赋 `indicator.opacity` 杀死绑定 → delayer.running 两态驱动（behavior 过渡）
  - QoolBGBox：leftSpace/rightSpace/bottomSpace 补 `label?.` 空安全（topSpace 先行一致）
  - IndexIndicator：rows/columns 绑定自身尺寸构成自引用环 → 垂直固定 `columns:1`、水平固定 `rows:1`（按 count 排布）
  - QoolComboBox：delegate 补 `Style.follow: root.Style`（popup 在 Overlay 层、attached 传播断链，delegate 样式此前回退默认主题）
- Qool.File：
  - FileInfoListModel：批量 insert 索引 `position+1` 固定值 → `position+i`（逆序+区间不符）；批量 append 空列表 first>last（模型契约违规）；removeRange 移除后 takeAt 错元素越界 → 先收集再移除；takeAt/infoAt 越界（qBound 放行 total）显式检查；sortInfos 的 fileInfosRemoved 移到 endResetModel 之后；data() 补 row 越界检查；单行 move 向下移动 destinationChild 差一（Qt 源码 QList::move 落 to）；批量 move 无效目标（to==total）取移除后长度=追加末尾 + validateIndexes 排序去重；移除 QRecursiveMutex（无跨线程调用方，死代码且违背 Qt 模型线程规范——单线程契约写入头文件注释）
  - UrlChecker：containsAcceptableUrls/acceptableUrls 的 static lambda 捕获 this（跨实例串用+悬垂）→ 非 static；suffixlist split 补 SkipEmptyParts（空段产生空后缀恒匹配）+ 后缀正则转义
  - FileInfoDB::getFileInfo：二次 `m_cache->object()` 防御判空；单线程契约注明
  - FileIconDB 析构：dynamic_cast 判空（provider 不保证 QObject）
  - FileIconImageProvider::compileUrl：路径 `%` 先 URL 片段转义（`%20` 等合法转义序列致路径失真；provider 端 QUrl::path() 自动解码）
  - FileInfoListView：`getFileInfos`（不存在的方法，静默失败）→ `infos()`
- Qool.Chat：
  - ChatRoom 注册路径：set_name 建立服务器连接后对 m_beepers 全部补发 wannaSignIn（QML 属性求值顺序下 Beeper 注册信号早于连接建立而丢失）；componentComplete 删除原条件补发循环（职责由 set_name 承担，原逻辑在 name 先赋值场景产生 "already signed in" 警告噪音；注册延迟到组件完成的原设计意图保留）
  - BasicBeeperApp::targetChange：`disconnect(oldTarget)` 误断全部出站连接 → `disconnect(oldTarget, nullptr, this, nullptr)`；日志引用 `newTarget->name()` 在换空目标时空指针解引用 → 改 oldTarget
  - ChatRoom::dumpInfo：m_server 空判（name 未设置时 QPointer 为 null）
  - Message::__generate_id__：seed 取时间戳（同毫秒同随机串 → messageID 碰撞）→ 混合进程内递增计数器
  - Beeper：channels 读写加 QMutex（服务器线程 trySend 跨线程读 QSet，数据竞争）；析构补 `QCoreApplication::removePostedEvents`（postEvent 投递队列中的 UAF 窗口）；name 宏 getter 不加锁的原因注释（QByteArray 隐式共享单指针实践安全）
  - MessageLogger：移除 QMutex（消息路径全主线程，锁为死代码，注释说明）
  - ChatRoomManager：purgeClosedServers 移除后重建空项再解引用（空指针崩溃）→ continue + take 先移出容器；beeperSignedOut→serverPurgingRequested 触发链移除（Beeper 登出是常态操作，即时 purge 摧毁复用缓存）→ QTimer 30s 周期清理
- plugins：
  - themeloader：`<custom>` 段误写入 active（custom 恒空）→ 写 custom；solve_values 的 has_ref 多查 lazyProperties 而 get_ref 不能取（copy 前向引用得空值，midnight.xml decorativeTextSize=0）→ 一致化（copy 链由多轮循环求解）；yes_tags 含 "no"（bool "no"→true）→ 移除；name 兜底被 load_metadata 整体覆盖 → 无 name 属性时补回
  - fileiconprovider：completeSuffix()（复合后缀永不命中单后缀索引键）→ suffix()；行解析 `sp.at(1)` 越界（损坏行崩溃）→ 判空跳过；database_initialized 原子化（异步图片线程并发读，bool 竞争）
- Qool.Debug：RectResizer 六个 DragMoveArea 补 `autoBind: false`（默认会拖动 Floater 自身，与 onWannaMove 手动调整双重驱动）
- Qool.DragMoveArea：`wannaMove` 参数从"相对按下起点的累计位移"改为"相对上次位置的增量位移"（契约：消费方按 `x += dx` 叠加）——原语义下每次 positionChanged 重复累加，窗口移动/缩放跳变不跟手（QoolWindowBG）、RectResizer 拖动超量变形（Playground 暴露）；消费方全部为增量叠加，无行为破坏
- Qool.Floater + Qool.Debug.RectResizer：手柄（Overlay 层 content）在"被调对象整体平移"时不跟随——Floater 的 updatePos 只在自身/直接父级 x/y 变化时自动触发，anchors 跟随使 RectResizer 相对坐标不变、触发链断开（实测：Dial 平移 +60/+50 手柄停留原地，缩放时因 Floater.x 绑定重求值才偶然刷新）。修复：Floater 暴露 `refresh()`；RectResizer 监听 root.parent 几何变化统一刷新 6 个手柄
- Qool.Color（裁定修复，v3 对照审查后续）：
  - ColorDB：color()/name() 裁决顺序从逆序（高优先覆盖）恢复为升序（"补充"型裁决，低优先 provider 提供基础色名、高优先仅补充未覆盖查询），QDoc 如实描述裁决语义
  - RandomHSVColorGenerator：宏展开的 _minN/_maxN/_preferredN helper 补 math::auto_bound 钳制（越界输入不复刻 v3 循环域 -1 缺陷）；防重复约束恢复为仅色相通道（sat/value/alpha 无约束均匀随机——v3 行为，迁移曾过度解读扩大到全通道）；QDoc 同步更新（255 量化、generate() 方法注释）
  - 排版文字去 qsTr：HSVPanel/HSLPanel/ColorSlider_*/ChannelSlider_*/ColorBankSlotButton 的通道标签（HUE/SATURATION/L/S 等）是像素字体排版画面元素、不翻译——移除 qsTr() 包装；AGENTS.md 新增「排版文字≠文本」规则
  - NumInput：动画按临时件策略全部移除（编辑弹跳 editingAnimation、边缘闪烁 edgeAnimation、下划线淡入 Behavior、边缘信号 leftEdgeReached/rightEdgeReached），仅保静态外观/布局/状态切换；animationEnabled 属性仅为 API 兼容保留；文件头补动画策略说明
  - NumInput：implicit 尺寸修复——v3 TextLineEdit 根为 QBasic.Control（implicit 自动取自 contentItem），拍平件改根为 T.Control 后实测（Qt 6.11）Templates.Control 不传播 contentItem implicit，implicit 恒 0 → 布局中分配高度 0、数字内容溢出与标签错位/重叠（用户验证发现）；显式绑定 implicitWidth/implicitHeight 回传（showUnderline 时含下划线区 5+4，语义与 v3 一致）
  - CycleChoice / ColorNameButton / ChannelBar：同 NumInput 的 Templates implicit 不传播问题一并修复（v3 根为 Qool.Controls 的 Button/AbstractButton/Control，implicit 自动传播；拍平件改根 T.* 后 implicit 恒 0——CycleChoice 在 ColorNameList 中塌陷不可见，实测 0×0 → 63×20；ColorNameButton/ChannelBar 消费方给显式尺寸无可见影响，按独立使用自洽原则补齐）
  - CycleChoice：动画按临时件策略全部移除（文字弹跳 BasicTextBehavior、颜色/透明度渐变 Behavior、背景边框色 Behavior、悬停渐变/按下/禁用覆盖层 Behavior 共 7 处）；状态反馈即时到位、无过渡动画；文件头 TODO 补字号备忘（迁入 Controls 时恢复 16px）；QDoc 交互反馈节更新
  - ColorPreviewer：移除 borderBox 边框（迁移时基于错误认知加入的样式功能，违背组件纯预览定位）；QDoc 改述——brief 删"前景色对比"、新增定位段（纯预览元素非完整原件、不提供样式外观、宿主自行包装）；保留专项注释说明移除原因
  - ColorNameButton：互斥逻辑重写——onCheckedChanged 覆盖全部 checked 变化路径（点击 + 程序化写入）、先取消旧选中再更新组引用；onClicked 简化（互斥由 onCheckedChanged 统一承担）；QDoc 补注独占互斥是刻意设计的 UI 模式
  - Page_Color：宽度改为 v4 页面风格——移除全部 width: root.width / parent.width 填满（迁移引入、与 v4 其他页面不一致），面板与控件回落自然宽度（implicitWidth）、面板包装层宽度跟随面板（width: \<panel\>.width），SectionBar 保持全宽；文件头 QoolTip 布局注释重写为准确机制（检测层 + GlobalChatRoom 驱动 + z:-1 光标优先级；包装层与 z:-1 保持，移除有光标回归风险）；四个面板的结构与 z:-1 全部保持
  - 文档落档：qoolcolor.qdoc 新增前景对比色归属说明（v4 无独立 foreground token，并入 text）+ 拍平件动画策略说明；HSVSurface 头注释 Style 对位段改述（删除"v4 light 的值恰好等于"旧论证）；ColorBankPanel/ColorNameList QDoc "v3 同构"→ v4 自述（默认状态自洽原则）
  - interfaces/qool_interfaces.qdoc：优先级语义扩充——priority 裁决按接口而定、不可一概而论，每个接口文档必须写明自身裁决语义（实例：ColorNameProvider 为"补充"型）
- QoolUIExample：Page_QoolBox `shape.shapeControl`（双重不存在引用）→ `box_shape.control.dumpInfo()`；Page_InputControls 删除不存在的 valueRole/currentValue（改 `listModel2.get(box3.currentIndex).value`）；PageFrame Loader 加载失败恢复 loadingBar+错误标题（此前进度条永久停留）；Page_Buttons `checkedButton` 空安全；CMakeLists IMPORTS/DEPENDENCIES 补 Qool.Controls/Components/Debug/File；示例资源从错误目标 `Qool` 改挂 `appQoolUIExample`

### 新增

- 误解文档化（刻意设计，防再误判）：Message 拷贝生成新身份（created/messageID 全新，拷贝≠相等是身份语义）；ChatRoom::postMessage 定向发送重载用途；Message::contains 的 AND 全包含+空集通配契约；ChatRoomServer 线程架构（专用线程、BlockingQueued 调用、postEvent 异步投递、外部不可达隔离）
- Button::flat 与 ProgressBar::indeterminate 的 QDoc 设计说明（flat=彻底无背景；indeterminate 运动不随 animationEnabled 门控=模式功能语义）
- 全量 QDoc：QoolCommon sidecar .qdoc（geometry/range_counter/qt_tools/std_tools/lazy_cache/default_variant_map）、Qool.Chat/Qool.File/plugins 全部 C++ 类型、Qool.Controls 全部 QML 类型、Example 页面说明
- AGENTS.md：公开组件默认状态自洽、模型遵循 Qt 线程规范、Debug 边界暴露原则、修复须评估专项注释+刻意设计必须 QDoc 说明

### 文档

- AGENTS.md：信号命名惯例补充——过去式语义（somethingHappened，瞬时状态变化宣告）、Changed 与 Updated 的区分原则（Changed=宏守卫"值实际变化才发"；Updated=手写"更新动作完成即发、不保证值变化"，实例 currentRowUpdated）、wannaXxx→执行槽→xxxChanged 实时接口成对模式、多个变更信号汇聚 when_ 前缀槽；bindable 宏由 QObjectBindableProperty::operator= 内置相等守卫保证（setter 不写守卫是刻意的，勿补勿删）
- QoolFile/AGENTS.md：删除两处「线程安全」表述（模型为单线程契约）
- AGENTS.md：移除「核心库瘦身原则」章节（错误记述——模块/组件取舍是实施时的裁定记录，已降级为 agent 长期记忆，不再作为项目规范约束）
- AGENTS.md：新增「插件约定」——插件优先级统一在插件 json 的 `priority` 字段定义（PluginLoader 从 json 元数据读取，接口不提供 priority 方法）；所有官方插件 json 必须包含该字段
- 新建 `QoolUI/interfaces/qool_interfaces.qdoc`：插件接口组织文档（\page）——接口定位、插件约定（元数据字段 name/author/priority、priority 统一 json 定义且 json 必须包含、接口头不冗余叙述）
- **Qool.Color 模块（新增）**：C++ 类型 ColorAssistant（RGB/CMYK/HSV/HSL 四空间 int/F 双轨全同步）、ColorBank（无界稀疏索引容器 + colorChanged(n) + filledIndexes() 持久化读面）、ColorDB（QML 单例，插件化色名双向查询）、ColorHueCycleModel、RandomHSVColorGenerator、Crystal4ContainmentMask（QQuickItem containmentMask 模式）；公开 QML 九组件：HSVPanel/HSLPanel/RGBPanel/CMYKPanel、ColorQuickPicker、ColorEdit、ColorPreviewer、ColorNameList、ColorBankPanel；_private 拍平件（NumInput/CycleChoice/NumTools.js + 视觉件族 24 件——不注册 qmldir、目录 import 私有机制，将来扩展为完整版进入 Qool.Controls）；插件 colornameprovider_default/commonzh（一插件一目录、json priority 0/-1、commonzh csv 163 色随 qrc 迁移）；示例页 Page_Color（BasicPage/SectionBar/QoolTip 风格，无 Dialog 示范）
- Qool.Color 修复：RandomHSVColorGenerator hue 域映射（0..255 量化域直接映射 0..359 色相参数域覆盖不全 → qRound(hue*360/255) 满环整数路径 + previous 统一 255 域）；ColorHueCycleModel 越界环折返（越界 hue 折回负值致异常色 → math::cycle_in_range 模数回绕）；ChannelSlider 数值输入悬挂引用（未定义 valueLimiter，编辑报 ReferenceError 不更新）→ 修正；ColorBank 刻意不做持久化（宿主三接法：注入前构造填充/监听 colorChanged 纪录/继承仿写）
- Qool.Color 迁移保真排查修复（v3 对照全量审查）：RandomHSVColorGenerator 8 个区间属性静默改名 minX/maxX → 恢复 v3 名 minimumX/maximumX（QML 未知属性赋值静默忽略，v3 消费方写入全部落空；QDoc 仍用 v3 旧名证明改名非有意）；QML 只读属性 previous（默认白色 + previousChanged）静默丢失 → 宏恢复（generate()/check_previous() 同步恢复非 const，与 v3 签名一致）；count() 被改名 combinationsCount() 且公式被改（锁定通道计 0/乘积+1 → 计 1/无+1）→ 恢复 v3 逐字公式；示例页 Page_Color 丢失 ColorBankPanel 的 columns: 4/高度 450 与 ColorNameList 高度 450 实例侧注入 → 恢复（槽位压扁、行数少 2）；NumInput 两处静默偏差恢复——编辑态 activeFocusOnPress true（长按/拖动后 tap 取消场景光标落点）、下划线淡入 Behavior 门控 enabled: root.enabled（v3 无条件运行，动画关闭时仍淡入）
- AGENTS.md：R1 修订——`Qool.Controls` 定为控件基础层（仅次于 Qool，类比 QtQuick.Controls），功能合集模块（Qool.Color/Chat/File/Debug）可依赖 Qool.Controls 及 Components；模块架构图/分层表/URI 表补 Qool.Color
- AGENTS.md：「已知陷阱 4」私有 QML 文件机制扩展——internal 标记（限私有件无互引，Qt 6.11 实证 internal 类型不能被其他 internal 文件引用）与「不注册 + 目录 import」（Qool.Color 采用：私有件不进 QML_FILES、经 qt_add_resources 入 qrc、模块内 `import "_private"` 使用）双机制

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
