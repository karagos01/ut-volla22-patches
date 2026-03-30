#include "fpwake_plugin.h"
#include <QQmlEngine>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QDBusReply>
#include <QDBusVariant>
#include <QDBusArgument>
#include <QProcess>
#include <QFile>

void FpWake::wakeScreen() {
    QDBusInterface iface("com.canonical.Unity.Screen", "/com/canonical/Unity/Screen",
                         "com.canonical.Unity.Screen", QDBusConnection::systemBus());
    if (iface.isValid()) iface.call("keepDisplayOn");
}

void FpWake::setBrightness(int value) {
    QDBusInterface iface("com.canonical.Unity.Screen", "/com/canonical/Unity/Screen",
                         "com.canonical.Unity.Screen", QDBusConnection::systemBus());
    if (iface.isValid()) iface.call("setUserBrightness", value);
}

void FpWake::setAutoBrightness(bool enabled) {
    QProcess::startDetached("dconf", {"write", "/com/lomiri/touch/system/auto-brightness", enabled ? "true" : "false"});
    QDBusInterface iface("com.canonical.Unity.Screen", "/com/canonical/Unity/Screen",
                         "com.canonical.Unity.Screen", QDBusConnection::systemBus());
    if (iface.isValid()) iface.call("userAutobrightnessEnable", enabled);
}

bool FpWake::getAutoBrightness() {
    QProcess p;
    p.start("dconf", {"read", "/com/lomiri/touch/system/auto-brightness"});
    p.waitForFinished(1000);
    return p.readAllStandardOutput().trimmed() == "true";
}

int FpWake::getBrightness() {
    QFile f("/sys/class/leds/lcd-backlight/brightness");
    if (f.open(QIODevice::ReadOnly)) {
        bool ok; int val = f.readAll().trimmed().toInt(&ok); f.close();
        if (ok) return val;
    }
    return -1;
}

void FpWake::setVolume(int percent) {
    // Sound indicator uses 0.0-1.0 double range, Activate takes int
    QDBusInterface iface("org.ayatana.indicator.sound", "/org/ayatana/indicator/sound",
                         "org.gtk.Actions", QDBusConnection::sessionBus());
    if (iface.isValid()) {
        QVariantList params;
        params << QVariant::fromValue(QDBusVariant(QVariant(percent)));
        iface.call("Activate", QString("volume"), params, QVariantMap());
    }
}

void FpWake::setMute(bool muted) {
    Q_UNUSED(muted);
    QDBusInterface iface("org.ayatana.indicator.sound", "/org/ayatana/indicator/sound",
                         "org.gtk.Actions", QDBusConnection::sessionBus());
    if (iface.isValid()) {
        iface.call("Activate", QString("mute"), QVariantList(), QVariantMap());
    }
}

int FpWake::getVolume() {
    // Read from indicator: Describe returns (enabled:bool, paramtype:string, [state:variant])
    // volume state is double 0.0-1.0
    QDBusInterface iface("org.ayatana.indicator.sound", "/org/ayatana/indicator/sound",
                         "org.gtk.Actions", QDBusConnection::sessionBus());
    if (iface.isValid()) {
        QDBusMessage reply = iface.call("Describe", QString("volume"));
        if (reply.type() == QDBusMessage::ReplyMessage && reply.arguments().size() > 0) {
            // Response is (bsav) - bool, string, array of variant
            QDBusArgument arg = reply.arguments().at(0).value<QDBusArgument>();
            arg.beginStructure();
            bool enabled; arg >> enabled;
            QString sig; arg >> sig;
            QVariantList states;
            arg.beginArray();
            while (!arg.atEnd()) {
                QDBusVariant v; arg >> v;
                states << v.variant();
            }
            arg.endArray();
            arg.endStructure();
            if (!states.isEmpty()) {
                double vol = states[0].toDouble();
                return qRound(vol * 100.0);
            }
        }
    }
    return 50;
}

bool FpWake::getMute() {
    QDBusInterface iface("org.ayatana.indicator.sound", "/org/ayatana/indicator/sound",
                         "org.gtk.Actions", QDBusConnection::sessionBus());
    if (iface.isValid()) {
        QDBusMessage reply = iface.call("Describe", QString("mute"));
        if (reply.type() == QDBusMessage::ReplyMessage && reply.arguments().size() > 0) {
            QDBusArgument arg = reply.arguments().at(0).value<QDBusArgument>();
            arg.beginStructure();
            bool enabled; arg >> enabled;
            QString sig; arg >> sig;
            QVariantList states;
            arg.beginArray();
            while (!arg.atEnd()) {
                QDBusVariant v; arg >> v;
                states << v.variant();
            }
            arg.endArray();
            arg.endStructure();
            if (!states.isEmpty()) return states[0].toBool();
        }
    }
    return false;
}


void FpWake::toggleFlashlight() {
    bool on = getFlashlight();
    QFile f("/sys/class/flashlight_core/flashlight/flashlight_torch");
    if (f.open(QIODevice::WriteOnly)) {
        f.write(on ? "0 0 0 0 0" : "1 1 0 1 0");
        f.close();
    }
}

bool FpWake::getFlashlight() {
    QFile f("/sys/class/flashlight_core/flashlight/flashlight_torch");
    if (f.open(QIODevice::ReadOnly)) {
        QString val = f.readAll().trimmed();
        f.close();
        return val != "0" && !val.isEmpty();
    }
    return false;
}

void FpWake::setRotationLock(bool locked) {
    QProcess p;
    p.start("dconf", {"write", "/com/lomiri/touch/system/rotation-lock", locked ? "true" : "false"});
    p.waitForFinished(1000);
}

bool FpWake::getRotationLock() {
    QProcess p;
    p.start("dconf", {"read", "/com/lomiri/touch/system/rotation-lock"});
    p.waitForFinished(1000);
    return p.readAllStandardOutput().trimmed() == "true";
}
void FpWake::toggleLocation() {
    QDBusInterface iface("com.lomiri.indicator.location", "/com/lomiri/indicator/location",
                         "org.gtk.Actions", QDBusConnection::sessionBus());
    if (iface.isValid()) {
        iface.call("Activate", QString("location-detection-enabled"), QVariantList(), QVariantMap());
    }
}

void FpWake::openSettings() {
    QProcess::startDetached("lomiri-app-launch", QStringList() << "lomiri-system-settings");
}

QString FpWake::wifiSsid() {
    QDBusInterface nm("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager",
                      "org.freedesktop.DBus.Properties", QDBusConnection::systemBus());
    QDBusReply<QVariant> reply = nm.call("Get", "org.freedesktop.NetworkManager", "ActiveConnections");
    if (!reply.isValid()) return "";
    QList<QDBusObjectPath> conns = qdbus_cast<QList<QDBusObjectPath>>(reply.value());
    for (const auto &conn : conns) {
        QDBusInterface ac("org.freedesktop.NetworkManager", conn.path(),
                          "org.freedesktop.DBus.Properties", QDBusConnection::systemBus());
        QDBusReply<QVariant> typeReply = ac.call("Get", "org.freedesktop.NetworkManager.Connection.Active", "Type");
        if (typeReply.isValid() && typeReply.value().toString() == "802-11-wireless") {
            QDBusReply<QVariant> idReply = ac.call("Get", "org.freedesktop.NetworkManager.Connection.Active", "Id");
            if (idReply.isValid()) return idReply.value().toString();
        }
    }
    return "";
}

QString FpWake::btDevice() {
    QProcess p; p.start("bluetoothctl", {"devices", "Connected"});
    p.waitForFinished(1000);
    QString out = p.readAllStandardOutput().trimmed();
    if (!out.isEmpty()) {
        int i = out.indexOf(' ', out.indexOf(' ') + 1);
        if (i > 0) return out.mid(i + 1).split('\n').first().trimmed();
    }
    return "";
}

void FpWake::wifiToggle() {
    QDBusInterface nm("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager",
                      "org.freedesktop.DBus.Properties", QDBusConnection::systemBus());
    QDBusReply<QVariant> reply = nm.call("Get", "org.freedesktop.NetworkManager", "WirelessEnabled");
    bool enabled = reply.isValid() && reply.value().toBool();
    nm.call("Set", "org.freedesktop.NetworkManager", "WirelessEnabled", QVariant::fromValue(QDBusVariant(!enabled)));
}

void FpWake::btToggle() {
    QProcess::startDetached("bluetoothctl", {"power", btEnabled() ? "off" : "on"});
}

bool FpWake::wifiEnabled() {
    QDBusInterface nm("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager",
                      "org.freedesktop.DBus.Properties", QDBusConnection::systemBus());
    QDBusReply<QVariant> reply = nm.call("Get", "org.freedesktop.NetworkManager", "WirelessEnabled");
    return reply.isValid() && reply.value().toBool();
}

bool FpWake::btEnabled() {
    QProcess p; p.start("bluetoothctl", {"show"});
    p.waitForFinished(1000);
    return p.readAllStandardOutput().contains("Powered: yes");
}

QVariantList FpWake::wifiNetworks() {
    QVariantList list;
    QProcess p; p.start("nmcli", {"-t", "-f", "active,signal,ssid", "dev", "wifi"});
    p.waitForFinished(5000);
    for (const QString &l : QString(p.readAllStandardOutput()).split('\n')) {
        QStringList parts = l.split(':');
        if (parts.size() >= 3 && !parts[2].isEmpty()) {
            QVariantMap net;
            net["active"] = parts[0] == "yes";
            net["signal"] = parts[1].toInt();
            net["ssid"] = parts[2];
            list.append(net);
        }
    }
    return list;
}

void FpWake::wifiConnect(const QString &ssid) {
    QProcess::startDetached("nmcli", {"con", "up", ssid});
}

void FpWakePlugin::registerTypes(const char *uri) {
    qmlRegisterSingletonType<FpWake>(uri, 0, 1, "FpWake",
        [](QQmlEngine *, QJSEngine *) -> QObject * { return new FpWake; });
}
