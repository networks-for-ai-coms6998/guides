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
