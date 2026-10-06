#!/bin/bash
# Vérifie la syntaxe de tous les scripts GDScript du projet.
G=${GODOT:-godot}
cd "$(dirname "$0")/.."
fail=0
for f in $(find . -name "*.gd" -not -path "./.godot/*" | sort); do
  out=$(timeout 60 $G --headless --path . --check-only --script "res://${f#./}" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|Compile Error|error\(" -A1 | grep -v "^--$" | grep -vE "Identifier not found: (Content|Game|UI|Sfx|Nav)$|Identifier not found: (Content|Game|UI|Sfx|Nav)\b" | grep -vE "^\s+at: GDScript::reload" )
  if [ -n "$out" ]; then echo "== $f"; echo "$out"; fail=1; fi
done
exit $fail
