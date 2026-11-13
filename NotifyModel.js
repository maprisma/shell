.pragma library
// shell.json's "notifications" group and the popups' placement, without QML:
// pure functions, tested by tests/run.sh.
//
// "notifications": { "dnd": false, "position": "top-right", "timeout": 5, "max": 5 }
// The same contract is read and written by Maprisma Notifier and Maprisma Settings.

var POSITIONS = ["top-right", "top", "top-left", "bottom-right", "bottom-left"]

function defaults() {
    return { dnd: false, position: "top-right", timeout: 5, max: 5 }
}

// A whole number in lo..hi: not a number → the default, out of range → clamped.
function intIn(v, lo, hi, fallback) {
    if (typeof v !== "number" || !isFinite(v)) return fallback
    return Math.min(hi, Math.max(lo, Math.round(v)))
}

// The group from a parsed shell.json (anything): every key checked on its own.
function normalize(cfg) {
    var d = defaults()
    var n = cfg && typeof cfg === "object" && cfg.notifications
    if (!n || typeof n !== "object" || Array.isArray(n)) return d
    return {
        dnd: typeof n.dnd === "boolean" ? n.dnd : d.dnd,
        position: POSITIONS.indexOf(n.position) >= 0 ? n.position : d.position,
        timeout: intIn(n.timeout, 1, 60, d.timeout),
        max: intIn(n.max, 1, 10, d.max)
    }
}

// shell.json's text with notifications.dnd set, every other key kept.
// null when the current text is not a JSON object (never clobber a file we can't read);
// a missing or empty file starts from {}.
function withDnd(text, on) {
    var cfg
    if (text === undefined || text === null || String(text).trim() === "") {
        cfg = {}
    } else {
        try {
            cfg = JSON.parse(text)
        } catch (e) {
            return null
        }
        if (!cfg || typeof cfg !== "object" || Array.isArray(cfg)) return null
    }
    var n = cfg.notifications
    if (!n || typeof n !== "object" || Array.isArray(n)) n = {}
    n.dnd = on === true
    cfg.notifications = n
    return JSON.stringify(cfg, null, 2) + "\n"
}

// The popup window's layer-shell anchors and margins for a position.
// bar: the bar's height. At the top the popups sit 6 px below the bar (as they always
// did), at the bottom and the sides 8 px from the edge. "top" anchors only the top
// edge: the compositor centres it.
var GAP = 8
function placement(position, bar) {
    if (POSITIONS.indexOf(position) < 0) position = defaults().position
    var top = position.indexOf("top") === 0
    var left = /left$/.test(position)
    var right = /right$/.test(position)
    return {
        top: top,
        bottom: !top,
        left: left,
        right: right,
        marginTop: top ? bar + 6 : 0,
        marginBottom: top ? 0 : GAP,
        marginLeft: left ? GAP : 0,
        marginRight: right ? GAP : 0
    }
}

// The popups after one more arrives: at most max, the oldest leave first.
// Returns { shown, dropped } (new arrays, oldest first).
function push(list, item, max) {
    var all = (list || []).filter(function (x) { return x !== item })
    all.push(item)
    return trim(all, max)
}

function trim(list, max) {
    var all = (list || []).slice()
    var keep = Math.max(1, max | 0)
    var cut = Math.max(0, all.length - keep)
    return { shown: all.slice(cut), dropped: all.slice(0, cut) }
}

function remove(list, item) {
    return (list || []).filter(function (x) { return x !== item })
}
