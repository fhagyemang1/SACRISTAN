#!/usr/bin/env python3
"""
Generates original, simple line-art SVG illustrations for the SACRISTAN
Reference Library (vestments and vessels). Deliberately minimalist
line-icon style (not photorealistic) so they read clearly at small sizes
on a phone, work in both light and dark theme, and — importantly — are
wholly original artwork with no copyright ambiguity.

Run: python3 tools/generate_illustrations.py
Output: app/assets/reference/*.svg
"""
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "reference")
os.makedirs(OUT_DIR, exist_ok=True)

STROKE = "#4A3B52"     # neutral dark plum-gray, reads on light & dark backgrounds
ACCENT = "#B1121C"     # liturgical red accent, used sparingly
GOLD = "#C9A227"

HEADER = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
<rect x="1" y="1" width="98" height="98" rx="14" fill="none" stroke="{stroke}" stroke-opacity="0.15" stroke-width="1.5"/>
'''.format(stroke=STROKE)
FOOTER = "</svg>\n"

def s(body: str) -> str:
    return HEADER + body + FOOTER

ICONS = {}

ICONS["chasuble.svg"] = s('''
<path d="M50 12 C40 12 34 20 34 28 L26 36 L34 42 L36 34 L36 88 L64 88 L64 34 L66 42 L74 36 L66 28 C66 20 60 12 50 12 Z"
  fill="none" stroke="{stroke}" stroke-width="3" stroke-linejoin="round"/>
<path d="M50 12 C45 18 45 26 50 30 C55 26 55 18 50 12 Z" fill="{accent}" fill-opacity="0.25" stroke="{stroke}" stroke-width="2"/>
<line x1="50" y1="30" x2="50" y2="80" stroke="{accent}" stroke-width="3"/>
'''.format(stroke=STROKE, accent=ACCENT))

ICONS["stole.svg"] = s('''
<path d="M40 14 C36 14 34 18 36 22 L46 50 L38 86 L48 86 L54 54 L44 20 C46 16 44 14 40 14 Z"
  fill="none" stroke="{stroke}" stroke-width="3" stroke-linejoin="round"/>
<path d="M60 14 C64 14 66 18 64 22 L54 50 L62 86 L52 86 L46 54 L56 20 C54 16 56 14 60 14 Z"
  fill="none" stroke="{stroke}" stroke-width="3" stroke-linejoin="round"/>
<circle cx="40" cy="18" r="3" fill="{accent}"/>
<circle cx="60" cy="18" r="3" fill="{accent}"/>
'''.format(stroke=STROKE, accent=ACCENT))

ICONS["alb.svg"] = s('''
<path d="M50 12 L38 22 L38 30 L32 88 L68 88 L62 30 L62 22 Z"
  fill="none" stroke="{stroke}" stroke-width="3" stroke-linejoin="round"/>
<line x1="38" y1="30" x2="62" y2="30" stroke="{stroke}" stroke-width="2"/>
<line x1="41" y1="45" x2="41" y2="82" stroke="{stroke}" stroke-width="1.5" stroke-opacity="0.4"/>
<line x1="50" y1="42" x2="50" y2="86" stroke="{stroke}" stroke-width="1.5" stroke-opacity="0.4"/>
<line x1="59" y1="45" x2="59" y2="82" stroke="{stroke}" stroke-width="1.5" stroke-opacity="0.4"/>
'''.format(stroke=STROKE))

ICONS["cincture.svg"] = s('''
<ellipse cx="50" cy="50" rx="26" ry="14" fill="none" stroke="{stroke}" stroke-width="4"/>
<path d="M72 50 C82 54 84 66 78 74 C74 78 66 78 64 72" fill="none" stroke="{stroke}" stroke-width="3.5" stroke-linecap="round"/>
<circle cx="78" cy="74" r="3" fill="{accent}"/>
<circle cx="70" cy="76" r="3" fill="{accent}"/>
'''.format(stroke=STROKE, accent=ACCENT))

ICONS["amice.svg"] = s('''
<rect x="24" y="38" width="52" height="30" rx="4" fill="none" stroke="{stroke}" stroke-width="3"/>
<line x1="24" y1="38" x2="14" y2="30" stroke="{stroke}" stroke-width="2.5"/>
<line x1="76" y1="38" x2="86" y2="30" stroke="{stroke}" stroke-width="2.5"/>
<line x1="24" y1="68" x2="14" y2="76" stroke="{stroke}" stroke-width="2.5"/>
<line x1="76" y1="68" x2="86" y2="76" stroke="{stroke}" stroke-width="2.5"/>
'''.format(stroke=STROKE))

ICONS["cope.svg"] = s('''
<path d="M50 14 C34 14 24 26 22 40 L20 86 L50 78 L80 86 L78 40 C76 26 66 14 50 14 Z"
  fill="none" stroke="{stroke}" stroke-width="3" stroke-linejoin="round"/>
<path d="M40 16 C40 22 44 26 50 26 C56 26 60 22 60 16" fill="none" stroke="{gold}" stroke-width="3"/>
<circle cx="50" cy="30" r="3" fill="{accent}"/>
'''.format(stroke=STROKE, accent=ACCENT, gold=GOLD))

ICONS["humeral_veil.svg"] = s('''
<path d="M18 34 C30 30 70 30 82 34 L78 50 C60 44 40 44 22 50 Z"
  fill="none" stroke="{stroke}" stroke-width="3" stroke-linejoin="round"/>
<path d="M30 46 C34 60 34 74 28 86" fill="none" stroke="{stroke}" stroke-width="2.5"/>
<path d="M70 46 C66 60 66 74 72 86" fill="none" stroke="{stroke}" stroke-width="2.5"/>
'''.format(stroke=STROKE))

ICONS["chalice.svg"] = s('''
<path d="M32 16 C32 32 40 40 46 44 L46 66 L34 82 L66 82 L54 66 L54 44 C60 40 68 32 68 16 Z"
  fill="none" stroke="{stroke}" stroke-width="3.5" stroke-linejoin="round"/>
<ellipse cx="50" cy="16" rx="18" ry="4" fill="none" stroke="{stroke}" stroke-width="3"/>
<rect x="30" y="82" width="40" height="6" rx="2" fill="{gold}" stroke="{stroke}" stroke-width="1.5"/>
'''.format(stroke=STROKE, gold=GOLD))

ICONS["paten.svg"] = s('''
<ellipse cx="50" cy="52" rx="34" ry="10" fill="none" stroke="{stroke}" stroke-width="3.5"/>
<ellipse cx="50" cy="49" rx="34" ry="10" fill="{gold}" fill-opacity="0.25" stroke="{stroke}" stroke-width="3"/>
'''.format(stroke=STROKE, gold=GOLD))

ICONS["ciborium.svg"] = s('''
<path d="M34 46 L34 66 C34 74 42 80 50 80 C58 80 66 74 66 66 L66 46 Z"
  fill="none" stroke="{stroke}" stroke-width="3.5" stroke-linejoin="round"/>
<ellipse cx="50" cy="46" rx="16" ry="4.5" fill="none" stroke="{stroke}" stroke-width="3"/>
<path d="M36 40 C36 30 44 24 50 24 C56 24 64 30 64 40" fill="none" stroke="{stroke}" stroke-width="3"/>
<circle cx="50" cy="18" r="4" fill="{accent}"/>
<rect x="42" y="80" width="16" height="6" rx="2" fill="{gold}" stroke="{stroke}" stroke-width="1.5"/>
'''.format(stroke=STROKE, accent=ACCENT, gold=GOLD))

ICONS["purificator.svg"] = s('''
<rect x="26" y="34" width="48" height="32" fill="none" stroke="{stroke}" stroke-width="3"/>
<line x1="26" y1="42" x2="74" y2="42" stroke="{stroke}" stroke-width="1.2" stroke-opacity="0.4"/>
<line x1="26" y1="50" x2="74" y2="50" stroke="{stroke}" stroke-width="1.2" stroke-opacity="0.4"/>
<line x1="26" y1="58" x2="74" y2="58" stroke="{stroke}" stroke-width="1.2" stroke-opacity="0.4"/>
<line x1="30" y1="70" x2="70" y2="70" stroke="{accent}" stroke-width="2.5"/>
'''.format(stroke=STROKE, accent=ACCENT))

ICONS["corporal.svg"] = s('''
<rect x="20" y="20" width="60" height="60" fill="none" stroke="{stroke}" stroke-width="3"/>
<path d="M50 34 L50 66 M38 50 L62 50" stroke="{accent}" stroke-width="2.5"/>
<line x1="20" y1="30" x2="80" y2="30" stroke="{stroke}" stroke-width="1" stroke-opacity="0.3"/>
<line x1="20" y1="70" x2="80" y2="70" stroke="{stroke}" stroke-width="1" stroke-opacity="0.3"/>
'''.format(stroke=STROKE, accent=ACCENT))

ICONS["pall.svg"] = s('''
<rect x="30" y="30" width="40" height="40" fill="none" stroke="{stroke}" stroke-width="3.5"/>
<path d="M50 40 L50 60 M40 50 L60 50" stroke="{gold}" stroke-width="3"/>
'''.format(stroke=STROKE, gold=GOLD))

ICONS["thurible.svg"] = s('''
<path d="M36 20 L64 20 M50 12 L50 20" stroke="{stroke}" stroke-width="2.5"/>
<path d="M38 20 L34 44 M62 20 L66 44" stroke="{stroke}" stroke-width="2"/>
<path d="M30 44 C30 58 38 68 50 68 C62 68 70 58 70 44 Z" fill="none" stroke="{stroke}" stroke-width="3.5"/>
<path d="M28 68 L72 68 L66 82 L34 82 Z" fill="none" stroke="{stroke}" stroke-width="3" stroke-linejoin="round"/>
<path d="M40 30 C44 24 40 18 44 12" fill="none" stroke="{accent}" stroke-width="2" stroke-linecap="round" opacity="0.7"/>
<path d="M56 28 C60 22 56 16 60 10" fill="none" stroke="{accent}" stroke-width="2" stroke-linecap="round" opacity="0.7"/>
'''.format(stroke=STROKE, accent=ACCENT))

ICONS["cruets.svg"] = s('''
<path d="M36 30 L36 22 L44 22 L44 30 C50 34 50 46 46 50 L46 78 C46 82 42 84 38 84 C34 84 30 82 30 78 L30 50 C26 46 26 34 36 30 Z"
  fill="none" stroke="{stroke}" stroke-width="2.8" stroke-linejoin="round"/>
<path d="M60 30 L60 22 L68 22 L68 30 C74 34 74 46 70 50 L70 78 C70 82 66 84 62 84 C58 84 54 82 54 78 L54 50 C50 46 50 34 60 30 Z"
  fill="{accent}" fill-opacity="0.2" stroke="{stroke}" stroke-width="2.8" stroke-linejoin="round"/>
'''.format(stroke=STROKE, accent=ACCENT))

ICONS["paschal_candle.svg"] = s('''
<path d="M50 10 C46 16 46 22 50 26 C54 22 54 16 50 10 Z" fill="{accent}"/>
<rect x="42" y="26" width="16" height="58" fill="none" stroke="{stroke}" stroke-width="3"/>
<path d="M42 40 L58 40 M50 32 L50 84" stroke="{gold}" stroke-width="2"/>
<path d="M46 50 L54 50 M46 60 L54 60 M46 70 L54 70" stroke="{stroke}" stroke-width="1.2" stroke-opacity="0.4"/>
'''.format(stroke=STROKE, accent=ACCENT, gold=GOLD))

ICONS["monstrance.svg"] = s('''
<circle cx="50" cy="42" r="16" fill="none" stroke="{gold}" stroke-width="3"/>
<circle cx="50" cy="42" r="7" fill="none" stroke="{stroke}" stroke-width="2.5"/>
<g stroke="{gold}" stroke-width="2.5">
<line x1="50" y1="20" x2="50" y2="12"/>
<line x1="50" y1="64" x2="50" y2="72"/>
<line x1="28" y1="42" x2="20" y2="42"/>
<line x1="72" y1="42" x2="80" y2="42"/>
<line x1="34" y1="26" x2="28" y2="20"/>
<line x1="66" y1="26" x2="72" y2="20"/>
<line x1="34" y1="58" x2="28" y2="64"/>
<line x1="66" y1="58" x2="72" y2="64"/>
</g>
<path d="M38 66 L62 66 L58 86 L42 86 Z" fill="none" stroke="{stroke}" stroke-width="3" stroke-linejoin="round"/>
'''.format(stroke=STROKE, gold=GOLD))

for name, content in ICONS.items():
    with open(os.path.join(OUT_DIR, name), "w") as f:
        f.write(content)

print(f"Wrote {len(ICONS)} SVG illustrations to {os.path.abspath(OUT_DIR)}")
for name in sorted(ICONS):
    print(" -", name)
