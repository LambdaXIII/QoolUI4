#ifndef QOOL_STYLEGROUPAGENT_H
#define QOOL_STYLEGROUPAGENT_H

#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolcommon/macro_foreach.hpp"

#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QQmlEngine>

Q_MOC_INCLUDE("qool_style.h")

QOOL_NS_BEGIN

class Style;
// 组面代理：把父 Style 的某一组（Active/Inactive/Disabled）暴露为
// 同名 typed 属性（Style.active.accent）。读 = 父 Style 该组取值；
// 写 = 只写该组 + 该组 mark_modified（与 Style 顶层 setter 写三组
// 相对，是单状态覆盖通道）。属性信号由父 Style 的 valueChanged 按
// 组过滤重发——组间切换不重发（组面绑定固定组，值不随切换变化）。
class StyleGroupAgent: public QObject {
  Q_OBJECT
  QML_ANONYMOUS
public:
  explicit StyleGroupAgent(int group, Style* parent);

protected:
  int m_group;
  Style* m_parentStyle;
  Q_SLOT void when_parentValueChanged(int group, QString key);

  /****** PROPERTIES ******/

#define DECL(T, N) QOBJECT_WRITABLE_PROPERTY_DECLARE(T, N)

#define __HANDLE__(N) DECL(QColor, N)
  QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, maroon,
    yellow, olive, lime, green)
  QOOL_FOREACH_10(__HANDLE__, aqua, cyan, teal, blue, navy, fuchsia,
    purple, orange, brown, pink)
  QOOL_FOREACH_3(__HANDLE__, positive, negative, warning)
  QOOL_FOREACH_3(
    __HANDLE__, controlBackgroundColor, controlBorderColor, infoColor)
  QOOL_FOREACH_10(__HANDLE__, accent, light, midlight, dark, mid,
    shadow, highlight, highlightedText, link, linkVisited)
  QOOL_FOREACH_10(__HANDLE__, text, base, alternateBase, window,
    windowText, button, buttonText, placeholderText, toolTipBase,
    toolTipText)
#undef __HANDLE__

#define __HANDLE__(N) DECL(int, N)
  QOOL_FOREACH_8(__HANDLE__, textSize, titleTextSize, toolTipTextSize,
    importantTextSize, decorativeTextSize, controlTitleTextSize,
    controlTextSize, windowTitleTextSize)
#undef __HANDLE__

#define __HANDLE__(N) DECL(qreal, N)
  QOOL_FOREACH_3(
    __HANDLE__, instantDuration, transitionDuration, movementDuration)
  QOOL_FOREACH_5(__HANDLE__, menuCutSize, buttonCutSize, controlCutSize,
    windowCutSize, dialogCutSize)
  QOOL_FOREACH_3(__HANDLE__, controlBorderWidth, windowBorderWidth,
    dialogBorderWidth)
  QOOL_FOREACH_2(__HANDLE__, windowElementSpacing, windowEdgeSpacing)
#undef __HANDLE__

  DECL(QStringList, papaWords)

#undef DECL
};

QOOL_NS_END

#endif // QOOL_STYLEGROUPAGENT_H
