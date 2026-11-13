import QtQuick
import "../BarModel.js" as M
import "../NotifyModel.js" as N

// Run by tests/run.sh: qml6 headless, exits 0 when every check passes.
Item {
    property int failed: 0
    property int passed: 0

    function eq(what, got, want) {
        var a = JSON.stringify(got), b = JSON.stringify(want)
        if (a === b) {
            passed++
        } else {
            failed++
            console.error("FAIL " + what + "\n  got  " + a + "\n  want " + b)
        }
    }

    function keys(list) {
        return M.visible(list).map(function (e) { return e.key })
    }

    Component.onCompleted: {
        var d = M.defaults()

        eq("normalize null gives defaults", M.normalize(null), d)
        eq("normalize keeps a valid layout", M.normalize(d), d)
        eq("normalize adds missing builtins and tray",
           M.normalize({ left: ["clock"], center: [], right: [] }),
           { version: 1, background: "opaque", left: ["clock", "launcher", "workspaces"], center: [], right: ["tray", "bluetooth", "network", "audio", "power"], hidden: [] })
        eq("normalize drops unknown and duplicates",
           M.normalize({ background: "glassy", left: ["launcher", "bogus", "launcher", 5], center: ["clock", "tray:a", "tray:a"], right: ["tray"] }).center,
           ["clock", "tray:a"])
        eq("normalize keeps the background", M.normalize({ background: "clear", left: ["clock"] }).background, "clear")
        eq("bad background", M.normalize({ background: "pink", left: ["clock"] }).background, "opaque")
        eq("parse garbage", M.parse("{"), null)

        eq("background cycle", [M.nextBackground("clear"), M.nextBackground("glassy"), M.nextBackground("opaque")], ["glassy", "opaque", "clear"])

        var trays = ["a", "b", "c"]
        var ex = M.expand(d, trays)
        eq("expand right", keys(ex.right), ["tray:a", "tray:b", "tray:c", "bluetooth", "network", "audio", "power"])
        eq("expand no tray icons keeps a hidden marker", M.expand(d, []).right[0], { key: "tray", kind: "marker", id: "", group: false, hidden: true })

        // Moving a builtin within a zone and across zones.
        eq("move clock to the left end",
           M.move(d, trays, "clock", "left", 0),
           { version: 1, background: "opaque", left: ["clock", "launcher", "workspaces"], center: [], right: ["tray", "bluetooth", "network", "audio", "power"], hidden: [] })
        eq("move power before bluetooth (index counts visible, without the moved one)",
           M.move(d, trays, "power", "right", 3).right,
           ["tray", "power", "bluetooth", "network", "audio"])
        eq("move past the end", M.move(d, trays, "launcher", "right", 99).right,
           ["tray", "bluetooth", "network", "audio", "power", "launcher"])

        // A tray icon dragged out of the group gets its own place.
        var c1 = M.move(d, trays, "tray:b", "left", 1)
        eq("tray icon to the left", c1.left, ["launcher", "tray:b", "workspaces"])
        eq("the group keeps its place", c1.right, ["tray", "bluetooth", "network", "audio", "power"])
        eq("expanded after: b is placed, not grouped", keys(M.expand(c1, trays).right), ["tray:a", "tray:c", "bluetooth", "network", "audio", "power"])

        // Inside the group: moving c before a keeps a and b grouped.
        var c2 = M.move(d, trays, "tray:c", "right", 0)
        eq("c before the group", c2.right, ["tray:c", "tray", "bluetooth", "network", "audio", "power"])
        eq("c2 shows c, a, b", keys(M.expand(c2, trays).right).slice(0, 3), ["tray:c", "tray:a", "tray:b"])

        // A builtin dropped into the middle of the group splits it: the part after it is placed.
        var c3 = M.move(d, trays, "power", "right", 1)
        eq("split group", c3.right, ["tray", "power", "tray:b", "tray:c", "bluetooth", "network", "audio"])

        // A placed icon whose app is gone stays in bar.json and hides.
        var c4 = M.move(c1, ["a", "c"], "clock", "center", 0)
        eq("placed but not running kept", c4.left, ["launcher", "tray:b", "workspaces"])
        eq("hidden in expand", M.expand(c1, ["a", "c"]).left[1].hidden, true)
        eq("index skips hidden entries", M.move(c1, ["a", "c"], "clock", "left", 1).left, ["launcher", "tray:b", "clock", "workspaces"])

        // With no tray icons at all the marker stays where it was.
        eq("marker kept", M.move(d, [], "power", "left", 0).right, ["tray", "bluetooth", "network", "audio"])
        eq("the marker itself does not move", M.move(d, [], "tray", "left", 0), d)

        eq("unique ids", M.uniqueIds(["chrome", "x", "chrome", ""]), ["chrome", "x", "chrome#2", "item"])
        eq("a move keeps the background", M.move({ background: "glassy", left: ["clock"] }, [], "clock", "right", 0).background, "glassy")

        // Review findings (Codex): the group keeps its place when its last icon leaves.
        var centered = M.normalize({ left: ["launcher", "workspaces"], center: ["clock", "tray"], right: ["bluetooth", "network", "audio", "power"] })
        eq("last grouped icon dragged away: tray stays in center", M.move(centered, ["a"], "tray:a", "left", 0).center, ["clock", "tray"])
        eq("and the icon is placed", M.move(centered, ["a"], "tray:a", "left", 0).left, ["tray:a", "launcher", "workspaces"])
        eq("dropping before the group's first icon goes before the group",
           M.move(d, trays, "power", "right", 0).right, ["power", "tray", "bluetooth", "network", "audio"])
        eq("unique ids never take a real id", M.uniqueIds(["a", "a", "a#2"]), ["a", "a#3", "a#2"])
        eq("prototype names are plain ids",
           keys(M.expand(d, ["constructor", "toString", "__proto__"]).right).slice(0, 3),
           ["tray:constructor", "tray:toString", "tray:__proto__"])
        eq("a placed prototype-named icon that is not running hides",
           M.expand({ left: ["tray:constructor"] }, []).left[0].hidden, true)

        // hidden (Maprisma Settings' "take out").
        var hid = M.normalize({ left: ["launcher", "workspaces"], center: ["clock"], right: ["tray", "tray:b", "power"],
                                hidden: ["launcher", "tray:b", "tray", "bogus", "launcher", 7, "tray:c"] })
        eq("hidden keeps valid entries once, never tray", hid.hidden, ["launcher", "tray:b", "tray:c"])
        eq("a hidden widget leaves its zone and does not come back", hid.left, ["workspaces"])
        eq("a hidden tray icon leaves its zone", hid.right, ["tray", "power", "bluetooth", "network", "audio"])
        eq("a hidden icon is not in the catch-all group", keys(M.expand(hid, ["a", "b", "c"]).right).slice(0, 2), ["tray:a", "power"])
        eq("a drag keeps hidden", M.move(hid, ["a", "b", "c"], "power", "left", 0).hidden, ["launcher", "tray:b", "tray:c"])
        eq("defaults have an empty hidden", M.normalize(null).hidden, [])
        eq("an old file without hidden is fine", M.normalize({ left: ["clock"] }).hidden, [])
        eq("everything hidden from a zone: defaults are not brought back",
           M.normalize({ left: ["launcher"], hidden: ["launcher"] }).left, ["workspaces"])

        // shell.json "notifications".
        var nd = { dnd: false, position: "top-right", timeout: 5, max: 5 }
        eq("notifications defaults", N.defaults(), nd)
        eq("no file / garbage", [N.normalize(null), N.normalize("x"), N.normalize({}), N.normalize({ notifications: [] }), N.normalize({ notifications: 3 })], [nd, nd, nd, nd, nd])
        eq("valid values kept", N.normalize({ notifications: { dnd: true, position: "bottom-left", timeout: 12, max: 3 } }),
           { dnd: true, position: "bottom-left", timeout: 12, max: 3 })
        eq("every position", N.POSITIONS.map(function (p) { return N.normalize({ notifications: { position: p } }).position }),
           ["top-right", "top", "top-left", "bottom-right", "bottom-left"])
        eq("bad types take the default", N.normalize({ notifications: { dnd: "true", position: "middle", timeout: "9", max: null } }), nd)
        eq("dnd must be a bool", [N.normalize({ notifications: { dnd: 1 } }).dnd, N.normalize({ notifications: { dnd: true } }).dnd], [false, true])
        eq("timeout clamped to 1..60", [0, -4, 61, 1e9, 2.6].map(function (t) { return N.normalize({ notifications: { timeout: t } }).timeout }), [1, 1, 60, 60, 3])
        eq("max clamped to 1..10", [0, 11, 7].map(function (m) { return N.normalize({ notifications: { max: m } }).max }), [1, 10, 7])
        eq("NaN/Infinity take the default", [N.normalize({ notifications: { timeout: NaN } }).timeout, N.normalize({ notifications: { max: Infinity } }).max], [5, 5])
        eq("one bad key leaves the others", N.normalize({ notifications: { dnd: true, position: 4, timeout: 30 } }),
           { dnd: true, position: "top-right", timeout: 30, max: 5 })

        // setDnd's read-modify-write.
        var shellText = JSON.stringify({ wallpaper: "/w.jpg", idle: { lock: 0 }, notifications: { position: "top", max: 2, extra: "x" }, other: [1] })
        eq("withDnd keeps every other key", JSON.parse(N.withDnd(shellText, true)),
           { wallpaper: "/w.jpg", idle: { lock: 0 }, notifications: { position: "top", max: 2, extra: "x", dnd: true }, other: [1] })
        eq("withDnd off", JSON.parse(N.withDnd(N.withDnd(shellText, true), false)).notifications.dnd, false)
        eq("withDnd on a missing or empty file", [JSON.parse(N.withDnd("", true)), JSON.parse(N.withDnd(null, false))],
           [{ notifications: { dnd: true } }, { notifications: { dnd: false } }])
        eq("withDnd replaces a bad notifications value", JSON.parse(N.withDnd('{"a":1,"notifications":"x"}', true)), { a: 1, notifications: { dnd: true } })
        eq("withDnd never clobbers an unreadable file", [N.withDnd("{", true), N.withDnd("[1]", true), N.withDnd("3", true)], [null, null, null])
        eq("withDnd ends with a newline", N.withDnd("{}", true).slice(-1), "\n")

        // Popup placement.
        eq("top-right", N.placement("top-right", 30),
           { top: true, bottom: false, left: false, right: true, marginTop: 36, marginBottom: 0, marginLeft: 0, marginRight: 8 })
        eq("top is centred (top edge only)", N.placement("top", 30),
           { top: true, bottom: false, left: false, right: false, marginTop: 36, marginBottom: 0, marginLeft: 0, marginRight: 0 })
        eq("top-left", N.placement("top-left", 30),
           { top: true, bottom: false, left: true, right: false, marginTop: 36, marginBottom: 0, marginLeft: 8, marginRight: 0 })
        eq("bottom-right", N.placement("bottom-right", 30),
           { top: false, bottom: true, left: false, right: true, marginTop: 0, marginBottom: 8, marginLeft: 0, marginRight: 8 })
        eq("bottom-left", N.placement("bottom-left", 30),
           { top: false, bottom: true, left: true, right: false, marginTop: 0, marginBottom: 8, marginLeft: 8, marginRight: 0 })
        eq("unknown position: top-right", N.placement("nowhere", 30), N.placement("top-right", 30))

        // At most max popups, the oldest leave first.
        var p = []
        for (var i = 1; i <= 4; i++) p = N.push(p, i, 3).shown
        eq("max 3 keeps the newest", p, [2, 3, 4])
        eq("push reports the dropped", N.push([1, 2, 3], 4, 2), { shown: [3, 4], dropped: [1, 2] })
        eq("push under max drops nothing", N.push([1], 2, 5), { shown: [1, 2], dropped: [] })
        eq("the same item twice moves to the end", N.push([1, 2], 1, 5).shown, [2, 1])
        eq("trim to a smaller max", N.trim([1, 2, 3, 4, 5], 2).shown, [4, 5])
        eq("trim never below one", N.trim([1, 2], 0).shown, [2])
        eq("remove", N.remove([1, 2, 3], 2), [1, 3])
        eq("push does not change its input", (function () { var a = [1, 2]; N.push(a, 3, 1); return a })(), [1, 2])

        console.log(passed + " passed, " + failed + " failed")
        Qt.exit(failed ? 1 : 0)
    }
}
