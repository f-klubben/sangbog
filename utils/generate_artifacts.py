import os
import re
import json
import sys
import base64
from pathlib import Path

CWD = Path.cwd()
JSON_PATH = CWD.joinpath("output/songs.json")


# =============================================================================
# FORMATTING CONFIG
# =============================================================================
# Controls how Typst markup is transformed in the output text.
#
# commands:
#   Maps each named Typst command to a (prefix, suffix) tuple that wraps the
#   inner content. Use ("", "") to simply unwrap (keep text, strip markup).
#   Examples:
#       "bf": (r"\textbf{", "}")   →  LaTeX bold
#       "em": (r"\textit{", "}")   →  LaTeX italic
#       "tt": (r"\texttt{", "}")   →  LaTeX monospace
#       "bf": ("", "")             →  plain text, no formatting
#
# math:
#   (prefix, suffix) wrapping inline math content from $...$
#   ("", "")    →  strip delimiters, keep content as plain text
#   ("$", "$")  →  re-emit as LaTeX inline math
#
# native_bold:
#   (prefix, suffix) for Typst native *bold* syntax
#   ("", "")           →  strip asterisks, keep text
#   (r"\textbf{", "}") →  LaTeX bold
#
# native_italic:
#   (prefix, suffix) for Typst native _italic_ syntax
#   ("", "")            →  strip underscores, keep text
#   (r"\textit{", "}")  →  LaTeX italic
#
# include_notes:
#   Whether #note[...] blocks appear in the output (as type "v").
#   Default: False

FORMATTING_CONFIG: dict = {
    # ── Named command wrappers ─────────────────────────────────────────────
    "commands": {
        "bf":      (r"*", "*"),   # bold
        "sf":      (r"sf{", "}"),   # sans-serif
        "sl":      (r"_", "_"),   # slanted
        "sc":      (r"sc{", "}"),   # small caps
        "em":      (r"_", "_"),   # emphasis / italic
        "tt":      (r"tt{", "}"),   # monospace
        "small":   ("", ""),   # smaller text
        "big":     ("", ""),   # bigger text
        "strong":  (r"*", "*"),   # strong / bold
        "emph":    (r"_", "_"),   # emphasis
        "context": ("", ""),   # layout wrapper
        "super":   ("", ""),   # layout wrapper
    },


    # ── Inline math: $...$ ────────────────────────────────────────────────
    # ("", "")    →  strip delimiters, emit content as plain text
    # ("$", "$")  →  re-emit as LaTeX inline math (with symbol translation)
    "math": ("$", "$"),

    # Typst math uses bare identifiers (nabla, alpha, sum) while LaTeX needs
    # a backslash (\nabla, \alpha, \sum).
    #
    # math_translate:
    #   "auto"  →  prepend \ to any bare word that matches a known LaTeX
    #              math command (handles the common case automatically)
    #   "map"   →  only apply explicit entries in math_symbol_map, no auto
    #   "none"  →  no translation, emit Typst math content as-is
    "math_translate": "auto",

    # Explicit symbol overrides applied before auto-translation.
    # Use for cases where Typst and LaTeX differ structurally, or where
    # auto-translation would produce the wrong result.
    # Example:
    #   "infinity": r"\infty",     # auto would give \infinity (wrong)
    #   "arrow.r":  r"\rightarrow",
    "math_symbol_map": {
        "infinity": r"∞",
        "arrow.r":  r"→",
        "arrow.l":  r"←",
        "arrow.t":  r"↑",
        "arrow.b":  r"↓",
        "<=":       r"≤",
        ">=":       r"≥",
        "!=":       r"≠",
        "in":       r"∈",
        "subset.eq":r"⊆",
        "subset":   r"⊂",
        "union":    r"∪",
        "sect":     r"∩",
        "times":    r"×",
        "dot":      r"⋅",
        "...":      r"…",
        "nabla":    r"∇",
        "_a":    r"_{a}",
    },

    # ── Native Typst bold: *text* ─────────────────────────────────────────
    "native_bold": (r"*", "*"),

    # ── Native Typst italic: _text_ ───────────────────────────────────────
    "native_italic": (r"_", "_"),

    # ── Notes ─────────────────────────────────────────────────────────────
    "include_notes": False,
}

# =============================================================================
# UTILS
# =============================================================================

def encode_image(image_path: str) -> str:
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def get_file_contents(path: str) -> str:
    with open(path, mode="r", encoding="utf-8") as f:
        return f.read()


def find_typ_files(root_dir: str) -> list[str]:
    """Recursively find all .typ files under root_dir."""
    results = []
    for dirpath, _, filenames in os.walk(root_dir):
        for fname in filenames:
            if fname.endswith(".typ"):
                results.append(os.path.join(dirpath, fname))
    return results


# =============================================================================
# TYPST BRACKET / PAREN EXTRACTION
# =============================================================================

def extract_bracket_content(text: str, start: int) -> tuple[str, int]:
    """
    Given text and the index of '[', return (inner_content, end_index).
    end_index points to the character after the closing ']'.
    Handles nesting.
    """
    assert text[start] == "[", f"Expected '[' at {start}, got {text[start]!r}"
    depth = 0
    i = start
    while i < len(text):
        if text[i] == "[":
            depth += 1
        elif text[i] == "]":
            depth -= 1
            if depth == 0:
                return text[start + 1:i], i + 1
        i += 1
    raise ValueError(f"Unmatched '[' starting at position {start}")


def extract_paren_content(text: str, start: int) -> tuple[str, int]:
    """
    Given text and the index of '(', return (inner_content, end_index).
    Handles nesting.
    """
    assert text[start] == "(", f"Expected '(' at {start}, got {text[start]!r}"
    depth = 0
    i = start
    while i < len(text):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return text[start + 1:i], i + 1
        i += 1
    raise ValueError(f"Unmatched '(' starting at position {start}")


# =============================================================================
# SONG HEADER PARSING
# =============================================================================

def parse_sang_header(content: str) -> tuple[str | None, str | None]:
    """
    Extract title and melody from a #sang(...) call.
    Returns (title, melody_or_None).

    Examples:
        #sang("Title")
        #sang("Title", subtext: "Mel: Something", cols: 2)
    """
    match = re.search(r'#sang\(', content)
    if not match:
        return None, None

    try:
        args_str, _ = extract_paren_content(content, match.end() - 1)
    except (ValueError, AssertionError):
        return None, None

    title_match = re.match(r'\s*"([^"]*)"', args_str)
    title = title_match.group(1).capitalize() if title_match else None

    subtext_match = re.search(r'subtext\s*:\s*"([^"]*)"', args_str)
    melody = None
    if subtext_match:
        raw = subtext_match.group(1)
        melody = re.sub(
            r'^(?:Mel(?:odi)?[\s:\-]+)', "", raw, flags=re.IGNORECASE
        ).strip().capitalize()

    return title, melody


# =============================================================================
# LYRIC TEXT CLEANING
# =============================================================================

def strip_typst_comments(text: str) -> str:
    """Remove Typst line and block comments while preserving line breaks."""
    text = re.sub(r'//[^\n]*', '', text)
    return re.sub(
        r'/\*.*?\*/',
        lambda match: ''.join(char for char in match.group(0) if char == '\n'),
        text,
        flags=re.DOTALL,
    )


def _apply_command_mapping(text: str, cmd: str) -> str:
    """
    Apply a named command mapping from FORMATTING_CONFIG to all occurrences
    of #cmd[...] in text.

    The inner content is preserved; prefix/suffix from the config are wrapped
    around it. Handles nested brackets correctly.
    """
    prefix, suffix = FORMATTING_CONFIG["commands"].get(cmd, ("", ""))
    result = []
    i = 0
    pattern = re.compile(rf'#{re.escape(cmd)}\s*\[')
    while i < len(text):
        m = pattern.search(text, i)
        if not m:
            result.append(text[i:])
            break
        result.append(text[i:m.start()])
        bracket_start = m.end() - 1  # index of '['
        try:
            inner, end = extract_bracket_content(text, bracket_start)
            result.append(f"{prefix}{inner}{suffix}")
            i = end
        except ValueError:
            # Malformed — emit as-is and move on
            result.append(text[m.start()])
            i = m.start() + 1
    return "".join(result)


# A large set of known LaTeX math command names (no backslash).
# Any bare word in Typst math matching one of these gets \\word in LaTeX output.
_LATEX_MATH_COMMANDS: frozenset[str] = frozenset({
    # Greek lowercase
    "alpha", "beta", "gamma", "delta", "epsilon", "varepsilon", "zeta", "eta",
    "theta", "vartheta", "iota", "kappa", "lambda", "mu", "nu", "xi",
    "pi", "varpi", "rho", "varrho", "sigma", "varsigma", "tau", "upsilon",
    "phi", "varphi", "chi", "psi", "omega",
    # Greek uppercase
    "Gamma", "Delta", "Theta", "Lambda", "Xi", "Pi", "Sigma", "Upsilon",
    "Phi", "Psi", "Omega",
    # Calculus / analysis
    "nabla", "partial", "infty", "int", "oint", "iint", "iiint",
    "sum", "prod", "lim", "limsup", "liminf", "sup", "inf", "max", "min",
    "frac", "dfrac", "tfrac", "sqrt", "overline", "underline",
    "hat", "tilde", "vec", "dot", "ddot", "bar", "check", "acute", "grave",
    # Operators
    "cdot", "times", "div", "pm", "mp", "oplus", "otimes", "circ",
    "wedge", "vee", "cap", "cup", "setminus",
    # Relations
    "leq", "geq", "neq", "approx", "equiv", "sim", "simeq", "cong",
    "subset", "supset", "subseteq", "supseteq", "in", "notin", "ni",
    "ll", "gg", "prec", "succ",
    # Arrows
    "to", "rightarrow", "leftarrow", "Rightarrow", "Leftarrow",
    "leftrightarrow", "Leftrightarrow", "mapsto",
    "uparrow", "downarrow", "nearrow", "searrow",
    # Sets / logic
    "forall", "exists", "neg", "land", "lor", "implies", "iff",
    "emptyset", "varnothing",
    # Functions
    "sin", "cos", "tan", "cot", "sec", "csc",
    "arcsin", "arccos", "arctan",
    "sinh", "cosh", "tanh",
    "log", "ln", "exp", "det", "dim", "ker", "hom", "arg",
    "gcd", "lcm", "deg", "tr", "rank",
    # Brackets / delimiters
    "left", "right", "big", "Big", "bigg", "Bigg",
    "lfloor", "rfloor", "lceil", "rceil", "langle", "rangle",
    # Misc
    "ldots", "cdots", "vdots", "ddots",
    "mathbb", "mathbf", "mathit", "mathrm", "mathcal", "mathfrak",
    "text", "mbox", "hspace", "vspace",
    "matrix", "pmatrix", "bmatrix", "vmatrix", "Vmatrix",
    "begin", "end", "quad", "qquad",
    "underbrace", "overbrace", "stackrel",
    "boldsymbol", "bm",
})

def clean_typst_text(text: str) -> str:
    """
    Transform Typst markup in lyric text according to FORMATTING_CONFIG.

    Processing order:
    1. Typst comments                           → remove
    2. Named command wrappers (#bf[...] etc.)  → prefix+content+suffix per config
    3. #set ... lines                           → remove
    4. #h(...) spacing                          → remove
    5. $...$ inline math                        → prefix+content+suffix per config
    6. Native *bold*                            → prefix+content+suffix per config
    7. Native _italic_                          → prefix+content+suffix per config
    8. #LaTeX                                   → "LaTeX"
    9. Backslash line-break                     → newline
    10. Remaining unknown #cmd                  → remove
    11. Stray brackets from unwrapping          → remove
    12. Collapse excess blank lines
    """
    # 1. Remove Typst comments before parsing markup.
    text = strip_typst_comments(text)

    # 2. Named command wrappers — process longest names first to avoid
    #    partial matches (e.g. "strong" before "s")
    for cmd in sorted(FORMATTING_CONFIG["commands"], key=len, reverse=True):
        text = _apply_command_mapping(text, cmd)

    # 3. Remove #set ... lines
    text = re.sub(r'#set\s+[^\n]*\n?', "", text)

    # 4. Remove #h(...) horizontal spacing
    text = re.sub(r'#h\s*\([^)]*\)', "", text)

    # 5. Stash math spans — must happen first so that _ and * inside $...$
    #    are not consumed by the bold/italic regexes, and so that backslashes
    #    inside math are not eaten by the line-break sub.
    math_spans: list[str] = []

    def _stash_math(m: re.Match) -> str:
        math_spans.append(m.group(0))
        return f"\x01MATH{len(math_spans) - 1}\x01"

    text = re.sub(r'\$[^$]*\$', _stash_math, text)

    # 6. Typst line-break: backslash at end of line
    text = re.sub(r'\s*\\\s*\n', "\n", text)

    # 7. Native bold/italic — safe now that math is stashed
    bold_pre, bold_suf = FORMATTING_CONFIG["native_bold"]
    text = re.sub(r'\*(.+?)\*', lambda m: f"{bold_pre}{m.group(1)}{bold_suf}", text)

    ital_pre, ital_suf = FORMATTING_CONFIG["native_italic"]
    text = re.sub(r'(?<!\\)_(\S.*?\S|\S)_', lambda m: f"{ital_pre}{m.group(1)}{ital_suf}", text)

    # 8. Restore math, translate Typst identifiers to LaTeX, apply delimiters
    math_pre, math_suf = FORMATTING_CONFIG["math"]
    translate_mode = FORMATTING_CONFIG.get("math_translate", "auto")
    symbol_map = FORMATTING_CONFIG.get("math_symbol_map", {})

    def _translate_math(inner: str) -> str:
        if translate_mode == "auto":
            # Prepend \ to bare words matching known LaTeX math commands.
            # Skips words already preceded by a backslash.
            def _maybe_prefix(m: re.Match) -> str:
                word = m.group(1)
                start = m.start(1)
                if start > 0 and inner[start - 1] == "\\":
                    return word
                return f"\\{word}" if word in _LATEX_MATH_COMMANDS else word

            inner = re.sub(r'(?<![A-Za-z\\])([A-Za-z]+)(?![A-Za-z])', _maybe_prefix, inner)

        # Apply explicit symbol map last — overrides auto-translation.
        # Longest keys first to avoid partial replacements (e.g. "arrow.r" before "arrow").
        # Uses word boundaries so "in" doesn't match inside "sin", "infinity", etc.
        # Also replaces the auto-prefixed form (\infinity → \infty).
        for typst_sym, latex_sym in sorted(
            symbol_map.items(), key=lambda kv: len(kv[0]), reverse=True
        ):
            repl = latex_sym.replace("\\", "\\\\")  # escape for re.sub replacement string
            if re.match(r'^[A-Za-z]+$', typst_sym):
                # Word — match with boundaries, replace both raw and auto-prefixed forms
                inner = re.sub(rf'\\{re.escape(typst_sym)}\b', repl, inner)
                inner = re.sub(rf'(?<![A-Za-z\\]){re.escape(typst_sym)}(?![A-Za-z])', repl, inner)
            else:
                # Operator/symbol — simple string replace (no regex needed)
                inner = inner.replace(f"\\{typst_sym}", latex_sym)
                inner = inner.replace(typst_sym, latex_sym)

        return inner

    def _restore_math(m: re.Match) -> str:
        original = math_spans[int(m.group(1))]
        inner = original[1:-1]  # strip $ delimiters
        if translate_mode != "none":
            inner = _translate_math(inner)
        return f"{math_pre}{inner}{math_suf}"

    text = re.sub(r'\x01MATH(\d+)\x01', _restore_math, text)

    # 9. Named constants
    text = re.sub(r'#LaTeX\b', "LaTeX", text)

    # 10. Remove remaining unknown #word commands
    text = re.sub(r'#[A-Za-zÆæØøÅå]\w*\b', "", text)

    # 11. Remove stray brackets left from unwrapping
    text = re.sub(r'\[', "", text)
    text = re.sub(r'\]', "", text)

    # 12. Strip leading whitespace from each line (Typst source indentation)
    text = "\n".join(line.lstrip() for line in text.splitlines())

    # 13. Collapse excess blank lines
    text = re.sub(r'\n{3,}', "\n\n", text)

    return text.strip()


# =============================================================================
# SONG BODY BLOCK FINDER
# =============================================================================

# Matches #commandName — supports Danish letters in command names
_CMD_RE = re.compile(r'#([A-Za-zÆæØøÅå]\w*)')

# Commands that take a [...] body block
_BRACKET_CMDS = {"vers", "omkvæd", "note", "align"}


def find_all_blocks(content: str) -> list[tuple[int, str, str]]:
    """
    Scan the interior of a #sang[...] body and return all recognised blocks
    in source order:

        (line_number, block_type, raw_content)

    block_type ∈ {"vers", "omkvæd", "note", "image", "csplit"}
    """
    results = []
    i = 0
    line_at = lambda pos: content[:pos].count("\n")

    while i < len(content):
        m = _CMD_RE.match(content, i)
        if not m:
            i += 1
            continue

        cmd = m.group(1)
        cmd_start = i
        i = m.end()

        # csplit ──────────────────────────────────────────────────────────────
        if cmd == "csplit":
            results.append((line_at(cmd_start), "csplit", ""))
            continue

        # #vers[...] / #omkvæd[...] / #note[...] / #align[...] ──────────────
        if cmd in _BRACKET_CMDS:
            j = i
            while j < len(content) and content[j] in (" ", "\t", "\n"):
                j += 1
            if j < len(content) and content[j] == "[":
                try:
                    block_content, end = extract_bracket_content(content, j)
                    results.append((line_at(cmd_start), cmd, block_content))
                    i = end
                except ValueError:
                    pass
            continue

        # #image("/path", ...) ───────────────────────────────────────────────
        if cmd == "image":
            j = i
            while j < len(content) and content[j] in (" ", "\t"):
                j += 1
            if j < len(content) and content[j] == "(":
                try:
                    img_args, end = extract_paren_content(content, j)
                    path_match = re.match(r'\s*"([^"]*)"', img_args)
                    if path_match:
                        results.append((
                            line_at(cmd_start),
                            "image",
                            path_match.group(1),
                        ))
                    i = end
                except ValueError:
                    pass
            continue

        # Unknown command – advance past it
        continue

    return results


# =============================================================================
# SONG BODY PARSER
# =============================================================================

def get_song_body(content: str) -> list:
    """
    Parse a full .typ song file and return the body list:

        verses   → (verse_index, "v", text)
        choruses → (verse_index, "c", text)
        images   → (verse_index, "i", width, rel_path, base64_data)
    """
    content = strip_typst_comments(content)
    sang_match = re.search(r'#sang\(', content)
    if not sang_match:
        return []

    try:
        _, paren_end = extract_paren_content(content, sang_match.end() - 1)
    except (ValueError, AssertionError):
        return []

    # Find the body block '['
    i = paren_end
    while i < len(content) and content[i] in (" ", "\t", "\n"):
        i += 1

    if i >= len(content) or content[i] != "[":
        return []

    try:
        body_content, _ = extract_bracket_content(content, i)
    except ValueError:
        return []

    blocks = find_all_blocks(body_content)
    result = []
    verse_index = 0

    for _, btype, raw in blocks:
        if btype == "vers":
            result.append((verse_index, "v", clean_typst_text(raw)))
            verse_index += 1

        elif btype == "omkvæd":
            result.append((verse_index, "c", clean_typst_text(raw)))

        elif btype == "note":
            if FORMATTING_CONFIG["include_notes"]:
                result.append((verse_index, "v", clean_typst_text(raw)))

        elif btype == "image":
            # raw is the image path as written in source, e.g.
            # "/sange/assets/enkortenlang/enkortenlangs1.png"
            image_path = raw.lstrip("/")
            width = "1.0"
            try:
                b64 = encode_image(image_path)
            except FileNotFoundError:
                b64 = ""
            result.append((verse_index, "i", width, image_path, b64))

        # csplit / align are layout hints – skip

    return result


# =============================================================================
# MAIN.TYP ORDER + SECTION PREFIX PARSING
# =============================================================================

def parse_main_order(main_path: str) -> list[tuple[str, str]]:
    """
    Parse main.typ and return an ordered list of (stem, prefix) pairs.

    Handles:
        #include "sange/unsorted/costadelsol.typ"  → stem "costadelsol"
        #nynummerpræfiks("G")                       → prefix changes to "G"
    """
    content = get_file_contents(main_path)
    order: list[tuple[str, str]] = []
    current_prefix = ""

    for line in content.splitlines():
        stripped = line.strip()

        # Section prefix reset
        prefix_match = re.match(
            r'#nynummerpr[æa]fiks\s*\(\s*"([^"]*)"\s*\)', stripped
        )
        if prefix_match:
            current_prefix = prefix_match.group(1)
            continue

        # Song include
        include_match = re.match(r'#include\s+"([^"]+)"', stripped)
        if include_match:
            stem = Path(include_match.group(1)).stem
            order.append((stem, current_prefix))

    return order


# =============================================================================
# COUNTER
# =============================================================================

class Counter:
    """
    Assigns song numbers matching the ordering and prefix scheme from main.typ.

    Songs are numbered per-section (prefix group), resetting to 1 when the
    prefix changes — mirroring #nynummerpræfiks + counter("song").update(0).

    Songs not found in the order list are appended at the end under the last
    active prefix.
    """

    def __init__(self, order: list[tuple[str, str]]):
        self._order = order

        # stem → (order_index, prefix)
        self._lookup: dict[str, tuple[int, str]] = {
            stem: (idx, prefix)
            for idx, (stem, prefix) in enumerate(order)
        }

        # Precompute per-section sequential numbers (1-indexed within prefix)
        self._section_numbers: dict[int, int] = {}
        section_counts: dict[str, int] = {}
        for idx, (stem, prefix) in enumerate(order):
            section_counts[prefix] = section_counts.get(prefix, 0) + 1
            self._section_numbers[idx] = section_counts[prefix]

        # For overflow (unknown) songs
        self._overflow_counts: dict[str, int] = dict(section_counts)
        self._last_prefix: str = order[-1][1] if order else ""

        self.last_number: int = 0
        self.last_prefix: str = ""

    def get(self, file_stem: str) -> tuple[str, int]:
        """Return (prefix, number) for the given file stem."""
        if file_stem in self._lookup:
            idx, prefix = self._lookup[file_stem]
            number = self._section_numbers[idx]
        else:
            prefix = "x"
            self._overflow_counts[prefix] = (
                self._overflow_counts.get(prefix, 0) + 1
            )
            number = self._overflow_counts[prefix]

        self.last_number = number
        self.last_prefix = prefix
        return prefix, number

    @staticmethod
    def format_number(prefix: str, number: int) -> str:
        return f"{prefix}{number}"


# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    songs_dir = "sange"
    main_typ = "main.typ"

    # Build ordering from main.typ
    if os.path.isfile(main_typ):
        order = parse_main_order(main_typ)
        print(f"Found {len(order)} songs listed in {main_typ}")
    else:
        print(f"Warning: {main_typ} not found – songs will be unordered", file=sys.stderr)
        order = []

    counter = Counter(order)

    # Collect all .typ files recursively under sange/
    all_typ_files = find_typ_files(songs_dir)
    print(f"Found {len(all_typ_files)} .typ files under '{songs_dir}/'")

    # Build stem → path map (last-wins if duplicate stems across subdirs)
    stem_to_path: dict[str, str] = {}
    for path in all_typ_files:
        stem_to_path[Path(path).stem] = path

    # Sort: main.typ order first, then any extras alphabetically
    ordered_paths: list[str] = []
    seen: set[str] = set()
    for stem, _ in order:
        if stem in stem_to_path and stem not in seen:
            ordered_paths.append(stem_to_path[stem])
            seen.add(stem)
    for path in sorted(all_typ_files):
        stem = Path(path).stem
        if stem not in seen:
            ordered_paths.append(path)
            seen.add(stem)

    # Parse each song
    json_res = []
    total = len(ordered_paths)

    for idx, song_path in enumerate(ordered_paths, start=1):
        sys.stdout.write("\rGenerating songbook %d%%" % ((idx / total) * 100))
        sys.stdout.flush()

        contents = get_file_contents(song_path)
        title, melody = parse_sang_header(contents)

        if title is None:
            continue

        prefix, number = counter.get(Path(song_path).stem)
        body = get_song_body(contents)

        json_res.append({
            "number": Counter.format_number(prefix, number),
            "title": title,
            "melody": melody,
            "body": body,
            "path": song_path,
        })

    print(f"\n\rWriting {len(json_res)} songs to {JSON_PATH}")
    with open(JSON_PATH, encoding="utf-8", mode="w") as f:
        f.write(json.dumps(json_res, ensure_ascii=False, indent=2))