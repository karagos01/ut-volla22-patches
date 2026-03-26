import QtQuick 2.4
import Biometryd 0.0

Item {
    property var enrollOp: null
    User { id: fpUser; uid: 32011 }
    Observer {
        id: obs
        onStarted: console.log("Touch the sensor repeatedly (~14 times)...")
        onProgressed: console.log("Progress:", Math.round(percent * 100), "%")
        onFailed: { console.log("FAILED:", reason); Qt.quit() }
        onSucceeded: { console.log("SUCCESS! Fingerprint enrolled, ID:", result); Qt.quit() }
    }
    Component.onCompleted: {
        if (!Biometryd.available) { console.log("Biometryd not available"); Qt.quit(); return }
        enrollOp = Biometryd.defaultDevice.templateStore.enroll(fpUser)
        enrollOp.start(obs)
    }
    Timer { interval: 120000; running: true; onTriggered: { console.log("Timeout"); if(enrollOp) enrollOp.cancel(); Qt.quit() } }
}
