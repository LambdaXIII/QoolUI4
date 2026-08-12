#ifndef QOOL_THEME_HQMODEL_H
#define QOOL_THEME_HQMODEL_H

#include "qoolns.hpp"

#include <QIdentityProxyModel>
#include <QtQml/qqmlregistration.h>

QOOL_NS_BEGIN

// 主题总览列表模型（普通类型，非单例，按需实例化）：主题列表的
// QML 消费面——QIdentityProxyModel 在构造时 C++ 侧挂接 ThemeDB::instance()
// 为源模型。全部主题的列表（row = 主题），roles 与 ThemeDB 源模型一致
// （name/theme/metadata/constants/active/inactive/disabled/custom）。
// 全套模型变更通知（insert/remove/reset/dataChanged）由 QAbstractProxyModel
// 机制原生转发，无需自实现；DB 经 C++ 指针引用，不进 QV4 值系统
// （规避跨 engine 共享 QObject 类别）。每实例一份视图，多视图各自
// 实例化，数据始终一致（同一源模型）。
class ThemeHQModel: public QIdentityProxyModel {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit ThemeHQModel(QObject* parent = nullptr);
};

QOOL_NS_END

#endif // QOOL_THEME_HQMODEL_H
