.pragma library
.import "objects.js" as Objects

// Settings described as a list of { path, type, default, … } (Config.schema).
// Types: text, screen, choice (options), color, int (min, max), list (of text).

// The defaults, as one object.
function defaults(schema) {
    let out = {};
    for (const s of schema)
        out = Objects.setPath(out, s.path, s.default);
    return out;
}

// The setting at `path`, or undefined.
function find(schema, path) {
    return schema.find(s => s.path === path);
}

// Why `value` won't do for this setting, or "" if it will.
function problem(s, value) {
    switch (s.type) {
    case "int":
        if (!Number.isInteger(value))
            return "takes a whole number";
        if ((s.min !== undefined && value < s.min) || (s.max !== undefined && value > s.max))
            return `takes ${s.min ?? "…"} to ${s.max ?? "…"}`;
        return "";
    case "list":
        return Array.isArray(value) && value.every(v => typeof v === "string") ? "" : "takes a list of text";
    case "color":
        return typeof value === "string" && /^(#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8}))?$/i.test(value)
            ? "" : 'takes a color ("#rrggbb") or ""';
    default:
        if (typeof value !== "string")
            return "takes text";
        if (s.type === "choice" && Array.isArray(s.options) && !s.options.includes(value))
            return `takes one of ${s.options.join(", ")}`;
        return "";
    }
}

// `values` with each setting that won't do put back to its default; the
// paths put back are added to `rejected`.
function validate(schema, values, rejected) {
    let out = values;
    for (const s of schema) {
        const value = Objects.getPath(out, s.path);
        if (value !== undefined && problem(s, value)) {
            rejected.push(s.path);
            out = Objects.setPath(out, s.path, s.default);
        }
    }
    return out;
}
