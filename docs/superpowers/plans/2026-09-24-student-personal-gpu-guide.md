# Student Personal-GPU Guide Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give students a self-service path to real GPU access on their own personal GCP account's $300 free-trial credit, to bridge the gap while the course's own GPU capacity (a separate request to CS department IT) is pending.

**Architecture:** A single new student-facing guide (`gcp-personal-gpu.md`) plus two small, dependency-free bash scripts under `scripts/` that wrap `gcloud compute instances create/stop/delete` with sensible defaults (T4 GPU, Deep Learning VM image with CUDA/PyTorch preinstalled). This is entirely independent of the `cloud-mgt` student-account work — different repo, no shared code, no live infrastructure risk (everything here runs against each student's own personal GCP account).

**Tech Stack:** Markdown (this repo's existing format, linted by `.markdownlint.yaml` via `.github/workflows/lint-markdown.yml`; links checked by `.github/workflows/check-links.yml`), bash (`gcloud` CLI wrapper scripts).

**Spec:** `cloud-mgt/docs/superpowers/specs/2026-09-24-student-account-provisioning-design.md` (the "Addendum: student self-service GPU guide" section)

## Global Constraints

- Everything here runs on each student's *own personal* GCP account and billing — no coordination with CS IT or the professor's project needed, and no live-infrastructure risk.
- The guide must call out, prominently and more than once, that an idle running GPU VM burns through the $300 credit fast, and that a *stopped* (not deleted) GPU instance still bills for its attached disk.
- The guide must call out the free-trial GPU-quota gotcha this project already hit once itself: **GCP does not grant GPU quota to free-trial billing accounts** — upgrading to a paid Cloud Billing account is required first, and doing so preserves the unused credit rather than triggering it.
- `MD013` (line length) is disabled in this repo's `.markdownlint.yaml` — no need to hand-wrap lines.

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

## 1. Create a Google Cloud account and redeem the free trial

Go to [cloud.google.com/free](https://cloud.google.com/free) and sign up
with any Google account. New accounts get $300 of credit, usable for 90
days.

## 2. Upgrade to a paid Cloud Billing account (required for any GPU)

**This is the step people skip and then get stuck on** — we hit this
exact issue ourselves setting up the course server. Google Cloud does
**not** grant GPU quota to free-trial billing accounts, full stop. You
must upgrade to a paid Cloud Billing account before requesting GPU quota.

Upgrading does **not** immediately charge you anything — it preserves
your unused $300 credit and removes the 90-day expiry, it just removes
the free-trial restrictions (including the GPU-quota block). You will
need a credit card on file, but you will not be charged unless you
exceed your $300 credit.

Instructions: [Upgrade your Free Trial account to a paid Cloud Billing account](https://cloud.google.com/billing/docs/how-to/upgrade)

## 3. Set a budget alert (do this before spinning anything up)

So you get an email before you burn through your credit, not after:

[Create, edit, or delete budgets and budget alerts](https://cloud.google.com/billing/docs/how-to/budgets)

A budget of $50-100 with alerts at 50%/90%/100% is plenty for a single
homework assignment's worth of GPU time.

## 4. Install the `gcloud` CLI

[Install the Google Cloud CLI](https://cloud.google.com/sdk/docs/install)

Then authenticate and set your project:

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

## 5. Request GPU quota

Even a paid account starts at **zero** GPU quota — you have to request
it, and approval can take 1-2 business days, so do this as early as
possible, not the night before an assignment is due:
[GPU quotas](https://cloud.google.com/compute/resource-usage#gpu_quota)

Request an NVIDIA T4 in `us-central1` (or whichever region you're using)
— a single T4 is enough for the throughput/latency measurements HW1
asks for; you do not need anything bigger for this course.

## 6. Spin up a GPU VM

This repo includes two scripts to make this easier:
[`scripts/create-gpu-vm.sh`](scripts/create-gpu-vm.sh) and
[`scripts/stop-gpu-vm.sh`](scripts/stop-gpu-vm.sh) /
[`scripts/delete-gpu-vm.sh`](scripts/delete-gpu-vm.sh).

```bash
bash scripts/create-gpu-vm.sh
```

By default this creates a single-T4 VM using Google's
[Deep Learning VM image](https://cloud.google.com/deep-learning-vm/docs)
(CUDA and PyTorch already installed — no manual driver setup). See
`--help` in the script for overriding the name/zone/GPU type.

SSH into it once it's up:

```bash
gcloud compute ssh coms6998-gpu --zone=us-central1-a
```

## 7. Turn it off the moment you're done — this is the part that matters

**A running GPU VM bills by the hour whether or not you're using it.**
The single biggest way people blow through their $300 credit is leaving
a GPU instance running overnight or over a weekend by accident.

- If you'll use it again soon: `bash scripts/stop-gpu-vm.sh` — this stops
  billing for compute, but the attached disk keeps billing a small
  amount for as long as the VM exists.
- If you're fully done with it: `bash scripts/delete-gpu-vm.sh` — this
  removes the disk too, so nothing keeps billing.

When in doubt, delete it — recreating it later takes under two minutes.

## 8. At the end of the semester

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
department IT) is pending -- covers the free-trial-accounts-can't-get-
GPU-quota gotcha this project already hit once itself, budget alerts,
and the create/stop/delete script usage.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `scripts/create-gpu-vm.sh`

**Files:**
- Create: `guides/scripts/create-gpu-vm.sh`

**Interfaces:**
- Produces: a CLI script, flags `-n/--name`, `-z/--zone`, `-g/--gpu-type`, `--dry-run`, defaults `coms6998-gpu` / `us-central1-a` / `nvidia-tesla-t4`.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# scripts/create-gpu-vm.sh: spin up a personal single-GPU VM on your own
# GCP account, for coursework that needs real GPU access before the
# course's own GPU capacity is ready (see ../gcp-personal-gpu.md).
#
# Usage: bash create-gpu-vm.sh [-n NAME] [-z ZONE] [-g GPU_TYPE] [--dry-run]
#
# IMPORTANT: this VM bills your personal GCP account by the hour while
# running. Stop it (stop-gpu-vm.sh) or delete it (delete-gpu-vm.sh) the
# moment you're done -- an idle GPU VM burns through your $300 credit fast.

set -euo pipefail

NAME="coms6998-gpu"
ZONE="us-central1-a"
GPU_TYPE="nvidia-tesla-t4"
MACHINE_TYPE="n1-standard-4"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name) NAME="$2"; shift 2 ;;
        -z|--zone) ZONE="$2"; shift 2 ;;
        -g|--gpu-type) GPU_TYPE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help)
            echo "Usage: $0 [-n NAME] [-z ZONE] [-g GPU_TYPE] [--dry-run]"
            exit 0
            ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

CMD=(gcloud compute instances create "$NAME"
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

echo "Creating $NAME in $ZONE with 1x $GPU_TYPE..."
echo "REMEMBER: run stop-gpu-vm.sh (or delete-gpu-vm.sh) as soon as you're" \
     "done -- this bills your personal GCP account while running."
"${CMD[@]}"
```

- [ ] **Step 2: Make executable and syntax-check**

Run: `cd guides && chmod +x scripts/create-gpu-vm.sh && bash -n scripts/create-gpu-vm.sh`
Expected: no output (valid syntax)

- [ ] **Step 3: Verify dry-run output**

Run: `cd guides && bash scripts/create-gpu-vm.sh --dry-run`
Expected output contains: `Would run: gcloud compute instances create coms6998-gpu --zone=us-central1-a --machine-type=n1-standard-4 --accelerator=type=nvidia-tesla-t4,count=1 ...`

Run: `cd guides && bash scripts/create-gpu-vm.sh -n test-vm -z us-east4-a -g nvidia-l4 --dry-run`
Expected output contains: `test-vm`, `us-east4-a`, `nvidia-l4` reflecting the overrides.

- [ ] **Step 4: Commit**

```bash
cd guides
git add scripts/create-gpu-vm.sh
git commit -m "Add create-gpu-vm.sh for students' personal GCP GPU credit"
```

---

### Task 3: `scripts/stop-gpu-vm.sh` and `scripts/delete-gpu-vm.sh`

**Files:**
- Create: `guides/scripts/stop-gpu-vm.sh`
- Create: `guides/scripts/delete-gpu-vm.sh`

**Interfaces:**
- Produces: two CLI scripts, flags `-n/--name`, `-z/--zone`, `--dry-run`, same defaults as Task 2.

- [ ] **Step 1: Write `stop-gpu-vm.sh`**

```bash
#!/usr/bin/env bash
# scripts/stop-gpu-vm.sh: stop your personal GPU VM (see create-gpu-vm.sh).
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
# including its disk, so nothing keeps billing (see create-gpu-vm.sh).
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
Expected: all links, including the three new `cloud.google.com` links and the two new `scripts/*.sh` relative links, report OK.

- [ ] **Step 3: Commit**

```bash
cd guides
git add README.md
git commit -m "Link the personal-GPU-credit guide from README"
```

## Self-review notes (from the plan author, before handoff)

- **Spec coverage:** account/credit setup, the free-trial-GPU-quota gotcha, budget alerts, Deep Learning VM image, and the repeated stop/delete-when-idle warning are all in Task 1's guide content; the create/stop/delete script trio is Tasks 2-3.
- **Independent of Track A:** this plan touches only the `guides` repo and each student's own personal GCP account — no dependency on the `cloud-mgt` plan, no live shared-server risk, safe to execute in either order relative to it.
