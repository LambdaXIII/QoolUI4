#ifndef QOOL_STYLE_H
#define QOOL_STYLE_H

#include "qool_itemtracker.h"
#include "qool_theme.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolcommon/qobject_property_macros.hpp"

#include "qoolns.hpp"

#include <QBindable>
#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QQuickAttachedPropertyPropagator>
#include <QQuickItem>

Q_MOC_INCLUDE("qool_stylegroupagent.h")

QOOL_NS_BEGIN
class StyleGroupAgent;

// Style 附加属性：样式体系的 QML 入口（宿主经 Style.xxx 取用/注入）。
// 三层设计：
// 1) 组数据：每实例持 Active/Inactive/Disabled 三张已解析值表（theme
//    flatMap 的拷贝）+ 逐组修改标记；currentGroup 由宿主状态推导
//    （ItemTracker bindable 绑定：禁用→Disabled、窗口失活→Inactive、
//    否则 Active），组切换时重发全部 typed 属性信号。
// 2) typed 属性：60+ 属性读当前组（get_value(currentGroup, key)）；
//    写则落全部三组 + mark_modified——宿主注入契约：显式覆盖永不被
//    继承/主题重解析冲掉。
// 3) 主题绑定：theme 变更从 ThemeDB 重解析（跳过修改键）并沿附加
//    属性树向下传播；inherit 只拷贝父级已解析值，子树不回查数据库。
// animationEnabled 是独立成员（不走组数据），仅向下传播。
class Style : public QQuickAttachedPropertyPropagator {
  Q_OBJECT
  QML_ELEMENT
  QML_ATTACHED(QOOL_NS::Style)
  QML_UNCREATABLE("")

public:
  explicit Style(QObject* parent = nullptr);

  static Style* qmlAttachedProperties(QObject* object);
  Q_INVOKABLE void dumpInfo() const;
  Q_INVOKABLE void dumpAllChildren() const;

  enum Groups {
    Active = Theme::Active,
    Inactive = Theme::Inactive,
    Disabled = Theme::Disabled
  };

  QVariant get_value(
      int group, const QString& key, const QVariant& defValue = {}) const;
  bool set_value(int group, const QString& key, const QVariant& value);

  Q_SIGNAL void valueChanged(int group, QString key);

  void mark_modified(int group, const QString& key);
  bool is_modified(int group, const QString& key) const;

protected:
  // 主题源标记：宿主显式设置 theme（set_theme）后置 true——该节点成为
  // 子树主题源，inherit 拒绝父级/其他传播（主题边界契约 C3）。与 typed
  // 覆盖（mark_modified）同为「显式设置 = 持久设计意图」；无取消机制
  //（宿主改回默认 theme 即重设源）。
  bool m_explicitTheme{false};
  QString m_theme;
  ItemTracker* m_itemTracker;
  // 三组已解析值表（主题 flatMap 的拷贝）：typed 属性按 currentGroup
  // 从中取值；set_value 写入并触发 valueChanged 扇出。
  QVariantMap m_activeData, m_inactiveData, m_disabledData;
  // 逐组修改标记：宿主显式覆盖的键（true）在 inherit/主题重解析时跳过，
  // 保证注入值不被传播覆盖。
  QMap<QString, bool> m_activeModified, m_inactiveModified, m_disabledModified;
  // animationEnabled 独立于组数据（主题常量中的同名键是遗留数据，属性
  // 通道不消费它）；setter 仅沿附加属性树向下传播。
  bool m_animationEnabled{true};

  QOOL_BINDABLE_MEMBER(Style, Groups, currentGroup);
  void initialize_data();
  void propagate_theme();
  void inherit(Style* other);
  Q_SLOT void when_themeChanged();
  Q_SLOT void check_changes(int group, QString key);
  Q_SLOT void when_curentGroupChanged();

  QList<QQuickAttachedPropertyPropagator*> find_children() const;

  void attachedParentChange(QQuickAttachedPropertyPropagator* newParent,
      QQuickAttachedPropertyPropagator* oldParent) override;

  bool eventFilter(QObject* object, QEvent* event) override;

  Style* m_follow{nullptr};
  Q_SLOT void follow_value(int group, QString key);

  /****** PROPERTIES ******/
  // theme 手写实现（非宏内联）：set_theme 需置 m_explicitTheme 主题源标记
  QOBJECT_WRITABLE_PROPERTY_DECLARE(QString, theme)
  QOBJECT_WRITABLE_PROPERTY_DECLARE(bool, animationEnabled)
  QOBJECT_CONSTANT_PROPERTY(StyleGroupAgent*, active, )
  QOBJECT_CONSTANT_PROPERTY(StyleGroupAgent*, inactive, )
  QOBJECT_CONSTANT_PROPERTY(StyleGroupAgent*, disabled, )
  QOBJECT_WRITABLE_PROPERTY_DECLARE(Style*, follow)

#define DECL(T, N) QOBJECT_WRITABLE_PROPERTY_DECLARE(T, N)

#define __HANDLE__(N) DECL(QColor, N)
  QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, maroon, yellow,
      olive, lime, green)
  QOOL_FOREACH_10(__HANDLE__, aqua, cyan, teal, blue, navy, fuchsia, purple,
      orange, brown, pink)
  QOOL_FOREACH_3(__HANDLE__, positive, negative, warning)
  QOOL_FOREACH_3(
      __HANDLE__, controlBackgroundColor, controlBorderColor, infoColor)
  QOOL_FOREACH_10(__HANDLE__, accent, light, midlight, dark, mid, shadow,
      highlight, highlightedText, link, linkVisited)
  QOOL_FOREACH_10(__HANDLE__, text, base, alternateBase, window, windowText,
      button, buttonText, placeholderText, toolTipBase, toolTipText)
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
  QOOL_FOREACH_3(
      __HANDLE__, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
  QOOL_FOREACH_2(__HANDLE__, windowElementSpacing, windowEdgeSpacing)
#undef __HANDLE__

  DECL(QStringList, papaWords)

#undef DECL
};

QOOL_NS_END

#endif // QOOL_STYLE_H
