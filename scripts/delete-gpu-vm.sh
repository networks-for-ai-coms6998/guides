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
