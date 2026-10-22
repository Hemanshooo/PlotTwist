#!/usr/bin/env python3
"""
Builds a book guide for Plot Twist: ChatGPT reads a whole book from Project
Gutenberg once, and the app writes every twist from what it found.

    python3 Tools/bookguide/build.py pride-and-prejudice     # one book from books.json
    python3 Tools/bookguide/build.py --all                   # every book in books.json
    python3 Tools/bookguide/build.py --gutenberg 158 --slug emma   # any Gutenberg book
    python3 Tools/bookguide/build.py --all --dry-run         # download and estimate cost only

Each guide holds a spoiler-free premise, the main characters, a summary of every
chapter, and the book's turning points. For each turning point ChatGPT quotes
where it begins; the script finds that quote in the real text and cuts the
passage from the book itself, so passages are always word-for-word, and the
moment's position in the book is measured, not guessed.

Needs Python 3.9+ and an OpenAI API key, from the OPENAI_API_KEY environment
variable or a file Tools/bookguide/.env containing OPENAI_API_KEY=sk-...
(that file is git-ignored). Nothing else to install.

Guides are written to Otherwise/Resources/Guides/<slug>.guide.json, where
Xcode picks them up on the next build.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
CACHE = HERE / "cache"
SEEDS = HERE / "seeds"
OUT = ROOT / "Otherwise" / "Resources" / "Guides"
MANIFEST = HERE / "books.json"

DEFAULT_MODEL = "gpt-6.1-sol"
# USD per million tokens (input, output), for the estimate only. Check
# https://developers.openai.com/api/docs/models for current prices.
PRICES = {
    "gpt-6-astra": (10.0, 50.0),
    "gpt-6.1-sol": (2.0, 10.0),
    "gpt-6-luna": (0.10, 0.50),
}
# Leave room in a 1.05M-token context for the instructions and the answer.
MAX_BOOK_TOKENS = 900_000
GUIDE_FORMAT = 1

PASSAGE_MIN_WORDS = 140
PASSAGE_MAX_WORDS = 300


# MARK: - Small helpers

def log(message: str) -> None:
    print(message, flush=True)


def warn(message: str) -> None:
    print(f"  ! {message}", flush=True)


def user_agent() -> str:
    contact = os.environ.get("PLOTTWIST_CONTACT", "").strip()
    return f"PlotTwist-bookguide/1.0 ({contact})" if contact else "PlotTwist-bookguide/1.0"


def api_key() -> str:
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    env_file = HERE / ".env"
    if not key and env_file.exists():
        for line in env_file.read_text().splitlines():
            name, _, value = line.partition("=")
            if name.strip() == "OPENAI_API_KEY":
                key = value.strip().strip('"').strip("'")
    if not key:
        sys.exit(
            "No OpenAI API key found.\n"
            "Create Tools/bookguide/.env containing OPENAI_API_KEY=sk-... "
            "or run: export OPENAI_API_KEY=sk-..."
        )
    return key


def estimate_tokens(text: str) -> int:
    # About four characters per token for English prose.
    return len(text) // 4


# MARK: - Gutenberg

def download(gutenberg_id: int) -> str:
    """The book's plain text, cached so each book is downloaded only once."""
    CACHE.mkdir(exist_ok=True)
    path = CACHE / f"pg{gutenberg_id}.txt"
    if path.exists():
        return path.read_text(encoding="utf-8")
    url = f"https://www.gutenberg.org/cache/epub/{gutenberg_id}/pg{gutenberg_id}.txt"
    log(f"  downloading {url}")
    request = urllib.request.Request(url, headers={"User-Agent": user_agent()})
    with urllib.request.urlopen(request, timeout=60) as response:
        text = response.read().decode("utf-8-sig", errors="replace")
    path.write_text(text, encoding="utf-8")
    # Gutenberg asks automated downloads to pause between files.
    time.sleep(2)
    return text


def header_field(raw: str, name: str) -> str | None:
    match = re.search(rf"^{name}:\s*(.+)$", raw[:6000], re.MULTILINE)
    return match.group(1).strip() if match else None


def strip_gutenberg(raw: str) -> str:
    """The book alone: Gutenberg's header, licence and footer removed."""
    text = raw.replace("\r\n", "\n").replace("\r", "\n")
    start = re.search(r"^\*\*\* ?START OF (?:THE|THIS) PROJECT GUTENBERG.*$", text, re.MULTILINE | re.IGNORECASE)
    end = re.search(r"^\*\*\* ?END OF (?:THE|THIS) PROJECT GUTENBERG.*$", text, re.MULTILINE | re.IGNORECASE)
    body = text[start.end() if start else 0 : end.start() if end else len(text)]
    # Producer credits sometimes sit just under the start marker.
    body = re.sub(r"\A\s*(?:Produced by|E-text prepared by|Transcribed from)[^\n]*(?:\n[^\n]+)*\n", "", body)
    return body.strip() + "\n"


# MARK: - Finding passages in the text

WORD = re.compile(r"[A-Za-z0-9À-ɏ]+(?:['’][A-Za-zÀ-ɏ]+)*")


def words_with_offsets(text: str) -> list[tuple[str, int]]:
    return [(m.group(0).lower().replace("’", "'"), m.start()) for m in WORD.finditer(text.replace("_", " "))]


class BookText:
    def __init__(self, body: str):
        self.body = body
        self.words = words_with_offsets(body)
        self.index: dict[str, list[int]] = {}
        for i, (word, _) in enumerate(self.words):
            self.index.setdefault(word, []).append(i)
        # Paragraphs: (start, end) character ranges separated by blank lines.
        self.paragraphs = [(m.start(), m.end()) for m in re.finditer(r"(?:[^\n]+\n?)+", body)]

    def find(self, quote: str) -> int | None:
        """Character offset where `quote` begins, tolerating punctuation and line breaks.
        Falls back to shorter runs of the quote if ChatGPT changed a word."""
        target = [w for w, _ in words_with_offsets(quote)]
        if not target:
            return None
        for size in (len(target), 10, 8, 6):
            if size > len(target):
                continue
            for start in range(0, len(target) - size + 1):
                run = target[start : start + size]
                hits = [i for i in self.index.get(run[0], []) if [w for w, _ in self.words[i : i + size]] == run]
                if len(hits) == 1:
                    # Step back to where the quote itself began.
                    i = max(hits[0] - start, 0)
                    return self.words[i][1]
        return None

    def passage(self, offset: int) -> str:
        """About 140–300 words of the book, from the paragraph where `offset` falls."""
        first = next((i for i, (s, e) in enumerate(self.paragraphs) if s <= offset < e), None)
        if first is None:
            return ""
        start = self.paragraphs[first][0]
        # A long paragraph: begin at the sentence the quote is in, not pages earlier.
        lead = self.body[start:offset]
        if len(WORD.findall(lead)) > 120:
            sentence = max(lead.rfind(". "), lead.rfind("! "), lead.rfind("? "), lead.rfind(".\n"))
            start = start + sentence + 2 if sentence >= 0 else offset
        chunks: list[str] = []
        count = 0
        for i in range(first, len(self.paragraphs)):
            s, e = self.paragraphs[i]
            paragraph = clean_paragraph(self.body[max(s, start) : e])
            if not paragraph:
                continue
            chunks.append(paragraph)
            count += len(paragraph.split())
            if count >= PASSAGE_MIN_WORDS:
                break
        return trim_words("\n\n".join(chunks), PASSAGE_MAX_WORDS)


def clean_paragraph(text: str) -> str:
    text = text.replace("_", "")
    text = re.sub(r"\[Illustration[^\]]*\]", "", text)
    lines = [line.strip() for line in text.splitlines()]
    return typeset(re.sub(r"\s+", " ", " ".join(line for line in lines if line)).strip())


def typeset(text: str) -> str:
    """Plain-text Gutenberg punctuation, set properly: curly quotes and em dashes."""
    text = re.sub(r"\s*--\s*", "—", text)
    # A quote mark opens at the start, after a space or opening punctuation; otherwise it closes.
    text = re.sub(r'(^|[\s(\[—])"', "\\1“", text)
    text = text.replace('"', "”")
    text = re.sub(r"(^|[\s(\[—“])'", "\\1‘", text)
    return text.replace("'", "’")


def trim_words(text: str, limit: int) -> str:
    words = text.split(" ")
    if len(words) <= limit:
        return text
    cut = " ".join(words[:limit])
    end = max(cut.rfind(". "), cut.rfind("! "), cut.rfind("? "), cut.rfind(".”"), cut.rfind(".\""))
    return cut[: end + 2].rstrip() if end > len(cut) // 2 else cut.rstrip() + "…"


# MARK: - ChatGPT

SYSTEM = (
    "You are a meticulous literary editor. You are preparing a reference guide to a book for an app "
    "in which readers imagine alternate versions of its plot. You have the complete text of the book. "
    "Everything you write must be true to the text: names, places, relationships and the order of events. "
    "Never invent, and never rely on adaptations or summaries you may remember."
)


def instructions(book: dict, seed: dict | None) -> str:
    parts = [
        f"Book: {book['title']} by {book['author']}" + (f" ({book['year']})" if book.get("year") else ""),
        "",
        "Read the whole book below, then return the guide:",
        "",
        "premise: two sentences that set up the book without any spoilers, at most 45 words.",
        "",
        "characters: the 12 to 20 most important characters, most important first. name is the name the text "
        "uses most; aliases are the other names, nicknames and titles the text uses for them; description is "
        "who they are, their relationships, and what they want, at most 40 words.",
        "",
        "chapters: every chapter in order, using the book's own divisions (chapters, letters, staves, or acts and "
        "scenes for a play). label is short, as printed: 'Ch. 12', 'Letter 4', 'Stave 2', 'Act 3, Sc. 1'. summary is "
        "one to three sentences saying concretely who does what, and where, at most 60 words.",
        "",
        "moments: the turning points, where a different choice or event would change the rest of the story. For each:",
        "- title: 3 to 6 words.",
        "- chapter: its label, matching one of your chapter labels.",
        "- happened: one sentence saying what happens, at most 30 words.",
        "- anchor: 10 to 16 consecutive words copied exactly, character for character, from the text where this "
        "moment begins. Choose words that appear only once in the book. Copy them; do not paraphrase.",
        "- aftermath: what this leads to later in the original, two or three sentences, at most 60 words.",
        "- characters: the names (from your characters list) of those involved.",
        "- alternatives: three different things that could have happened instead, each under 10 words.",
    ]
    if seed:
        parts += [
            "",
            "The app already has these moments. Return exactly one moment for each, in the same order, with seedID "
            "set to its id. Keep its title and alternatives unless they contradict the text. Correct its chapter and "
            "happened if they are inaccurate. Do not add other moments.",
            json.dumps(
                [{k: m[k] for k in ("id", "chapter", "title", "happened", "alternatives")} for m in seed["moments"]],
                ensure_ascii=False,
                indent=1,
            ),
        ]
    else:
        parts += [
            "",
            "Choose 8 to 10 moments spread across the whole book, in the order they happen. Set seedID to null.",
        ]
    return "\n".join(parts)


def schema() -> dict:
    def obj(properties: dict) -> dict:
        return {"type": "object", "properties": properties, "required": list(properties), "additionalProperties": False}

    text = {"type": "string"}
    texts = {"type": "array", "items": text}
    return obj({
        "premise": text,
        "characters": {"type": "array", "items": obj({"name": text, "aliases": texts, "description": text})},
        "chapters": {"type": "array", "items": obj({"label": text, "summary": text})},
        "moments": {"type": "array", "items": obj({
            "seedID": {"type": ["string", "null"]},
            "title": text,
            "chapter": text,
            "happened": text,
            "anchor": text,
            "aftermath": text,
            "characters": texts,
            "alternatives": texts,
        })},
    })


def ask_chatgpt(model: str, book: dict, seed: dict | None, body: str) -> dict:
    payload = {
        "model": model,
        "input": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": instructions(book, seed) + "\n\n=== THE BOOK ===\n\n" + body},
        ],
        "text": {"format": {"type": "json_schema", "name": "book_guide", "schema": schema(), "strict": True}},
        "max_output_tokens": 48_000,
    }
    request = urllib.request.Request(
        "https://api.openai.com/v1/responses",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Authorization": f"Bearer {api_key()}", "Content-Type": "application/json"},
        method="POST",
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=1200) as response:
                return json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")[:600]
            if error.code in (429, 500, 502, 503, 504) and attempt < 3:
                wait = 20 * (attempt + 1)
                warn(f"OpenAI answered {error.code}; trying again in {wait}s")
                time.sleep(wait)
                continue
            sys.exit(f"OpenAI answered {error.code}: {detail}")
        except (urllib.error.URLError, TimeoutError) as error:
            if attempt < 3:
                warn(f"{error}; trying again")
                time.sleep(15)
                continue
            raise
    raise RuntimeError("unreachable")


def guide_from_response(response: dict) -> dict:
    if response.get("status") == "incomplete":
        reason = (response.get("incomplete_details") or {}).get("reason")
        sys.exit(f"ChatGPT stopped before finishing ({reason}). Try again, or a model with more output room.")
    for item in response.get("output", []):
        if item.get("type") != "message":
            continue
        for content in item.get("content", []):
            if content.get("type") == "refusal":
                sys.exit(f"ChatGPT declined: {content.get('refusal')}")
            if content.get("type") == "output_text":
                return json.loads(content["text"])
    sys.exit("ChatGPT's answer had no guide in it.")


# MARK: - Open Library (for books outside the app's catalogue)

def open_library_book(title: str, author: str) -> dict | None:
    query = urllib.parse.urlencode({
        "title": title, "author": author, "limit": 1,
        "fields": "key,title,author_name,first_publish_year,cover_i",
    })
    request = urllib.request.Request(f"https://openlibrary.org/search.json?{query}", headers={"User-Agent": user_agent()})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            docs = json.loads(response.read().decode("utf-8")).get("docs", [])
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        return None
    return docs[0] if docs else None


# MARK: - Assembling the guide

def assemble(book: dict, seed: dict | None, found: dict, text: BookText, model: str) -> dict:
    labels = [c["label"] for c in found["chapters"]]
    seed_moments = {m["id"]: m for m in (seed or {}).get("moments", [])}
    known = {c["name"] for c in found["characters"]}
    moments = []
    for index, m in enumerate(found["moments"]):
        seeded = seed_moments.get(m.get("seedID") or "")
        offset = text.find(m["anchor"])
        if offset is None:
            warn(f"couldn't find the quote for “{m['title']}” in the text; no passage for it")
            # Place it by its chapter instead.
            chapter = labels.index(m["chapter"]) if m["chapter"] in labels else index
            position = (chapter + 0.5) / max(len(labels), 1)
            passage = None
        else:
            position = offset / max(len(text.body), 1)
            passage = text.passage(offset)
        unknown = [name for name in m["characters"] if name not in known]
        if unknown:
            warn(f"“{m['title']}” names characters not in the list: {', '.join(unknown)}")
        moments.append({
            "id": seeded["id"] if seeded else f"{book['slug']}-{index + 1}",
            "chapter": m["chapter"],
            "position": round(position, 4),
            "title": m["title"],
            "happened": m["happened"],
            "alternatives": [a for a in m["alternatives"] if a.strip()][:3],
            "characters": m["characters"],
            "passage": passage,
            "aftermath": m["aftermath"],
        })
    if seed and len(moments) != len(seed["moments"]):
        warn(f"expected {len(seed['moments'])} moments, got {len(moments)}")
    order = [m["position"] for m in moments]
    if order != sorted(order):
        warn("the moments aren't in reading order; sorting them by where they fall in the text")
        moments.sort(key=lambda m: m["position"])

    return {
        "format": GUIDE_FORMAT,
        "slug": book["slug"],
        "gutenbergID": book["gutenberg"],
        "model": model,
        "builtAt": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "book": book_record(book, seed),
        "premise": seed["premise"] if seed else found["premise"],
        "characters": found["characters"],
        "chapters": found["chapters"],
        "moments": moments,
    }


def book_record(book: dict, seed: dict | None) -> dict:
    if seed:
        # Books in the app's catalogue keep the catalogue's identity and cloth cover.
        return {"id": f"catalog/{book['slug']}", "title": book["title"], "author": book["author"],
                "year": book.get("year"), "coverID": None}
    match = open_library_book(book["title"], book["author"])
    return {
        "id": match["key"] if match else f"guide/{book['slug']}",
        "title": book["title"],
        "author": book["author"],
        "year": book.get("year") or (match or {}).get("first_publish_year"),
        "coverID": (match or {}).get("cover_i"),
    }


# MARK: - Running

def build(book: dict, model: str, force: bool, dry_run: bool, from_response: Path | None) -> bool:
    slug = book["slug"]
    target = OUT / f"{slug}.guide.json"
    log(f"\n{book['title']} (Gutenberg #{book['gutenberg']})")
    if target.exists() and not force and not dry_run:
        log("  already built; use --force to build it again")
        return True

    raw = download(book["gutenberg"])
    printed = header_field(raw, "Title")
    if printed and not loosely_equal(printed, book["title"]):
        warn(f"Gutenberg calls this “{printed}”; check the Gutenberg number")
    body = strip_gutenberg(raw)
    tokens = estimate_tokens(body)
    words = len(body.split())
    cost = ""
    if model in PRICES:
        cin, cout = PRICES[model]
        cost = f", about ${tokens / 1e6 * cin + 20_000 / 1e6 * cout:.2f} with {model}"
    log(f"  {words:,} words, about {tokens:,} tokens{cost}")
    if tokens > MAX_BOOK_TOKENS:
        warn("too long to read in one go; skipped")
        return False
    if dry_run:
        return True

    seed_path = SEEDS / f"{slug}.json"
    seed = json.loads(seed_path.read_text(encoding="utf-8")) if seed_path.exists() else None

    if from_response:
        response = json.loads(from_response.read_text(encoding="utf-8"))
    else:
        log(f"  {model} is reading the book (this can take a few minutes)…")
        started = time.time()
        response = ask_chatgpt(model, book, seed, body)
        CACHE.mkdir(exist_ok=True)
        (CACHE / f"{slug}.response.json").write_text(json.dumps(response, ensure_ascii=False, indent=1), encoding="utf-8")
        usage = response.get("usage") or {}
        log(f"  read in {time.time() - started:.0f}s · {usage.get('input_tokens', '?')} tokens in, "
            f"{usage.get('output_tokens', '?')} out")

    found = guide_from_response(response)
    guide = assemble(book, seed, found, BookText(body), model)
    OUT.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(guide, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    with_passages = sum(1 for m in guide["moments"] if m["passage"])
    log(f"  wrote {target.relative_to(ROOT)}: {len(guide['characters'])} characters, "
        f"{len(guide['chapters'])} chapters, {len(guide['moments'])} moments ({with_passages} with passages)")
    return True


def loosely_equal(a: str, b: str) -> bool:
    def norm(s: str) -> str:
        return re.sub(r"[^a-z0-9]+", " ", s.lower().replace("’", "").replace("'", "")).replace("the ", "").strip()
    return norm(a).startswith(norm(b)[:20]) or norm(b).startswith(norm(a)[:20])


def main() -> None:
    parser = argparse.ArgumentParser(description="Build Plot Twist book guides with ChatGPT.")
    parser.add_argument("slugs", nargs="*", help="books from books.json, by slug")
    parser.add_argument("--all", action="store_true", help="every book in books.json")
    parser.add_argument("--gutenberg", type=int, help="any Gutenberg book, by number")
    parser.add_argument("--slug", help="with --gutenberg: the guide's name, e.g. emma")
    parser.add_argument("--title", help="with --gutenberg: the title (default: from Gutenberg)")
    parser.add_argument("--author", help="with --gutenberg: the author (default: from Gutenberg)")
    parser.add_argument("--year", type=int, help="with --gutenberg: first published")
    parser.add_argument("--model", default=os.environ.get("PLOTTWIST_MODEL", DEFAULT_MODEL))
    parser.add_argument("--force", action="store_true", help="rebuild guides that already exist")
    parser.add_argument("--dry-run", action="store_true", help="download and estimate cost; don't ask ChatGPT")
    parser.add_argument("--from-response", type=Path, help="assemble from a saved OpenAI response (testing)")
    args = parser.parse_args()

    manifest = {b["slug"]: b for b in json.loads(MANIFEST.read_text(encoding="utf-8"))}
    books: list[dict] = []
    if args.gutenberg:
        raw = download(args.gutenberg)
        title = args.title or header_field(raw, "Title") or f"Gutenberg {args.gutenberg}"
        author = args.author or header_field(raw, "Author") or "Unknown"
        slug = args.slug or re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
        books.append({"slug": slug, "gutenberg": args.gutenberg, "title": title, "author": author, "year": args.year})
    if args.all:
        books += manifest.values()
    for slug in args.slugs:
        if slug not in manifest:
            sys.exit(f"No book called {slug} in books.json. Choose from: {', '.join(manifest)}")
        books.append(manifest[slug])
    if not books:
        parser.print_help()
        return
    if not args.dry_run and not args.from_response:
        api_key()  # Fail early, before any downloads.

    failed = [b["slug"] for b in books if not build(b, args.model, args.force, args.dry_run, args.from_response)]
    if failed:
        sys.exit(f"\nNot built: {', '.join(failed)}")
    log("\nDone. Build the app in Xcode to include the new guides.")


if __name__ == "__main__":
    main()
