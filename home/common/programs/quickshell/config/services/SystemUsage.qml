pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory and root filesystem usage in percent.
Singleton {
    id: root

    property real cpu: 0
    property real memory: 0
    property real disk: 0

    property var lastCpu: null

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            // cpu  user nice system idle iowait irq softirq steal (guest columns are already in user/nice)
            const fields = text().split("\n")[0].trim().split(/\s+/).slice(1, 9).map(Number);
            const idle = fields[3] + fields[4];
            const total = fields.reduce((sum, value) => sum + value, 0);
            if (root.lastCpu !== null && total > root.lastCpu.total)
                root.cpu = 100 * (1 - (idle - root.lastCpu.idle) / (total - root.lastCpu.total));
            root.lastCpu = {
                idle,
                total
            };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const content = text();
            const field = key => Number(content.match(new RegExp(`^${key}:\\s+(\\d+)`, "m"))?.[1] ?? 0);
            const total = field("MemTotal");
            if (total > 0)
                root.memory = 100 * (total - field("MemAvailable")) / total;
        }
    }

    Process {
        id: df
        command: ["df", "-B1", "--output=size,used", "/"]
        stdout: StdioCollector {
            id: dfOut
            onStreamFinished: {
                const [size, used] = dfOut.text.trim().split("\n")[1].trim().split(/\s+/).map(Number);
                if (size > 0)
                    root.disk = 100 * used / size;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }
}
