import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// "Claude ━━━┿━ 72%": the Claude plan's week in the bar (services/ClaudeUsage). A 48px track in
// the day arc's style: the weekly limit used lit in text at 42%, a tick where even use would have
// reached by now, so fill past the tick is ahead of pace. The figure sits in a fixed cell; at 90%
// it turns caution and is underlined (the tooltip says "high"), alert at the limit, text2 while
// the reading is old. The label is gilt while its plate (ClaudePanel) is open. Hidden until the
// first reading, and without a Claude sign-in in omp.
Item {
    id: root

    readonly property bool open: panel.visible

    visible: ClaudeUsage.available
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.toggle()
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 6

        BarText {
            text: "Claude"
            color: root.open ? Theme.gilt : area.containsMouse ? Theme.text : Theme.text2
        }

        Item {
            id: track
            implicitWidth: 48
            implicitHeight: 8

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 2
                color: Theme.rule
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(Math.min(ClaudeUsage.percent, 100) / 100 * track.width)
                height: 2
                color: Theme.tint(Theme.text, 0.42)
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round(ClaudeUsage.elapsed * (track.width - 1))
                width: 1
                height: 6
                color: Theme.tint(Theme.text, 0.7)
            }
        }

        BarText {
            Layout.preferredWidth: widest.advanceWidth
            text: `${Math.round(ClaudeUsage.percent)}%`
            color: ClaudeUsage.full ? Theme.alert : ClaudeUsage.high ? Theme.caution : ClaudeUsage.stale ? Theme.text2 : Theme.text
            font.underline: ClaudeUsage.high

            TextMetrics {
                id: widest
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.features: Theme.fontFeatures
                text: "100%"
            }
        }
    }

    Tooltip {
        anchorItem: root
        active: area.containsMouse && !panel.visible
        text: {
            const parts = [`Claude ${Math.round(ClaudeUsage.percent)}% of this week`];
            if (ClaudeUsage.full)
                parts.push("limit reached");
            else if (ClaudeUsage.high)
                parts.push("high");
            parts.push(`resets ${ClaudeUsage.when(ClaudeUsage.weekEnd)}`);
            if (ClaudeUsage.stale && ClaudeUsage.fetchedAt > 0)
                parts.push(`as of ${ClaudeUsage.when(ClaudeUsage.fetchedAt)}`);
            return parts.join(" · ");
        }
    }

    ClaudePanel {
        id: panel
        anchorItem: root
    }
}
