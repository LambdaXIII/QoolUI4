# ColorAssistant 通道锚定模型：单权威 RGBA + 无表达维度记忆（hue=-1 语义退役）

ColorAssistant 的唯一事实源是 `m_color`，任何写入后一律经 `toRgb()` 再 `.toHsv()/toHsl()` 重算全部通道广播。色彩空间换算在**无表达维度**上会把通道坍缩成约定值（hue→-1、sat→归 0），而无条件重算把「暂时的无表达」固化成「永久的丢失」。实证症状：HSVWheel 圆心拖出丢失方向（色相被 -1 吞掉后按红解析）、外部编辑框改 hue/sat 在灰轴上被静默吞掉、RGB 拉黑后 HSV/HSL 全部通道塌死且取色表面停摆。

本次定案：**RGBA 单权威 + 三锚定坐标（通道锚定）**。不把所有通道升级为权威——多套权威互相冗余，需要同步裁决协议，且奇点照样丢；真正需要记忆的只有无表达维度。

## 无表达维度清单

| 维度 | 无表达条件 | 说明 |
|---|---|---|
| hue | 灰轴：hsv 的 sat=0 或 v=0；hsl 的 sat=0 或 l∈{0,1} | HSV 与 HSL 的 hue 是同一数学量（RGB 色度角），**共享一个锚** |
| hsvSaturation | v=0（黑） | |
| hslSaturation | l=0 或 l=1（黑/白） | |

其余全部通道（RGB、CMYK、value/lightness、alpha）处处有表达，纯投影，无需处理。

## Considered Options

- **保留 Qt 惯例（hue=-1 表无彩色），消费方各自 shadow 保持**——被拒：面板编辑框等经 assistant 直写的路径修不掉，只是绕开；-1 守卫与补偿补丁（sat-bump）持续增殖。
- **全成员权威 + 同步协议**——被拒：N 套互相冗余的坐标需裁决谁赢、漂移累积、奇异维度仍需特判；状态最多、收益为零。
- **双轨（getter 保 -1 + 另立 keptHue）**——被拒：两个真相来源，长期最丑。
- **单权威 RGBA + 锚定坐标（采纳）**：零新增存储（锚=现有成员的新更新语义，见决策 9），语义完备，读一致性与所见即所得兼得。

## Key Decisions

1. **锚更新规则（三分支，完整表述）**：
   - **显式写总是落锚**：分量 setter / QList setter 先把被写维度的成员设为请求值（经钳制/归一化），再从成员重建候选色——即使结果色中该维度无表达（黑上写 hue 被记住、暂不表达，v 拉起即恢复方向；否则灰轴编辑框写 hue 仍被吞，复现症状 2）；
   - **有表达跟随换算**：`set_color` 推导行仅在派生值有表达时覆盖锚（任何路径产生的彩色都刷新——否则 RGB 途中读数与实际颜色矛盾）；
   - **无表达冻结**：其余情况锚不动。
2. **锚即公开读数**：`hsvHueF`/`hslHueF`/`hsvSaturationF`/`hslSaturationF` 返回锚，恒 ∈[0,1)。**hue=-1 从公开契约退役（int/F 双轨同步退役，见决策 8）**。无彩色判定 = `valueF == 0 ∨ saturationF == 0`（黑轴上 hsvSaturation 锚冻结非零值，单看 saturation 会误判）。锚恢复的是显式写的最近值或塌缩前显示值——所见即所得，不存在「用户没见过的恢复值」。
3. **setter 从成员重建**：各分量 setter 用成员直接构造候选色（如 `fromHsvF(m_hsvHueF, s, m_hsvValueF, alpha)`），不再从 `m_color.toHsv()` 塌缩源读取；`set_color` 的推导行改为「有表达才覆盖」。成员、getter、信号、相等守卫机制不变。
4. **不变式**：本空间通道写永不丢失本空间其它通道；交叉空间写入的读数变化是真实换算而非塌缩。
5. **锚初值**：无效色（从未设色）时 hue=0、双 sat=0——与初始黑自洽，首次设色即覆盖有表达部分。
6. **原子写不扩面**：现有三维 QList 族（hsvF/hslF/rgbaF/cmykF 及 int 轨）即单次 set_color 原子操作；二维场景用三维写表达（v/l 填现值），不新增 hsF/slF 之类 API。
7. **alpha 不在锚定范围**：它在所有空间转换中原样携带，本就满足通道保持语义。
8. **int 轨随锚迁移**：`hsvHue`/`hslHue`/`hsvSaturation`/`hslSaturation` 等 int 成员改为从对应锚定 F 成员换算（量程缩放取整），灰轴上同样不产生 -1——否则 F 轨读 0.7、int 轨读 -1，公开契约自相矛盾。getter 签名不变。
9. **锚的物理表示 = 现有成员**：不新增存储。「三锚」是现有 `m_hsvHueF`/`m_hsvSaturationF`/`m_hslHueF`/`m_hslSaturationF` 四成员的新更新语义；两个 hue 成员为概念共享的同一锚，恒等同步（同值更新、两信号都发）。头文件除注释外不改。

## Consequences

- 消费方简化：HSVWheel/HSLBox 的 `hue<0` 守卫与「不播种」特判退场；ColorChannelSlider/ColorChannelVerticalSlider 的 sat-bump 补丁及其测试删除（新语义下为死码，**不得回填**）；两表面的交互写改用 QList 原子写，消除串行多写中间态。
- 测试迁移：`test_hueAchromatic` 等锁定 -1 的断言重写为锚语义断言；新增核心验收场景「RGB 拉黑（三锚并发冻结）→逐通道恢复」「圆心拖出方向保真」。
- 文档修订：所有描述 -1 语义的 reference 同步退役该表述。
- 不受影响：RandomHSVColorGenerator 依赖的是 QColor 层的 -1 语义（非 ColorAssistant）；ColorMapper 经 `color()` 派生读数，数值等价。

## 决策状态

- 决策已定案（2026-08-26，拷问式讨论收敛：Q-A″ 锚语义=连续延拓 / Q-B 不加二维 API / Q-C 初值定案 / Q-D 清理范围含 HSLBox 同批修复与几何重定位正确性修复）。实现待执行，spec 见 `.scratch/color-assistant-channel-anchor/spec.md`。
- **2026-08-26 推演修订（四子代理并行 rehearsal）**：锚更新规则细化为三分支（新增「显式写总是落锚」——原字面规则会在灰轴吞掉显式 hue 写，复现症状 2）；无彩色判定式改为 `valueF==0 ∨ saturationF==0`（黑轴 sat 锚冻结非零值）；增补 int 轨随锚迁移（决策 8）与锚物理表示=现有成员（决策 9）。修订由执行者/评审员/校验员/测试者四视角推演发现驱动，语义方向与定案讨论一致。
