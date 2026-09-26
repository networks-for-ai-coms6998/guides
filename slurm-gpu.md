# Running GPU Jobs with Slurm

The course server gives you a strong GPU for testing your homework, but
there is exactly **one** NVIDIA L4 GPU for the whole class. To share it
fairly we use a job scheduler called **Slurm**. This guide explains what
Slurm is, how to run your code on the GPU, and what to do when something
goes wrong.

Using the server is optional. If you have not logged in yet, start with
[connect-to-server.md](connect-to-server.md). To get your homework repo
onto the server, see [git-on-the-server.md](git-on-the-server.md).

## What Slurm is, and why we use it

Two machines are involved:

-   The **login node** is the machine you SSH into (`mv.cs.columbia.edu`).
    It is a small CPU-only machine that is up 24/7. Use it for editing,
    `git`, small tests, and submitting jobs. Each user is limited to
    1 CPU, 512 MB of RAM, and 100 processes there.
-   The **GPU machine** is a separate computer with the L4 GPU. **You never
    log in to it.** Instead you ask Slurm to run a command there for you.

If all 40 students wanted the GPU at once and just logged in, they would
step on each other. With Slurm you submit a _job_ ("run this command on
the GPU for at most N minutes"). Slurm puts jobs in a queue, runs them
one at a time, and frees the GPU when each one finishes.

Consequence: **if many people submit at the same time, you wait.** Start
well before the deadline (more than a few hours), not the night before.

## One-time setup: the shared environment

Do **not** create your own virtual environment and do **not** run
`pip install torch`. PyTorch is several GB and will blow through your disk
quota (1 GB soft, 2 GB hard). A ready-made environment with `torch`,
`transformers`, and the TinyLlama weights is shared by everyone. Load it
with:

```bash
source /home/coms6998-shared/env.sh
```

You must do this in **every new shell** and **inside every batch job
script** (see below). Loading it does not use any of your quota.

Note that the HW1 README suggests creating a venv and running
`pip install -r code/requirements.txt`. On the course server, skip that and
use the shared environment instead. (If you work on your own machine, the
README instructions still apply.)

## Interactive jobs: `srun`

An interactive job gives you a shell on the GPU machine. It is good for
debugging: you type a command, see the output right away, and change your
code.

From the login node, in your repo directory:

```bash
srun -p gpu --gres=gpu:1 --time=00:10:00 --pty bash
```

What the flags mean:

- `-p gpu` uses the partition (queue) that contains the GPU machine.
- `--gres=gpu:1` asks for one GPU.
- `--time=00:10:00` is the maximum run time (10 minutes here).
- `--pty bash` gives you an interactive shell.

If the GPU is free, you get a prompt on the GPU machine right away. If it
is busy, the command waits until your turn. Once you have the prompt:

```bash
source /home/coms6998-shared/env.sh
python code/less_minimal_full_server.py --prompt "Say hi" --max-tokens 64
exit
```

**Always `exit` when you are done.** An interactive shell holds the single
GPU for as long as it is open, even if you are just thinking or have gone
to lunch. Everyone behind you in the queue waits. (Slurm will end it
after your `--time` runs out, but do not rely on that.)

## Batch jobs: `sbatch`

A batch job is a script that Slurm runs for you. You submit it and can
disconnect; the output goes to a file. This is the best option for
anything longer than a single command, such as sweeps.

Save this as `job.sh` in your repo, edit the last line, and submit it:

```bash
#!/bin/bash
#SBATCH -p gpu
#SBATCH --gres=gpu:1
#SBATCH --time=00:10:00
#SBATCH -o hw1-%j.out
source /home/coms6998-shared/env.sh
python code/less_minimal_full_server.py --prompt "Say hi" --max-tokens 64
```

```bash
sbatch job.sh
```

Slurm prints `Submitted batch job <jobid>`. The lines starting with
`#SBATCH` are options for Slurm (the same ones as for `srun`). `%j` in
the `-o` line is replaced with the job id, so your output lands in
`hw1-<jobid>.out`, in the directory you submitted from.

The `source .../env.sh` line is required. Your batch job starts in a fresh
shell that does not know about the shared environment.

Read the output with:

```bash
cat hw1-<jobid>.out
tail -f hw1-<jobid>.out    # follow it live; Ctrl-C to stop watching
```

`tail -f` only stops _watching_; your job keeps running.

## Watching and cancelling jobs

| Command | What it does |
| --- | --- |
| `squeue` | Show the whole queue (everyone's jobs) |
| `squeue -u $USER` | Show only your jobs |
| `scancel <jobid>` | Cancel a job (queued or running) |
| `sinfo` | Show whether the GPU machine is up (`idle`, `alloc`, `down`, ...) |

In `squeue` output, the `ST` column is the job state: `PD` means pending
(waiting in the queue), `R` means running. When a job finishes it
disappears from `squeue`; look at its `.out` file for the result.

If you started something by mistake, or a job is stuck, run
`scancel <jobid>` right away so you do not hold the GPU.

## Limits

-   **15 minutes maximum per job.** If you do not pass `--time`, the
    default is **5 minutes**. A job that runs past its limit is killed.
-   Asking for more than 15 minutes is rejected at submit time with
    `Requested time limit is invalid`. Lower `--time`.
-   **No GPU jobs are scheduled between 1 and 7 a.m. ET.** Do not plan to
    run or wait for jobs overnight. Do not submit jobs that would still be
    running at 1 a.m.; such a job will not be started.
-   The login node cannot load the model: it has only 512 MB of RAM. Always
    run the model through `srun` or `sbatch`.
-   Your home directory has a 1 GB soft / 2 GB hard disk quota.
-   `/tmp` is local to each machine, so the login node and the GPU machine
    do not share it. Keep your scripts and outputs under your **home
    directory**, which is visible on both.

## Etiquette

-   Ask for only the time you need. A 3-minute test should say
    `--time=00:03:00`.
-   Keep jobs short and iterate: change your code, run a short test, and if
    you need to run again, **submit again**. Short jobs keep the queue
    moving for everyone.
-   Debug on tiny inputs (a small `--max-tokens`) before launching a big
    sweep.
-   Do not keep an interactive shell open while idle. `exit` it.
-   Do not submit dozens of jobs at once "just in case". Check
    `squeue -u $USER` and cancel what you no longer need.

## Worked example: HW1 from clone to a small sweep

This walks through a first run of the HW1 starter code. Replace `<uni>`
with your UNI. See [git-on-the-server.md](git-on-the-server.md) for the
git details.

### 1. Log in and get your repo

```bash
ssh -A <uni>@mv.cs.columbia.edu
git clone git@github.com:networks-for-ai-coms6998-hw/hw1-<uni>.git
cd hw1-<uni>
```

### 2. Do a first test run interactively

```bash
srun -p gpu --gres=gpu:1 --time=00:10:00 --pty bash
source /home/coms6998-shared/env.sh
python code/less_minimal_full_server.py --prompt "Say hi" --max-tokens 64
```

The starter script prints its progress in numbered steps (loading the
model, prefill, decode). Try the `--verbose` flag too, which unwraps the
model layer by layer (this is the path you will modify in the homework):

```bash
python code/less_minimal_full_server.py --prompt "Say hi" --max-tokens 64 --verbose
```

Then leave the GPU:

```bash
exit
```

You are back on the login node. Confirm this with `hostname` if you are
unsure.

### 3. Run from a batch script

Once the single run works, use `sbatch` for anything longer. The starter
script's flags are `--model`, `--device`, `--prompt`, `--max-tokens`, and
`--verbose`. A small sweep over the number of generated tokens looks like
this (save as `sweep.sh`):

```bash
#!/bin/bash
#SBATCH -p gpu
#SBATCH --gres=gpu:1
#SBATCH --time=00:12:00
#SBATCH -o sweep-%j.out
source /home/coms6998-shared/env.sh

for N in 32 64 128 256; do
    echo "=== max-tokens=$N ==="
    python code/less_minimal_full_server.py \
        --prompt "Explain the KV cache in one paragraph." \
        --max-tokens "$N" --verbose
done
```

Once you have added your own options in the homework, add them to the loop
in the same way. For example, with a flag you defined yourself
(`--compression` and `<your-setting-flag>` below are **placeholders**, not
flags in the starter code):

```bash
for MODE in none <your-algorithm-1> <your-algorithm-2>; do
    for N in 64 128 256; do
        echo "=== compression=$MODE max-tokens=$N ==="
        python code/less_minimal_full_server.py \
            --prompt "Explain the KV cache in one paragraph." \
            --max-tokens "$N" --compression "$MODE" --verbose
    done
done
```

Submit and watch:

```bash
sbatch sweep.sh
squeue -u $USER
cat sweep-<jobid>.out
```

Everything in one job must finish within its `--time`, and `--time`
cannot exceed 15 minutes. Each run loads the model again, which costs
some seconds, so keep the sweep small. If it does not fit in 15 minutes,
split it into several jobs (for example one job per algorithm) and
submit them one after another.

### 4. Save your results

Copy the numbers you need into your report, then commit and push from the
login node (not from inside a job):

```bash
git add UNI-hw1-report.md plots/ code/
git commit -m "HW1: first results"
git push
```

Replace `UNI` with your own UNI in the file name.

Do not commit large files (model weights, big logs). They count against
your disk quota and do not belong in the repo.

## Troubleshooting

| Symptom | Likely cause and fix |
| --- | --- |
| Job stays `PD` (pending) with reason `Resources` or `Priority` | Normal: the GPU is busy or others are ahead of you. Check `squeue` to see who is running. Wait, or cancel with `scancel <jobid>` and resubmit when it is quieter. Starting early helps. |
| Job stays `PD` overnight | No GPU jobs are scheduled between 1 and 7 a.m. ET, and a job that would still be running at 1 a.m. will not be started. Do not plan to wait overnight; check `squeue` and `sinfo`, and resubmit a shorter job earlier in the day. |
| `sbatch: error: ... Requested time limit is invalid` | `--time` is above the 15-minute maximum. Use `--time=00:15:00` or less. |
| Job killed with `DUE TO TIME LIMIT` (in the `.out` file) | It hit its `--time`. The default without `--time` is only 5 minutes. Set `--time` explicitly (up to 15 minutes), or run a smaller test. |
| `command not found: python`, or `ModuleNotFoundError: No module named 'torch'` | You did not run `source /home/coms6998-shared/env.sh` in that shell. Add it to the job script, or run it after `srun ... --pty bash`. Do not `pip install torch`. |
| The model will not load on the login node (killed, or out of memory) | The login node has 512 MB of RAM. Run through `srun` or `sbatch`. |
| `CUDA out of memory` | Your run needs more GPU memory than the L4 has (about 23 GB), or an earlier process is still holding it. Reduce `--max-tokens` or the prompt length, and check that you do not start two model processes at once in the same job. |
| `Disk quota exceeded` | You wrote large files into your home directory (venv, model downloads, logs, checkpoints). Check with `du -sh ~/* ~/.[!.]* 2>/dev/null \| sort -h \| tail`, delete what you do not need, and use the shared environment instead of your own. |
| No `hw1-<jobid>.out` file | The job has not started yet (still `PD`), or you are looking in the wrong directory. The file is created in the directory where you ran `sbatch`. Check `squeue -u $USER`, and `ls` in that directory. |
| A script or output I wrote in `/tmp` is missing | `/tmp` is local to each machine. Keep files under your home directory. |
| `git` says `Permission denied (publickey)` inside a job | Jobs do not have your forwarded SSH key. Run git on the login node. See [git-on-the-server.md](git-on-the-server.md). |
| `srun` prompt never appears and I do not know why | Check `squeue -u $USER` and `sinfo` in a second terminal. Press Ctrl-C to give up, and `scancel` any leftover job. |

If none of this helps, post on Ed (preferably publicly) with the job id,
the command you ran, and the full text of the error.
