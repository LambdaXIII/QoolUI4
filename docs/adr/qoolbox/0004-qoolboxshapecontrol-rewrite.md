# 重写保留 QoolBoxShapeControl（内部 gadget 化）

`QoolBoxShapeControl`（公开 QML 类型）**不删除，重写保留**（原决策为"删除"，本修订反转）：重写为 `ShapeControl` 子类 + 内部 gadget 化——C++ 构造时自行安装两个 `QoolBoxGadget`（`outer` borderWidth 0 + `inner` borderWidth = settings.borderWidth、`referenceBox` 指 outer），转发暴露 ext*/int* 16 点、usedWidth/usedHeight、四个 `*Space`、contains，公开可绑定属性 `settings`（类型 QoolBoxSettingsBase*）。对外契约沿用旧类（ext*/int*/topSpace 等命名）——旧消费方（变体/path/QoolBGBox/HUD/BasicLabel）语法零改，仅内部实现替换。safe*/safeBorderWidth/borderShrinkSize 系列砍（圆角 path 改造后无消费方）。零兼容重构的语义从"移除"变为"重写"：公开类型保留，宿主 `control.extTLx` 等用法延续，且 control 整体可替换/共享（见 ADR-0007）。
