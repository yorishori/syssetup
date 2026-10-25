.pragma library

// Recursively overlay `over` onto `base`; keys unknown to base are ignored,
// except under an empty object, which takes whatever is there (a theme's
// own tweaks: their keys are its business). Used for settings over their
// defaults and for theme tweaks over a theme's tokens.
//
// A value of the wrong type (a string where the default is a number, a list
// where it's a group…) keeps the default; its dotted path is added to
// `rejected`, if given, so the caller can say so.
function merge(base, over, rejected, prefix) {
    const isObject = v => v !== null && typeof v === "object" && !Array.isArray(v);
    const out = {};
    for (const key in base) {
        const b = base[key], o = over?.[key];
        const path = prefix ? `${prefix}.${key}` : key;
        const reject = () => {
            rejected?.push(path);
            return b;
        };
        if (o === undefined)
            out[key] = b;
        else if (Array.isArray(b))
            out[key] = Array.isArray(o) ? o : reject();
        else if (isObject(b))
            out[key] = !isObject(o) ? reject() : Object.keys(b).length === 0 ? o : merge(b, o, rejected, path);
        else
            out[key] = typeof o === typeof b ? o : reject();
    }
    return out;
}
