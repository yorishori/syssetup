pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Read-only calendar events from a CalDAV server (Config.calendar.url).
//
// No sync and no polling: load(from, to) queries the server for that range
// only, when the calendar asks (on open / month change). Recurring events are
// expanded by the server, so each result is a plain occurrence.
//
// Login comes from ~/.netrc via curl. An unreachable server just means no
// events; a rejected login is reported to Health.
Singleton {
    id: root

    readonly property string url: Config.calendar.url
    readonly property string origin: (url.match(/^https?:\/\/[^\/]+/) ?? [""])[0]

    // idle, offline, unauthorized, ready
    property string state: "idle"
    readonly property bool available: state === "ready"

    // [{ href, name, color }]
    property var calendars: []
    // Occurrences in the last loaded range:
    // [{ summary, location, start: Date, end: Date, allDay, color, calendar }]
    property var events: []

    property var range: null  // { from, to } most recently asked for

    function load(from: date, to: date): void {
        range = { from, to };
        if (!url)
            return;
        if (state === "ready")
            fetch();
        else
            discover();
    }

    // Events that touch the given local day, all-day first, then by start time.
    function on(day: date): var {
        const start = new Date(day.getFullYear(), day.getMonth(), day.getDate());
        const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 1);
        return events
            .filter(e => e.start < end && e.end > start)
            .sort((a, b) => (b.allDay - a.allDay) || (a.start - b.start));
    }

    // ── HTTP (curl, one request at a time) ───────────────────────────────────

    property var queue: []

    function request(method: string, target: string, depth: string, body: string, done: var): void {
        queue = [...queue, { method, target, depth, body, done }];
        next();
    }

    function next(): void {
        if (http.running || queue.length === 0)
            return;
        const job = queue[0];
        queue = queue.slice(1);
        http.job = job;
        http.command = ["curl", "-s", "-m", "6", "--netrc-optional", "-X", job.method,
            "-H", `Depth: ${job.depth}`, "-H", "Content-Type: application/xml; charset=utf-8",
            "--data-binary", job.body, "-w", "\n%{http_code}", job.target];
        http.running = true;
    }

    Process {
        id: http

        property var job: null

        stdout: StdioCollector {
            onStreamFinished: {
                const cut = text.lastIndexOf("\n");
                const code = parseInt(text.slice(cut + 1)) || 0;
                const job = http.job;
                http.job = null;
                try {
                    job.done(code, text.slice(0, cut));
                } finally {
                    Qt.callLater(root.next);
                }
            }
        }
    }

    // ── Discovery: principal → calendar home → calendars ─────────────────────

    function absolute(href: string): string {
        return href.startsWith("http") ? href : origin + href;
    }

    function hrefIn(body: string, tag: string): string {
        const m = body.match(new RegExp(`<(?:\\w+:)?${tag}[^>]*>\\s*<(?:\\w+:)?href>([^<]+)<`));
        return m ? m[1].trim() : "";
    }

    // Set state from an HTTP status; true if the response can be used.
    function usable(code: int): bool {
        if (code === 401 || code === 403) {
            state = "unauthorized";
            return false;
        }
        if (code !== 207) {
            state = "offline";
            return false;
        }
        return true;
    }

    function discover(): void {
        const dav = 'xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"';
        request("PROPFIND", url, "0", `<d:propfind ${dav}><d:prop><d:current-user-principal/></d:prop></d:propfind>`, (code, body) => {
            if (!usable(code))
                return;
            const principal = hrefIn(body, "current-user-principal");
            request("PROPFIND", absolute(principal), "0", `<d:propfind ${dav}><d:prop><c:calendar-home-set/></d:prop></d:propfind>`, (code, body) => {
                if (!usable(code))
                    return;
                const home = hrefIn(body, "calendar-home-set");
                request("PROPFIND", absolute(home), "1", `<d:propfind ${dav}><d:prop><d:resourcetype/><d:displayname/><c:supported-calendar-component-set/></d:prop></d:propfind>`, (code, body) => {
                    if (!usable(code))
                        return;
                    const found = [];
                    for (const r of body.match(/<(?:\w+:)?response[\s>][\s\S]*?<\/(?:\w+:)?response>/g) ?? []) {
                        const isCalendar = /<(?:\w+:)?calendar\s*\/>/.test(r);
                        const comps = r.match(/<(?:\w+:)?comp\s+name="([^"]+)"/g);
                        if (!isCalendar || (comps && !comps.some(c => c.includes("VEVENT"))))
                            continue;
                        const href = (r.match(/<(?:\w+:)?href>([^<]+)</) ?? [])[1];
                        const name = (r.match(/<(?:\w+:)?displayname>([^<]*)</) ?? [])[1] || href;
                        found.push({ href: absolute(href), name, color: "" });
                    }
                    const palette = Config.calendar.colors;
                    root.calendars = found.map((c, i) => Object.assign(c, { color: palette[i % palette.length] }));
                    root.state = "ready";
                    if (root.range)
                        root.fetch();
                });
            });
        });
    }

    // ── Events ───────────────────────────────────────────────────────────────

    function stamp(d: date): string {
        return d.toISOString().replace(/[-:]/g, "").replace(/\.\d+/, "");
    }

    function fetch(): void {
        const from = stamp(range.from), to = stamp(range.to);
        const key = from + to;
        const body = `<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">`
            + `<d:prop><c:calendar-data><c:expand start="${from}" end="${to}"/></c:calendar-data></d:prop>`
            + `<c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VEVENT">`
            + `<c:time-range start="${from}" end="${to}"/></c:comp-filter></c:comp-filter></c:filter>`
            + `</c:calendar-query>`;

        let pending = calendars.length, collected = [];
        if (pending === 0)
            events = [];
        for (const cal of calendars) {
            request("REPORT", cal.href, "1", body, (code, text) => {
                if (code === 207)
                    collected.push(...parseEvents(text, cal));
                else if (code === 401 || code === 403)
                    root.state = "unauthorized";
                // Only the latest range wins; a stale response is dropped.
                if (--pending === 0 && root.range && stamp(root.range.from) + stamp(root.range.to) === key)
                    root.events = collected;
            });
        }
    }

    function unxml(s: string): string {
        return s.replace(/&#13;/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
            .replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, "&");
    }

    function unics(s: string): string {
        return s.replace(/\\n/gi, " ").replace(/\\([,;\\])/g, "$1");
    }

    // "20260927" (all-day), "20260927T140000Z" (UTC) or "20260927T140000" (local).
    function icsDate(v: string): date {
        const n = (a, b) => parseInt(v.slice(a, b));
        if (v.length === 8)
            return new Date(n(0, 4), n(4, 6) - 1, n(6, 8));
        const args = [n(0, 4), n(4, 6) - 1, n(6, 8), n(9, 11), n(11, 13), n(13, 15)];
        return v.endsWith("Z") ? new Date(Date.UTC(...args)) : new Date(...args);
    }

    function parseEvents(xml: string, cal: var): var {
        const out = [];
        for (const block of xml.match(/<(?:\w+:)?calendar-data[^>]*>[\s\S]*?<\/(?:\w+:)?calendar-data>/g) ?? []) {
            const ics = unxml(block.replace(/^<[^>]*>|<\/[^>]*>$/g, "")).replace(/\r?\n[ \t]/g, "");
            for (const vevent of ics.match(/BEGIN:VEVENT[\s\S]*?END:VEVENT/g) ?? []) {
                const props = {};
                for (const line of vevent.split(/\r?\n/)) {
                    const m = line.match(/^([A-Z-]+)((?:;[^:]*)?):(.*)$/);
                    if (m && !(m[1] in props))
                        props[m[1]] = { params: m[2], value: m[3] };
                }
                if (!props.DTSTART || props.STATUS?.value === "CANCELLED")
                    continue;
                const allDay = props.DTSTART.value.length === 8;
                const start = icsDate(props.DTSTART.value);
                const end = props.DTEND ? icsDate(props.DTEND.value)
                    : new Date(start.getTime() + (allDay ? 86400000 : 0));
                out.push({
                    summary: unics(props.SUMMARY?.value ?? "(no title)"),
                    location: unics(props.LOCATION?.value ?? ""),
                    start, end, allDay,
                    color: cal.color,
                    calendar: cal.name
                });
            }
        }
        return out;
    }

    HealthCheck {
        source: "calendar"
        ok: root.state !== "unauthorized"
        reason: `login to ${root.origin} was rejected; add it to ~/.netrc`
        grace: 0
    }

    // qs ipc call events status
    IpcHandler {
        target: "events"

        function status(): string {
            return `${root.state}: ${root.calendars.map(c => c.name).join(", ") || "no calendars"}; ${root.events.length} events loaded`;
        }
    }
}
