[最新变更]

### 变更（debug-facility-rework，QoolCommon 调试设施重写——C++20 函数化 + 宏门控分离）

- **架构分层**：入口宏（`xDebug`/`xInfo`/`xWarning`/`xCritical` + Q 后缀）保留为永久 API——只有宏能在调用点做条件编译与 `this` 注入；实现全部函数化收进 `QOOL_NS::debug`，宏名仅转发。25 个消费文件约 150 调用点零改动
- **Release 门控**：`XDBG_NO_DEBUG`/`XDBG_NO_INFO`/`XDBG_NO_WARNING` 抹除对应入口（同时尊重 `QT_NO_DEBUG_OUTPUT`/`QT_NO_WARNING_OUTPUT`）；抹除态走 `NoDebug` sink 吞掉整条 `<<` 链，包装器不被遍历；`xCritical` 永远编译
- **`xCritical` 修正**：通道由 `qDebug()` 改 `qCritical()`（旧版严重级别信息丢失）；`xFatal` 删除（`qFatal` 无法流式、伪装致命，零调用点）
- **`xDBGList` 泛化**：`Range1D` concept 支持 QList/QSet/QStringList/std::vector/std::set/std::array 等全部一维容器；字符串容器（QString/QByteArray/char 派生值类型）显式排除；输出标签统一 `[List:N]`
- **`xDBGMap` 泛化**：`MapLike` concept 接受 pair-range 或 `asKeyValueRange()` 视图（兼容 Qt 6.11 迭代器行为）；键值宽度保留 16/30 对齐；`[Map:N]` 标签
- **Q 后缀 QGADGET 支持**：实现改模板按 `staticMetaObject` 取类名（旧 QObject 转型收窄了 Theme/Message 等元对象类型的适用面）
- **`xDBGVariant` 修正**：类型名统一走兜底回退（null 值 `???`）、删死色彩宏
- **颜色宏保留**：67 处字面量相邻拼接调用点依赖宏展开，30+ 颜色宏不动
- **新增 `docs/reference/QoolCommon/debug.md`**：入口宏门控矩阵、NoDebug sink、包装器 concept 门禁、Qt 6.11 迭代器事实、Release 启用方式（未在 CMake 自动接线，由构建配置决定）

### 变更（channel-anchor，ColorAssistant 通道锚定——灰轴塌缩根治，ADR-0020）

- **通道锚定模型**（ColorAssistant）：RGBA 单权威 + hue/hsvSaturation/hslSaturation 三锚定坐标；锚更新三分支——显式写总是落锚、有表达跟随真实换算、无表达冻结；hue=-1 从公开契约退役（无彩判定改 `valueF==0 ∨ saturationF==0`）
- **越界语义**：HSV/HSL 双轨越界改钳制/归一化（hue 正模 wrap、其余 clamp，颜色保持有效）；CMYK 与 rgba/cmyk 列表越界仍 Invalid
- **取色表面**（HSVWheel/HSLBox）：交互改 `hsvF`/`hslF` 原子写（单轮广播）；删全部 hue<0 守卫；负 hue 正模归一化替代拒写；HSVWheel 圆心 NaN 防御
- **滑块清理**：ColorChannelSlider/ColorChannelVerticalSlider 删 sat-bump 私写补丁（灰上 hue 直写落锚，无需补偿）

### 变更（colorbank-family，ColorBank API 重做收尾 + 面板重写 + 私有件清理）

- **ColorBank API 重做**：`setColor→setCellColor`、`colorChanged(n)→cellColorUpdated(n)`、`filledIndexes()+color()→validCellIndexes()+cellColor()`；新增可写 `defaultColor`（默认 transparent，未写索引返回之）、只读 `cells`（= max(24, 最大已写索引+1)）；`clear`/`eraseCellColor` 幂等守卫；`setCellColors` 按列表长度整体重建（等于 defaultColor 的项不入 map）
- **信号缺口修复**：补 `defaultColorChanged` 发射；`cellsChanged` 统一为「值变才发」；`validCellIndexesChanged` 在键集变化处发射；`setCellColors` 对「旧键 ∪ 新范围」逐格比较有效色、变化才发 `cellColorUpdated`
- **ColorBankPanel 重写**：删 `colorAssistant` 注入，改 `color` 属性（S/L 槽位读写目标）；`slots→cells`；槽位改 ColorPreviewer 格 + 左右半区 AbstractButton
- **私有件删除**：`_private/ColorBankSlotButton.qml`（面板内联实现后零消费者）、`_private/ColorCursor.qml`（孤儿件）

### 变更（color-name-family，色名按钮族 + ColorHQ 单例面 + 预览迁移）

- **组件族**：新增公开 `ColorNameButton`、`ColorNameButtonSurface`、`ColorNameEdit`（输入经 `ColorHQ.isValidColorName`/`color` 解析回写、非法输入撤回）、`ColorNameListView`；**删除** `ColorEdit`/`ColorNameList` 及其私有件（替代映射：ColorEdit→ColorNameEdit、ColorNameList→ColorNameListView）
- **ColorPreviewer 迁移**：重写为 Shapes 路径四分区预览——背景上下对分 + 内容左右对分（solidColor 实色 / 原色含 alpha），新增 `horizontalRatio`/`verticalRatio`
- **ColorHQ 单例面**：QML 注册名 `ColorNameHQ`→`ColorHQ`；方法面 `names`/`hasColor`/`name` → `colorNames`/`isProvidedColorName`/`colorName`，新增 `isValidColorName`；`QML_EXTENDED(ColorLiterals)` 全量助手直接挂在单例
- **ColorAssistant**：移除 `QML_EXTENDED(ColorLiterals)`——通道字面量整体让渡给 `ColorHQ` 单例
- **ColorChannelEdit**：新增显式 `tagOnTop` + contentItem.states 四态分派；displayItem 水平对齐随 `mirrored` 分派；`ChannelNumText`→`ColorNumText` 改名

### 变更（channel-family-migration，竖直族收口：高亮补遗 + 面板迁移 + 私有件清理）

- **接口**：HSVValue 短标签 VAL→BRIT（C++ 共享查表）；ColorChannelVerticalSlider 边框补 justMoved 高亮（TimerLatch 挂 valueChanged，`Qt.lighter(channelColor, 1.4)` 保持 `Style.movementDuration * 2` 窗口后回落）
- **迁移**：RGBPanel（5 列）/CMYKPanel（4 列）每列换用 `ColorChannelControl { orientation: Qt.Vertical }`（通道映射 Brightness→HSVValue、其余同名常量）——旧列获得键盘步进/点击跳转/RTL/边框高亮
- **清理**：删除私有件 ChannelSlider 基类 + 9 个 per-channel 变体 + ChannelBar + NumInput（消费方清零）

### 变更（colorchannelcontrol-orientation，ColorChannelControl orientation 双布局）

- **接口**：外壳新增 `orientation`（默认 `Qt.Horizontal`）+ 只读派生 `horizontal`/`vertical`
- **实现**：contentItem 换 Loader 双布局组件分派（水平=编辑行上 + 滑块下；竖直=滑块上 + 镜像编辑行下）；子组件经共享 assistant/链持态，销毁重建无状态损失

版本号不随常规修改迭代（当前 4.0.0），仅在正式发布时递增；本文件记录每次修改的内容。

### 变更（colorchanneledit-mirrored，ColorChannelEdit 响应内置 mirrored 镜像布局）

- **决策**：不自声明 `mirrored` 属性——直接消费 Qt 6.11 `QQuickControl` 自带只读 FINAL 属性 `mirrored`（QML 重声明即组件整体 unavailable）
- **实现**：tag/editor 坐标绑定按 `root.mirrored` 取反——水平：editor 贴左、tag 贴右；竖直：editor 在上、tag 堆其下。文字内容/方向/对齐不受影响

### 变更（colorassistant-zero-alpha-retention，ColorAssistant 零 alpha 保通道语义成文）

- **零 alpha 保通道语义成文**：任一写入口写 0 仅透明不丢 RGB、恢复 alpha 即还原原色；全透明态下 solidColor 可取不透明变体、name 保持 #AARRGGBB 报通道；输入字面量 `"transparent"`/`#00000000` 的归零发生在解析侧

### 变更（colorassistant-test-hardening，ColorAssistant 越界语义契约修正）

- **探针实证修正交接假设两处**：`rgbaF` 越界 float **非 Invalid**（extended 接受，isValid=true、分量视图收敛回 [0,1]）；int 列表 hue 位越界**不 wrap** 直接 Invalid（与分量 setter 的 wrap 相反）
- `ColorAssistant.md` Out-of-range 节按实证矩阵补齐缺口（RGB/alpha 分量 clamp、int hue wrap、列表入口三分语义、Invalid 恢复）

### 变更（colorassistant-list-alpha，ColorAssistant 列表 alpha 语义统一为保留）

- **决策（A2）**：6 个无 a 位列表属性（cmyk/cmykF/hsv/hsvF/hsl/hslF）写入统一保留当前 alpha（原仅 `hsl` 带保留，其余 5 个为 v3 修复中断遗留）；rgba/rgbaF 含 a 位语义不变

### 变更（qtquick-panel-fix，Qt Creator 面板 QML 测试识别修复）

- **QML 修复**：20 个 QML 单元各建独立 `CMakeLists.txt`（`qoolui_add_qml_test` 增强为兼容「当前目录即单元目录」/「相对子目录」两用法），CMake `directory` 完全唯一化——Qt Creator 面板可逐测试发现/运行 QML 单元
- **C++ 面板弹窗修复**：`tst_qool_box_hit`/`tst_qool_hover_e2e` 在 `QTEST_MAIN` 前加静态 `qputenv("QT_QPA_PLATFORM","offscreen")`

### 变更（test-facility-reform，测试设施改革）

- **测试单元编写规范重写**（`QoolUITests/AGENTS.md`）：新增单元↔组件一一对应、以参考文档为准绳、不测内部实现四原则 + 写法规则；README 散落约定上收；根 AGENTS 测试节指针同步
- **越界测试清理**（只删不改）：QML 侧 60 个越界测试函数删除（47 纯越界整删 + 13 混合函数整体删）
- **架构改造：每 QML 测试单元独立 target**：共享 harness 废除；20 个 QML 单元各自独立子目录 + 独立 target + `qoolui_add_qml_test()` 辅助函数；批次目录提升顶层
- **红色测试处置**：两个期望 FAIL 测试对应产品缺陷已修复（NumberRanger `format_strings`、Style `set_value` 相等短路），测试直接转绿

### 变更（very-important-block，AGENTS 顶部 VERY-IMPORTANT 强调块）

- **AGENTS 顶部新增 `<VERY-IMPORTANT>` 块**：`[MUSTMUSTMUST]` 注释规则行 ×3、验证分级表 ×5、尾部防删注释——重复声明为刻意强调，非冗余

### 变更（verification-tier-top，验证分级模型提升为顶层规则）

- **AGENTS 第二行新增验证分级表**：注释/文档/无逻辑重命名 → 代码走读；纯 QML 行为改动 → 用户运行验证或单测试；构建结构改动 → build；完整落地一套修改 → build + 全量 ctest
- **后部「验证策略」章节去重**：分级模型表移除，仅保留行为规则并指向顶部

### 变更（colorchannel-comment-cleanup，ColorChannel 两 Slider 家族注释清理）

- **全删废话注释**（新 AGENTS 首行规则执行）：两 Slider 家族及全部关联元素（Track 双件、Colors 双 JS、旧竖直族）注释大幅精简——删除定位叙述/历史沿革/ADR 引用/自解释重复，仅保留「看不懂会误改」的必要点

### 变更（agent-comment-rule，AGENTS 首行注释硬规则）

- **新增规则**（AGENTS.md 第一行，`[MUSTMUSTMUST]`）：代码注释不允许写废话，每个代码文件中的注释内容不能超过该文件的 5%

### 变更（colorchannelverticalslider-fixes，VerticalSlider 手柄鼠标图标 + hue 填充正常色）

- **手柄鼠标图标**：ColorChannelVerticalSlider handle 新增 MouseArea（objectName "handleCursorArea"，acceptedButtons NoButton 不拦截模板拖动），cursorShape 随方向切换（SizeHorCursor / SizeVerCursor）
- **hue 填充正常色**：HSVHue/HSLHue 前景填充主色 = 色相正常值 `hsva(value,1,1,1)`（固定 sat/lightness = 1，仅随 position 变化）——填充与背景原理式有意分叉；非 hue 填充不变

### 变更（colorchannelverticalslider-orientation，ColorChannelVerticalSlider 水平形态 + ColorChannelSlider 显式锚定——ADR-0018 实现演进）

- **ColorChannelVerticalSlider 双形态**（orientation 默认 `Qt.Vertical`，不改名）：填充锚定值 0 端沿值增大方向生长；α 渐变沿生长轴；hue 彩虹沿值方向（垂直与水平 RTL 反排、水平 LTR 升序）——`Gradient.orientation` 实现，采样不变式零成本保留
- **ColorChannelSlider 显式锚定** `orientation: Qt.Horizontal`

### 变更（colorchannelverticalslider，ColorChannelVerticalSlider 竖直通道滑块组件）

- **新增公开组件 ColorChannelVerticalSlider**（Qool.Color）：竖直单通道滑块——T.Slider 独立实现（不继承 ColorChannelSlider），迁移 `_private/ChannelBar` 填充条视觉（圆角 5/4、从底部填充、身份色渐变、justMoved 1s 高亮、无 hover、无可见手柄）；链模型照搬 ColorChannelSlider（PropertyProxy 无条件双向 + clamp + sat-bump + hue<0 守卫 + 播种 + 同值收敛）；hue 彩虹原理式跟随；填充 = 轨道在填充顶边的采样色
- **新增** `_private/ColorChannelVerticalTrack.qml` + `_private/ColorChannelVerticalColors.js`；CMake QML_FILES 注册公开件

### 变更（numtools-removal，NumTools.js 移除——功能并入 Qore.bound / ColorNameHQ.formatChannelNumberFloat）

- **删除 `_private/NumTools.js`**：`limitNumber` → `Qore.bound`（语义等价）；`simplifyChannelNumber` → `ColorNameHQ.formatChannelNumberFloat`（四输出同款）；`mapNumber` 无消费方随文件删除
- **消费方迁移**（4 文件）：ChannelSlider（×2）、ColorNameView（×2）、HSVSurface、HSLBox——公开组件不再依赖私有 JS 工具

### 变更（hslbox-public，HSLBox 公开化 + HSLPanel 接线——票 05）

- **新增公开组件 HSLBox**（Qool.Color 一级组件）：HSL 二维取色表面，单向链架构对齐 HSVWheel——矩形平面响应鼠标取色（`saturation`/`lightness` 同时写），`hue` 外部/联动驱动；三属性 `hue`/`saturation`/`lightness` 双向接口；写入钳制两路（hue 越界不写/圆周归一化、sat/ltn clamp）
- **HSLPanel 改引用公开 HSLBox**：删 `import "_private"`
- **清理**：删除旧 `_private/HSLBox.qml`（交互映射迁移进公开件，reset/双击随契约裁剪移除）；`HSLSurface` 保持 `_private` 不动

### 变更（colorcursor-hsvwheel，ColorCursor 组合件 + HSVWheel 接线 + 清理——票 04）

- **重写 `_private/ColorCursor.qml` 为组合件**（ADR-0016/0017）：CrystalCursor + CenterPlacer + TimerLatch——HSV/HSL 两表面共用取色光标；契约对齐旧 HSVWheelCursor（animationEnabled 父链继承 / currentColor / userInteracting / centerx / centery / size / expandDelta）
- **HSVWheel 改引用 ColorCursor**：删除 latchTarget 与 centerx/centery 绑定，改事件驱动 `updateCursor()`；objectName "wheelCursor" 保留
- **清理**：删除 `_private/HSVWheelCursor.qml`、`_private/ColorCrystal.qml`、`qool_crystal4containmentmask.{h,cpp}`（CMake SOURCES + reference + index 同步）

### 变更（open-interface-resync，CenterPlacer target 切换 / ItemAnimatedResizer enabled 恢复就位）

- **CenterPlacer target 切换（开放接口）**：运行中换挂载对象 → 从新 target 现读同步 center（旧值不残留）；Connections 自动转移；从 null 挂上同理
- **CenterPlacer 封装收口**：同步函数收进内部 `pCtrl`；自身信号监听一律 Connections 独立对象
- **ItemAnimatedResizer enabled 恢复就位**：恢复 enabled 时按当前 resized 就位一次（动画路径，未变时 no-op）

### 变更（color-cursor-chain，取色光标骨架收束 + 两 Slider 手柄内联）

- **新增 `CenterPlacer`**（Qool 几何挂件，ADR-0015）：`centerx`/`centery` ↔ `x`/`y` 双向同步（w/h 参与换算），任意带 x/y/w/h 的对象可挂载；同值守卫断环、target null 安全
- **新增 `CrystalCursor`**（Qool.Controls.Components 基准件，ADR-0016）：延迟缩放行为能力——`expanded` 唯一行为输入（置 true 立即展开、置 false 经防抖窗口回落）；内部 `Qool.Crystal` 菱形（自带精确 contains 命中域）
- **两 Slider 手柄内联 CrystalCursor**：`Qool.Controls.Slider` handle 与 `ColorChannelSlider` handle 均改内联；删除 `_private/ColorChannelSliderHandle.qml`
- **`ItemAnimatedResizer` 初始就位修复**：初始绑定 `resized=true` 不再停在收缩态——新增 `first_time_ensure()` 构造后按 resized 当前值跳变就位

### 变更（hsvwheel，HSVWheel 二维取色表面公开组件 + 单向链架构）

- **新增公开组件 HSVWheel**（Qool.Color 一级组件）：HSV 二维取色表面——色轮响应鼠标取色（`hue`/`saturation` 同时写）、`value` 驱动圆盘压暗层（alpha = 1 - value）、单向链驱动架构；三值双向属性 `hue`/`saturation`/`value`；写入钳制两路（hue 越界不写、sat/value clamp、hue>1 圆周归一化）
- **新增 `_private/HSVWheelCursor`**：`Qool.Crystal` 菱形 + 三态展开（hover/userInteracting/值变化锁存 TimerLatch）+ HoverHandler；定位单向派生
- **HSVPanel 改用公开 HSVWheel**；旧 `_private/HSVWheel.qml` 删除；`_private/HSVSurface` 新增 `darkAlpha` 只读派生

### 变更（hsl-hsv-panel-colorchannel，HSL/HSV 面板通道行迁移到新版三件套 + 旧水平族废弃）

- **HSL/HSV Panel 通道行替换**：顶部数字输入行 → `ColorChannelEdit`；底部滑块 → `ColorChannelControl`
- **删除旧水平滑块族**（替换后无引用）：`ColorSlider.qml`（基类）+ `ColorSlider_Hue/Value/Alpha.qml` + `ColorSliderBackground.qml`——5 文件删除

### 变更（colorchannelcontrol，ColorChannelControl 单通道组合行组件）

- **新增公开组件 ColorChannelControl**（Qool.Color）：Control 基座组合 ColorChannelEdit + ColorChannelSlider，contentItem ColumnLayout 竖直堆叠；集束共有属性 `animationEnabled`（显式 root 转发）/`channel`/`colorAssistant`（单一共享实例——集束不变量）/`value`（外壳自持第三投影，非 alias）/`readOnly`；纯封装——不暴露 edit/slider 子组件别名
- **ColorChannelEdit 扩展**：新增 `readOnly` 属性转发内部 EditableText

### 变更（slider-track-both-axes，Slider/RangeSlider 轨道双向收缩）

- **轨道几何改双向收缩**：Slider/RangeSlider 默认轨道由「主轴铺满 + 法向收缩居中」改为**宽高双向各收缩 shrinkSize + 双向居中**——收缩态 handle 与轨道贴边对齐
- **锁存间隔跟随 Style.movementDuration**：TimerLatch `interval` 由固定 500ms 改为 `Style.movementDuration × 2`——锁存窗口随主题运动时长缩放

## [4.0.0] — 2026-08-21

### 变更（colorchannelslider，ColorChannelSlider 通道滑块组件）

- **新增公开组件 ColorChannelSlider**（Qool.Color，ADR-0013 高定）：通用单通道（`channel: int` 覆盖 14 通道枚举）；`value ↔ PropertyProxy ↔ colorAssistant` 无条件双向链（同值守卫收敛、onCompleted 播种）；sat-bump；[0,1] 裁剪（旧环绕废弃）；无 defaultValue/reset/双击重置；模板级 background/handle 插拔是唯一外观接口
- **_private 视觉件**：`ColorChannelSliderTrack`（Crystal 六边形双色轨道 + 自动对比描边 + 收缩模型）、`ColorChannelSliderTrackHue`（彩虹覆写 11 档）、`ColorChannelSliderHandle`（共享光标三态展开）、`ColorChannelSliderColors.js`

### 变更（geolocker，Qool.GeoLocker 几何锁定器）

- **新增 Qool.GeoLocker**（SmartObject 便捷工具，非 Item 容器）：target 的 x/y/width/height 锁定跟随 lockTo——总开关 enabled + 四维度独立开关；target/lockTo 可为任何带四属性的对象；内置四个 Binding（开关门控）
- **首个消费方——EditableText displayItem**：displayItem 内 GeoLocker 四维锁定到 contentItem（几何统一由 GeoLocker 承担）

### 变更（channelnumtext-unify，ColorChannelEdit 文本组件统一）

- **新增 `_private/ChannelNumText`**（拍平件）：通道标签与数值显示的统一文本组件——字体来源统一 `PixelFont.normal` 防漂移；透明即隐藏
- **ColorChannelEdit 重构**：标签与 displayItem 均换 ChannelNumText；编辑框宽度 FontMetrics 锁定 4 字符（显示形态最长 `.xxx`，宽度稳定不跳动）

### 变更（colorchannel-format-parse-unify，归一化通道值 format/parse 统一到 ColorLiterals）

- **formatChannelNumberFloat 重构**：刻意仅 '0'/'1'/'.xxx'/'NaN' 四种输出——显式 NaN 分支；round 到 1000 归 '1'、round 到 0 归 '0'（修复千分位边界）
- **新增 parseChannelNumberFloat**：清洗输入 → 无小数点头部补点（整数按纯小数解释）→ 解析——与 format 配对
- **两处组件方法重构为委托**：NumInput.parseChannelValue 与 ColorChannelEdit 统一走 `ColorNameHQ.parseChannelNumberFloat`（行为变化："5" → 0.5、"1.5" → 1.5、"1500" → 0.15）

### 变更（colorchanneledit-displayitem-validator，ColorChannelEdit 显示解耦 + 输入校验）

- **显示层重构（displayItem 覆写）**：显示从「劫持 editor.text」改为覆写 EditableText.displayItem——显示直连真实源 format(proxy.value)，text 退化为纯保存形式
- **输入校验（validator）**：RegularExpressionValidator 正则 `^[+-]?(\d+(\.\d*)?|\.\d+)$`——允许无前导零、拒绝空串/非法/科学计数法；非法输入收尾 rejected（不写 text）→ 显示自然回位
- **EditableText.md 文档补充**：displayItem 条目新增「Design intent」段

### 变更（colorchanneledit-sync-tests，ColorChannelEdit 同步重构 + Qool.Color 测试批次）

- **ColorChannelEdit 同步架构定案**：`value ↔ colorAssistant` 无条件双向同步——`value` 为组件源/唯一写入口，`proxy` 仅承担 `channelNameF` 动态寻址桥
- **修复三处确定性缺陷**：首帧空白（显示改声明式 Binding 读真实源 + onCompleted 播种）、收尾不回位（textFromEditText 返回规范化串）、解析语义（改仓库 `parseChannelValue` 约定：x>1 → /1000、限幅 [0,1]、NaN 透传）

### 变更（cpp-conventions + qool-final-removal，C++ 惯例落盘 + 全 Qool 去 FINAL + PropertyProxy 合规）

- **AGENTS 编码规范新增惯例（MUST）**：惯例定义（仅 AGENTS 列出的才是惯例）/成员声明处 `{初始值}` 初始化/命名风格补 `m_camelCase` + `bindable_camelCase`/Q_PROPERTY 集中声明/调试信息用 xDebug 宏
- **全 Qool 去 FINAL**（回到稀疏 FINAL 库基线）：8 类「所有属性全 FINAL 且 class 非 final」去 FINAL（NumberNotifier/ShapeControl/ShapeControlGadget/OffsetProjector/CircleGadget/CirclePoint/QoolBoxGadget/ColorMapperStop/NumberMapperStop）
- **PropertyProxy 合规调整**：value/五能力/宏属性去 FINAL；`m_interval = -1` 改 `QBINDABLE_SET_VALUE`；成员声明处花括号初始化

### 变更（propertyproxy，PropertyProxy 无状态属性代理）

- **新增 PropertyProxy**（Qool 模块 C++ QML 类型）：`target` + `property` 桥接任意对象属性，暴露 `value` 作为**无状态代理**——getter 现读、setter 直写，无内部存储、数据源唯一（ADR-0012）
- **双路径同步（读方向）**：观测建立立即 read 一次；有 NOTIFY → 事件驱动；无 NOTIFY → 轮询（`interval` 三态：<0 不轮询 / =0 周期零定时器 / >0 固定间隔）
- **净化可写性 + 五能力**：`isWritable` 单一条件；isReadable/isWritable/isConstant/isResettable/isBindable 只读随观测刷新
- **无效态**：target null / 属性无效 / 不可读 → value 无效 + 能力全 false + 不连信号不启动定时器；target 先析构安全

### 变更（style-design-article，Style 设计原理深度文章）

- **新建 `docs/articles/style-design.md`**：从「为什么」与「怎么用」角度记述样式体系——核心设计决策、实现技术、亮点用法、心智模型三原则、演进记录；`style-system.md` 增互链

### 变更（style-contract-tests，Style 行为契约锚定——修复两处真实缺陷）

- **行为契约锚定**（style-system.md「行为契约」节）：12 条可证伪契约 C1-C12（传播构造/覆盖持久/主题边界/相等赋值不刷新/覆盖不传播/组切换/附加树连通/修改键/Theme 查找/ThemeDB/follow/组面读写），文档与测试一一对应
- **修复 C3 主题边界疏漏**：`set_theme` 置 `m_explicitTheme` 主题源标记；`inherit` 开头检查显式源节点拒绝父级传播——祖先 theme 变化在边界处断裂
- **修复 C4 set_value 相等守卫笔误**：`m_activeData == value`（整表与单值比较恒 false）→ `m_activeData.value(key) == value`——相等赋值短路、不再发多余信号

### 变更（style-docs，Style 体系文档化 + 机制注释）

- **新建 `docs/reference/Qool/Style.md`**：5 节完整参考——三层设计（组数据 + typed 属性 + 主题绑定）、读/写不对称语义、`follow`/`animationEnabled`/组面、信号机制
- **深化 `docs/articles/style-system.md`**：补数据流全链、继承/传播机制、currentGroup 推导、修改追踪与宿主注入契约、通知机制、已知缺口与陷阱
- **机制注释**（qool_style.h/cpp、qool_theme.h/cpp、qool_stylegroupagent.h、QoolPalette.qml）：类级设计说明 + 关键机制点状注释
- **发现并记录三处既有缺口**（未改动行为）：QoolPalette 引用不存在的 `Style.*.brightText`、system 主题常量缺 `infoColor`、`Style::find_children` 递归累加被丢弃

### 变更（adr-timeliness，ADR 时效性总体规则）

- **根 AGENTS.md 工作流约定新增「ADR 时效性（MUST）」**：ADR 是决策锚定、优先级最高——任何讨论/修订/决策之后、动手实施之前，先检查相关 ADR 是否需要同步调整

### 变更（verification-strategy + test-facility-friction，验证策略分级 + 测试设施整改）

- **根 AGENTS.md 新增「验证策略」节**：验证强度随改动类型分级（注释/文档→走读；纯 QML/行为→用户运行验证或针对性单测试；构建结构→编译；完整落地→build+全量 ctest）——**全量编译+测试非默认动作**
- **构建脚本透传 bug 修复**（qoolui_build_windows.py / qoolui_build_linux.py）：`args.extra = [a for a in unknown if a != "--"]` 用 `unknown` 覆盖了 argparse 已收集的 positional 透传参数——改 `parse_args` + 直接使用 `args.extra`（透传须前置 `--` 分隔）
- **QoolUITests/AGENTS.md**：输出验证改通道分级（可靠 = eval 内核 python subprocess + 文件重定向 / 真实终端）；测试工作流改分级；补三条摩擦规避

### 变更（verticalslider-removal + adr-reconcile，VerticalSlider 完全移除 + ADR/文档记述校对）

- **VerticalSlider 完全移除**：删除组件、模块注册、reference 文档、示例页引用——独立实现与 Slider 家族架构割裂，竖直需求由 Slider `orientation: Qt.Vertical` 正交适配承担（ADR-0010）
- **ADR 演进校对**：0009/0010/0011 追加「实现演进（2026-08-21）」段

### 变更（slider-style-color-unification，Slider/RangeSlider 三色属性删除——配色统一走 Style）

- **删除三色实例属性**（Slider/RangeSlider）：`color`/`backgroundColor`/`borderColor`——配色统一走统一样式接口 Style（附着传播换色）；轨道渐变 from 端 = `Style.buttonText` 75% 透明、to 端 = `Style.accent`；描边 = `ThemeHQ.recommendForeground(Style.buttonText)`
- **手柄采样监听改 Style 传播**：Crystal 内独立只读哨兵属性（`_accentWatch`/`_textWatch` 绑定 Style）+ onChanged 捕获附着传播变化触发重采样
- **AGENTS.md**：QML 组件规范新增「animationEnabled 声明序（MUST）」——控件声明 `animationEnabled` 必须置自定义属性第一位
- **API 破坏**：三色属性删除——宿主经 Style 附着属性换色；描边不再可单独定制

### 变更（controls-focus-highlight，Qool.Controls 焦点高亮）

- **焦点高亮行为**（Slider/RangeSlider/Dial）：控件获得键盘焦点（`root.visualFocus`）时默认 `background` 外边框切换至 `Style.highlight`、失焦恢复——内联条件绑定，不引入叠层；切换经 `BasicColorBehavior` 门控 `animationEnabled`
- **聚焦色硬编码 `Style.highlight`**：不设独立属性/opt-out 接口
- **Dial 新增 `animationEnabled`**：`parent?.animationEnabled ?? Style.animationEnabled`
- **范围**：仅 Slider/RangeSlider/Dial；可聚焦性不默认开启（`activeFocusOnTab` 由宿主按 Qt 标准方式启用）

### 变更（rangeslider-orientation-rtl，RangeSlider 对齐 Qt 官方 orientation×RTL 正交统一）

- **法向尺寸抽象 `side`**（RangeSlider）：轨道/前景收缩、窄条换向全部基于它（横竖对称、镜像无关）；`shrinkSize` 基准 `root.height` → `side`
- **background implicit 随 orientation 交换**：150×25 ↔ 25×150
- **双 handle 窄条换向 + 双分支定位**：水平竖条 ↔ 垂直横条；不相交公式随轴换；光标随轴向（SplitHCursor ↔ SplitVCursor）；RTL 由模板免费承载
- **rangeBox 区间盒跨轴统一**：主轴起点 = min(first.vP, second.vP) × 行程、跨度 = |second.vP − first.vP| × 行程 + 尖角余量（附带修复 RTL 下区间盒负宽）

## [4.0.0] — 2026-08-20

### 变更（build-auto-configure + tests-agents，build 自动前置 configure + 测试设施规范补充）

- **build 命令自动前置 configure**（`Scripts/qoolui_build_common.py`）：每次编译前先 `cmake --preset dev-<kit>-<type>` 空跑——glob 结果与文件列表在每次构建前重新求值；QT_DIR 从 CMakeCache 回读
- **QoolUITests/AGENTS.md 补充测试设施规范**：QML 测试文件运行期扫描加载（改 `tst_*.qml` 无需重链）；「输出验证」小节（Qt Test 结果走 stdout、Qt 消息走 stderr）

### 修复（dial-valuecolor-source-follow + rangeslider-foreground-color，Dial 采样色跟随 + RangeSlider 前景色接线）

- **Dial valueColor 源色不跟随修复**：C++ 方法绑定改手动驱动——`Component.onCompleted` 初始采样 + 信号 connect 四源（positionChanged/highColorChanged/midColorChanged/lowColorChanged → `updateValueColor()`）
- **RangeSlider 前景色接线**：`rangeCrystal` 补 `color: root.color`（此前前景恒 Crystal 默认色、宿主设置无效）

### 修复（slider-handle-sample-frozen，Slider 手柄采样冻结缺陷）

- **Slider 手柄采样冻结修复**：handle 色改 handle 侧驱动——`Component.onCompleted` 初始采样 + 信号 connect 三源（positionChanged/colorChanged/backgroundColorChanged → `updateColor()`）；初始正确 + 运行时源色变化实时跟随

### 变更（slider-orientation-rtl，Slider 对齐 Qt 官方 orientation×RTL 正交统一）

- **法向尺寸抽象 `side`**（Slider）：手柄边长/收缩量/轨道收缩/展开全部基于它
- **handle 官方双分支定位**（水平 x 由 visualPosition 驱动、垂直 y 由 visualPosition 驱动）；轨道双分支（沿主轴铺满 + 法向收缩居中）
- **渐变锚定值增大端**：水平 LTR 左→右、RTL 右→左；垂直 from 底→to 顶（不受 RTL 影响）
- **采样改 `position`**（不镜像）——RTL 下采样错位修复；**implicit 随 orientation 交换**（150×25 ↔ 25×150）；**光标随轴向**

### 变更（slider-background-resizer-align，Slider 对齐 RangeSlider 架构演进）

- **Slider 改标准 background 驱动尺寸**：删除 root 直接默认尺寸与外部 Binding，改自写 implicit 公式 + background 显式 implicit（150×25）——替换新实例同样受控
- **RangeSlider 默认尺寸统一 150×25**（background implicit 200×22 → 150×25）
- **Slider handle 改用 ItemAnimatedResizer**（删除 BasicNumberBehavior）；**锁存内化 + 接口移除**：删除公开属性 `justMoved`/`valueVelocity` 与 NumberNotifier
- **禁用冻结**：cResizer 接 `enabled: root.enabled`——禁用时手柄整体静止

### 变更（rangeslider-enabled-gate + itemanimatedresizer-docs）

- **RangeSlider 前景 resizer 接 `enabled`**：禁用时值变化锁存不再展开前景，hover/光标/展开动画同受门控（禁用即整体静止）
- **ItemAnimatedResizer 修复后退方向误引用前进模板**：`backwardAni` 原取 `templateFowardAni`（复制笔误）→ 改取 `templateBackwardAni`；`go_backward` 动画门控检查同步改查后退模板

### 变更（rangeslider-template-handle，RangeSlider 回归模板 handle 体系）

- **决策反转**：删除 RangeHandle 自建三区交互体系（DragMoveArea → 意图信号 → 宿主换算），组件内设置 `first.handle`/`second.handle` 默认 handle 激活模板状态机——snap/live/键盘/nearest/端点钳制全部模板行为（零自建）
- **handle 窄条 + 不相交定位**：窄条宽度 = availableHeight/2，定位行程 = availableWidth − width×2（任意值下两 handle 永不相交）；`z:10` 盖在 contentItem 之上
- **前景入 contentItem**：`surface` 属性**删除**——前景（Crystal）直接置于 contentItem 内 `rangeBox` 区间盒；hover 展开由 HoverHandler + ItemAnimatedResizer 驱动；锁存移除（`firstJustMoved`/`secondJustMoved` 删除）
- **API 破坏**：`rangeHandle` 属性、`RangeHandle` 类型、`surface` 属性、`firstJustMoved`/`secondJustMoved` 全部删除；行为插拔点 = `first.handle`/`second.handle`

### 变更（slider-align，Slider 对齐 RangeSlider 接口面演进）

- **RangeSlider `bgColor` 更名 `backgroundColor`**
- **Slider 新增外观通道**：`color`（渐变右端色）/`backgroundColor`（渐变左端，轨道 75% 透明渲染）/`borderColor`（轨道描边，自动对比推荐）；轨道渐变左端由 `Style.text` 改为 `backgroundColor` 75% 透明
- **`preferredHeight` 公开属性移除**：改为默认 handle 与 background 的内部配套约定
- **`encountered` 更名 `expanded`**（与 RangeSlider surface 命名统一）

### 变更（rangeslider-interface-landing，RangeSlider/RangeHandle 接口面落地演进）

- **RangeHandle 收敛为纯交互件**：删除全部位置/外观输入——三区各为独立 DragMoveArea 发意图信号 `wannaMoveFirstX`/`wannaMoveSecondX`/`wannaMoveRangeX`（载荷 = 像素增量位移）；新增热区扩展、光标 alias、`down`/`hovered` 聚合
- **RangeSlider 区间盒几何**：值→位置映射收敛为 `dummyRangeBox` 区间盒（x/width 经 Binding 组施加）；端点/整体钳制在值域（`first ∈ [from, second.value]`、`second ∈ [first.value, to]`）
- **色彩通道 + 外观**：`color`（前景填充）/`bgColor`（轨道背景，75% 透明渲染）/`borderColor`（自动对比推荐）；前景 Crystal 尖角外溢；surface 自布局（默认 `anchors.fill` 区间盒）
- **锁存分化**：`justMoved` → `firstJustMoved`/`secondJustMoved`（两端独立 500ms 窗口）

### 变更（rangeslider-three-layer，RangeSlider 三层重构实现落地）

- **新组件 `Qool.Controls.RangeHandle`**（Item 基座）：区间逻辑单一归属——输入 firstPosition/secondPosition/cutSize/preferredHeight/externalExpanded/color/animationEnabled；信号 firstMoved/secondMoved/rangeMoved；surface 布局经动态 Binding 施加（宿主替换 surface 时新实例同样受控）；可独立实例化
- **RangeSlider 重构为三层**：模板 + 静态 Crystal 轨道 → 内置 RangeHandle（`rangeHandle` 属性——宿主继承替换即行为插拔）→ surface（默认 Crystal 整体前景，端点重合自动退化菱形）；值→位置映射留在 RangeSlider；三区域交互（左拖 first/右拖 second/中拖整体滑移）

## [4.0.0] — 2026-08-19

### 变更（rangeslider-three-layer-design，RangeSlider 三层重构设计决策落地）

- **ADR 0009**：RangeSlider 重构决策落定——三层结构（静态背景轨道 + RangeHandle 独立组件 + surface 外观插拔件），整体 Crystal 前景取代双手柄；三区域分区交互；保留 T.RangeSlider 模板与 API
- **FIXME 清理**：Slider.qml 移除 2 处、RangeSlider.qml 移除 2 处（对应议题经裁决取消）；VerticalSlider 重构 FIXME 保留

## [4.0.0] — 2026-08-19

### 新增（cut-sizes-locker，QoolBoxSettings 四切角统一联动插件）

- **CutSizesLocker**（Qool 模块，`QoolBoxCutSizesLocker` 继承 SmartObject）：`QoolBoxSettings` 专属插件——启用期四角切角统一为 `cutSize`；停用恢复进入锁定前一刻的快照；五条变更路径汇聚到同一统一逻辑；快照时机 = 进入锁定状态瞬间；构造时 parent 为 QoolBoxSettings 自动挂接，否则 target null 安全空转

## [4.0.0] — 2026-08-17

### 变更（comment-cleanup，全仓库违规注释清理）

- **清理标准**：注释非 ADR/非工作记录/非文档/不替代代码结构——决策史、迁移记录、排错史、验证史、日期、成篇论述、v3 对比、spec/票死引用、注释掉的死代码一律移除
- **Qool 核心组件头部精简**（HalfCrystal/Crystal/Slider/RangeSlider/VerticalSlider）：成篇论述头部 → 3-5 行定位 + reference 文档指引
- **QoolColor 迁移记录全清（32 文件）**：`NOTE(迁移)` 头部整段删除；`v3 行为照迁/原样` 等 368 处 v3 对比清零；陷阱约束保留
- **QoolControls 日期与决策措辞、C++ 注释措辞、QoolUITests/QoolUIExample**：工作记录/日期/排错史删除，保留原因/结论

### 变更（norms-system-landing，规范体系重设计落地）

- **根 AGENTS.md 重写为 12 节**：文档地图/定位/模块架构/技术栈约束/构建命令/编码规范/QML 组件规范/注释与文档规范/测试/工作流约定/已知陷阱/变更记录
- **ADR 迁移到严格模块粒度**：`docs/adr/qoolbox/0002-0008` → `docs/adr/QoolUI/Qool/`；`architecture/0001` → `docs/adr/QoolUI/`；ADR README 重写（两级布局 + 全局流水号约定）
- **QDoc → Markdown 迁移**：13 个 `.qdoc` 全部删除，转换 14 个目标文件（reference + articles）
- **docs/agents 三件套更新**：issue-tracker/domain/triage-labels
- **子/模块 AGENTS**：QoolUITests 新增工作流节；新建 QoolUIExample/AGENTS.md、QoolDebug/AGENTS.md；QoolFile 引用修正

### 变更（qdoc-residue-cleanup，源码 QDoc 注释块全面迁移）

- **源码 QDoc 注释块迁移（107 文件全清）**：公开类型成篇文档完整迁移为 `docs/reference/<模块>/<类型>.md`（英文、Qt 官方风格、MUST 5 节）；_private 与纯 C++ 内部类 QDoc 块转为普通简体中文注释
- **reference 文档新增 68 篇**（Qool 25 / Qool.Chat 5 / Qool.Color 15 / Qool.Controls 15 / Qool.Debug 3 / Qool.File 8）；Qool.Chat/Controls/Debug/File 新建 index.md
- **悬空引用清理**：宏头文件「详细文档见 .qdoc」→ reference 文档；源码「见 QDoc」→「见 reference 文档」

### 修复（halfcrystal-style-channel-implicit-loop，Shape 作 contentItem 的收敛反馈环）

- **Shape 作 contentItem 的收敛反馈环修复**（Page_HalfCrystal）：contentItem 改为定尺寸 Item（implicit 100×100），HalfCrystal 作其子项 `anchors.fill` 跟随内容区——控件读稳定 implicit 而非 Shape 动态 implicit，环在接缝断开

## [4.0.0] — 2026-08-14

### 新增（rangeslider，Qool.Controls.RangeSlider 区间滑块）

- **RangeSlider 组件**（`T.RangeSlider` 模板根）：轨道 = Crystal 六边形基底（Style.text，无渐变）；已选段 = 平切矩形（color 默认 Style.accent）；手柄 = HalfCrystal 三角形（first direction W 尖朝左 / second direction E 尖朝右）；展开反馈照 Slider 核心（hover/按下/justMoved 锁存 → 展开到控件全高）；锁存 = TimerLatch + 双 Connections（不暴露 valueVelocity）；已选段几何 x/右缘 = 两手柄中心线（值相等退化 = 宽 0 + 两三角重合成菱形）
- **示例页**：Page_InputControls2 加「RangeSlider 区间滑块」组

### 变更（spinbox-halfcrystal-indicator，SpinBox 指示器换 HalfCrystal + BasicArrow 删除）

- **SpinBox up/down 指示器：BasicArrow → HalfCrystal**：direction E/W、显式 12×12（与原指示器同尺寸，位置公式不变）
- **BasicArrow 删除**：组件文件 + QoolControlsComponents CMake 注册清理；BasicRotationBehavior 零内部引用但保留（Qool 公开类型）

### 变更（halfcrystal-shape-redesign，HalfCrystal 重做 + Crystal 描边属性公开）

- **HalfCrystal 重做**：根组件改为 **Shape 根**——pCtrl 升级为 ShapeControl 实例，内建三个内描边中间量 + 八点模型（外四点 + 内四点）；渲染 = 双层内描边模型（外路径 borderColor 描边环 + 内路径 color 填充面）；五形态经 states 定义（菱形默认 + N/S/W/E 四态）；Transition 动画后移除（point 多分量值属性插值不可靠）
- **HalfCrystalGadget 删除**（公开类型移除）：源文件 + 注册 + 测试全量清理
- **命中掩码 = gB**（RectGadget 数值矩形 contains，非 FillContains）；宿主 MouseArea 精确 hover 需显式挂载
- **Crystal/HalfCrystal 公开属性调整**：`strokeColor` → `borderColor`；新增 `borderWidth`（默认 1）；borderWidth < 1 不描边（阈值语义）
- **RectGadget x/y 取消默认绑定 target 位置**（固定 0，本地画布坐标）；派生几何单一数据源 rect（九点/半区/maxInnerSquareRect 统一基于 rect 计算）

### 变更（build-dir-parent，构建目录归置 build/ 之下）

- **构建产物目录移入 `build/` 之下**：`build-<kit>-<Type>/` → `build/build-<kit>-<Type>/`——CMakePresets.json 六处 preset 的 `binaryDir` + 脚本 `build_dir()` 两处硬改动，文档同步；旧根级构建目录为 gitignored 遗留

### 变更（crystal-octagonshape-refactor，Crystal 重构为 OctagonShape 特化）

- **Crystal 重构**：根组件改为 **OctagonShape 特化**——内部注入 QoolBoxShapeControl + QoolBoxSettings 特化（四角 cut 恒绑定 shortEdge/2）；三形态即 QoolBoxGadget cut = shortEdge/2 特化；公开面 color/strokeColor/fillGradient/fillItem/掩码契约保留；cutSize 不作公开接口
- **fillGradient 补面**：OctagonShape/OctagonCurvedShape 补 `fillGradient` alias；QoolBox 补公开 `fillGradient` 属性（ShapeGradient 类型）
- **CrystalGadget 删除**（公开类型移除）：掩码契约由 QoolBoxShapeControl::contains 承接

### 变更（qoolbox-shapecontrol-redesign 执行，spec D1-D8）

- **QoolBoxShapeControl 重写（gadget 化，ADR-0004/0006/0007）**：内部替换为两个 QoolBoxGadget（outer borderWidth 0 + inner borderWidth=settings.borderWidth）；转发 ext*/int* 16 点（坐标系改为 target 内部坐标绝对点）；*Space 新公式；contains；settings 类型改 QoolBoxSettings*（单一类型）且同步用信号连接；删除旧面 safe*/intPolygon/extPolygon 等
- **QoolBox 公开面**：settings/control/*Space 四属性/fillItem/animatingHint；撤销 cutSize/curved 别名；退行 rectShape 内联（fillItem 非空排除退行）
- **变体改造（低级组成件）**：OctagonShape/OctagonCurvedShape `required property control` 注入、不持有几何；直角变体 containmentMask: control（ShapeContainmentMask 删除）；圆角变体 FillContains
- **QoolBoxHud（Qool.Debug，原 OctagonShapeHud 重定位，ADR-0008）**：`property QoolBox box: parent`，读 box.control 的 ext*/int* 16 点

### 变更（qoolui-example-qoolbox-adapt，QoolUIExample QoolBox 适配）

- **修复静默回归**：QoolTipPanel 顶层 `curved: true` 指向已撤销的 QoolBox 别名（QML 顶层未知属性赋值创建动态属性、渲染不读）——移入 `settings` 块恢复圆角设计
- **注释清理**：删除修改历史注释；Page_QoolBox 类型名更新为 QoolBoxHud
- **AGENTS.md 规范**：编码规范新增「注释与文档」条目——注释/文档不体现修改历史（修改历史归 CHANGELOG）

### 修复（ShapeControl target 尺寸同步去绑定化——QoolBox 系绑定环）

- **ShapeControl target 尺寸经信号连接同步（基类去绑定化）**：`width/height` 原为 QProperty 绑定（隐式尺寸拓扑下构成绑定环）——改为 target 尺寸信号连接写入缓存 QProperty，`QTimer::singleShot(0)` 延迟到事件循环写入；`x/y` 保持绑定

### 文档

- **QoolBoxGadget 算法独立 qdoc 文章**（`qool_qoolbox_geometry.qdoc`）：点定位与内缩算法详细论述（几何模型/used 派生/向量符号表/shrink 原理与推导/d\* 解析式对偶线性规划推导/边界条件）
- **QoolBoxGadget 类型文档精简为用法导向**：语义契约/输入接线/命名规范/referenceBox 用法/命中判定契约，算法细节链接文章

### 新增

- **QoolBoxGadget**（QML 类型，Qool 模块）：八边形控制点计算器（gadget 模式，挂载于标准 ShapeControl 之下）——cutSizes 硬参数（形状由 cut 决定）、width/height 期望尺寸（极限情况中心对称溢出而非压缩）；单一 8 点输出（pointTL..pointLT）；shrink 层几何真值（8 条平移半平面交集，d\* = 12 候选 O(1) 解析式）；referenceBox 几何参考源（5 介入点 ref 优先）；contains O(1) 线性不等式；全程不读宿主几何
- 旧 `QoolBoxShapeControl`/safe 链原样保留

## [4.0.0] — 2026-08-13

### 变更

- **QML 单例契约修复（系统性违规改造）**：进程级 C++ 单例经 `QML_SINGLETON` 暴露在**多 QQmlEngine** 场景崩溃 → 4 个违规类（ThemeDatabase/ColorNameDatabase/FileIconDB/FileInfoDB）按**单例组件设计模式**（DB/HQ/HQModel 三件套）拆分：DB 改名 XxxDB（C++ 全局单例）保留全部逻辑并摘除 QML 注册；HQ（新类 XxxHQ，QML 单例，`create()` 每 engine 独立实例）转发原暴露接口；模型走 HQModel（QIdentityProxyModel 挂接 DB，非单例）
- `QOOL_SIMPLE_SINGLETON_QML_CREATE` 宏从 `singleton.hpp` 删除（违规模式载体）；AGENTS「单例」节改写为模式固化（三选一形态 + 三件套规范 + 硬约束）

### 新增

- **OffsetProjector**（QML 类型，Qool 模块）：位移映射节点——输入方向 `direction`/距离度量方向 `refDirection`/移动距离 `refDistance`，输出实际位移向量 `offset`；退化契约（零向量/refDistance==0/正交 → offset 零向量）；输出值相等守卫
- **单例组件设计模式固化**（AGENTS「单例」节 + ADR-0001 + 根 CONTEXT.md）：形态三选一 + 硬约束——禁止进程级 C++ 单例经 QML_SINGLETON 暴露、接口双侧保留、模型非单例化
- **ThemeHQModel**（QML 类型，Qool 模块）：主题总览列表模型——roles 与源模型一致；installTheme 后 rowsInserted 实时转发；多视图各自实例化数据一致

### 修复

- **HalfCrystal 掩码 hover 误判**：QHoverEvent 分发只检查 item 自身 contains、不检查祖先 containmentMask——宿主 MouseArea 显式挂载组件掩码（`containmentMask: 组件id.containmentMask`）；HalfCrystal/Crystal QDoc「命中掩码」节补 hover 挂载契约
- **多 QQmlEngine 场景 SEGFAULT（0xc0000005）**：进程级 C++ 单例经 `QML_SINGLETON` 暴露被多个 engine 共享使用——按 DB+HQ+HQModel 契约重构后不再崩溃，单 engine 行为不变

### 文档

- AGENTS.md：「单例」节模式固化 + QML 模块注册节同步修订；QoolFile AGENTS 的 FileInfoDB/FileIconDB 描述更新
- QDoc：ThemeHQ、ThemeHQModel、ColorNameHQ、FileIconHQ、FileInfoHQ 新类型文档（生命周期「进程级 QML 单例」→ 每 engine 实例 + App 级共享数据）

### 新增

- **构建工具脚本**（`Scripts/qoolui_build_*.py`，Windows 可用 / Unix 骨架）：统一构建/测试/部署入口——common.py（共享逻辑 + 命令实现 + 输出双写落盘）+ windows.py（MSVC vswhere→vcvars64 注入 / MinGW PATH 前置）+ macos.py/linux.py 骨架；**kit×type 构建矩阵**（CMakePresets.json 展开为 6 preset，构建目录 `build-<kit>-<Type>`）；`scripts/win_build_test.ps1` 被替代删除
- msvc/mingw 双路径实测修复：Qt Tools 定位层级、qt_dir 归一化、run/install 漏传 env、透传参数解析、run_app Qt 运行时注入

### 变更

- **测试设施落地定案**：测试目录迁移 `QoolUI/tests/` → **顶级 `QoolUITests/`**（自包含）；共享宏族 `qool_test.hpp` + INTERFACE 库 `QoolUITestSupport`，现有 C++ 测试全部改写；QML 测试按**批次模型**组织（每模块一个 harness target `tst_<模块>_qml`，共享 `qml_test_main.cpp` 模板）；Windows Qt 前缀解析改 **qt.conf 自包含方案**（任何运行通道零环境注入）；CMake 组织（输出树下沉 `build/QoolUITests/`、`QOOL_BUILD_TESTS` 开关、`include(CTest)` 顶层条件化）；规范载体 `QoolUITests/AGENTS.md`（术语表 9 条/测试方法规范/测试策略/CMake 组织定案）
- 顶层 CMakeLists 加 `include(CTest)`；QoolUI/CMakeLists.txt 按 `BUILD_TESTING` 条件加入 `tests/`
- 新增 `docs/agents/`（issue-tracker.md / triage-labels.md / domain.md）；`.scratch/` 清空历史内容
- Qool.Controls.Components.ScrollBar、BasicScrollView → **移入 Qool.Controls 并改名**（BasicScrollView → **ScrollView**）
- Qool.Controls.Components.Crystal → **移入 Qool 模块**（与 HalfCrystal 同层）；移除 `control` 属性；Slider/VerticalSlider 移除对 Components 的依赖

### 修复

- **QML 测试静默加载旧组件（LINK_DEPENDS 补依赖边）**：`QoolUITests/qml/CMakeLists.txt` 给 tst_qool_qml 加 `LINK_DEPENDS "$<TARGET_FILE:Qool>"`——DLL 更新 → exe 重链 → POST_BUILD 复制重跑
- **Polar2D 标量乘除语义错误**：`operator*`/`operator/` 曾实现为 `radius + r` / `radius - r` → 修复为 `radius * r` / `radius / r`
- **PositionLocker 动态跟随失效**：`basePos` 经 `mapFromItem` 函数调用不建立绑定依赖——改显式读取 lockTo.x/y 参与计算
- **Vector2D 拷贝构造笔误**：`m_vector{other.m_from}` → 拷贝后向量被起点取代，改 `m_vector{other.m_vector}`
- **NumberRanger::format 字符串替换分支不可达**：QString 恒 `canConvert<qreal>` 数值分支先命中——字符串分支前置；修正 'g' 精度语义（有效数字而非小数位）
- **HalfCrystal 绑定循环与尺寸增长**：Shape 引擎路径变化强制 setImplicitSize → implicit 正反馈环——root 改 Item + 内部 Shape anchors.fill（环断开，API/渲染/掩码不变）
- **CrystalGadget 补精确命中掩码**：`contains()` C++ 覆写（外接矩形粗判 + 四角切角域排除）；Crystal 挂 `containmentMask: gadget`
- **RectGadget 修复**：构造期 target null 守卫；半区几何缺陷（halfWidth/halfHeight 曾误绑中心坐标）；`CrystalGadget::contains` 四角排除条件写反（不等号反向）
- **QML 测试 QtQuick.Shapes 插件加载失败**：`QoolUITests/qml/CMakeLists.txt` `find_file` 定位 + 条件 POST_BUILD 复制 qmlshapesplugin
- **Crystal implicit 尺寸陷阱**：root 改 Item + 内部 Shape anchors.fill（HalfCrystal 同构修复落地）

### 文档

- **属性宏体系文档化**：`property_macros.qdoc`（三宏族定位/签名对照/用法示例/陷阱）；4 个宏头文件补文件头注释
- RectGadget 补 QDoc（rect 覆盖默认 target 绑定行为/九点半区/contains）；CrystalGadget QDoc 补 contains；Crystal/HalfCrystal QDoc 更新
- **测试设施文档同步与消重**：三份文档（QoolUITests/README.md、QoolUITests/AGENTS.md、根 AGENTS.md）同步到 kit×type 构建体系并消解重复定义

## [4.0.0] — 2026-08-11

### 新增

- **Qool.Controls.BasicScrollView**（带 Qool 主题滚动条的滚动视图基底）：官方成品 QC.ScrollView 根 + 内置 Qool ScrollBar（垂直/水平）+ 显式内容让位（rightPadding/bottomPadding = effectiveScrollBar 尺寸）；宿主零配置获得 Qool 主题滚动
- **Qool.Controls.EditableTextBox**（多行文本输入框成品）：BasicTextArea + BasicScrollView；文本 API 经 alias 直通（text/readOnly/color/selectionColor 等）；textEdited/editingFinished 信号转发；无背景、默认 240×120
- **Qool.Controls.Components.BasicTextArea**（多行文本域基底）：QC.TextArea 主题化——Qool 主题文本三色 + Style.controlTextSize + wrapMode 默认 Wrap；无背景；不自带滚动
- **Qool.Controls.TextField → Qool.Controls.EditableText 改名**（名字说真话：可编辑的 Text——非 TextField 兼容层；BasicTextField 保留原名）
- **Qool.Controls.EditableText 新增 echoMode 密码回显**：echoMode（官方 4 枚举）+ passwordCharacter + passwordMaskDelay；displayText 密码化派生；readOnly + echoMode 非编辑态同样掩码
- **Qool.PositionTracker**（2D 位置追踪器）：追踪 target 局部点的场景/屏幕坐标——逐层监听祖先链；帧内合并 + 值去重；`update()` 强制重算
- **Qool.Floater**：`noVisibleSync`/`noEnabledSync` 开关（默认 false，替身契约保持全量同步）

### 修复

- **Qool.Controls.ScrollBar 规范对齐**：补 `visible: policy !== ScrollBar.AlwaysOff` 策略绑定（AlwaysOff 时完全隐藏；挂 Flickable 时影响内容区让位计算）
- **Qool.Floater 位置机制改造（PositionTracker 驱动）**：三组 Connections 替换为两个 PositionTracker（root 原点 + target）——**祖先链高层平移盲区消除**；坐标通道改用场景坐标；`refresh()` 保留并委托 tracker

### 文档

- Qool.Controls.TextField 补全 QDoc（双层结构/编辑会话/判定信号语义/插拔函数/契约差异）；ComboBox/SpinBox QDoc 更新；TextField QDoc 补 selectByMouse 与 readOnly 语义扩展

## [4.0.0] — 2026-08-10

### 其他

- ScrollBar/ScrollIndicator 淡出延迟机制由 DelayTimer 改用 TimerLatch；删除 Qool.DelayTimer 类型（无消费方）
- Slider 手柄/轨道展开语义调整：展开态水晶占满控件高度；轨道与水晶常态同高 = 新公开属性 `preferredHeight`；取消 v3「菱形顶出轨道」刻意效果；默认高度 20 → 25
- Slider/Crystal/TimerLatch 新版调整：TimerLatch 改名（becameActive/becameInactive → activated/deactivated、activate → trigger）并内联 Timer；Crystal 移除 size/leftPoint/rightPoint；Slider API 收缩（fillGradient/fillItem/crystalSize 移除）；手柄 MouseArea 修复（acceptedButtons: NoButton）；colorAt 采样改 visualPosition；锁存窗口 1s → 500ms；新增 animationEnabled/valueVelocity/justMoved
- OctagonShape fillGradient 别名回滚（无使用方）；Slider 用例自 Playground 迁移 Page_InputControls2

### 新增

- **Qool.Controls.SpinBox**（L1 裸控件）：T.DoubleSpinBox 基座，int/double 一体步进——透明尺寸背景、点击覆盖式编辑（Text 常显 + Loader 激活 BasicTextField）、左右全高指示器占位
- **Qool.Controls.TextField 双层强化版**（系列可编辑控件编辑域消费基底）：展示层（displayItem 常驻）+ 编辑会话（editing 开关、Loader 懒加载 BasicTextField）；编辑模型 judge 常驻隐藏 TextInput（acceptableInput 单点事实源）；accepted/rejected 独立信号；插拔三件套 displayTextFromText/textFromEditText/displayItem；官方 API 兼容（textEdited/inputMask/inputMethodHints/wrapMode）
- **Qool.Controls.Components.BasicTextField 还原纯净**：撤销 rejected 下沉——定位回归「主题化默认 TextField」；editingFinished 信号释放给上层
- **Qool.Controls.Components.BasicArrow**（方向箭头组件）：等腰直角三角形（顶角 90°）——direction 八方向；图形逻辑 ShapeControl 体系（CircleGadget + 双 TriangleGadget）；叠放双 Shape；默认 12×12
- **Qool.BasicRotationBehavior**（角度属性 Behavior）：旋转动画沿最近路径过渡（等价角判定）；拦截时经 targetValueChanged 同步动画起点
- **Qool.Controls.SpinBox**：指示器替换为 BasicArrow；编辑域迁移到 TextField（双层强化版）
- **Qool.Controls.ComboBox / SpinBox 编辑域迁移到 TextField**：两控件删除各自的 Loader 识别缺口补偿；ComboBox 常驻 TextField（currentText ↔ text 命令式同步、accepted/rejected 透传）；SpinBox 常驻 TextField（value → textFromValue 喂入显示、displayTextOverride 移除）；TextField 增量：selectByMouse 转发、readOnly 语义扩展

### 修复

- TextField 编辑会话文本残留（Binding 组件回写时序不可靠）→ 弃用 Binding 改手动同步
- TextField 编辑层初始空文本（Binding 首次求值污染 judge）→ onTextEdited 方案
- TextField 收尾递归重复（editing=false 触发桥接再次收尾）→ finishing 标志防重
- TextField 悬空 editTextChanged 调用（alias 不生成信号）→ 删除
- TextField MouseArea 悬停光标未响应 readOnly → enabled: !readOnly

### 文档

- Qool.Controls.TextField 补全 QDoc（双层结构/编辑会话/判定信号语义/插拔函数/契约差异）；ComboBox/SpinBox QDoc 更新（编辑域说明/accepted-rejected 新信号）；TextField QDoc 补 selectByMouse 与 readOnly 语义扩展

### 其他

- IndexIndicator 圆点列垂直居中；ComboBox delegate 宽度改 ListView.view.width（右缘裁剪修复）
- qool_vector2d.h 的 QML_VALUE_TYPE 去引号（注册风格统一）
- Playground 清理；TextField 文件头补 popup 焦点归还可能性记录；IndexIndicator 补大型模型性能 TODO；SpinBox 示例扩展为一组

## [4.0.0] — 2026-08-09

### 修复

- **Qool.Controls ComboBox editable 按 Enter 后结束编辑**：Qt 默认 accepted 后焦点仍留在文本域、编辑状态悬挂——BasicTextField onAccepted 中调用 root.accepted() 激活 ComboBox accepted 信号并释放焦点；onTextEdited 把编辑文本反向同步回 editText

### 变更

- AGENTS.md：技术栈节新增「以官方文档为准，不探查 Qt 源码」（仅怀疑 Qt 本身 bug 时才探查验证；推断未文档化行为须标注未验证）
- AGENTS.md：文档规范（QDoc）节新增「QML 类型文档内容规范」——文档叙述用法而非开发笔记、结构对齐官方页、逐属性说明、接口兼容性声明、契约差异明示

### 移除

- **Qool.Controls 删除 QoolComboBox**：`qoolboxsettings remake` 重构时旧版 ComboBox 存档副本误入公开注册——创建即零消费方，功能为 ComboBox 真子集，冻结一年未演进；同步移除 CMakeLists 注册

## [4.0.0] — 2026-08-07

### 修复

- `.cmake-format.py` 全面调教：`additional_commands` 声明 Qt 6 CMake API 与 QoolUI 自定义命令关键字结构——此前仅占位 `foo`，所有 Qt 命令被当纯位置参数只能逐行垂直堆叠
- 布局参数定案（嵌套方案）：`max_prefix_chars` 10 + `max_lines_hwrap` 2 + `min_prefix_chars` 10；`enable_markup` 关闭（英文断词合并中文注释）；`enable_sort` 关闭（QML_FILES/SOURCES 分组有语义）；lint 命名模式放宽兼容项目风格
- qool_qml_project_setup.cmake：删除 convert_paths_to_relative（唯一调用方改用 GLOB_RECURSE RELATIVE）；qoolui_collect_assets `PARENT_SCOPE}` 笔误修复
- QoolUIExample：`qoolui_collect_assets(appQoolUIExample)` 参数与引用变量不匹配（示例资源静默为空）→ `qoolui_collect_assets(QOOL_ASSETS)`
- QoolControls：`_private/DialRangeArc.qml` 裸注册进 QML_FILES（违反私有件机制）→ 改 QoolColor 同款 qrc 私有件机制
- **插件按接口分包（AGENTS.md 插件约定新增）**：同一接口的多个插件组织在同一包（目录）中，以不同 CMake target 共存；`plugins/colornameprovider_default/` 与 `commonzh/` 合并为 `plugins/colornameprovider/`

## [4.0.0] — 2026-08-06

### 修复

- **QoolCommon**（QoolCommon/qoolcommon/）：math::average 累加器 `0` → `N(0)` + 空列表返回；tools::find_all_indexes 死循环（from 含自身）；tools::generate_random_string 越界读（sizeof(charset)）→ charset.size()-1；LazyCache 补 Rule of Five + 析构补 delete + value() 全锁读；singleton.hpp 两 IMPL 改 magic statics；math::normalize_degrees 负角补 360° 归位；DefaultVariantMap size() 取并集键数 + 补拷贝赋值；QGADGET_READONLY_PROPERTY_DECLARE 删除错误的 setter 声明
- **Qool.Controls**：ComboBox background opacity 经 Loader 边界不可见 → Loader 加 id + 可空访问；PaPaWall refresh() 引用不存在的枚举成员；ScrollIndicator onStarted/onFinished 直接赋 opacity 杀死绑定 → delayer.running 两态驱动；QoolBGBox 补 `label?.` 空安全；IndexIndicator rows/columns 自引用环 → 垂直固定 columns:1、水平固定 rows:1；QoolComboBox delegate 补 `Style.follow: root.Style`
- **Qool.File**：FileInfoListModel 批量 insert 索引/空列表/removeRange/越界/sortInfos/move 差一等系列修复；UrlChecker static lambda 捕获 this → 非 static；FileInfoDB 二次判空；FileIconDB 析构 dynamic_cast 判空；FileIconImageProvider::compileUrl 路径 `%` 先 URL 转义；FileInfoListView `getFileInfos` → `infos()`
- **Qool.Chat**：ChatRoom set_name 后对 m_beepers 补发 wannaSignIn（注册信号早于连接建立丢失）；BasicBeeperApp::targetChange disconnect 误断全部出站连接；ChatRoom::dumpInfo m_server 空判；Message seed 改混合进程内递增计数器；Beeper channels 加 QMutex + 析构 removePostedEvents；ChatRoomManager purgeClosedServers 空指针崩溃修复 + 30s 周期清理
- **plugins**：themeloader `<custom>` 段误写 active → 写 custom；solve_values has_ref 多查 lazyProperties 一致化；yes_tags 含 "no" 移除；name 兜底被 load_metadata 覆盖补回；fileiconprovider completeSuffix → suffix；行解析越界判空跳过；database_initialized 原子化
- **Qool.Debug RectResizer**：六个 DragMoveArea 补 `autoBind: false`（默认会拖动 Floater 自身，双重驱动）
- **Qool.DragMoveArea**：`wannaMove` 参数从「相对按下起点的累计位移」改为「相对上次位置的增量位移」（消费方按 `x += dx` 叠加）——原语义重复累加不跟手
- **Qool.Floater + Qool.Debug.RectResizer**：手柄在「被调对象整体平移」时不跟随——Floater 暴露 `refresh()`；RectResizer 监听 root.parent 几何变化统一刷新 6 个手柄
- **Qool.Color（裁定修复，v3 对照审查后续）**：ColorDB 裁决顺序恢复为升序（"补充"型裁决）；RandomHSVColorGenerator 补 auto_bound 钳制、防重复约束恢复为仅色相通道；排版文字去 qsTr（新增「排版文字≠文本」规则）；NumInput 动画全部移除（仅保静态外观，animationEnabled 仅 API 兼容）；NumInput/CycleChoice/ColorNameButton/ChannelBar Templates implicit 不传播修复（显式绑定 implicitWidth/Height）；CycleChoice 动画全部移除；ColorPreviewer 移除 borderBox 边框；ColorNameButton 互斥逻辑重写（onCheckedChanged 统一承担）；Page_Color 宽度改 v4 页面风格
- **QoolUIExample**：Page_QoolBox `shape.shapeControl` 双重不存在引用 → `box_shape.control.dumpInfo()`；Page_InputControls 删除不存在的 valueRole/currentValue；PageFrame Loader 加载失败恢复 loadingBar；Page_Buttons checkedButton 空安全；示例资源从错误目标 Qool 改挂 appQoolUIExample

### 新增

- 误解文档化（刻意设计，防再误判）：Message 拷贝生成新身份、ChatRoom::postMessage 定向发送、Message::contains AND 全包含+空集通配、ChatRoomServer 线程架构
- Button::flat 与 ProgressBar::indeterminate 的 QDoc 设计说明
- 全量 QDoc：QoolCommon sidecar .qdoc、Qool.Chat/Qool.File/plugins 全部 C++ 类型、Qool.Controls 全部 QML 类型、Example 页面说明
- AGENTS.md：公开组件默认状态自洽、模型遵循 Qt 线程规范、Debug 边界暴露原则、修复须评估专项注释 + 刻意设计必须 QDoc 说明

### 文档

- AGENTS.md：信号命名惯例补充（过去式语义/Changed 与 Updated 区分/wannaXxx→执行槽→xxxChanged 成对/多信号汇聚 when_ 前缀槽）；bindable 宏内置相等守卫（setter 不写守卫是刻意的）
- QoolFile/AGENTS.md：删除两处「线程安全」表述（模型为单线程契约）
- AGENTS.md：移除「核心库瘦身原则」章节；新增「插件约定」（priority 统一 json 定义且必须包含）
- 新建 `QoolUI/interfaces/qool_interfaces.qdoc`：插件接口组织文档
- **Qool.Color 模块（新增）**：C++ 类型 ColorAssistant（四空间 int/F 双轨全同步）、ColorBank（无界稀疏索引容器）、ColorDB（QML 单例插件化色名查询）、ColorHueCycleModel、RandomHSVColorGenerator、Crystal4ContainmentMask；公开 QML 九组件（HSVPanel/HSLPanel/RGBPanel/CMYKPanel/ColorQuickPicker/ColorEdit/ColorPreviewer/ColorNameList/ColorBankPanel）；_private 拍平件（NumInput/CycleChoice/NumTools.js + 视觉件族 24 件）；插件 colornameprovider_default/commonzh；示例页 Page_Color
- Qool.Color 修复：RandomHSVColorGenerator hue 域映射（qRound(hue*360/255) 满环）；ColorHueCycleModel 越界环折返 → math::cycle_in_range；ChannelSlider 数值输入悬挂引用修正
- Qool.Color 迁移保真排查修复（v3 对照全量审查）：RandomHSVColorGenerator 8 个区间属性静默改名 minX/maxX → 恢复 v3 名 minimumX/maximumX；QML 只读属性 previous 静默丢失 → 宏恢复；count() 公式被改 → 恢复 v3 逐字公式；示例页丢失实例侧注入恢复；NumInput 两处静默偏差恢复
- AGENTS.md：R1 修订（Qool.Controls 定为控件基础层）；「已知陷阱 4」私有 QML 文件机制扩展（internal 标记与「不注册 + 目录 import」双机制）

## [4.0.0] — 2026-08-05

### 修复

- OctagonExternalShapePath 修正未定义 `root` 引用（id 与绑定不一致致边框层不渲染）
- OctagonInternalShapePath / OctagonExternalShapePath：`pathHints: PahtLinear` 拼写 → `PathLinear`
- CutSizeBinding：BL/BR 绑定误读 `from.cutSizeTR` → 改读各自角
- BasicLabel：`cutSizesLocked: true; cutSize: 4` → `cutSizes: 4`
- SystemTheme：INACTIVE/DISABLED 宏误写入 `m_data[Active]` → 补真实调色板
- math::is_equal 零附近判定分支 `ab > epsilon` → `<`；math::cycle_in_range 负模修正（`mod += distance` → `+= range`、`value <= max` → `<= right`）
- math QDoc 从 Qool/qool.qdoc 迁至 QoolCommon（独立仅头文件库文档不得挂靠 Qool 模块）
- CMake：删除 QoolConstants.qml 悬挂引用、重复 target_link_libraries、注释残留
- QoolUIExample：声明 `IMPORTS Qool`/`Qool.Chat` + `DEPENDENCIES TARGET`——消除 qmlcachegen AOT 统计中的跨模块类型回退
- .gitignore：补充 `.omp/`

### 新增

- **ShapeContainmentMask**：containmentMask 包装类型，命中判定委托 `ShapeControl::contains()` 数值算法
- **QoolBoxShapeControl::contains**：支持 offsetX/offsetY 位移（判定区跟随视觉形状）
- 独立 QDoc 组织文件 `QoolUI/Qool/qool.qdoc`：模块总览、Style 体系与 QoolWindow 配件哲学、属性集中文档、math 命名空间
- 本次涉及文件的完整 QDoc 注释

### 文档

- AGENTS.md：增补 QDoc 规范、变更记录规范；新增「仓库定位」章节（基础设施性质/C++ 绝不动态导出/QML 引擎类型系统为唯一暴露形式/示例程序三重角色）；「模块架构」重写（分层模型/依赖约束/依赖机制三场景/qmldir 开发规范）；「已知陷阱 1」更正为依赖声明机制
- AGENTS.md：标题改 QoolUI4；技术栈更新（Qt 最新正式 Release 当前 6.11.1、绝不兼容旧版）；新增三条硬约束（零第三方依赖/版本跟进/容器与算法 STL 优先）
- 新增 README.md：品牌门面版（定位与口号/QoolBox 核心形状体系/级联样式系统/模块概述/示例程序/许可证）
- AGENTS.md：新增「阅读约定」；QML 组件规范新增「多层插拔」设计原则；动画条目补 `animationEnabled` 语义
- 新增 `QoolFile/AGENTS.md`：Qool.File 模块级规范（多层插拔落地分层表/Display 契约/行为样式归属规则）
- Qool.File 补 QML 类型 QDoc：FileInfoListView/FileInfoDelegate/BasicFileInfoDisplay
