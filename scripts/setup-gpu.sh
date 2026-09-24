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
if [[ "${confirm,,}" != "y" ]]; then
    echo "Stopping. Come back once you're ready."
    exit 0
fi

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
    if [[ "${use_current,,}" == "n" ]]; then
        CURRENT_PROJECT=""
    fi
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
