# QoolBoxGadget 内部质量：中间量降权 + 全称命名 + QVector2D

QoolBoxGadget 的公开 QML 面只留输入（cut*/borderWidth/offsetX/offsetY/referenceBox）+ 输出（point* 8 点 + 分量 + usedWidth/usedHeight + contains）；中间量（vec*/shrink*/dStar/shrinkD/linesC/intersectVerts/origin/usedHalf*）降为内部裸 `QProperty`（无 Q_PROPERTY、无 NOTIFY signal——无 QML 消费方、无 signal 监听者）。命名全称少缩写（dStar→maxShrinkDistance、shrinkD→shrinkDistance、linesC→insetLineConstants、intersectVerts→intersectionVertices）；自由位移向量用 `QVector2D`（QPointF 是位置类型）。原因：QoolUI 是开源库，无论是否暴露命名都不可随意；QObjectBindableProperty 的 Q_PROPERTY+signal 对纯内部量是死重，裸 QProperty 已提供 setBinding/value/依赖追踪。

**安装位置（修订）**：gadget 由 `QoolBoxShapeControl`（C++）构造时安装（outer + inner，referenceBox 链），非 QML 侧挂载；gadget 保留公开注册（QML 类型）——可作为普通 Gadget 被独立使用（坐标计算器），control 封装不影响其独立性。
