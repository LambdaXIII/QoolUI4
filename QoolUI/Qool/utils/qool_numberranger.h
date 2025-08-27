#ifndef QOOL_NUMBERRANGER_H
#define QOOL_NUMBERRANGER_H

#include "qool_smartobj.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qbindable_property_macros.hpp"

#include <QObject>
#include <QQmlEngine>
#include <optional>

QOOL_NS_BEGIN

class NumberRanger: public SmartObject {
  Q_OBJECT
  QML_ELEMENT
public:
  enum ValidateModes {
    AutoValidate = 0,
    IgnoreTop,
    IgnoreBottom,
    None = -1
  };
  Q_ENUM(ValidateModes)

  explicit NumberRanger(QObject* parent = nullptr);
  Q_INVOKABLE QVariant validate(const QVariant& number) const;
  Q_INVOKABLE QVariant validatePrecision(const QVariant& number) const;
  Q_INVOKABLE QVariant format(const QVariant& v) const;

private:
  qreal decimalfy(qreal x) const;
  QOOL_BINDABLE_MEMBER(
    NumberRanger, std::optional<qreal>, validated_top);
  QOOL_BINDABLE_MEMBER(
    NumberRanger, std::optional<qreal>, validated_bottom);

  void setup_tracking_numbers();

  QBINDABLE_WRITABLE_PROPERTY(
    NumberRanger, QVariant, bottom)
  QBINDABLE_WRITABLE_PROPERTY(
    NumberRanger, QVariant, top)
  QBINDABLE_WRITABLE_PROPERTY(
    NumberRanger, int, decimals)
  QBINDABLE_WRITABLE_PROPERTY(
    NumberRanger, ValidateModes, validateMode)

#define DECL_V(_N_)                                                    \
  QBINDABLE_WRITABLE_PROPERTY(                         \
    NumberRanger, QVariant, input##_N_)                                \
  QBINDABLE_READONLY_PROPERTY(                         \
    NumberRanger, QVariant, validated##_N_)

  QOOL_FOREACH_10(DECL_V, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

#undef DECL_V
};

QOOL_NS_END

#endif // QOOL_NUMBERRANGER_H
