#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char* argv[]) {
  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;
  // engine.addImportPath(QStringLiteral("."));
  engine.addImportPath(QStringLiteral("qml"));
  engine.addPluginPath(QStringLiteral("qoolplugins"));

  QObject::connect(
    &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
    []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("QoolUIExample", "Main");

  return app.exec();
}
