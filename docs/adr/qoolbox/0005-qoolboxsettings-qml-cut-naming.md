# QoolBoxSettings 单一类型 + cut 命名规范（修订：双类型 → 单一类型）

**修订说明（2026-08-14）**：本 ADR 原定双类型结构（C++ Base + QML 派生类），执行期经两轮实证收敛为**单一 C++ 类型**。原决策文本见文末"原决策（已修订）"。

settings 定案为单一类型：`QoolBoxSettings`（C++ 类，QML_ELEMENT 注册、可实例化，定义全部属性：cutSizeTL/TR/BL/BR、borderWidth、borderColor、fillColor、offsetX/offsetY、curved）。`QoolBoxShapeControl.settings` 属性类型直接为 `QoolBoxSettings*`（无抽象基类，无多态层）。类型默认值 = C++ 常量（无 Style 默认——C++ 构造时无 engine 上下文），主题联动由消费方（QoolBox/QoolBGBox 等）在实例化处显式绑定 Style 字段实现（现状模式 `settings: QoolBoxSettings { borderWidth: Style.controlBorderWidth; ... }`）。

cut 面只留四角 `cutSizeTL/TR/BL/BR` 规范命名（砍 singular `cutSize` 与 uniform `cutSizes`；后者仅一个消费方在 Example，不在兼容范围）。统一设置能力高度可选，不塞进每个实例（独立 CutSizeLocker 待有真实消费方时按可插拔形态实现）。**settings 是 QObject 引用属性**：`qbox1.settings: qbox2.settings` 共享实例（改任一方影响所有引用者；字段级绑定/动画作用于共享对象）；需要独立副本 → 新建 `QoolBoxSettings` 实例赋值（QDoc 契约明示）。原因：字段级绑定/动画是 settings 的主流用法（值类型不可行）；Qt 官方先例 Control.palette（QObject 外观组）。

## 修订历程（为何双类型收敛为单一类型）

1. **主路径（已否定）**：Base（C++ 属性定义处）+ QML 侧 `QoolBoxSettings.qml` 继承 Base、在 QML 里绑 Style 默认值——宿主实例化即得当前主题外观。`settings` 属性类型 = Base*，接受子类实例（多态）。
2. **实证否定（2026-08-14，01 票）**：QML 文件以 QML_UNCREATABLE C++ 类型为根继承，qmlcachegen 编译期通过，但运行时引擎拒绝——"Type unavailable ... is a probe base type; instantiate <Sub> instead."（引擎对组件根元素做 creatable 检查，不区分"继承定义"与"实例化"）。"QML 类型继承 Base"不可行。
3. **第一轮 fallback（已修正）**：双类都放 C++（Base 保留 + QoolBoxSettings 继承 Base，QML_UNCREATABLE 注册 Base 供属性类型解析）。执行期发现此结构是弯路——Base 的唯一派生场景（QML 继承）已死，抽象层无存在意义，且 Base 类型名暴露在 QML 类型系统（宿主可见 QoolBoxSettingsBase，尽管不可实例化），违背"隐藏 Base"意图。
4. **最终定案（本修订）**：删除 Base，收敛为单一 `QoolBoxSettings`。`settings` 属性类型直接为本类（已注册 QML 类型），内联赋值（`settings: QoolBoxSettings {...}`）与引用赋值（`settings: otherBox.settings`）类型完全匹配——最初"Base* 属性类型需 QML_UNCREATABLE 基类做类型解析"的问题随 Base 删除而消失。消费方语法零改（QML 类型名不变）。
