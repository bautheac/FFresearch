#!/usr/bin/env python3
"""Check a built pkgdown site for defects a build exit code cannot see.

Usage: check-site.py <repo-root> [--dst <site-dir>]

<repo-root> holds _pkgdown.yml and man/; the site defaults to its docs/
directory (--dst overrides). A build that exits 0 only proves pkgdown ran;
these checks ask whether the output is current and reachable:

  1. broken internal links  -- every href/src in every page resolves to a file
  2. insecure links         -- no page links out over http://
  3. reference index        -- reference/index.html links exactly the topics
                              _pkgdown.yml lists (internal topics are excluded
                              by pkgdown, so they are allowed to be absent)
  4. stale region labels    -- no page still says 'global' / 'global (ex US)'
  5. coverage text          -- every dataset page that documents a period
                              column states the 1971 start and the 2026 end
  6. completeness           -- every man/*.Rd topic has a page, and every page
                              in reference/ is either listed, internal, or a
                              declared redirect stub
  7. freshness              -- pkgdown.yml records a pkgdown version and a
                              last_built date

Redirect stubs -- the bare <html> files with a meta refresh that pkgdown writes
for Rd aliases and for `redirects:` entries -- are legitimate extras: each is
checked against man/ or _pkgdown.yml under 6, and they are exempt from 4 and 5
because they contain no prose.

Exit 0 only when every check passes. A check that inspects nothing is itself a
failure (see the vacuity guards at the end). That is not theoretical: the first
version of this script parsed `contents:` items out of _pkgdown.yml as if they
were top-level list entries, matched no topics at all, and reported the seven
legitimate reference links as unexpected -- a checker whose counters were
printed in its last line is what made that obvious.
"""
import pathlib
import re
import sys
import urllib.parse
from html.parser import HTMLParser

# Region labels that must not survive the 2026-11 relabel. Word-boundary exact,
# so 'globally' does not match.
STALE_LABELS = [r"\bglobal\b", r"\bglobal \(ex US\)"]
# Page text that makes a coverage claim necessary.
PERIOD_COLUMN = re.compile(r"\bperiod\b\s*:")


class Refs(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refs = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        for key in ("href", "src"):
            if a.get(key):
                self.refs.append(a[key])


def page_refs(html):
    parser = Refs()
    parser.feed(html)
    return parser.refs


def resolve(page, site, ref):
    """Path a ref points to inside site; None when external or anchor-only."""
    if re.match(r"^(https?:|//|mailto:|data:|javascript:|#)", ref):
        return None
    path = urllib.parse.urlparse(ref).path
    if not path:
        return None
    if path.startswith("/"):
        return (site / path.lstrip("/")).resolve()
    return (page.parent / path).resolve()


def is_redirect_stub(html):
    """pkgdown's stubs: a bare <html> with a meta refresh and noindex."""
    head = html[:600]
    return 'http-equiv="refresh"' in head and "noindex" in head


def plain_text(html):
    return re.sub(r"<[^>]+>", " ", html)


def topics_from_pkgdown(root):
    """Bare topic names in the reference: block of _pkgdown.yml."""
    text = (root / "_pkgdown.yml").read_text(encoding="utf-8")
    block = re.search(r"^reference:\n(.*?)(?=^\S|\Z)", text, re.M | re.S)
    if not block:
        raise SystemExit(f"FAIL: no reference: block in {root / '_pkgdown.yml'}")
    return [m.group(1) for m in
            re.finditer(r"^\s+-\s+([A-Za-z0-9_.-]+)\s*$", block.group(1), re.M)]


def internal_topics(root):
    """Topics pkgdown keeps out of the index (@keywords internal)."""
    return {p.stem for p in (root / "man").glob("*.Rd")
            if "\\keyword{internal}" in p.read_text(encoding="utf-8")}


def alias_stems(root):
    """Stems pkgdown emits redirect stubs for: \\alias values that are not
    themselves an Rd file. This is reference_redirects() in pkgdown; restated
    here so the checker does not need an installed package to answer it."""
    stems = {p.stem for p in (root / "man").glob("*.Rd")}
    aliases = set()
    for p in (root / "man").glob("*.Rd"):
        aliases |= set(re.findall(r"\\alias\{([^}]*)\}", p.read_text(encoding="utf-8")))
    return {f"reference/{s}.html" for s in aliases - stems}


def redirect_targets(root):
    """`from` paths of the redirects: block in _pkgdown.yml, as site-relative
    paths. This is what build_redirect() writes stubs for."""
    text = (root / "_pkgdown.yml").read_text(encoding="utf-8")
    block = re.search(r"^redirects:\n(.*?)(?=^\S|\Z)", text, re.M | re.S)
    if not block:
        return set()
    pairs = re.findall(r'^\s*-\s*\[\s*"?([^",\]]+)"?\s*,\s*"?([^",\]]+)"?\s*\]',
                       block.group(1), re.M)
    return {frm for frm, _ in pairs}


def main(argv):
    root = pathlib.Path(argv[1]).resolve()
    site = root / "docs"
    if "--dst" in argv:
        site = pathlib.Path(argv[argv.index("--dst") + 1]).resolve()

    problems = []
    pages = sorted(site.rglob("*.html"))
    if not pages:
        print(f"FAIL: no HTML pages under {site}")
        return 1

    # 1, 2, 4 -- per page.
    link_checks = 0
    for page in pages:
        rel = page.relative_to(site)
        html = page.read_text(encoding="utf-8", errors="replace")
        for ref in page_refs(html):
            link_checks += 1
            if ref.startswith("http://"):
                problems.append(f"FAIL: {rel}: insecure link '{ref}'")
                continue
            target = resolve(page, site, ref)
            if target is not None and not target.exists():
                problems.append(f"FAIL: {rel}: broken link '{ref}'")
        if is_redirect_stub(html):
            continue
        text = plain_text(html)
        for pattern in STALE_LABELS:
            if re.search(pattern, text):
                problems.append(f"FAIL: {rel}: stale label matching /{pattern}/")

    # 3 -- reference index vs _pkgdown.yml.
    want = topics_from_pkgdown(root)
    internal = internal_topics(root)
    stubs_ok = alias_stems(root)
    index = site / "reference" / "index.html"
    index_links = set()
    if not index.exists():
        problems.append("FAIL: reference/index.html missing")
    else:
        index_links = {r[: -len(".html")] for r in page_refs(index.read_text(encoding="utf-8"))
                       if re.fullmatch(r"[\w.-]+\.html", r) and r != "index.html"}
        for topic in want:
            if topic not in index_links:
                problems.append(f"FAIL: reference/index.html omits '{topic}' (listed in _pkgdown.yml)")
        for extra in sorted(index_links - set(want)):
            problems.append(f"FAIL: reference/index.html lists '{extra}' (not in _pkgdown.yml)")

    # 5 -- coverage text on period-bearing pages.
    coverage_pages = 0
    for page in sorted((site / "reference").glob("*.html")):
        html = page.read_text(encoding="utf-8", errors="replace")
        if is_redirect_stub(html):
            continue
        text = plain_text(html)
        if not PERIOD_COLUMN.search(text):
            continue
        coverage_pages += 1
        if "1971" not in text:
            problems.append(f"FAIL: reference/{page.name}: documents a period column "
                            "but never mentions the 1971 coverage start")
        if "2026" not in text:
            problems.append(f"FAIL: reference/{page.name}: documents a period column "
                            "but never mentions the 2026 coverage end")

    # 6 -- completeness, both directions.
    for rd in sorted((root / "man").glob("*.Rd")):
        if not (site / "reference" / f"{rd.stem}.html").exists():
            problems.append(f"FAIL: man/{rd.name} has no reference/{rd.stem}.html page")
    ref_pages = sorted((site / "reference").glob("*.html"))
    for page in ref_pages:
        if page.stem == "index":
            continue
        rel = f"reference/{page.name}"
        if is_redirect_stub(page.read_text(encoding="utf-8", errors="replace")):
            continue
        if page.stem not in want and page.stem not in internal:
            problems.append(f"FAIL: {rel} is neither listed in _pkgdown.yml "
                            "nor an internal topic")

    # Every stub anywhere in the site must be one pkgdown was asked to write:
    # an Rd alias page, or a declared `redirects:` entry. A stub from an earlier
    # build lingers in docs/ otherwise, since pkgdown only writes, never prunes.
    declared = redirect_targets(root)
    for page in pages:
        rel = str(page.relative_to(site))
        if not is_redirect_stub(page.read_text(encoding="utf-8", errors="replace")):
            continue
        if rel not in declared and rel not in stubs_ok:
            problems.append(f"FAIL: {rel} is a redirect stub with no `redirects:` entry in "
                            "_pkgdown.yml and no matching alias in man/")

    # 7 -- freshness.
    yml = site / "pkgdown.yml"
    if not yml.exists():
        problems.append("FAIL: pkgdown.yml missing (was the site ever built?)")
    else:
        meta = yml.read_text(encoding="utf-8")
        if not re.search(r"^pkgdown: [0-9]", meta, re.M):
            problems.append("FAIL: pkgdown.yml has no pkgdown: version")
        if not re.search(r"^last_built: \d{4}-\d{2}-\d{2}", meta, re.M):
            problems.append("FAIL: pkgdown.yml has no last_built date")

    # Vacuity guards: a run that inspected nothing must not report success.
    for name, n in (("links", link_checks), ("reference pages", len(ref_pages)),
                    ("coverage-bearing pages", coverage_pages), ("_pkgdown.yml topics", len(want))):
        if n == 0:
            problems.append(f"FAIL: compared zero {name} -- the checker is broken, not the site")

    for line in problems:
        print(line)
    print(f"CHECK_SITE: {len(pages)} pages, {link_checks} refs, {coverage_pages} coverage pages, "
          f"{len(want)} _pkgdown.yml topics, {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
