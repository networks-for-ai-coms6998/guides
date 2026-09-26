#!/usr/bin/env bash
# scripts/lint.sh: run the same checks CI runs (.github/workflows/*.yml) locally,
# so lint status is known before pushing. No Docker needed.
#
#   markdownlint : markdownlint-cli 0.26.0 -- the version bundled in the
#                  avtodev/markdown-lint:v1 image that CI uses -- with .markdownlint.yaml
#   the shell    : run shellcheck on scripts/*.sh and scripts/tests/*.sh (brew install shellcheck)
#   bash 3.2     : scripts/tests/test_setup_gpu.sh under macOS system bash
#   links        : markdown-link-check on every *.md  (network; SKIP_LINKS=1 to skip)
#
# Usage: scripts/lint.sh          exits non-zero if any check fails
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

MDL_VERSION="0.26.0"
fail=0
step() { printf '\n== %s\n' "$1"; }

step "markdownlint-cli ${MDL_VERSION}"
npx --yes "markdownlint-cli@${MDL_VERSION}" -c .markdownlint.yaml ./ || fail=1

step "shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck scripts/*.sh scripts/tests/*.sh || fail=1
else
    echo "shellcheck not installed (brew install shellcheck)" >&2
    fail=1
fi

step "bash 3.2 test harness"
PATH="/bin:$PATH" bash scripts/tests/test_setup_gpu.sh >/dev/null || fail=1

if [ "${SKIP_LINKS:-0}" != "1" ]; then
    step "markdown-link-check"
    for f in $(git ls-files '*.md'); do
        npx --yes markdown-link-check -q "$f" || fail=1
    done
fi

if [ "$fail" -eq 0 ]; then
    printf '\nAll checks passed.\n'
else
    printf '\nSome checks FAILED.\n' >&2
fi
exit "$fail"
