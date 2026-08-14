# QoolBox 渲染结构：单 Shape 双 ShapePath

QoolBox 的八边形渲染采用单 Shape 双 ShapePath（外环 path + 填充 path），而非双 Shape。原因：ShapePath 继承 Path（QObject）无 opacity/visible，单 Shape 下无法按 path 独立裁剪；但双 Shape 会让两个独立 Item 共享同一条内边缘（都来自 inner 8 点），AA 光栅化有接缝风险，且对控件背景尺寸而言透明 path 的额外开销可忽略。权衡后取单 Shape 保共边安全，放弃双 Shape 的独立裁剪收益。
