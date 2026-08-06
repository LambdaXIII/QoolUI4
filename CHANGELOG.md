# Changelog

版本号不随常规修改迭代（当前 4.0.0），仅在正式发布时递增；本文件记录每次修改的内容。

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
