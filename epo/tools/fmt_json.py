#!/usr/bin/env python3
"""Reformate les JSON de data/ de façon lisible (une entrée par bloc, sous-objets sur une ligne)."""
import json, sys

def inline(v):
    return json.dumps(v, ensure_ascii=False, separators=(", ", ": "))

def fmt_entry(v, ind):
    if isinstance(v, dict):
        lines = []
        for k, x in v.items():
            lines.append(f'{ind}\t{json.dumps(k, ensure_ascii=False)}: {inline(x)}')
        return "{\n" + ",\n".join(lines) + f"\n{ind}}}"
    return inline(v)

def fmt(path):
    d = json.load(open(path, encoding="utf-8"))
    if isinstance(d, dict):
        out = "{\n" + ",\n".join(f'\t{json.dumps(k, ensure_ascii=False)}: {fmt_entry(v, chr(9))}' for k, v in d.items()) + "\n}\n"
    else:
        out = "[\n" + ",\n".join(f'\t{fmt_entry(v, chr(9))}' for v in d) + "\n]\n"
    json.loads(out)
    open(path, "w", encoding="utf-8").write(out)

for p in sys.argv[1:]:
    fmt(p)
    print("ok", p)
