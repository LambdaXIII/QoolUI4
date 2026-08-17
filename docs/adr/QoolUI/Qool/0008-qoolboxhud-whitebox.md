# QoolBoxHud：QoolBox 专用调试工具

`OctagonShapeHud` 重定位为 `QoolBoxHud`——QoolBox 专用调试工具（不再服务低级组件；能兼容更好但不作首要考量）。形态：`property QoolBox box: parent`，读 `box.control` 的 ext*/int* 16 点（control 是 QoolBox 公开属性，直接消费）——原先的 objectName + Qt.findChild 白盒方案随 control 公开而撤销（QoolBox 零对象暴露的决策已被 ADR-0007 推翻）。原因：control 公开后 HUD 无需内部契约；调试件只消费公开面。
