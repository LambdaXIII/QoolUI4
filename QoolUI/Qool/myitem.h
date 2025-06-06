#ifndef MYITEM_H
#define MYITEM_H

#include <QtQuick/QQuickPaintedItem>

class MyItem : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT
    Q_DISABLE_COPY(MyItem)
public:
    explicit MyItem(QQuickItem *parent = nullptr);
    void paint(QPainter *painter) override;
    ~MyItem() override;

    Q_INVOKABLE QString greeting() const;
};

#endif // MYITEM_H
