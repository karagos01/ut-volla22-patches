import QtQuick 2.4
import "key_constants.js" as UI

ActionKey {
    label: "Ctrl"
    shifted: "Ctrl"
    action: "ctrl"

    padding: 0
    width: panel.keyWidth

    overridePressArea: true

    normalColor: panel.ctrlActive ? fullScreenItem.theme.actionKeyPressedColor
                                  : fullScreenItem.theme.actionKeyColor

    onPressed: {
        if (maliit_input_method.useAudioFeedback)
            audioFeedback.play();

        if (maliit_input_method.useHapticFeedback)
            pressEffect.start();

        panel.ctrlActive = !panel.ctrlActive;
    }
}
