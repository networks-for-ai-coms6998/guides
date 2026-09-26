# Using Your Homework Repo on the Course Server

This guide shows how to work with your private assignment repos from the
course server (`mv.cs.columbia.edu`) with as little effort as possible.

The short version: connect with **SSH agent forwarding**, and the SSH key
that is already on your GitHub account works on the server too. There is
nothing to install and nothing to store on the server.

Prerequisites:

-   You can log in to the server: see [connect-to-server.md](connect-to-server.md).
-   Your laptop has an SSH key added to your GitHub account: see
    [github-ssh-key.md](github-ssh-key.md). Before you connect, run
    `ssh-add -l` on the **laptop**: it must list your key.

## What is agent forwarding?

Your laptop runs an _SSH agent_ that holds your private key in memory.
With agent forwarding, the server can ask _your laptop's agent_ to sign
in to GitHub on your behalf while your SSH session is open. Your private
key never leaves your laptop.

There is **no need to store a GitHub token, key, or password on the
server**, and no `SendEnv` variables or other special setup are needed.

## Repo names

Every assignment repo is private, lives in the GitHub organization
`networks-for-ai-coms6998-hw`, and is named `<assignment>-<uni>`:

- `reading-response-3-<uni>`
- `hw1-<uni>`

Replace `<uni>` with your own UNI (lowercase).

## Set up (once)

### 1. Connect with agent forwarding

```bash
ssh -A <uni>@mv.cs.columbia.edu
```

If you configured the `cs6998` alias as described in
[github-ssh-key.md](github-ssh-key.md), just run:

```bash
ssh cs6998
```

### 2. Tell git who you are

On the server:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Use the same email as on your GitHub account if you want your commits to be
linked to it.

### 3. Check that your key is visible

On the server:

```bash
ssh-add -l
```

It should list your key. If it says `The agent has no identities` or
`Could not open a connection to your authentication agent`, see
[Troubleshooting](#troubleshooting).

### 4. Clone your repo

The first time you contact GitHub, ssh asks whether to trust the host key.
Type `yes`.

```bash
git clone git@github.com:networks-for-ai-coms6998-hw/hw1-<uni>.git
cd hw1-<uni>
```

Use the `git@github.com:...` (SSH) form, not the `https://` form.

## Day-to-day workflow

Pick one of these. Option A is recommended.

### Option A: edit on your laptop, run on the server

1.  Edit your code on your laptop, in your usual editor.
2.  Commit and push from your laptop.
3.  On the server, in your repo directory, before each run:

    ```bash
    git pull
    ```

4.  Run your code (see [slurm-gpu.md](slurm-gpu.md) for GPU jobs).

You can also use VS Code with the Remote-SSH extension: it edits the files
directly on the server, so you can skip the push/pull step and run `git`
from the integrated terminal. Note that the VS Code helper process runs on
the login node and may hit its memory limit (512 MB of RAM per user) and be
killed; if it keeps disconnecting, use a plain terminal plus
edit-locally-and-push (see [connect-to-server.md](connect-to-server.md)).

The advantage of this option is that your laptop is the single source of
truth, and you always have your latest work on GitHub.

### Option B: edit on the server

1.  Edit files on the server (`nano`, `vim`, or VS Code Remote-SSH, which may be killed by the
    login node's 512 MB memory limit; see above).
2.  Run your code.
3.  Commit and push from the server:

    ```bash
    git add <files>
    git commit -m "Describe what you changed"
    git push
    ```

If you use both options, always `git pull` before you start editing in a
new place, so the two copies do not diverge.

## Push early, and mind the deadline

The deadline is authoritative: pushes made after the deadline do not count,
even if GitHub still accepts them. Repos are locked around or after the
deadline, but a successful push after the deadline does not make your
submission on time. There are no extensions. Push early and often, and
after your final push, open your repo on github.com and check that your
latest commit and files are really there.

## Run git on the login node, not inside jobs

The forwarded agent exists only **while your SSH session is open**. That
has two consequences:

-   Slurm jobs (`sbatch`, and the shell you get from `srun`) run on a
    different machine without your forwarded key, so `git` will fail with
    `Permission denied (publickey)` there. Do all `git clone`, `pull`, and
    `push` commands on the **login node**, before you submit a job or after
    it finishes.
-   Once you disconnect, the agent is gone. Anything running later on your
    behalf (for example a queued job) cannot use it.

See [slurm-gpu.md](slurm-gpu.md) for how jobs work.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `Permission denied (publickey)` on `git clone` or `git push` | Your key is not loaded in the agent on your **laptop**. On the laptop, run `ssh-add -l`. If your key is not listed, run `ssh-add ~/.ssh/id_ed25519` (or the path to your key), then disconnect and reconnect with `ssh -A` (or `ssh cs6998`). |
| `ssh-add -l` on the server says `Could not open a connection to your authentication agent` | You connected without `-A`. Reconnect with `ssh -A <uni>@mv.cs.columbia.edu` or use the `cs6998` alias. |
| `Host key verification failed` for `github.com` | Run `ssh -T git@github.com` on the server and answer `yes` when asked to trust the host. Compare with the fingerprints GitHub publishes in its documentation if you want to be careful. |
| Works in one terminal but not in `tmux` or `screen` | Shells that were already running inside `tmux` keep a stale `SSH_AUTH_SOCK` from the old SSH session (`screen` has the same problem). Reconnect with `ssh -A` (or `ssh cs6998`) and reattach, then in each existing shell run `export SSH_AUTH_SOCK=$(tmux show-environment SSH_AUTH_SOCK \| cut -d= -f2)`, or just open a new tmux window or pane. Check with `ssh-add -l`. |
| `Permission denied (publickey)` inside `sbatch` or `srun` | Expected. Jobs have no forwarded key. Run `git` on the login node. |
| The push is rejected after the deadline | The repo is locked. Pushes after the deadline do not count, whether or not GitHub accepts them. |
| `Your branch is behind` or a rejected non-fast-forward push | Run `git pull`, resolve any conflicts, and push again. |
| `Disk quota exceeded` while cloning | Your home directory is full (500 MB soft / 1 GB hard). Delete large files you do not need. See [slurm-gpu.md](slurm-gpu.md). |

## Fallback: no agent forwarding

Windows PowerShell has no `rsync`; use `scp -r` or WSL instead.

If agent forwarding does not work for you (for example, you cannot get
`ssh-add -l` to list your key), you can skip git on the server entirely:

1.  Keep your repo on your laptop and do all git operations there.
2.  Copy the code you want to run to the server with `scp` or `rsync`
    (see [connect-to-server.md](connect-to-server.md)):

    ```bash
    rsync -av --exclude .git ./hw1-<uni>/ <uni>@mv.cs.columbia.edu:hw1-<uni>/
    ```

3.  Run it on the server, and copy the results back the same way:

    ```bash
    rsync -av <uni>@mv.cs.columbia.edu:hw1-<uni>/results/ ./results/
    ```

4.  Commit and push from your laptop.

Again: do not put a GitHub token, key, or password on the server as a
workaround.
