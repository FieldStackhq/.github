#!/usr/bin/env bash
# Tests protected_tables.py against the case directories under fixtures/protected-tables/.
# Locally: PROTECTED_TABLES_PYTHON="uv run --no-project python" bash .github/scripts/protected_tables.test.sh
# Its own variable, not PYTHON, so a runner's PYTHON cannot make it test another interpreter than the gate's.
set -uo pipefail

# CI runs this from the caller's root and each case runs in a scratch repo, so resolve once.
OWN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$OWN_DIR/protected_tables.py"
FIXTURES="$OWN_DIR/fixtures/protected-tables"
PYTHON="${PROTECTED_TABLES_PYTHON:-python3}"
export PYTHONUTF8=1
unset PROTECTED_TABLES_TEST_CRASH

DEFAULT_TABLES="Infra.CurationRule,Infra.CurationRuleHistory"
SCRATCH_LIST="$(mktemp)"
if [ -z "$SCRATCH_LIST" ] || [ ! -f "$SCRATCH_LIST" ]; then
  echo "protected-tables: cannot create the scratch list; the check itself is broken"
  exit 1
fi
# On any exit, remove the scratch repos still listed (an early exit skips the per-case cleanup).
cleanup() {
  local d
  [ -f "$SCRATCH_LIST" ] || return 0
  while IFS= read -r d || [ -n "$d" ]; do
    [ -n "$d" ] && rm -rf "$d"
  done < "$SCRATCH_LIST"
  rm -f "$SCRATCH_LIST"
}
trap cleanup EXIT
ran=0
passed=0
failed=0

# Rewrites the scratch copy only: LF-normalise first, then apply the encoding.
ENCODE_PY='
import sys
mode = sys.argv[1]
for p in sys.argv[2:]:
    text = open(p, "rb").read().decode("utf-8").replace("\r\n", "\n")
    if mode == "crlf":
        data = text.replace("\n", "\r\n").encode("utf-8")
    elif mode == "bom":
        data = b"\xef\xbb\xbf" + text.encode("utf-8")
    elif mode == "utf16":
        data = b"\xff\xfe" + text.encode("utf-16-le")
    else:
        sys.exit("unknown encode: " + mode)
    open(p, "wb").write(data)
'

g() { git -c user.name=harness -c user.email=harness@invalid -c commit.gpgsign=false "$@"; }

# Prints a reason and returns 1 on any problem; the caller counts the case.
check_case() {
  local dir="$1" name="$2"
  local tables="$DEFAULT_TABLES" range_kind="two-dot" encode="" crash="" line key val

  if [ ! -d "$dir/change" ] || [ ! -f "$dir/expect" ]; then
    echo "  case needs change/ and expect"
    return 1
  fi

  if [ -f "$dir/args" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%$'\r'}"
      [ -z "$line" ] && continue
      key="${line%%=*}"
      val="${line#*=}"
      case "$key" in
        tables) tables="$val" ;;
        range) range_kind="$val" ;;
        encode) encode="$val" ;;
        crash) [ "$val" = "1" ] || { echo "  unknown crash value: $val"; return 1; }; crash="$val" ;;
        *) echo "  unknown args key: $key"; return 1 ;;
      esac
    done < "$dir/args"
  fi

  local scratch
  scratch="$(mktemp -d)" || { echo "  mktemp failed"; return 1; }
  echo "$scratch" >> "$SCRATCH_LIST"

  # git init then checkout -b works on any Git version (init -b needs 2.28).
  if ! ( cd "$scratch" && g init -q . && g checkout -q -b harness && g config core.autocrlf false ); then
    echo "  git init failed"
    rm -rf "$scratch"
    return 1
  fi

  if [ -d "$dir/base" ]; then
    cp -R "$dir/base/." "$scratch/" || { echo "  copying base/ failed"; rm -rf "$scratch"; return 1; }
  fi
  ( cd "$scratch" && g add -A && g commit -q --allow-empty -m base ) \
    || { echo "  base commit failed"; rm -rf "$scratch"; return 1; }

  local base_sha range
  base_sha="$(cd "$scratch" && git rev-parse HEAD)"
  case "$range_kind" in
    two-dot) range="$base_sha HEAD" ;;
    three-dot) ( cd "$scratch" && g branch main ); range="main...HEAD" ;;
    empty) range="" ;;
    bad) range="no-such-ref HEAD" ;;
    *) echo "  unknown range kind: $range_kind"; rm -rf "$scratch"; return 1 ;;
  esac

  cp -R "$dir/change/." "$scratch/" || { echo "  copying change/ failed"; rm -rf "$scratch"; return 1; }

  if [ -n "$encode" ]; then
    local enc_files=() f
    while IFS= read -r -d '' f; do
      enc_files+=("${f#./}")
    done < <(cd "$dir/change" && find . -type f -print0)
    if [ "${#enc_files[@]}" -gt 0 ]; then
      if ! ( cd "$scratch" && $PYTHON -c "$ENCODE_PY" "$encode" "${enc_files[@]}" ); then
        echo "  encode=$encode failed"
        rm -rf "$scratch"
        return 1
      fi
    fi
  fi

  ( cd "$scratch" && g add -A && g commit -q --allow-empty -m change ) \
    || { echo "  change commit failed"; rm -rf "$scratch"; return 1; }

  local out rc
  out="$(cd "$scratch" && if [ -n "$crash" ]; then export PROTECTED_TABLES_TEST_CRASH=1; fi; $PYTHON "$SCRIPT" --tables "$tables" --range "$range" 2>&1)"
  rc=$?

  local ok=0 first=1 want_rc=""
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    [ -z "$line" ] && continue
    if [ "$first" = 1 ]; then
      first=0
      want_rc="$line"
      if [ "$rc" != "$want_rc" ]; then
        echo "  exit code: wanted $want_rc, got $rc"
        ok=1
      fi
    elif [[ "$out" != *"$line"* ]]; then
      echo "  output lacks: $line"
      ok=1
    fi
  done < "$dir/expect"

  if [ "$first" = 1 ]; then
    echo "  expect is empty (line 1 must be the exit code)"
    ok=1
  fi
  if [ "$ok" != 0 ]; then
    echo "  --- output ---"
    printf '%s\n' "$out" | sed 's/^/  | /'
  fi

  rm -rf "$scratch"
  return "$ok"
}

for dir in "$FIXTURES"/*/; do
  [ -d "$dir" ] || continue
  dir="${dir%/}"
  name="$(basename "$dir")"
  ran=$((ran + 1))
  if details="$(check_case "$dir" "$name")"; then
    passed=$((passed + 1))
    echo "PASS $name"
  else
    failed=$((failed + 1))
    echo "FAIL $name"
    printf '%s\n' "$details"
  fi
done

# Every scratch repo must be gone, or the harness leaks into the runner's temp space.
leftover=0
while IFS= read -r d || [ -n "$d" ]; do
  if [ -n "$d" ] && [ -e "$d" ]; then
    echo "FAIL scratch repo not removed: $d"
    leftover=$((leftover + 1))
  fi
done < "$SCRATCH_LIST"
rm -f "$SCRATCH_LIST"

echo "protected-tables harness: $ran cases, $passed passed, $failed failed, $leftover scratch repos left"
if [ "$ran" -eq 0 ] || [ "$failed" -gt 0 ] || [ "$leftover" -gt 0 ]; then
  echo "protected-tables: the check itself is broken; see the failures above"
  exit 1
fi
exit 0
