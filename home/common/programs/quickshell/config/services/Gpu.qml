pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NVIDIA GPU utilisation and temperature from one long-running nvidia-smi (-l 2) instead of a process per sample.
Singleton {
    id: root

    property bool available: false
    property real usage: 0
    property real temperature: 0

    Process {
        id: smi
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits", "-l", "2"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const [usage, temperature] = line.split(",").map(Number);
                if (isNaN(usage) || isNaN(temperature))
                    return;
                root.usage = usage;
                root.temperature = temperature;
                root.available = true;
            }
        }
        // Missing driver or a driver reload: hide the ring and retry slowly.
        onExited: {
            root.available = false;
            restart.start();
        }
    }

    Timer {
        id: restart
        interval: 30000
        onTriggered: smi.running = true
    }
}
