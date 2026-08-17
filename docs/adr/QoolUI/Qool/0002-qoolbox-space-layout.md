# QoolBox `*Space` 布局量：溢出转换与钳 0

QoolBox 的布局量 `*Space`（topSpace/bottomSpace/leftSpace/rightSpace）由新版 `QoolBoxShapeControl`（C++）计算（公式 `max(0, max(相邻 cut) − (used − 期望)/2)`），QoolBox 转发为自身公开属性。原因：cut 改为硬参数后，溢出（used > 期望）时八边形以期望中心对称溢出，内容盒需从 used 坐标系换算回期望坐标系，故减 `(used − 期望)/2`；钳 0 因 `*Space` 是排版参考值，负值徒增消费复杂度。`*Space` 提供在 control 上（几何单元的一部分：点 + used + space 一体，单一事实源）；QoolBox 转发公开（宿主接口）；同系组件（QoolBGBox 等）覆盖同名属性是期望行为——同系同类语义（QoolBGBox 的 space 含 label 调整，内部读 `control.*Space` 无冲突）。
