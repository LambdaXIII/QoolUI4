## QML 编写指南

本文涵盖**项目级**组件设计哲学、程序编写规则等，子版块中可能对这些内容进行补充或覆盖。

本项目中，在C++领域中所说的 **属性** ——特指 Qt 元对象系统中的 PROPERTY，
在 QML 中它们被 `property` 关键字声明，
每个QML组件的**property 直接暴露给其上1级对象**，
其它非property的成员，可以认为是“私有”的。

## 多层插拔

各种视觉组件、对其子元素应提供插拔能力；
若组件或子元素同时包含「特化功能」和「外观」两方面，应将这两方面的插拔能力尽可能解耦。

## 主题系统

Qool 中提供了一套主题系统，具体组件为 `ThemeHQ` 和 `Style`。

其中 `Qool.Style` 是 Attach 对象，可在各级组件中直接使用，它提供主题 token 支持，可同时作为数据源和样式接口使用。而且它在 QML 树中是**级联感知 & 子树覆盖**的。

## animationEnabled
`animationEnabled` 不是字面意思，它的开关用于**取舍完整的视觉效果和较好的性能**，它:

- [MUST] 必被视觉组件声明，除非父类已经包含它
- [MUST] 在属性声明的第一位置（全项目统一）
- [SHOULD] 其标准定义为：`property animationEnabled: parent?.animationEnabled ?? Style.animationEnabled`

## 编写细节
- `pragma ComponentBehavior: Bound`：按需编写（Bound = 组件内 id 绑定到实例），[MUST NOT]不得无脑使用
- [MUST NOT] 在组件的原始声明处定义 **非契约性的objectName**，如果是测试需要，应该在其实例被声明处设置
- [MAY BUT SHOULD NOT] 一般不使用 .js 定义通用方法，而是通过模块级对象实现（或暴露 QoolCommon 中的）算法函数
