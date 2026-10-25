.pragma library

// Recursively overlay `over` onto `base`; keys unknown to base are ignored,
// except under an empty object, which takes whatever is there (a theme's
// own tweaks: their keys are its business). Used for settings over their
// defaults and for theme tweaks over a theme's tokens.
function merge(base, over) {
    const isObject = v => v !== null && typeof v === "object" && !Array.isArray(v);
    const out = {};
    for (const key in base) {
        const b = base[key], o = over?.[key];
        if (o === undefined)
            out[key] = b;
        else if (Array.isArray(b))
            out[key] = Array.isArray(o) ? o : b;
        else if (isObject(b))
            out[key] = !isObject(o) ? b : Object.keys(b).length === 0 ? o : merge(b, o);
        else
            out[key] = o;
    }
    return out;
}
