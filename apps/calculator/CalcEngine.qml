import QtQuick

QtObject {
    id: root

    // the number on the display, raw (no thousands separators): "0", "12.", "-5", "0.7734"
    property string entry: "0"
    // true while digits are being typed into entry; false when entry is a computed value (or a fresh
    // "0") and the next digit starts a new number
    property bool typing: false
    // completed [number, operator, number, operator, ...] pairs; entry is the pending operand.
    // Always reassigned, never mutated, so bindings on it update.
    property var tokens: []
    // entry is the result of "="
    property bool done: false
    // {op, val} that a repeated "=" applies again
    property var rep: null
    // division by zero etc.: shows "Error" until the next key
    property bool err: false
    // text for the line above the display
    property string expr: ""

    readonly property string display: err ? "Error" : group(entry)
    // the operator waiting for its second operand (to highlight its key), or ""
    readonly property string pendingOp: (typing || tokens.length === 0) ? "" : tokens[tokens.length - 1]

    // "=" was pressed: the finished equation and its result, for the history list
    signal evaluated(string equation, string result)

    readonly property int maxDigits: 15
    readonly property var priority: ({ "+": 1, "−": 1, "×": 2, "÷": 2 })

    // Helpers

    // Rounds away float noise (0.1 + 0.2) and returns the raw text of a number; null if it isn't finite.
    function raw(n) {
        if (!isFinite(n)) return null
        return String(Number(n.toPrecision(12)))
    }

    function apply(a, op, b) {
        switch (op) {
        case "+": return a + b
        case "−": return a - b
        case "×": return a * b
        case "÷": return a / b
        }
    }

    // [n, op, n, op, n]: * and : first, then + and −, each left to right. NaN on division by zero.
    function evaluate(t) {
        const nums = [t[0]]
        const ops = []
        for (let i = 1; i < t.length; i += 2) {
            const op = t[i]
            while (ops.length && priority[ops[ops.length - 1]] >= priority[op]) {
                const b = nums.pop()
                nums.push(apply(nums.pop(), ops.pop(), b))
            }
            ops.push(op)
            nums.push(t[i + 1])
        }
        while (ops.length) {
            const b = nums.pop()
            nums.push(apply(nums.pop(), ops.pop(), b))
        }
        return nums[0]
    }

    // "1234567.891" -> "1,234,567.891"; exponent forms ("1e+21") are left alone
    function group(text) {
        if (text.indexOf("e") >= 0) return text
        const neg = text.charAt(0) === "-"
        if (neg) text = text.slice(1)
        const dot = text.indexOf(".")
        const int = (dot < 0 ? text : text.slice(0, dot)).replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        return (neg ? "-" : "") + int + (dot < 0 ? "" : text.slice(dot))
    }

    function exprText(t) {
        let out = ""
        for (let i = 0; i < t.length; i++)
            out += i % 2 === 0 ? group(String(t[i])) : t[i]
        return out
    }

    // Key presses

    function reset() {
        entry = "0"
        typing = false
        tokens = []
        done = false
        rep = null
        err = false
        expr = ""
    }

    function fail() {
        reset()
        err = true
    }

    // a digit or "." after a result starts a new calculation
    function startFresh() {
        tokens = []
        expr = ""
        rep = null
        done = false
        typing = false
    }

    // A history entry's result becomes the number on the display
    function load(result) {
        reset()
        entry = result
        done = true
    }

    function press(key) {
        if (err) {
            reset()
            if (key === "AC") return
        }

        if (key === "AC") { reset(); return }

        if (key.length === 1 && key >= "0" && key <= "9") {
            if (done) startFresh()
            if (!typing) { entry = key; typing = true }
            else if (entry === "0") entry = key
            else if (entry === "-0") entry = "-" + key
            else if (entry.replace(/[-.]/g, "").length < maxDigits) entry += key
            return
        }

        if (key === ".") {
            if (done) startFresh()
            if (!typing) { entry = "0."; typing = true }
            else if (entry.indexOf(".") < 0) entry += "."
            return
        }

        if (key === "⌫") {
            if (!typing) return
            entry = entry.slice(0, -1)
            if (entry === "" || entry === "-") entry = "0"
            return
        }

        if (key === "±") {
            if (entry === "0" && !typing) { entry = "-0"; typing = true; return }
            entry = entry.charAt(0) === "-" ? entry.slice(1) : "-" + entry
            if (entry === "-0" && !typing) entry = "0"
            return
        }

        if (key === "%") {
            const p = raw(Number(entry) / 100)
            if (p === null) { fail(); return }
            entry = p
            typing = false
            return
        }

        if (priority[key]) {
            if (done) { tokens = []; done = false; rep = null }
            const t = tokens.slice()
            if (t.length && !typing) t[t.length - 1] = key   // operator pressed twice: replace it
            else t.push(Number(entry), key)
            const shown = raw(evaluate(t.slice(0, -1)))
            if (shown === null) { fail(); return }
            tokens = t
            entry = shown
            typing = false
            expr = exprText(t)
            return
        }

        if (key === "=") {
            let full
            if (tokens.length) {
                full = tokens.concat([Number(entry)])
                rep = { op: full[full.length - 2], val: full[full.length - 1] }
            } else if (rep) {
                full = [Number(entry), rep.op, rep.val]
            } else {
                return
            }
            const res = raw(evaluate(full))
            if (res === null) { fail(); return }
            const equation = exprText(full)
            expr = equation
            entry = res
            tokens = []
            typing = false
            done = true
            evaluated(equation, res)
        }
    }
}
