#ifndef FPWAKE_H
#define FPWAKE_H
#include <QObject>
#include <QQmlExtensionPlugin>
class FpWake : public QObject {
    Q_OBJECT
public:
    explicit FpWake(QObject *parent = nullptr) : QObject(parent) {}
    Q_INVOKABLE void wakeScreen();
};
class FpWakePlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")
public:
    void registerTypes(const char *uri) override;
};
#endif
