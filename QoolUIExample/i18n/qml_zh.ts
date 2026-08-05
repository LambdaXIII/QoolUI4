<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE TS>
<TS version="2.1" language="zh_CN" sourcelanguage="en_US">
<context>
    <name></name>
    <message id="qooltip-basic-button-1">
        <source>普通按钮的介绍</source>
        <oldsource>Tip for the plain simple button</oldsource>
        <translation type="obsolete">你好！</translation>
    </message>
    <message id="qooltip-basicbutton">
        <location filename="../pages/Page_Buttons.qml" line="26"/>
        <source>普通按钮的介绍</source>
        <translation>QoolUI 默认提供了一个普通的按钮控件。它并非 QtQuick.Controls.Button 的简单包装，而是使用 Baisc.AbstractButton 重新设计的控件。

BasicButton 只是一个基础框架，处于性能考虑并不包含完整的按钮功能。但是你可以方便地扩展它，以实现自定义的，符合 QoolUI 规范的按钮。</translation>
    </message>
    <message id="qooltip-basicbutton-extra-properties">
        <location filename="../pages/Page_Buttons.qml" line="36"/>
        <location filename="../pages/Page_Buttons.qml" line="46"/>
        <source>介绍按钮对于 flat 和 highlighted 的支持</source>
        <translation>为了保持和 QtQuick 默认按钮功能的兼容性，QoolButton 也有 flat 和 highlighted 属性，用法和标准按钮一样。

当 flat=true 时，未高亮的按钮将不会绘制背景元素。

当当按钮处于可选择模式的时候，按钮将会反色绘制。</translation>
    </message>
    <message id="qooltip-qoolbutton">
        <location filename="../pages/Page_Buttons.qml" line="62"/>
        <source>介绍QoolButton</source>
        <translation>QoolButton 是 QoolUI 中的标准按钮，基于 BasicButton 实现。除了基础功能之外，还提供了高亮显示、禁用状态等外观状态。</translation>
    </message>
    <message id="qooltip-qoolbutton-extra-properties">
        <location filename="../pages/Page_Buttons.qml" line="74"/>
        <source>QoolButton也可以flat</source>
        <translation>你可能已经注意到了，QoolButton 使用了切角矩形作为背景，并且可以设置一个标题显示在按钮上。除此之外，QoolButton 还有更多的功能。

标题文字作为背景的一部分，当按钮处于扁平模式的时候不会显示。</translation>
    </message>
    <message id="qooltip-qoolbutton-checkable">
        <location filename="../pages/Page_Buttons.qml" line="88"/>
        <source>介绍QoolButton的checkable属性</source>
        <translation>因为继承于 QtQuick 的按钮实现，QoolButton 完全支持 checkable 属性。

当它 checkable 时，并不会像基础按钮一样反色渲染，而是高亮按钮的边框。</translation>
    </message>
    <message id="qooltip-qoolbutton-animation">
        <location filename="../pages/Page_Buttons.qml" line="102"/>
        <source>介绍如何控制组件的动画</source>
        <translation>当按钮处于 disabled 的状态时，将会绘制一个动态的红色警戒线。QoolUI 中的很多控件都有类似的动态效果，可以在主题设置中统一关闭以提高性能。

这里只是把这个按钮的动画开关连接到了上一个按钮的选定状态上。</translation>
    </message>
    <message id="qooltip-buttongroup-support">
        <location filename="../pages/Page_Buttons.qml" line="162"/>
        <source>介绍这些按钮与ButtonGroup的兼容情况</source>
        <translation>BasicButton 和 QoolButton 都完美地兼容 QtQuick 自带的 ButtonGroup 功能。此处的四个不同的按钮被指派到了同一个 ButtonGroup 中，可以看到它们中只能同时激活一个。</translation>
    </message>
    <message id="qooltip-basicbutton-example">
        <location filename="../pages/Page_Buttons.qml" line="176"/>
        <source>介绍 BasicButton 和 papa words</source>
        <translation>自定义 QoolButton 的方法很简单：直接复写其 contentItem 即可。

你可能注意到了，QoolUI 的按钮在鼠标按下时会显示一些装饰性的文字，这是 QoolUI 的一个核心特性。
每次按下按钮时都会以随机的大小和角度显示一段随机的文字。
文字的内容可以通过主题统一指定，也可以为单独的控件专门设置。

此功能本身是利用 PaPaWall 组件实现的，你可以直接使用它来渲染这样的一个叠层，此时可以直接设置文字内容而不需要使用 QoolUI 样式系统。</translation>
    </message>
    <message id="qooltip-filedropper">
        <location filename="../pages/Page_QoolFile.qml" line="40"/>
        <source>介绍FileDropper以及Qool.File的基本原理</source>
        <translation>FileDropper 时一个处理外部文件拖拽的接收器。

当拖动内容到它上面时，它会识别拖动的内容中是否包含文件句柄，并给出外观反馈。
如果内容可以接受，那么松开鼠标之后将会发出相应的信号。

-----

在此示例组件中，拖动文件后将会显示嗯图标，这并不是 FileDropper 的功能，而是通过覆盖其 contentItem 实现的。

Qool.File 模块内置了一些常见的文件格式的图标，这些图标通过文件的扩展名进行识别。
你可以通过编写你自己的插件对图标素材和识别方式进行扩展，QoolUI 将会自动加载并安装。</translation>
    </message>
    <message id="qooltip-fileinfolistcontrol">
        <location filename="../pages/Page_QoolFile.qml" line="51"/>
        <source>介绍文件列表控件</source>
        <translation>出于方便性的考虑，Qool.File 模块包含一套文件列表的实现。

- FileInfoListModel 是保存、控制文件信息列表的 model，它可以管理由多个文件信息组成的列表，并提供基本的信息查询。它继承于 Qt 内置的 AbstractListModel，所以你可以编写自己的 view 和它配合使用。
- FileInfoListView 是一个默认的和 FileInfoListModel 配合的 view。在其中你可以通过拖动对文件进行排序。默认情况下它内置一个 FileInfoListModel，所以你可以直接使用它管理文件列表。
- FileInfoListToolBar 对 FileInfoListView 中的功能提供一个工具条。
- FileInfoListControl 本身其实是一个包含了 FileInfoListView 和 FileInfoListToolBar 的 FileDropper。你可以通过拖动文件来添加到列表，并且通过拖动或工具栏对列表进行整理。示例中的控件就是它。</translation>
    </message>
    <message id="qooltip-combobox-normal">
        <location filename="../pages/Page_InputControls.qml" line="49"/>
        <source>介绍QoolUI版的ComboBox</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="qooltip-combobox-titled">
        <location filename="../pages/Page_InputControls.qml" line="62"/>
        <source>QoolUI版的ComboBox可以设置标题</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="qooltip-combobox-customed">
        <location filename="../pages/Page_InputControls.qml" line="84"/>
        <source>通过设置背景属性甚至可以恢复QoolControl原本的样式</source>
        <translation type="unfinished"></translation>
    </message>
</context>
<context>
    <name>ExampleBasicButton</name>
    <message>
        <location filename="../pages/components/ExampleBasicButton.qml" line="6"/>
        <source>自定义的按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/ExampleBasicButton.qml" line="10"/>
        <source>欢迎使用QoolUI!</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/ExampleBasicButton.qml" line="10"/>
        <source>我是一块砖！</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/ExampleBasicButton.qml" line="10"/>
        <source>垂死病中惊坐起</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/ExampleBasicButton.qml" line="10"/>
        <source>笑问客从何处来</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/ExampleBasicButton.qml" line="11"/>
        <source>快点我！</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/ExampleBasicButton.qml" line="11"/>
        <source>Look in my eyes!</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/ExampleBasicButton.qml" line="22"/>
        <source>点我试试？</source>
        <translation type="unfinished"></translation>
    </message>
</context>
<context>
    <name>Main</name>
    <message>
        <location filename="../Main.qml" line="16"/>
        <source>Hello, Qool World!</source>
        <translation>欢迎使用 QoolUI ！</translation>
    </message>
</context>
<context>
    <name>MainWindowToolBar</name>
    <message>
        <location filename="../MainWindowToolBar.qml" line="21"/>
        <source>中文</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../MainWindowToolBar.qml" line="33"/>
        <source>英文</source>
        <translation type="unfinished"></translation>
    </message>
</context>
<context>
    <name>Page_Buttons</name>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="12"/>
        <location filename="../pages/Page_Buttons.qml" line="59"/>
        <source>酷酷的按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="13"/>
        <source>QoolUI提供了风格化的按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="23"/>
        <source>默认按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="42"/>
        <source>可以 Check 的按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="42"/>
        <source>已经 Check 的按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="58"/>
        <source>这是一个酷酷的按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="69"/>
        <source>酷酷的按钮也可以有 flat 模式</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="70"/>
        <source>平平无奇的酷酷的按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="82"/>
        <source>可以开关的按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="83"/>
        <source>动画已启用</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="83"/>
        <source>动画已禁用</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="96"/>
        <source>被禁用的按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="97"/>
        <source>奏凯！别摸我！</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="114"/>
        <source>成组的按钮</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="123"/>
        <source>已选定按钮%1</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="129"/>
        <source>选项1</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="137"/>
        <source>选项2</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="144"/>
        <source>QoolButton也可以的</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="145"/>
        <source>选项3</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="152"/>
        <source>这也行</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="153"/>
        <source>选项4</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Buttons.qml" line="32"/>
        <source>标记为 flat 的按钮</source>
        <translation type="unfinished"></translation>
    </message>
</context>
<context>
    <name>Page_InputControls</name>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="12"/>
        <source>标准输入控件</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="13"/>
        <source>Qool.Controls 重写了多种标准输入控件</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="17"/>
        <source>小明</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="17"/>
        <source>小李</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="17"/>
        <source>大美</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="17"/>
        <source>笨笨</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="23"/>
        <source>正常</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="27"/>
        <source>向上</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="31"/>
        <source>向下</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="56"/>
        <source>你最喜欢的人是？</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_InputControls.qml" line="71"/>
        <source>设置菜单弹出方向</source>
        <translation type="unfinished"></translation>
    </message>
</context>
<context>
    <name>Page_Playground</name>
    <message>
        <location filename="../pages/Page_Playground.qml" line="14"/>
        <source>试炼场</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Playground.qml" line="15"/>
        <source>测试一些东西……</source>
        <translation type="unfinished"></translation>
    </message>
</context>
<context>
    <name>Page_QoolBox</name>
    <message>
        <location filename="../pages/Page_QoolBox.qml" line="10"/>
        <source>QoolBox</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_QoolBox.qml" line="11"/>
        <source>酷酷的 Box</source>
        <translation type="unfinished"></translation>
    </message>
</context>
<context>
    <name>Page_QoolFile</name>
    <message>
        <location filename="../pages/Page_QoolFile.qml" line="11"/>
        <source>Qool.File 模块</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_QoolFile.qml" line="12"/>
        <source>QoolUI 的 File 模块提供了一些用于与文件系统交互的简单组件</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_QoolFile.qml" line="22"/>
        <source>可以把文件丢到这里</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_QoolFile.qml" line="46"/>
        <source>文件列表控件</source>
        <translation type="unfinished"></translation>
    </message>
</context>
<context>
    <name>Page_Welcome</name>
    <message>
        <location filename="../pages/Page_Welcome.qml" line="7"/>
        <source>欢迎</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/Page_Welcome.qml" line="8"/>
        <source>欢迎使用 QoolUI 4! 一个月前，乐元素也首曝了一款基于UE5研发的大世界都市ARPG：《白银之城》，从官方展示的11分钟实机画面来看，该作的完成度已经相当高了。而在上述两款产品曝光之前，都市开放世界作为国内新兴细分游戏品类的“扛把子”，早已有多款二游新品严阵以待：网易雷火《无限大》，完美世界《异环》，诗悦《望月》，不论是投入力度、重视程度，还是从PV及测试所展示的产品质量来看，一众厂商俨然已将这个品类视作开放世界赛道下一世代的“入场券”。</source>
        <translation type="unfinished"></translation>
    </message>
</context>
<context>
    <name>QoolBoxShapeControlPanel</name>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="32"/>
        <source>图形宽度</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="41"/>
        <source>图形高度</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="50"/>
        <source>描边宽度</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="60"/>
        <source>左上切角距离</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="70"/>
        <source>右上切角距离</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="80"/>
        <source>左下切角距离</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="90"/>
        <source>右下切角距离</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="100"/>
        <source>水平偏移量</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="109"/>
        <source>竖直偏移量</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="121"/>
        <source>图形颜色</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="126"/>
        <source>描边颜色</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="138"/>
        <source>方形切角</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="145"/>
        <source>圆形切角</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="154"/>
        <source>显示外顶点</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="159"/>
        <source>显示内顶点</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="166"/>
        <source>锁定边角</source>
        <translation type="unfinished"></translation>
    </message>
    <message>
        <location filename="../pages/components/QoolBoxShapeControlPanel.qml" line="175"/>
        <source>Dump信息至控制台</source>
        <translation type="unfinished"></translation>
    </message>
</context>
</TS>
