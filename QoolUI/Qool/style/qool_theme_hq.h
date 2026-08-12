#ifndef QOOL_THEME_HQ_H
#define QOOL_THEME_HQ_H

#include "qool_theme.h"

#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QStringList>
#include <QVariant>

QOOL_NS_BEGIN

// 主题 QML 面（QML 单例，每 engine 独立实例）：转发 ThemeDB 的原 QML
// 暴露接口（查询/写面/static/属性/信号），实现全部调 ThemeDB::instance()。
// 进程级数据与逻辑单份在 ThemeDB（C++ 全局单例，不暴露 QML）——本类
// 只承载 QML 面，多 engine 场景每个 engine 一份实例，互不共享对象。
// 生命周期：create() → new ThemeHQ(engine)（parent = engine；引擎析构
// singletonInstances.clear() 不删对象，parent 关系是唯一安全出口）。
class ThemeHQ: public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(ThemeHQ)
  QML_SINGLETON

public:
  static ThemeHQ* create(QQmlEngine* engine, QJSEngine*) {
    return new ThemeHQ(engine);
  }

  Q_INVOKABLE Theme theme(const QString& name) const;
  Q_INVOKABLE void installTheme(Theme theme);
  Q_SIGNAL void themeInstalled(const QString& name);

  Q_INVOKABLE QVariant anyValue(Theme::Groups group, const QString& key,
    const QVariant& defvalue = {}) const;
  Q_INVOKABLE QVariant anyValue(
    const QString& key, const QVariant& defvalue = {}) const;

  Q_INVOKABLE static qreal visualBrightness(QColor color);
  Q_INVOKABLE static QColor recommendForeground(const QColor& bgColor,
    const QColor& light = { "white" },
    const QColor& dark = { "black" });

  // 属性读 ThemeDB（App 级共享数据）。信号仅转发 themeInstalled：
  // DB 的 themes/count 变化通知不存在（安装只发 themeInstalled，
  // 与改造前一致）——QML 侧绑定 themes/count 不随安装刷新，需要
  // 实时列表请使用 ThemeHQModel。
  Q_PROPERTY(QStringList themes READ themes NOTIFY themesChanged)
  Q_PROPERTY(int count READ count NOTIFY countChanged)
  QStringList themes() const;
  int count() const;
  Q_SIGNAL void themesChanged();
  Q_SIGNAL void countChanged();

private:
  explicit ThemeHQ(QObject* parent = nullptr);
};

QOOL_NS_END

#endif // QOOL_THEME_HQ_H
