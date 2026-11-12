import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services
import qs.widgets

// The control panel's Claude section: the plan's week, this week's limit in words first (used,
// and when it runs out at the pace so far), then the week drawn as a chart in an inset well: a day
// per column split at midnight, the even pace as a muted diagonal, the readings as an enamel line
// that steps up as the week is used, and a gilt dot at now, as on the day arc. Under it when the
// week resets and how much of it has gone; then the model and session limits and a link to
// claude.ai's own page. When the reading was taken (`updated`) goes in the section's header.
ColumnLayout {
    id: root

    signal linkOpened

    readonly property string updated: {
        if (ClaudeUsage.fetchedAt === 0)
            return "";
        const at = ClaudeUsage.when(ClaudeUsage.fetchedAt);
        switch (ClaudeUsage.status) {
        case "ok":
            return `Updated ${at}`;
        case "expired":
            return `As of ${at}, until omp runs`;
        case "rejected":
            return `As of ${at}, sign-in refused`;
        case "limited":
            return `As of ${at}, asked too often`;
        case "unreachable":
            return `As of ${at}, offline`;
        default:
            return `As of ${at}, Claude didn't answer`;
        }
    }

    readonly property string pace: {
        if (ClaudeUsage.reset)
            return `A new week began ${ClaudeUsage.when(ClaudeUsage.weekStart)}`;
        if (ClaudeUsage.full)
            return `Limit reached until ${ClaudeUsage.when(ClaudeUsage.weekEnd)}`;
        if (ClaudeUsage.runsOutAt > 0)
            return `At this pace it runs out ${ClaudeUsage.when(ClaudeUsage.runsOutAt)}`;
        if (!ClaudeUsage.paced)
            return "Too early in the week to tell the pace";
        return `On pace to end the week near ${Math.round(ClaudeUsage.projected)}%`;
    }

    spacing: 0

    component Rule: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        implicitHeight: 1
        color: Theme.rule
    }

    component Label: BarText {
        Layout.bottomMargin: 6
        color: Theme.text2
        font.pixelSize: 11
    }

    RowLayout {
        Layout.fillWidth: true

        BarText {
            Layout.fillWidth: true
            text: "This week"
            font.pixelSize: 12
        }

        BarText {
            text: `${Math.round(ClaudeUsage.percent)}%`
            color: ClaudeUsage.full ? Theme.alert : ClaudeUsage.high ? Theme.caution : Theme.text
            font.underline: ClaudeUsage.high
            font.pixelSize: 12
            font.bold: true
        }
    }

    // Running out early is the one thing here that asks for a change, so it alone is caution;
    // the words carry it as well as the colour.
    BarText {
        Layout.fillWidth: true
        Layout.topMargin: 2
        text: root.pace
        color: ClaudeUsage.full ? Theme.alert : ClaudeUsage.runsOutAt > 0 ? Theme.caution : Theme.text2
        font.pixelSize: 12
        wrapMode: Text.Wrap
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 8
        implicitHeight: chart.height + days.height + 18
        radius: Theme.radiusInset
        color: Theme.inset

        WeekChart {
            id: chart
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            anchors.topMargin: 10
            height: 72
        }

        // The days under their columns; a sliver of a day (the week begins and ends at the
        // same hour) goes unnamed.
        Item {
            id: days
            anchors.left: chart.left
            anchors.right: chart.right
            anchors.top: chart.bottom
            anchors.topMargin: 2
            height: 14

            Repeater {
                model: chart.columns.filter(c => c.width >= 26)

                BarText {
                    required property var modelData

                    x: modelData.x
                    width: modelData.width
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData.label
                    color: Theme.text2
                    font.pixelSize: 11
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6

        BarText {
            Layout.fillWidth: true
            text: `Resets ${ClaudeUsage.when(ClaudeUsage.weekEnd)} · in ${ClaudeUsage.span(ClaudeUsage.weekEnd - ClaudeUsage.now)}`
            color: Theme.text2
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        BarText {
            text: `${Math.round(ClaudeUsage.elapsed * 100)}% of the week gone`
            color: Theme.text2
            font.pixelSize: 11
        }
    }

    Rule {
        visible: ClaudeUsage.others.length > 0
    }

    Label {
        visible: ClaudeUsage.others.length > 0
        text: "Other limits"
    }

    Repeater {
        model: ClaudeUsage.others

        ColumnLayout {
            id: limit

            required property var modelData
            required property int index
            readonly property real percent: ClaudeUsage.reset && modelData.kind.startsWith("weekly") ? 0 : modelData.percent

            Layout.fillWidth: true
            Layout.topMargin: index > 0 ? 6 : 0
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                BarText {
                    Layout.preferredWidth: 80
                    text: limit.modelData.label
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Theme.inset

                    Rectangle {
                        width: Math.round(Math.min(limit.percent, 100) / 100 * parent.width)
                        height: parent.height
                        radius: 2
                        color: Theme.fill
                    }
                }

                BarText {
                    Layout.preferredWidth: 38
                    horizontalAlignment: Text.AlignRight
                    text: `${Math.round(limit.percent)}%`
                    color: limit.percent >= 100 ? Theme.alert : limit.percent >= 90 ? Theme.caution : Theme.text2
                    font.underline: limit.percent >= 90 && limit.percent < 100
                    font.pixelSize: 11
                }
            }

            BarText {
                readonly property bool ownReset: limit.modelData.resets_at !== null && Math.abs(limit.modelData.resets_at * 1000 - ClaudeUsage.weekEnd) > 3600 * 1000

                visible: text !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 90
                text: limit.modelData.allowance !== null ? `Up to ${limit.modelData.allowance}% of the weekly limit` : ownReset ? `Resets ${ClaudeUsage.when(limit.modelData.resets_at * 1000)}` : ""
                color: Theme.text2
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    RowLayout {
        visible: ClaudeUsage.extra !== null
        Layout.fillWidth: true
        Layout.topMargin: 8

        BarText {
            Layout.fillWidth: true
            text: "Extra usage this month"
            color: Theme.text2
            font.pixelSize: 11
        }

        BarText {
            readonly property var extra: ClaudeUsage.extra

            text: extra === null ? "" : `${Number(extra.used).toLocaleString(Qt.locale(), "f", extra.decimals)} of ${Number(extra.limit).toLocaleString(Qt.locale(), "f", extra.decimals)} ${extra.currency}`
            font.pixelSize: 11
        }
    }

    Rule {}

    ListRow {
        Layout.fillWidth: true
        icon: Icons.openInNew
        label: "Usage on claude.ai"
        onClicked: {
            Qt.openUrlExternally("https://claude.ai/settings/usage");
            root.linkOpened();
        }
    }

    // The week as a chart: x from the week's start to its reset, y from nothing to the limit.
    component WeekChart: Item {
        id: chart

        readonly property double start: ClaudeUsage.weekStart
        readonly property double end: ClaudeUsage.weekEnd
        readonly property var points: ClaudeUsage.history
        readonly property real nowX: xOf(ClaudeUsage.now)
        readonly property real nowY: yOf(ClaudeUsage.percent)
        // The days: [{ x, width, label }], split at local midnight.
        readonly property var columns: {
            if (end <= start || width <= 0)
                return [];
            const edges = [start];
            const midnight = new Date(start);
            midnight.setHours(24, 0, 0, 0);
            for (let t = midnight.getTime(); t < end; t += 24 * 3600 * 1000)
                edges.push(t);
            edges.push(end);
            const result = [];
            for (let i = 0; i + 1 < edges.length; i++) {
                const x = xOf(edges[i]);
                result.push({
                    x: x,
                    width: xOf(edges[i + 1]) - x,
                    label: Qt.formatDate(new Date(edges[i]), "ddd")
                });
            }
            return result;
        }

        function xOf(t: double): real {
            return end > start ? (t - start) / (end - start) * width : 0;
        }

        // The dot's room is kept at both ends, so 0% and 100% stay inside the well.
        function yOf(percent: real): real {
            return 4 + (height - 8) * (1 - Math.min(Math.max(percent, 0), 100) / 100);
        }

        onPointsChanged: canvas.requestPaint()
        onWidthChanged: canvas.requestPaint()
        onColumnsChanged: canvas.requestPaint()
        onNowXChanged: canvas.requestPaint()
        onNowYChanged: canvas.requestPaint()

        Canvas {
            id: canvas
            anchors.fill: parent

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width;
                const h = height;

                // Midnights.
                ctx.lineWidth = 1;
                ctx.strokeStyle = String(Theme.rule);
                ctx.beginPath();
                for (const column of chart.columns.slice(1)) {
                    const x = Math.round(column.x) + 0.5;
                    ctx.moveTo(x, 0);
                    ctx.lineTo(x, h);
                }
                ctx.stroke();

                // Even pace, dotted from nothing at the start to the limit at the reset.
                ctx.fillStyle = String(Theme.muted);
                const y0 = chart.yOf(0);
                const y1 = chart.yOf(100);
                for (let x = 0; x < w; x += 5)
                    ctx.fillRect(Math.round(x), Math.round(y0 + (y1 - y0) * x / w), 2, 1);

                // The readings: each holds until the next.
                const points = chart.points;
                if (points.length === 0)
                    return;
                ctx.strokeStyle = String(Theme.text);
                ctx.lineWidth = 1.5;
                ctx.lineJoin = "round";
                ctx.beginPath();
                ctx.moveTo(chart.xOf(points[0][0]), chart.yOf(points[0][1]));
                for (let i = 1; i < points.length; i++) {
                    const x = chart.xOf(points[i][0]);
                    ctx.lineTo(x, chart.yOf(points[i - 1][1]));
                    ctx.lineTo(x, chart.yOf(points[i][1]));
                }
                ctx.lineTo(chart.nowX, chart.yOf(points[points.length - 1][1]));
                ctx.stroke();

                // Now, as on the day arc: gilt, ringed in the well's own ground.
                ctx.fillStyle = String(Theme.inset);
                ctx.beginPath();
                ctx.arc(chart.nowX, chart.nowY, 5.5, 0, 2 * Math.PI);
                ctx.fill();
                ctx.fillStyle = String(Theme.gilt);
                ctx.beginPath();
                ctx.arc(chart.nowX, chart.nowY, 3.5, 0, 2 * Math.PI);
                ctx.fill();
            }

            // A canvas keeps its last picture when resized; draw it again at the new size.
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onAvailableChanged: requestPaint()
        }
    }
}
