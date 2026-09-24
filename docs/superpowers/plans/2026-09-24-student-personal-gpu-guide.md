# Student Personal-GPU Guide Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give students a self-service path to real GPU access on their own personal GCP account's $300 free-trial credit, to bridge the gap while the course's own GPU capacity (a separate request to CS department IT) is pending.

**Architecture:** A short guide (`gcp-personal-gpu.md`) covers only what a script cannot do for the student — signing up for the $300 credit, installing `gcloud`, and authenticating. Everything after that is one script, `scripts/setup-gpu.sh`, which does the rest end-to-end (project creation, billing link, API enablement, GPU-quota check, VM creation) and prints its own explanation/confirmation banner before touching anything, mirroring the pattern `pygrader/scripts/onboard-ta.sh` already uses for TA onboarding. Two small companion scripts (`stop-gpu-vm.sh`, `delete-gpu-vm.sh`) handle teardown. This is entirely independent of the `cloud-mgt` student-account work — different repo, no shared code, no live infrastructure risk (everything here runs against each student's own personal GCP account).

**Tech Stack:** Markdown (this repo's existing format, linted by `.markdownlint.yaml` via `.github/workflows/lint-markdown.yml`; links checked by `.github/workflows/check-links.yml`), bash (`gcloud` CLI automation), `python3` (already virtually universal, used here only for a one-line JSON parse — no new dependency to install).

**Spec:** `cloud-mgt/docs/superpowers/specs/2026-09-24-student-account-provisioning-design.md` (the "Addendum: student self-service GPU guide" section)

## Global Constraints

- Everything here runs on each student's *own personal* GCP account and billing — no coordination with CS IT or the professor's project needed, and no live-infrastructure risk.
- The guide and the script's own opening banner must both call out, prominently, that an idle running GPU VM burns through the $300 credit fast, and that a *stopped* (not deleted) GPU instance still bills for its attached disk.
- Do not claim the script can automate the free-trial → paid Cloud Billing upgrade — that's a manual, consent-requiring click in the Console. The script detects the resulting zero-GPU-quota symptom and tells the student exactly what to do, then exits non-zero so they can re-run once fixed.
- `setup-gpu.sh` prints a `step`/`ok`/`warn`-style explanation banner and asks for confirmation *before* doing anything, the same pattern `pygrader/scripts/onboard-ta.sh` uses for TA onboarding — this is a deliberate consistency choice, not incidental.
- `MD013` (line length) is disabled in this repo's `.markdownlint.yaml` — no need to hand-wrap lines.
- All bash scripts here must run under **bash 3.2** (macOS's stock `/bin/bash`, unchanged since Apple stopped shipping GPLv3 code) — no bash-4+-only features (`${var,,}`/`${var^^}` case conversion, associative arrays, `mapfile`). Use `case "$var" in [Yy]*) ... ;; esac`-style pattern matching for case-insensitive comparisons instead. This was found and fixed during Task 2's implementation, when a subagent caught the original draft's `${confirm,,}` crashing under macOS's default bash with "bad substitution" — `bash -n` does not catch this, since it's a runtime failure, not a parse error.

---

### Task 1: Write the student guide

**Files:**
- Create: `guides/gcp-personal-gpu.md`

- [ ] **Step 1: Write the guide**

```markdown
# Using Your Own GCP GPU Credit (Temporary, While Course GPU Access Is Pending)

The course server (`mv.cs.columbia.edu`) does not have a GPU yet, and
getting one added is in progress (a request to CS department IT). Until
that lands, you can use your **own personal Google Cloud account's $300
free-trial credit** to run real GPU workloads for coursework like HW1's
transformer-inference profiling.

This is entirely on your own personal account, not the course's — nothing
here needs course staff involvement.

## What you need to do by hand

Just these three things — everything else is one script.

### 1. Create a Google Cloud account and redeem the free trial

Go to [cloud.google.com/free](https://cloud.google.com/free) and sign up
with any Google account. New accounts get $300 of credit, usable for 90
days.

### 2. Install the `gcloud` CLI

[Install the Google Cloud CLI](https://cloud.google.com/sdk/docs/install)

### 3. Authenticate

```bash
gcloud auth login
```

## Then run one script

```bash
bash scripts/setup-gpu.sh
```

This does everything else: creates a GCP project and links it to your
billing account, enables the Compute Engine API, checks your GPU quota,
and creates a single-GPU VM (Google's Deep Learning VM image — CUDA and
PyTorch already installed, no manual driver setup).

**It explains each step and asks you to confirm before doing anything —
read that explanation, it covers the cost warnings you need.**

If your GPU quota comes back as zero, the script will stop and tell you
exactly what to do (this almost always means upgrading from the free
trial to a paid Cloud Billing account first — **this does not charge you
anything**, it just removes the free-trial GPU-quota block and preserves
your $300 credit — then requesting GPU quota, which can take 1-2 business
days). Re-run the script once that's done.

## Turn it off the moment you're done — this is the part that matters

**A running GPU VM bills by the hour whether or not you're using it.**
The single biggest way people blow through their $300 credit is leaving
a GPU instance running overnight or over a weekend by accident.

- If you'll use it again soon: `bash scripts/stop-gpu-vm.sh` — this stops
  billing for compute, but the attached disk keeps billing a small
  amount for as long as the VM exists.
- If you're fully done with it: `bash scripts/delete-gpu-vm.sh` — this
  removes the disk too, so nothing keeps billing.

When in doubt, delete it — recreating it later takes under two minutes.

## At the end of the semester

Delete any GPU VMs you created (`scripts/delete-gpu-vm.sh`), and consider
deleting the whole GCP project if you don't plan to keep using it, so
nothing keeps quietly billing after the course ends.
```

- [ ] **Step 2: Verify markdown lint passes**

Run: `cd guides && docker run --rm -v "$PWD:/workdir" avtodev/markdown-lint:v1 --config .markdownlint.yaml gcp-personal-gpu.md`

If Docker isn't available locally, install `markdownlint-cli` instead and run `markdownlint -c .markdownlint.yaml gcp-personal-gpu.md` — either matches what `.github/workflows/lint-markdown.yml` runs in CI.

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd guides
git add gcp-personal-gpu.md
git commit -m "$(cat <<'EOF'
Add student guide for using personal GCP GPU credit

Bridges the gap while the course server's own GPU request (to CS
department IT) is pending. Covers only what setup-gpu.sh can't do for
the student (signup, gcloud install, auth) -- the script handles the
rest and explains itself before running.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `scripts/setup-gpu.sh` — end-to-end automated setup

**Files:**
- Create: `guides/scripts/setup-gpu.sh`
- Test: `guides/scripts/tests/test_setup_gpu.sh` (bash test harness using a stub `gcloud`)

**Interfaces:**
- Produces: a CLI script, flags `-z/--zone`, `-g/--gpu-type`, `--dry-run` (dry-run only skips the final VM-creation command — everything before it, including project creation and billing link, is real, since those steps are idempotent and there's no meaningful way to "preview" them).

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# scripts/setup-gpu.sh: end-to-end setup of a personal GPU VM on your own
# GCP account, for coursework that needs real GPU access before the
# course's own GPU capacity is ready (see ../gcp-personal-gpu.md).
#
# Prerequisites (see ../gcp-personal-gpu.md for the how-to on each):
#   1. A Google Cloud account with the $300 free-trial credit redeemed.
#   2. The gcloud CLI installed.
#   3. `gcloud auth login` (or `gcloud init`) already run.
#
# From there, this script does everything else: creates/selects a GCP
# project, links it to your billing account, enables the Compute Engine
# API, checks your GPU quota (and tells you exactly what to do if it's
# zero), and creates a single-GPU Deep Learning VM.
#
# Usage: bash setup-gpu.sh [-z ZONE] [-g GPU_TYPE] [--dry-run]
#
# IMPORTANT: the VM this creates bills your personal GCP account by the
# hour while running. Use stop-gpu-vm.sh or delete-gpu-vm.sh the moment
# you're done -- an idle GPU VM burns through your $300 credit fast.

set -euo pipefail

ZONE="us-central1-a"
GPU_TYPE="nvidia-tesla-t4"
MACHINE_TYPE="n1-standard-4"
VM_NAME="coms6998-gpu"
DRY_RUN=false

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
ok()   { printf '    \033[1;32m✓\033[0m %s\n' "$1"; }
warn() { printf '    \033[1;33m!\033[0m %s\n' "$1"; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -z|--zone) ZONE="$2"; shift 2 ;;
        -g|--gpu-type) GPU_TYPE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help)
            echo "Usage: $0 [-z ZONE] [-g GPU_TYPE] [--dry-run]"
            exit 0
            ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

REGION="${ZONE%-*}"

# ---------------------------------------------------------------------------
step "GPU setup for coms6998 -- what this script does"
# ---------------------------------------------------------------------------
cat <<EOF
This sets up a single-GPU (${GPU_TYPE}) VM on YOUR OWN personal GCP
account, using your \$300 free-trial credit -- a bridge until the course
server's own GPU access (a separate request to CS department IT) is
ready.

It will, in order:
  1. Create (or reuse) a GCP project and link it to your billing account.
  2. Enable the Compute Engine API.
  3. Check your GPU quota in ${REGION} -- if it's zero, this script will
     tell you exactly what to do and stop; re-run it once quota is
     approved (can take 1-2 business days).
  4. Create a ${MACHINE_TYPE} VM with 1x ${GPU_TYPE}, using Google's Deep
     Learning VM image (CUDA/PyTorch already installed).

IMPORTANT -- read this part twice: once the VM is created, it bills your
personal GCP account BY THE HOUR while it's running, whether or not
you're actively using it. Run stop-gpu-vm.sh or delete-gpu-vm.sh the
moment you're done for a session. When in doubt, delete it -- recreating
it later takes under two minutes.

Prerequisites this script assumes you've already done (see
../gcp-personal-gpu.md if not):
  - Signed up for GCP and redeemed the \$300 free-trial credit.
  - Installed the gcloud CLI.
  - Run \`gcloud auth login\` (or \`gcloud init\`).
EOF
read -r -p "Ready to proceed? [y/N] " confirm
case "$confirm" in
    [Yy]) ;;
    *)
        echo "Stopping. Come back once you're ready."
        exit 0
        ;;
esac

# ---------------------------------------------------------------------------
step "1. Checking gcloud authentication"
# ---------------------------------------------------------------------------
ACTIVE_ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)')"
if [[ -z "$ACTIVE_ACCOUNT" ]]; then
    warn "No active gcloud account found."
    warn "Run: gcloud auth login"
    exit 1
fi
ok "authenticated as $ACTIVE_ACCOUNT"

# ---------------------------------------------------------------------------
step "2. GCP project"
# ---------------------------------------------------------------------------
CURRENT_PROJECT="$(gcloud config get-value project 2>/dev/null || true)"
if [[ "$CURRENT_PROJECT" == "(unset)" ]]; then
    CURRENT_PROJECT=""
fi
if [[ -n "$CURRENT_PROJECT" ]]; then
    read -r -p "Use current project '$CURRENT_PROJECT'? [Y/n] " use_current
    case "$use_current" in
        [Nn]*) CURRENT_PROJECT="" ;;
    esac
fi

if [[ -z "$CURRENT_PROJECT" ]]; then
    DEFAULT_PROJECT_ID="coms6998-gpu-$((RANDOM % 9000 + 1000))"
    read -r -p "New project ID [${DEFAULT_PROJECT_ID}]: " PROJECT_ID
    PROJECT_ID="${PROJECT_ID:-$DEFAULT_PROJECT_ID}"

    if gcloud projects describe "$PROJECT_ID" &>/dev/null; then
        ok "project $PROJECT_ID already exists"
    else
        gcloud projects create "$PROJECT_ID" --name="coms6998 GPU"
        ok "created project $PROJECT_ID"
    fi
    gcloud config set project "$PROJECT_ID"
    CURRENT_PROJECT="$PROJECT_ID"
fi

BILLING_ENABLED="$(gcloud billing projects describe "$CURRENT_PROJECT" --format='value(billingEnabled)' 2>/dev/null || echo "False")"
if [[ "$BILLING_ENABLED" != "True" ]]; then
    BILLING_ACCOUNT="$(gcloud billing accounts list --format='value(name)' --limit=1)"
    if [[ -z "$BILLING_ACCOUNT" ]]; then
        warn "No billing account found on this Google account."
        warn "Redeem your \$300 credit at https://cloud.google.com/free first, then re-run this script."
        exit 1
    fi
    gcloud billing projects link "$CURRENT_PROJECT" --billing-account="${BILLING_ACCOUNT#billingAccounts/}"
    ok "linked $CURRENT_PROJECT to billing account ${BILLING_ACCOUNT#billingAccounts/}"
else
    ok "billing already enabled on $CURRENT_PROJECT"
fi

# ---------------------------------------------------------------------------
step "3. Enabling the Compute Engine API"
# ---------------------------------------------------------------------------
gcloud services enable compute.googleapis.com --project="$CURRENT_PROJECT"
ok "Compute Engine API enabled"

# ---------------------------------------------------------------------------
step "4. Checking GPU quota in $REGION"
# ---------------------------------------------------------------------------
QUOTA_METRIC="NVIDIA_T4_GPUS"
GPU_QUOTA="$(gcloud compute regions describe "$REGION" --project="$CURRENT_PROJECT" --format=json \
    | python3 -c "import json,sys; q={x['metric']: x['limit'] for x in json.load(sys.stdin)['quotas']}; print(int(q.get('$QUOTA_METRIC', 0)))")"

if [[ "$GPU_QUOTA" -lt 1 ]]; then
    warn "GPU quota for $QUOTA_METRIC in $REGION is 0."
    warn "Two things are almost certainly needed here:"
    warn "  1. If you're still on the free trial, GCP will NOT grant GPU"
    warn "     quota until you upgrade to a paid Cloud Billing account"
    warn "     (this preserves your \$300 credit, it does not charge you):"
    warn "     https://cloud.google.com/billing/docs/how-to/upgrade"
    warn "  2. Then request GPU quota (can take 1-2 business days):"
    warn "     https://cloud.google.com/compute/resource-usage#gpu_quota"
    warn "Re-run this script once quota shows as approved."
    exit 1
fi
ok "GPU quota OK ($GPU_QUOTA available for $QUOTA_METRIC in $REGION)"

# ---------------------------------------------------------------------------
step "5. Creating the GPU VM"
# ---------------------------------------------------------------------------
CMD=(gcloud compute instances create "$VM_NAME"
    --project="$CURRENT_PROJECT"
    --zone="$ZONE"
    --machine-type="$MACHINE_TYPE"
    --accelerator="type=$GPU_TYPE,count=1"
    --maintenance-policy=TERMINATE
    --image-family=common-cu124
    --image-project=deeplearning-platform-release
    --boot-disk-size=100GB
)

if $DRY_RUN; then
    echo "Would run: ${CMD[*]}"
    exit 0
fi

"${CMD[@]}"

# ---------------------------------------------------------------------------
step "Done"
# ---------------------------------------------------------------------------
cat <<EOF
SSH in with:
  gcloud compute ssh $VM_NAME --zone=$ZONE --project=$CURRENT_PROJECT

REMEMBER: stop-gpu-vm.sh or delete-gpu-vm.sh the moment you're done for
a session -- this VM bills by the hour while running.
EOF
```

- [ ] **Step 2: Make executable and syntax-check**

Run: `cd guides && chmod +x scripts/setup-gpu.sh && bash -n scripts/setup-gpu.sh`
Expected: no output (valid syntax)

- [ ] **Step 3: Write a stub-`gcloud` test harness**

Real GCP calls can't run in CI or in this review, so the test harness puts a fake `gcloud` first on `PATH` that returns canned responses for each subcommand `setup-gpu.sh` calls, and lets the *real* `python3` parse the canned JSON (no need to fake that too).

```bash
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
```

- [ ] **Step 4: Run the test harness**

Run: `cd guides && chmod +x scripts/tests/test_setup_gpu.sh && bash scripts/tests/test_setup_gpu.sh`
Expected:
```
PASS: no active account exits 1
PASS: zero quota exits 1 with guidance
PASS: happy path reaches dry-run VM creation
All setup-gpu.sh tests passed.
```

- [ ] **Step 5: Commit**

```bash
cd guides
git add scripts/setup-gpu.sh scripts/tests/test_setup_gpu.sh
git commit -m "$(cat <<'EOF'
Add setup-gpu.sh: end-to-end automated personal-GPU setup

Replaces the earlier plan's create-gpu-vm.sh with a single script that
explains itself and asks for confirmation up front (matching
onboard-ta.sh's pattern), then automates project creation, billing
link, API enablement, and GPU-quota checking before creating the VM --
stopping with exact manual instructions if quota is zero, since the
free-trial-to-paid-billing upgrade is a manual Console action this
script deliberately doesn't claim to automate.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: `scripts/stop-gpu-vm.sh` and `scripts/delete-gpu-vm.sh`

**Files:**
- Create: `guides/scripts/stop-gpu-vm.sh`
- Create: `guides/scripts/delete-gpu-vm.sh`

**Interfaces:**
- Produces: two CLI scripts, flags `-n/--name`, `-z/--zone`, `--dry-run`, defaults `coms6998-gpu` / `us-central1-a` (matching `setup-gpu.sh`'s `VM_NAME`/`ZONE` defaults).

- [ ] **Step 1: Write `stop-gpu-vm.sh`**

```bash
#!/usr/bin/env bash
# scripts/stop-gpu-vm.sh: stop your personal GPU VM (see setup-gpu.sh).
# Stopping halts compute billing, but the attached disk keeps billing a
# small amount for as long as the VM exists -- use delete-gpu-vm.sh
# instead if you're fully done with it.
#
# Usage: bash stop-gpu-vm.sh [-n NAME] [-z ZONE] [--dry-run]

set -euo pipefail

NAME="coms6998-gpu"
ZONE="us-central1-a"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name) NAME="$2"; shift 2 ;;
        -z|--zone) ZONE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help)
            echo "Usage: $0 [-n NAME] [-z ZONE] [--dry-run]"
            exit 0
            ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

CMD=(gcloud compute instances stop "$NAME" --zone="$ZONE")

if $DRY_RUN; then
    echo "Would run: ${CMD[*]}"
    exit 0
fi

"${CMD[@]}"
echo "Stopped. Note: the attached disk still bills a small amount while" \
     "it exists -- use delete-gpu-vm.sh if you're fully done."
```

- [ ] **Step 2: Write `delete-gpu-vm.sh`**

```bash
#!/usr/bin/env bash
# scripts/delete-gpu-vm.sh: permanently delete your personal GPU VM,
# including its disk, so nothing keeps billing (see setup-gpu.sh).
#
# Usage: bash delete-gpu-vm.sh [-n NAME] [-z ZONE] [--dry-run]

set -euo pipefail

NAME="coms6998-gpu"
ZONE="us-central1-a"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name) NAME="$2"; shift 2 ;;
        -z|--zone) ZONE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help)
            echo "Usage: $0 [-n NAME] [-z ZONE] [--dry-run]"
            exit 0
            ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

CMD=(gcloud compute instances delete "$NAME" --zone="$ZONE" --quiet)

if $DRY_RUN; then
    echo "Would run: ${CMD[*]}"
    exit 0
fi

"${CMD[@]}"
```

- [ ] **Step 3: Make executable and syntax-check both**

Run: `cd guides && chmod +x scripts/stop-gpu-vm.sh scripts/delete-gpu-vm.sh && bash -n scripts/stop-gpu-vm.sh && bash -n scripts/delete-gpu-vm.sh`
Expected: no output (valid syntax)

- [ ] **Step 4: Verify dry-run output for both**

Run: `cd guides && bash scripts/stop-gpu-vm.sh --dry-run`
Expected output contains: `Would run: gcloud compute instances stop coms6998-gpu --zone=us-central1-a`

Run: `cd guides && bash scripts/delete-gpu-vm.sh --dry-run`
Expected output contains: `Would run: gcloud compute instances delete coms6998-gpu --zone=us-central1-a --quiet`

- [ ] **Step 5: Commit**

```bash
cd guides
git add scripts/stop-gpu-vm.sh scripts/delete-gpu-vm.sh
git commit -m "Add stop/delete-gpu-vm.sh companion scripts"
```

---

### Task 4: Link the new guide from `README.md`

**Files:**
- Modify: `guides/README.md`

- [ ] **Step 1: Add a link**

Add a new line under the "Programming Enviroment" section (matching the existing list's style):

```markdown
- [Using Your Own GCP GPU Credit](gcp-personal-gpu.md): Run real GPU workloads on your personal GCP account while the course server's own GPU access is pending.
```

- [ ] **Step 2: Verify links resolve**

Run: `cd guides && docker run --rm -v "$PWD:/workdir" ghcr.io/tcort/markdown-link-check:stable README.md gcp-personal-gpu.md` (or equivalent local `markdown-link-check` install) — matches what `.github/workflows/check-links.yml` runs in CI.
Expected: all links, including the new `cloud.google.com` links, report OK.

- [ ] **Step 3: Commit**

```bash
cd guides
git add README.md
git commit -m "Link the personal-GPU-credit guide from README"
```

## Self-review notes (from the plan author, before handoff)

- **Spec coverage:** account/credit setup, the free-trial-GPU-quota gotcha, Deep Learning VM image, and the repeated stop/delete-when-idle warning are all in Task 1's guide and Task 2's script banner; the automation itself (project/billing/API/quota/VM) is Task 2; teardown is Task 3.
- **Design change from the first draft of this plan:** the original design split "explain" (guide) from "do" (a plain `create-gpu-vm.sh` with no automation beyond the `gcloud compute instances create` call itself). Per explicit user direction, this revision consolidates project creation, billing linking, API enablement, and quota checking into one script (`setup-gpu.sh`) that explains itself and asks for confirmation before running — mirroring `onboard-ta.sh`'s existing pattern in this codebase — rather than requiring the guide to walk the student through each GCP Console step by hand.
- **Independent of Track A:** this plan touches only the `guides` repo and each student's own personal GCP account — no dependency on the `cloud-mgt` plan, no live shared-server risk, safe to execute in either order relative to it.
