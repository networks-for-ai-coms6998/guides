# Using Your Own GCP GPU Credit (Optional)

The course server (`mv.cs.columbia.edu`) has a GPU that you can use through
Slurm; see [Using the GPU with Slurm](slurm-gpu.md). That is the default way
to run GPU work for this course, and you do not need anything in this guide to
complete the assignments.

This guide is an **optional alternative** for when you want a GPU of your own:
for example to experiment without waiting in the Slurm queue, to try a larger
GPU, or to keep a GPU environment you fully control. You can use your **own
personal Google Cloud account's $300 free-trial credit** to run real GPU
workloads like HW1's inference profiling.

This is entirely on your own personal account, not the course's: it is not
required, the course does not pay for it, and the course staff cannot manage
or debug your cloud account. Assignments must still be submitted through your
GitHub repository as described in [Using git on the server](git-on-the-server.md) and [Submission](submission.md).

## What you need to do by hand

Just these four things — everything else is one script.

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

### 4. Get this repo

```bash
git clone https://github.com/networks-for-ai-coms6998/guides.git
cd guides
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
trial to a paid Cloud Billing account first — upgrading does not charge you
by itself and should keep your remaining credit, but any usage beyond the
credit or trial is billed — then requesting GPU quota, which can
take a few business days). Re-run the script once that's done.

**Important:** Once the VM is created, it bills by the hour whether or not you're using it — make sure to stop or delete it when you're done (see below).

## Turn it off the moment you're done — this is the part that matters

**A running GPU VM bills by the hour whether or not you're using it.**
The single biggest way people blow through their $300 credit is leaving
a GPU instance running overnight or over a weekend by accident.

-   If you'll use it again soon: `bash scripts/stop-gpu-vm.sh` — this
    stops billing for compute, but the attached disk keeps billing a
    small amount for as long as the VM exists.
-   If you're fully done with it: `bash scripts/delete-gpu-vm.sh` — this
    removes the disk too, so nothing keeps billing.

When in doubt, delete it — recreating it later usually takes only a few minutes.

## At the end of the semester

Delete any GPU VMs you created (`scripts/delete-gpu-vm.sh`), and consider
deleting the whole GCP project if you don't plan to keep using it, so
nothing keeps quietly billing after the course ends.
