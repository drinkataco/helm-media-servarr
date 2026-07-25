#!/usr/bin/env sh
#
# Tests the secret-substitution logic used by the prepare-config init container
# in templates/deployment.yaml. The escape step must match the template
# exactly; keep them in sync.
#
# See issue #343: a raw '/' (or '&', '\') in a secret value was breaking sed's
# s/// command because those characters are metacharacters in the replacement.

# shellcheck disable=SC2016
# $name inside single-quoted test inputs is literal — that's the placeholder
# the substitute function replaces via sed. Shell expansion is not wanted here.

set -eu

# Mirror of the escape used in templates/deployment.yaml:
# escapes &, /, and \ so they survive as literals in a sed s/// replacement.
escape_replacement() {
  printf '%s' "$1" | sed -e 's|[&/\]|\\&|g'
}

# Runs the substitute-with-escape flow end-to-end: given a secret value,
# placeholder name (used in the config as "$name"), and input, return the
# substituted output. Matches what the rendered init container does.
substitute() {
  value=$1
  name=$2
  input=$3
  esc=$(escape_replacement "$value")
  printf '%s' "$input" | sed -e "s/\$$name/$esc/g"
}

assert_eq() {
  desc=$1
  expected=$2
  actual=$3
  if [ "$expected" != "$actual" ]; then
    printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$desc" "$expected" "$actual" >&2
    exit 1
  fi
  printf 'ok - %s\n' "$desc"
}

# --- Test cases ---

# Baseline: no metacharacters, just a plain value.
assert_eq 'baseline substitution' \
  '<ApiKey>plain-value</ApiKey>' \
  "$(substitute 'plain-value' 'apiKey' '<ApiKey>$apiKey</ApiKey>')"

# The reported case: CIDR notation with a forward slash.
assert_eq 'slash in value (#343)' \
  'Address = 10.0.0.2/16' \
  "$(substitute '10.0.0.2/16' 'ipMask' 'Address = $ipMask')"

# Ampersand is sed's replacement-side metacharacter for "the matched pattern".
assert_eq 'ampersand in value' \
  'value = a&b' \
  "$(substitute 'a&b' 'ampVal' 'value = $ampVal')"

# Backslash is the sed escape character.
assert_eq 'backslash in value' \
  'path = a\b\c' \
  "$(substitute 'a\b\c' 'winPath' 'path = $winPath')"

# All three metacharacters together.
assert_eq 'all metacharacters in one value' \
  'combo = a/b&c\d' \
  "$(substitute 'a/b&c\d' 'combo' 'combo = $combo')"

# Multiple occurrences of the same placeholder — sed's /g flag should replace all.
assert_eq 'placeholder appears multiple times' \
  'x=hello y=hello' \
  "$(substitute 'hello' 'greet' 'x=$greet y=$greet')"

printf '\nAll tests passed.\n'
