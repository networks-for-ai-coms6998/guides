#!/usr/bin/env bash
# scripts/tests/test_setup_gpu.sh: exercises setup-gpu.sh's branching logic
# against a stub gcloud, since real GCP calls can't run here.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUB_BIN="$(mktemp -d)"
trap 'rm -rf "$STUB_BIN"' EXIT

write_stub_gcloud() {
    # $1: "authenticated" or "unauthenticated"
    # $2: GPU quota to report (integer)
    local auth_state="$1" quota="$2"
    {
        echo "#!/usr/bin/env bash"
        printf 'STUB_AUTH_STATE=%q\n' "$auth_state"
        printf 'STUB_GPU_QUOTA=%q\n' "$quota"
        # Single-quoted heredoc below -- none of this is expanded at write
        # time. $1/$2/$3 here are the STUB's own runtime args (i.e. the
        # real setup-gpu.sh's gcloud invocation), not write_stub_gcloud's;
        # only STUB_AUTH_STATE/STUB_GPU_QUOTA (assigned above) carry the
        # per-test-case values through to the stub's actual execution.
        cat <<'STUBEOF'
case "$1 $2" in
    "auth list")
        if [[ "$STUB_AUTH_STATE" == "authenticated" ]]; then echo "student@gmail.com"; else echo ""; fi
        ;;
    "config get-value") echo "(unset)" ;;
    "config set") exit 0 ;;
    "projects describe") exit 1 ;;
    "projects create") exit 0 ;;
    "billing projects")
        if [[ "$3" == "describe" ]]; then echo "False"; else exit 0; fi
        ;;
    "billing accounts") echo "billingAccounts/012345-ABCDEF-6789AB" ;;
    "services enable") exit 0 ;;
    "compute regions")
        echo "{\"quotas\": [{\"metric\": \"NVIDIA_T4_GPUS\", \"limit\": ${STUB_GPU_QUOTA}.0}]}"
        ;;
    "compute instances") exit 0 ;;
    *) echo "unstubbed gcloud call: $*" >&2; exit 1 ;;
esac
STUBEOF
    } > "$STUB_BIN/gcloud"
    chmod +x "$STUB_BIN/gcloud"
}

run_case() {
    local description="$1" auth_state="$2" quota="$3" extra_args="$4" expected_exit="$5" expected_grep="$6"
    write_stub_gcloud "$auth_state" "$quota"
    set +e
    # Two lines of stdin: "y" answers the opening confirmation prompt, the
    # empty second line accepts the default value at the "New project ID"
    # prompt (Step 2 runs -- and so needs this -- before the quota check
    # in Step 4, so every case that gets past Step 1 needs both lines).
    output="$(printf 'y\n\n' | PATH="$STUB_BIN:$PATH" bash "$SCRIPT_DIR/../setup-gpu.sh" $extra_args 2>&1)"
    actual_exit=$?
    set -e
    if [[ "$actual_exit" != "$expected_exit" ]]; then
        echo "FAIL ($description): expected exit $expected_exit, got $actual_exit" >&2
        echo "$output" >&2
        exit 1
    fi
    if ! grep -qF "$expected_grep" <<< "$output"; then
        echo "FAIL ($description): expected output to contain: $expected_grep" >&2
        echo "$output" >&2
        exit 1
    fi
    echo "PASS: $description"
}

run_case "no active account exits 1" "unauthenticated" 0 "--dry-run" 1 "No active gcloud account found"
run_case "zero quota exits 1 with guidance" "authenticated" 0 "--dry-run" 1 "upgrade to a paid Cloud Billing account"
run_case "happy path reaches dry-run VM creation" "authenticated" 8 "--dry-run" 0 "Would run: gcloud compute instances create coms6998-gpu"

echo "All setup-gpu.sh tests passed."
