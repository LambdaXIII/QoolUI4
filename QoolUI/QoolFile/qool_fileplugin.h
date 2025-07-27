#ifndef QOOL_FILEPLUGIN_H
#define QOOL_FILEPLUGIN_H

#include <QObject>
#include <QQmlEngineExtensionPlugin>

class Qool_FilePlugin: public QQmlEngineExtensionPlugin {
  Q_OBJECT
  Q_PLUGIN_METADATA(IID QQmlEngineExtensionInterface_iid)
public:
  explicit Qool_FilePlugin(QObject* parent = nullptr);
  void initializeEngine(QQmlEngine* engine, const char* uri) override;
};

void qml_register_types_qool_file();

#endif // QOOL_FILEPLUGIN_H
