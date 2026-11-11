.pragma library
// The bar's layout, without QML: pure functions, tested by tests/run.sh.
//
// bar.json: { version, background, left: [...], center: [...], right: [...] }
// An entry is a built-in widget id ("clock"), "tray" (every tray icon that has
// no place of its own) or "tray:<item id>" (one tray icon placed by hand).

var BUILTINS = ["launcher", "workspaces", "clock", "bluetooth", "network", "audio", "power"]
var ZONES = ["left", "center", "right"]
var BACKGROUNDS = ["clear", "glassy", "opaque"]

function defaults() {
    return {
        version: 1,
        background: "opaque",
        left: ["launcher", "workspaces"],
        center: ["clock"],
        right: ["tray", "bluetooth", "network", "audio", "power"]
    }
}

function defaultZone(id) {
    var d = defaults()
    for (var i = 0; i < ZONES.length; i++)
        if (d[ZONES[i]].indexOf(id) >= 0) return ZONES[i]
    return "right"
}

function parse(text) {
    try {
        return JSON.parse(text)
    } catch (e) {
        return null
    }
}

function validEntry(entry) {
    if (typeof entry !== "string") return false
    if (BUILTINS.indexOf(entry) >= 0 || entry === "tray") return true
    return /^tray:[^\x00-\x1f]{1,200}$/.test(entry)
}

// A layout that is whole: every built-in once, "tray" once, nothing unknown.
function normalize(cfg) {
    var out = { version: 1, background: "opaque", left: [], center: [], right: [] }
    var d = defaults()
    if (!cfg || typeof cfg !== "object") cfg = d
    out.background = BACKGROUNDS.indexOf(cfg.background) >= 0 ? cfg.background : d.background
    var seen = {}
    var any = false
    for (var z = 0; z < ZONES.length; z++) {
        var list = Array.isArray(cfg[ZONES[z]]) ? cfg[ZONES[z]] : []
        for (var i = 0; i < list.length; i++) {
            var e = list[i]
            if (!validEntry(e) || seen[e]) continue
            seen[e] = true
            any = true
            out[ZONES[z]].push(e)
        }
    }
    if (!any) {
        var bg = out.background
        out = normalize(d)
        out.background = bg
        return out
    }
    for (var b = 0; b < BUILTINS.length; b++)
        if (!seen[BUILTINS[b]]) out[defaultZone(BUILTINS[b])].push(BUILTINS[b])
    if (!seen["tray"]) out.right.unshift("tray")
    return out
}

function nextBackground(current) {
    var i = BACKGROUNDS.indexOf(current)
    return BACKGROUNDS[(i + 1) % BACKGROUNDS.length]
}

// What the bar shows: per zone a list of { key, kind, id, group, hidden }.
// kind: "builtin", "tray" or "marker" (the place of "tray" while it has no
// icons). group: a tray icon shown at the "tray" place. hidden: not drawn (a
// placed tray icon whose app is not running, or the empty marker).
function expand(cfg, trayIds) {
    cfg = normalize(cfg)
    var placed = {}
    for (var z = 0; z < ZONES.length; z++)
        for (var i = 0; i < cfg[ZONES[z]].length; i++)
            if (cfg[ZONES[z]][i].indexOf("tray:") === 0) placed[cfg[ZONES[z]][i].slice(5)] = true
    var running = {}
    for (var t = 0; t < trayIds.length; t++) running[trayIds[t]] = true
    var out = { left: [], center: [], right: [] }
    for (z = 0; z < ZONES.length; z++) {
        var list = cfg[ZONES[z]]
        for (i = 0; i < list.length; i++) {
            var e = list[i]
            if (e === "tray") {
                var group = trayIds.filter(function (id) { return !placed[id] })
                if (group.length === 0)
                    out[ZONES[z]].push({ key: "tray", kind: "marker", id: "", group: false, hidden: true })
                for (var g = 0; g < group.length; g++)
                    out[ZONES[z]].push({ key: "tray:" + group[g], kind: "tray", id: group[g], group: true, hidden: false })
            } else if (e.indexOf("tray:") === 0) {
                var id = e.slice(5)
                out[ZONES[z]].push({ key: e, kind: "tray", id: id, group: false, hidden: !running[id] })
            } else {
                out[ZONES[z]].push({ key: e, kind: "builtin", id: e, group: false, hidden: false })
            }
        }
    }
    return out
}

function visible(list) {
    return list.filter(function (e) { return !e.hidden })
}

// Moves the entry [key] to [zone], before the [index]th visible entry there
// (counted without the moved entry; past the end = after the last visible
// one). A tray icon moved this way gets a place of its own.
function moveTo(expanded, key, zone, index) {
    var out = { left: expanded.left.slice(), center: expanded.center.slice(), right: expanded.right.slice() }
    var moved = null
    for (var z = 0; z < ZONES.length; z++) {
        var list = out[ZONES[z]]
        for (var i = 0; i < list.length; i++) {
            if (list[i].key === key) {
                moved = list.splice(i, 1)[0]
                break
            }
        }
        if (moved) break
    }
    if (!moved || moved.kind === "marker" || ZONES.indexOf(zone) < 0) return expanded
    moved = { key: moved.key, kind: moved.kind, id: moved.id, group: false, hidden: false }
    var target = out[zone]
    var shown = []
    for (i = 0; i < target.length; i++) if (!target[i].hidden) shown.push(i)
    var at
    if (index < 0) index = 0
    if (index < shown.length) at = shown[index]
    else at = shown.length ? shown[shown.length - 1] + 1 : target.length
    target.splice(at, 0, moved)
    return out
}

// Back to bar.json's form. The first run of grouped tray icons becomes
// "tray" again; grouped icons split off from it get places of their own.
function collapse(expanded, background) {
    var cfg = { version: 1, background: BACKGROUNDS.indexOf(background) >= 0 ? background : "opaque", left: [], center: [], right: [] }
    var marker = false
    for (var z = 0; z < ZONES.length; z++) {
        var list = expanded[ZONES[z]]
        var inRun = false
        for (var i = 0; i < list.length; i++) {
            var e = list[i]
            if (e.kind === "marker") {
                if (!marker) cfg[ZONES[z]].push("tray")
                marker = true
                inRun = false
            } else if (e.group) {
                if (!marker) {
                    cfg[ZONES[z]].push("tray")
                    marker = true
                    inRun = true
                } else if (!inRun) {
                    cfg[ZONES[z]].push(e.key)
                }
            } else {
                // Hidden placed icons keep their place without ending the run.
                if (!e.hidden) inRun = false
                cfg[ZONES[z]].push(e.key)
            }
        }
    }
    return normalize(cfg)
}

// One drag and drop, from bar.json to bar.json.
function move(cfg, trayIds, key, zone, index) {
    cfg = normalize(cfg)
    return collapse(moveTo(expand(cfg, trayIds), key, zone, index), cfg.background)
}

// Tray item ids made unique (two copies of one app share an id).
function uniqueIds(ids) {
    var count = {}
    return ids.map(function (id) {
        id = String(id || "item")
        count[id] = (count[id] || 0) + 1
        return count[id] > 1 ? id + "#" + count[id] : id
    })
}
