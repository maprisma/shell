import QtQuick
import "../BarModel.js" as M

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
           { version: 1, background: "opaque", left: ["clock", "launcher", "workspaces"], center: [], right: ["tray", "bluetooth", "network", "audio", "power"] })
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
           { version: 1, background: "opaque", left: ["clock", "launcher", "workspaces"], center: [], right: ["tray", "bluetooth", "network", "audio", "power"] })
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

        console.log(passed + " passed, " + failed + " failed")
        Qt.exit(failed ? 1 : 0)
    }
}
