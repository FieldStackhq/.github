#!/usr/bin/env python3
"""Flag db/ SQL statement shapes that can destroy, detach or shorten a protected table's data or history.
Usage: --tables "A.B,C.D" --range "<git range>". Exit: 0 clean, 1 findings, 2 usage/read/git error or refused
SQL (control/format characters, non-ASCII in code, "..." names, $name$), 3 crash."""
import argparse
import bisect
import os
import re
import subprocess
import sys
import unicodedata
from collections import namedtuple

Tok = namedtuple("Tok", "kind text line start end up nm")
Seg = namedtuple("Seg", "toks batch")
WORD = re.compile(r"[\w#@$]+")
NUM = re.compile(r"0[xX][0-9A-Fa-f]*|\$?[0-9]+(?:\.[0-9]*)?(?:[eE](?:[+-]?[0-9]+)?)?")
MARK = re.compile(r"--\s*MIGRATION SAFETY:(.*)$", re.I | re.S | re.A)
ANY = "any protected table"
# Placeholder table for sp_rename/sp_changeobjectowner given a variable; check_file expands it.
VIA_VAR = "\0variable"
RESERVED = frozenset(
    "ON WHERE SET WITH SELECT JOIN INNER LEFT RIGHT FULL CROSS OUTER WHEN GROUP ORDER HAVING UNION "
    "OPTION VALUES FROM AS WHILE IF ELSE BEGIN END DELETE INSERT UPDATE MERGE DROP ALTER PRINT EXEC "
    "EXECUTE DECLARE RETURN TRUNCATE CREATE THEN GO".split())
STOP = frozenset("SELECT WHERE SET GROUP ORDER HAVING VALUES INSERT DELETE UPDATE MERGE WHEN THEN".split())
ROW_WRITES = frozenset("INSERT UPDATE MERGE INTO UPDATETEXT WRITETEXT".split())
WRITES = ROW_WRITES | {"DELETE", "TRUNCATE"}
DESC = {
    "E1": "DROP TABLE removes the table and its data",
    "E2": "TRUNCATE TABLE removes every row",
    "E3": "DELETE (or MERGE ... THEN DELETE) removes rows",
    "E4": "dropping a column or period loses data",
    "E5": "ALTER COLUMN can change or lose data",
    "E6": "turning SYSTEM_VERSIONING off detaches the history",
    "E7": "a finite HISTORY_RETENTION_PERIOD shortens the history",
    "E8": "sp_rename breaks the table or column name",
    "E9": "SWITCH moves partitions in or out",
    "E10": "ALTER SCHEMA TRANSFER or sp_changeobjectowner moves the table",
    "N1": "a seed re-runs on every deploy and must not write to a protected table or call a procedure in its schema",
    "N2": "-- @no-transaction is not allowed in a file that references a protected table",
    "E11": ("a write to a history table, or to a protected table after SYSTEM_VERSIONING is turned off, "
            "is not recorded in history"),
    "N3": "SYSTEM_VERSIONING turned OFF needs a later statement, after a ';' or GO, re-attaching it with a "
          "different protected HISTORY_TABLE",
    "N4": "code outside a procedure, function or view body in db/programmable/ re-runs whenever db-deploy "
          "re-applies the file, and any trigger body outside db/seed/ runs on every write; neither may write to a "
          "protected table, run dynamic SQL (EXEC (...), EXEC @v, sp_executesql), or call a procedure in its "
          "schema or in this file",
}
DEFS = frozenset("PROC PROCEDURE FUNCTION VIEW".split())


class Fail(Exception):
    def __init__(self, msg, path=None, line=None):
        super().__init__(msg)
        self.path = path
        self.line = line


def unq(text):
    close = "]" if text[0] == "[" else text[0]
    inner = text[1:-1] if len(text) > 1 and text.endswith(close) else text[1:]
    return (inner.replace("]]", "]") if close == "]" else inner.replace('""', '"')).rstrip(" ")


def quoted(text, i, close):
    j = i + 1
    while True:
        k = text.find(close, j)
        if k < 0:
            return len(text)
        if text.startswith(close * 2, k):
            j = k + 2
        else:
            return k + 1


def fold(s):
    return unicodedata.normalize("NFKC", s).casefold()


def lex(text):
    toks, n, i = [], len(text), 0
    nls = [m.start() for m in re.finditer("\n", text)]

    # Keywords match ASCII only; names fold case (and, inside strings, width) for matching.
    def mk(kind, s, e):
        t = text[s:e]
        up = (t.upper() if t.isascii() else t) if kind == "word" else ""
        nm = fold(t) if kind == "word" else fold(unq(t)) if kind in ("br", "dq") else None
        toks.append(Tok(kind, t, bisect.bisect_left(nls, s) + 1, s, e, up, nm))

    while i < n:
        c = text[i]
        if c.isspace():
            i += 1
        elif text.startswith("--", i):
            e = text.find("\n", i)
            e = n if e < 0 else e
            mk("lc", i, e)
            i = e
        elif text.startswith("/*", i):
            depth, j = 1, i + 2
            while j < n and depth:
                if text.startswith("/*", j):
                    depth, j = depth + 1, j + 2
                elif text.startswith("*/", j):
                    depth, j = depth - 1, j + 2
                else:
                    j += 1
            mk("bc", i, j)
            i = j
        elif c in "'[\"":
            j = quoted(text, i, "]" if c == "[" else c)
            mk({"'": "str", "[": "br", '"': "dq"}[c], i, j)
            i = j
        elif "0" <= c <= "9" or (c == "$" and "0" <= text[i + 1:i + 2] <= "9"):
            # A literal stops at the first letter it cannot take (0DELETE, 0eDELETE, $0DELETE; hex takes A-F),
            # as SQL Server reads it.
            e = NUM.match(text, i).end()
            mk("num", i, e)
            i = e
        else:
            m = WORD.match(text, i)
            if not m:
                mk("p", i, i + 1)
                i += 1
            elif m.group() in ("N", "n") and text.startswith("'", m.end()):
                j = quoted(text, m.end(), "'")
                mk("str", i, j)
                i = j
            else:
                mk("word", i, m.end())
                i = m.end()
    return toks


def segments(text, toks):
    segs, cur, cur_batch, next_batch = [], [], True, True
    for t in toks:
        if t.kind in ("lc", "bc"):
            continue
        is_go = False
        if t.kind == "word" and t.up == "GO":
            before = text[t.start - 1] if t.start else " "
            after = text[t.end] if t.end < len(text) else " "
            is_go = before.isspace() and (after.isspace() or after == ";")
        if is_go or (t.kind == "p" and t.text == ";"):
            if cur:
                segs.append(Seg(cur, cur_batch))
                cur = []
            next_batch = next_batch or is_go
            continue
        if not cur:
            cur_batch, next_batch = next_batch, False
        cur.append(t)
    if cur:
        segs.append(Seg(cur, cur_batch))
    return segs


def match_at(toks, i, prot):
    t = toks[i]
    if t.nm is None:
        return None
    if i + 2 < len(toks) and toks[i + 1].kind == "p" and toks[i + 1].text == ".":
        for s, tb, c in prot:
            if t.nm == s and toks[i + 2].nm == tb:
                return c, 3
    if i and toks[i - 1].kind == "p" and toks[i - 1].text == ".":
        return None
    for _, tb, c in prot:
        if t.nm == tb:
            return c, 1
    return None


def str_table(tok, prot):
    body = tok.text[tok.text.index("'") + 1:]
    return name_table((body[:-1] if body.endswith("'") else body).replace("''", "'"), prot)


def name_table(body, prot):
    sub = lex(body)
    for k in range(len(sub)):
        m = match_at(sub, k, prot)
        if m:
            end = k + m[1]
            if end == len(sub) or (end + 2 == len(sub) and sub[end].text == "." and sub[end + 1].nm):
                return m[0]
    return None


class Scan:
    """Token helpers over one segment."""

    def __init__(self, seg, prot):
        self.toks, self.batch, self.prot, self.n = seg.toks, seg.batch, prot, len(seg.toks)
        self.ms, self.ren, i = [], [], 0
        while i < self.n:
            m = match_at(self.toks, i, prot)
            if m:
                self.ms.append((i, m[1], m[0]))
                i += m[1]
            else:
                i += 1

    def up(self, k):
        return self.toks[k].up if 0 <= k < self.n else ""

    def punct(self, k, ch):
        return 0 <= k < self.n and self.toks[k].kind == "p" and self.toks[k].text == ch

    def seq(self, k, pat):
        return k + len(pat) <= self.n and all(
            (self.toks[k + m].up or self.toks[k + m].text) == p for m, p in enumerate(pat))

    def close(self, k):
        d = 0
        for j in range(k, self.n):
            d += self.punct(j, "(") - self.punct(j, ")")
            if d == 0:
                return j
        return self.n - 1

    def name_end(self, j):
        if j >= self.n or self.toks[j].nm is None:
            return j
        j += 1
        while self.punct(j, "."):
            while self.punct(j, "."):
                j += 1
            if j < self.n and self.toks[j].nm is not None:
                j += 1
        return j

    def table_of_item(self, j):
        e = self.name_end(j)
        for k in range(j, e):
            m = match_at(self.toks, k, self.prot)
            if m and k + m[1] == e:
                return m[0]
        return None

    def name_start(self, i):
        while i >= 2 and self.punct(i - 1, ".") and self.toks[i - 2].nm is not None:
            i -= 2
        return i

    def skip_top(self, j):
        if self.up(j) == "TOP":
            j = self.close(j + 1) + 1 if self.punct(j + 1, "(") else j + 2
            if self.up(j) == "PERCENT":
                j += 1
        return j

    def clause_ok(self, i):
        k = i - 1
        while self.punct(k, "("):
            k -= 1
        if self.up(k) in ("FROM", "JOIN", "APPLY", "USING", "UPDATE", "MERGE", "INTO"):
            return True
        if not self.punct(k, ","):
            return False
        d = case_d = 0
        for m in range(k - 1, -1, -1):
            if self.punct(m, ")"):
                d += 1
            elif self.punct(m, "("):
                if d == 0:
                    return False
                d -= 1
            elif d == 0 and self.up(m) == "END":
                case_d += 1
            elif d == 0 and self.up(m) == "CASE" and case_d > 0:
                case_d -= 1
            elif d == 0 and case_d == 0 and self.up(m) in ("FROM", "JOIN", "APPLY", "USING"):
                return True
            elif d == 0 and case_d == 0 and self.up(m) in STOP:
                return False
        return False

    def body_from(self, p, resolve):
        """Tables named by the first depth-0 FROM source of the bracketed query at p.
        Redundant brackets are skipped and a nested query in that FROM is followed."""
        while True:
            while self.punct(p + 1, "(") and self.close(p + 1) == self.close(p) - 1:
                p += 1
            d, nxt = 0, None
            for k in range(p + 1, self.close(p)):
                d += self.punct(k, "(") - self.punct(k, ")")
                if d == 0 and self.up(k) == "FROM":
                    if not self.punct(k + 1, "("):
                        return resolve(k + 1)
                    nxt = k + 1
                    break
            if nxt is None:
                return set()
            p = nxt

    def bindings(self):
        bind = {}
        for i, ln, c in self.ms:
            j = i + ln + (self.up(i + ln) == "AS")
            if (j < self.n and self.toks[j].nm and self.toks[j].up not in RESERVED
                    and self.clause_ok(self.name_start(i))):
                bind.setdefault(self.toks[j].nm, set()).add(c)

        def resolve(j):
            c = self.table_of_item(j)
            if c:
                return {c}
            if self.name_end(j) == j + 1:
                return bind.get(self.toks[j].nm, set())
            return set()

        for i in range(1, self.n):
            if self.toks[i].nm is not None and (self.up(i - 1) == "WITH" or self.punct(i - 1, ",")):
                j = i + 1
                if self.punct(j, "("):
                    j = self.close(j) + 1
                if self.up(j) == "AS" and self.punct(j + 1, "("):
                    for c in self.body_from(j + 1, resolve):
                        bind.setdefault(self.toks[i].nm, set()).add(c)
            elif self.punct(i, "(") and (self.up(i + 1) == "SELECT" or self.punct(i + 1, "(")) and self.clause_ok(i):
                q = self.close(i) + 1
                q += self.up(q) == "AS"
                if q < self.n and self.toks[q].nm and self.toks[q].up not in RESERVED:
                    for c in self.body_from(i, resolve):
                        bind.setdefault(self.toks[q].nm, set()).add(c)
        for i in range(1, self.n):
            nm = self.toks[i].nm
            if nm in bind and self.name_end(i) == i + 1 and self.clause_ok(i):
                j = i + 1 + (self.up(i + 1) == "AS")
                if j < self.n and self.toks[j].nm and self.toks[j].up not in RESERVED:
                    bind.setdefault(self.toks[j].nm, set()).update(bind[nm])
        return resolve

    def schema_call(self, k, schemas):
        parts = []
        while k < self.n and self.toks[k].nm is not None:
            parts.append(self.toks[k].nm)
            k += 1
            if not self.punct(k, "."):
                break
            while self.punct(k, "."):
                k += 1
        return len(parts) >= 2 and parts[-2] in schemas


def analyze(s, seed, body=0):
    """Return (findings as (rule, table, line), E6 hits as (table, off_line))."""
    res, e6, seen = [], [], set()
    toks, n = s.toks, s.n
    resolve = s.bindings()

    def add(rule, c, default):
        if (rule, c) not in seen:
            seen.add((rule, c))
            lines = [toks[i].line for i, _, cc in s.ms if cc == c]
            res.append((rule, c, min(lines) if lines else default))

    def retention(r, c):
        for k in range(r, n):
            if s.up(k) == "HISTORY_RETENTION_PERIOD" and s.punct(k + 1, "=") and s.up(k + 2) != "INFINITE":
                add("E7", c, toks[k].line)

    # A finite retention in a statement that points HISTORY_TABLE at a protected table shortens its history.
    a = next((i for i in range(n) if s.up(i) in ("ALTER", "CREATE") and s.up(i + 1) == "TABLE"), None)
    if a is not None:
        hist = {s.table_of_item(k + 2) for k in range(a + 2, n)
                if s.up(k) == "HISTORY_TABLE" and s.punct(k + 1, "=") and s.table_of_item(k + 2)}
        for h in sorted(hist):
            retention(a + 2, h)
    for i, t in enumerate(toks):
        u = t.up
        if u == "DROP" and s.up(i + 1) == "TABLE":
            j = i + 2 + 2 * (s.up(i + 2) == "IF" and s.up(i + 3) == "EXISTS")
            while True:
                c = s.table_of_item(j)
                if c:
                    add("E1", c, t.line)
                j = s.name_end(j)
                if not s.punct(j, ","):
                    break
                j += 1
        elif u == "TRUNCATE" and s.up(i + 1) == "TABLE":
            c = s.table_of_item(i + 2)
            if c:
                add("E2", c, t.line)
        elif u == "DELETE" and s.up(i - 1) != "THEN":
            j = s.skip_top(i + 1)
            for c in resolve(j + (s.up(j) == "FROM")):
                add("E3", c, t.line)
        elif u == "MERGE" and any(s.up(k) == "THEN" and s.up(k + 1) == "DELETE" for k in range(n)):
            j = s.skip_top(i + 1)
            for c in resolve(j + (s.up(j) == "INTO")):
                add("E3", c, t.line)
        elif u == "ALTER" and s.up(i + 1) == "TABLE" and s.table_of_item(i + 2):
            c, r = s.table_of_item(i + 2), s.name_end(i + 2)
            d = next((k for k in range(r, n) if s.up(k) == "DROP"), None)
            if d is not None and any(s.up(k) in ("COLUMN", "PERIOD") for k in range(d + 1, n)):
                add("E4", c, t.line)
            for k in range(r, n):
                if k > r and s.up(k) == "ALTER":
                    break
                if s.up(k) == "ALTER" and s.up(k + 1) == "COLUMN":
                    add("E5", c, t.line)
                if s.seq(k, ["SYSTEM_VERSIONING", "=", "OFF"]):
                    add("E6", c, t.line)
                    e6.append((c, toks[k + 2].line))
                if s.up(k) == "SWITCH":
                    add("E9", c, t.line)
            retention(r, c)
        elif u == "CREATE" and s.up(i + 1) == "TABLE" and s.table_of_item(i + 2):
            retention(s.name_end(i + 2), s.table_of_item(i + 2))
        elif u == "SWITCH" and any(s.up(k) == "ALTER" and s.up(k + 1) == "TABLE" for k in range(i)):
            to = next((k for k in range(i + 1, n) if s.up(k) == "TO"), None)
            c = s.table_of_item(to + 1) if to is not None else None
            if c:
                add("E9", c, t.line)
        elif u == "ALTER" and s.up(i + 1) == "SCHEMA" and s.up(i + 3) == "TRANSFER":
            k = i + 4
            if s.up(k) == "OBJECT" and s.punct(k + 1, ":") and s.punct(k + 2, ":"):
                k += 3
            c = s.table_of_item(k)
            if c:
                add("E10", c, t.line)
        elif t.nm in ("sp_rename", "sp_changeobjectowner"):
            rule = "E8" if t.nm == "sp_rename" else "E10"
            for k in range(i + 1, n):
                a = toks[k]
                c = (str_table(a, s.prot) if a.kind == "str"
                     else name_table(unq(a.text), s.prot) if a.kind in ("br",) else None)
                if c:
                    add(rule, c, a.line)
                    s.ren.append((a.start, c))
                elif a.text.startswith("@") and not s.punct(k + 1, "="):
                    add(rule, VIA_VAR, t.line)
    if seed:
        # GRANT, DENY, REVOKE and UPDATE STATISTICS write no rows; T-SQL needs no ';', so a write keyword after
        # their permission list (first ON/TO/FROM) or after STATISTICS starts another statement and is checked.
        perm = next((k for k in range(1, n) if s.up(k) in ("ON", "TO", "FROM")), 1)
        no_rows = ((s.up(0) in ("GRANT", "DENY", "REVOKE") and not any(s.up(k) in WRITES for k in range(perm, n)))
                   or (s.up(0) == "UPDATE" and s.up(1) == "STATISTICS"
                       and not any(s.up(k) in WRITES for k in range(2, n))))
        if any(i >= body for i, _, _ in s.ms) and not no_rows and any(t.up in WRITES for t in toks[body:]):
            for c in dict.fromkeys(c for i, _, c in s.ms if i >= body):
                add("N1", c, toks[0].line)
        schemas = {sc for sc, _, _ in s.prot}
        for i, t in enumerate(toks):
            if t.up in ("EXEC", "EXECUTE"):
                k = i + 1
                if k < n and toks[k].text.startswith("@") and s.punct(k + 1, "="):
                    k += 2
                if k < n and toks[k].text.startswith("@") and not s.punct(k + 1, "="):
                    add("N1", ANY, t.line)
                if k < n and toks[k].text == "(":
                    add("N1", ANY, t.line)
                if s.schema_call(k, schemas):
                    add("N1", ANY, t.line)
        if any(t.nm == "sp_executesql" for t in toks):
            add("N1", ANY, toks[0].line)
        if s.batch and s.schema_call(0, schemas):
            add("N1", ANY, toks[0].line)
    return res, e6


def reattaches(s, c):
    pat = ["SET", "(", "SYSTEM_VERSIONING", "=", "ON", "("]
    for i in range(s.n):
        if s.up(i) == "ALTER" and s.up(i + 1) == "TABLE" and s.table_of_item(i + 2) == c:
            for k in range(s.name_end(i + 2), s.n):
                if s.up(k) == "ALTER":
                    break
                if not s.seq(k, pat):
                    continue
                p = k + 5
                for m in range(p + 1, s.close(p)):
                    if s.up(m) == "HISTORY_TABLE" and s.punct(m + 1, "="):
                        h = s.table_of_item(m + 2)
                        if h and h != c:
                            return True
    return False


def parse_entry(e):
    t = lex(e.strip())
    if len(t) == 3 and t[0].nm and t[2].nm and t[1].kind == "p" and t[1].text == ".":
        raw = [x.text if x.kind == "word" else unq(x.text) for x in (t[0], t[2])]
        return t[0].nm, t[2].nm, raw[0] + "." + raw[1]
    return None


def parse_tables(spec):
    prot = {}
    for e in spec.split(","):
        if e.strip():
            p = parse_entry(e)
            if not p:
                raise Fail(f"--tables entry '{e.strip()}' must be schema.table")
            prot.setdefault(p[:2], p)
    if spec.strip() and not prot:
        raise Fail("--tables names no table")
    return list(prot.values())


def parse_markers(comments, prot):
    ok, bad, known = set(), [], {(s, t): c for s, t, c in prot}
    for t in comments:
        m = MARK.match(t.text) if t.kind == "lc" else None
        sp = re.search(r"\s--(?:\s|$)", m.group(1), flags=re.A) if m else None
        if not sp:
            continue
        names = [x.strip(" \t") for x in m.group(1)[:sp.start()].split(",")]
        reason = m.group(1)[sp.end():].strip(" \t")
        found = [(x, parse_entry(x)) for x in names]
        wrong = next((x for x, p in found if not p or p[:2] not in known), None)
        if wrong is not None:
            bad.append((t.line, wrong or ANY, "names a table that is not protected"))
        elif not reason:
            bad.append((t.line, ANY, "has no reason after ' -- ' on the same line"))
        else:
            ok.update(known[p[:2]] for _, p in found)
    return ok, bad


def no_tx_header(text):
    for line in text.split("\n")[:10]:
        s = line.strip()
        if s and not s.startswith("--"):
            return False
        if s == "-- @no-transaction":
            return True
    return False


def read_text(path):
    try:
        with open(path, "rb") as f:
            raw = f.read().decode("utf-8-sig")
    except (OSError, UnicodeDecodeError) as e:
        raise Fail(f"cannot read as UTF-8: {e}", path)
    parts = raw.split("\n")
    text = "\n".join([x[:-1] if x.endswith("\r") else x for x in parts[:-1]] + parts[-1:])
    # Control and format characters (lone CR, NUL, U+200B, a mid-file BOM...) split differently in
    # DbUp, SQL Server and this lexer, so a file containing one is refused.
    if not (text.isascii() and not re.search(r"[\x00-\x08\x0b-\x1f\x7f]", text)):
        for idx, ch in enumerate(text):
            if ch not in "\t\n" and unicodedata.category(ch) in ("Cc", "Cf"):
                line = text.count("\n", 0, idx) + 1
                raise Fail(f"line {line}: character U+{ord(ch):04X} is not allowed here; remove it or replace "
                           "it with a space", path, line)
    # DbUp removes $schema$. and fails the deploy on any other $name$ variable, so refuse both here,
    # where the line can be named (comments included, a harmless over-refusal).
    m = re.search(r"\$[A-Za-z0-9_-][^$\n]*\$", text)
    if m:
        line = text.count("\n", 0, m.start()) + 1
        raise Fail(f"line {line}: '{m.group()}' is not allowed; DbUp removes $schema$. and treats other $name$ "
                   "as variables", path, line)
    return text


def last_part(s, k):
    e = s.name_end(k)
    return s.toks[e - 1].nm if e > k else None


def check_file(path, prot):
    """Return the file's findings as (line, rule, table, message)."""
    text = read_text(path)
    toks = lex(text)
    # Non-ASCII outside strings and comments (fullwidth keywords, zero-width or odd spaces in names)
    # reads differently in SQL Server and this lexer, so the file is refused.
    if not text.isascii():
        spans = [(t.start, t.end) for t in toks if t.kind in ("str", "lc", "bc")]
        starts = [s for s, _ in spans]
        for m in re.finditer(r"[^\x00-\x7f]", text):
            k = bisect.bisect_right(starts, m.start()) - 1
            if k < 0 or m.start() >= spans[k][1]:
                line = text.count("\n", 0, m.start()) + 1
                raise Fail(f"line {line}: character U+{ord(m.group()):04X} is not allowed outside a string or "
                           "comment", path, line)
    # DbUp does not lex "..." names, so any one in code can split batches differently from SQL Server.
    for t in toks:
        if t.kind == "dq":
            raise Fail(f"line {t.line}: double-quoted names are not allowed (DbUp splits batches around them "
                       "differently); use [brackets]", path, t.line)
    scans = [Scan(sg, prot) for sg in segments(text, toks)]
    low = path.lower()
    seed, mig = low.startswith("db/seed/"), low.startswith("db/migrations/")
    prog = low.startswith("db/programmable/")
    # Top level: in db/programmable/, a GO batch that does not start CREATE [OR ALTER] | ALTER + PROC/FUNCTION/VIEW
    # (re-runs when the file is re-applied), and a trigger batch in any folder (any write fires it). Not exemptable.
    top, defn, trig, top_hits, defs, hdr = set(), False, False, set(), set(), {}
    for idx, s in enumerate(scans):
        if s.batch:
            k = 1 + 2 * (s.up(0) == "CREATE" and s.up(1) == "OR" and s.up(2) == "ALTER")
            defn = s.up(0) in ("CREATE", "ALTER") and s.up(k) in DEFS
            if defn and s.up(k) in ("PROC", "PROCEDURE") and last_part(s, k + 1):
                defs.add(last_part(s, k + 1))
            # A trigger header (ON <table> ... FOR|AFTER|INSTEAD OF <events> AS) writes nothing, so the write
            # test starts after the AS that follows its events (WITH EXECUTE AS comes before them).
            trig = s.up(0) in ("CREATE", "ALTER") and s.up(k) == "TRIGGER"
            if trig:
                f = next((j for j in range(k + 1, s.n) if s.up(j) in ("FOR", "AFTER", "INSTEAD")), k)
                a = next((j for j in range(f + 1, s.n) if s.up(j) == "AS"), None)
                if a is not None:
                    hdr[idx] = a + 1
        if (prog and not defn) or (trig and not seed):
            top.add(idx)
    found, e6 = [], []
    for idx, s in enumerate(scans):
        # Top level behaves like a seed: analyze's N1 refusals are reported as N4.
        res, hits = analyze(s, seed or idx in top, hdr.get(idx, 0))
        if idx in top:
            res = [("N4" if r == "N1" else r, c, ln) for r, c, ln in res]
            calls = [i + 1 + 2 * (s.punct(i + 2, "=") and s.toks[i + 1].text.startswith("@"))
                     for i, t in enumerate(s.toks) if t.up in ("EXEC", "EXECUTE")] + [0] * s.batch
            res += [("N4", ANY, s.toks[k].line) for k in calls if k < s.n and last_part(s, k) in defs]
            top_hits.update(res)
        found += res
        e6 += [(idx, c, ln) for c, ln in hits]
    first = {}
    for idx, c, ln in e6:
        first.setdefault((idx, c), ln)
    e6 = [(idx, c, ln) for (idx, c), ln in first.items()]
    for idx, c, ln in e6:
        if not any(reattaches(s, c) for s in scans[idx + 1:]):
            found.append(("N3", c, ln))
    # After versioning goes OFF, any statement that writes, or may write, a protected table is not recorded
    # in history, so the marker must name that table (reads and later statements can over-flag).
    if e6:
        for j, s in enumerate(scans[min(idx for idx, _, _ in e6):], min(idx for idx, _, _ in e6)):
            if any(t.up in ROW_WRITES for t in s.toks) and s.ms:
                tabs = list(dict.fromkeys(c for _, _, c in s.ms))
                for c in tabs:
                    found.append(("E11", c, min(s.toks[i].line for i, _, cc in s.ms if cc == c)))
                    if j in top:
                        top_hits.add(found[-1])
    # A table named ...History is treated as a history table: SQL Server only lets it be written while
    # versioning is off, so any statement that writes, or may write, it needs a marker naming it.
    hist = {c for _, t_, c in prot if t_.endswith("history")}
    for j, s in enumerate(scans):
        if any(t.up in ROW_WRITES for t in s.toks):
            for c in dict.fromkeys(c for _, _, c in s.ms if c in hist):
                found.append(("E11", c, min(s.toks[i].line for i, _, cc in s.ms if cc == c)))
                if j in top:
                    top_hits.add(found[-1])
    found = list(dict.fromkeys(found))
    # A rename/move via a variable flags each table named in code or a whole string (unless already flagged).
    # N2 names the first table in code or a rename/move argument, else one of those named tables.
    cands = sorted([(s.toks[i].start, c) for s in scans for i, _, c in s.ms] + [x for s in scans for x in s.ren])
    named = sorted({c for _, c in cands} | {c for t in toks if t.kind == "str" for c in [str_table(t, prot)] if c})
    found = [(r, c, ln, (r, c, ln) in top_hits) for r, c, ln in found]
    direct = {(r, c, t) for r, c, _, t in found}
    found = [(r, x, ln, t) for r, c, ln, t in found
             for x in ([y for y in named if (r, y, t) not in direct] if c == VIA_VAR else [c])]
    refs = [c for s in scans for _, _, c in s.ms]
    referenced = bool(refs) or any(r in ("E8", "E10") for r, *_ in found)
    if mig and referenced and no_tx_header(text):
        found.append(("N2", cands[0][1] if cands else named[0] if named else prot[0][2], 1, False))
    ok, bad = parse_markers(toks, prot) if referenced else (set(), [])
    out = []
    for rule, c, ln, is_top in found:
        if rule[0] == "N":
            out.append((ln, rule, c, DESC[rule]))
        elif seed:
            out.append((ln, rule, c, f"{DESC[rule]}; not allowed under db/seed/, even with a marker"))
        elif is_top:
            out.append((ln, rule, c, f"{DESC[rule]}; not allowed at the top level of a db/programmable/ file "
                        "or in a trigger (it re-runs when the file is re-applied, or on every write), even with a "
                        "marker"))
        elif c not in ok:
            out.append((ln, rule, c, f"{DESC[rule]}; add '-- MIGRATION SAFETY: {c} -- <reason>' (reason on the same "
                        "line), and end statements with ';' so a neighbouring statement is not flagged"))
    for ln, name, why in bad:
        out.append((ln, "MARKER", name, f"a MIGRATION SAFETY marker {why}; use "
                    "'-- MIGRATION SAFETY: <schema.table>[, <schema.table>] -- <reason>'"))
    return sorted(out, key=lambda o: o[0])


def list_files(rng):
    if rng.split():
        cmd = ["git", "-c", "core.quotePath=false", "diff", "-z", "--name-only", "--diff-filter=ACMRT",
               *rng.split(), "--", "db/"]
        try:
            p = subprocess.run(cmd, capture_output=True)
        except OSError as e:
            raise Fail(f"cannot run git: {e}")
        if p.returncode:
            raise Fail(f"git diff failed ({p.returncode}): {p.stderr.decode('utf-8', 'replace').strip()}")
        names = p.stdout.decode("utf-8", "surrogateescape").split("\0")
    else:
        names = [os.path.join(d, f).replace(os.sep, "/") for d, _, fs in os.walk("db") for f in fs]
    return sorted({x for x in names if x.lower().endswith(".sql")})


def esc_msg(s):
    return s.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def esc_file(s):
    return esc_msg(s).replace(":", "%3A").replace(",", "%2C")


def run(argv):
    ap = argparse.ArgumentParser(prog="protected_tables.py")
    ap.add_argument("--tables", required=True)
    ap.add_argument("--range", default="")
    a = ap.parse_args(argv)
    if os.environ.get("PROTECTED_TABLES_TEST_CRASH") == "1":
        raise RuntimeError("forced crash for the harness")
    prot = parse_tables(a.tables)
    if not prot:
        print("protected-tables: no protected tables")
        return 0
    files, count = list_files(a.range), 0
    for path in files:
        for ln, rule, table, msg in check_file(path, prot):
            count += 1
            print(f"::error file={esc_file(path)},line={ln}::{esc_msg(f'protected-tables {rule} on {table}: {msg}')}")
    if count:
        print(f"protected-tables: {count} finding(s) in {len(files)} file(s) checked")
        return 1
    print(f"protected-tables: no findings in {len(files)} file(s) checked")
    return 0


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    try:
        code = run(sys.argv[1:])
    except Fail as e:
        where = f" file={esc_file(e.path)}" + (f",line={e.line}" if e.line else "") if e.path else ""
        print(f"::error{where}::protected-tables {esc_msg(str(e))}")
        code = 2
    except Exception as e:
        print(f"::error::protected-tables crashed with {type(e).__name__}: {esc_msg(str(e))}")
        code = 3
    sys.exit(code)


if __name__ == "__main__":
    main()
