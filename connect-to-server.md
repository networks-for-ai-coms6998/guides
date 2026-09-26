# Connecting to the course server

Every enrolled student has an account on the course server,
`mv.cs.columbia.edu`. Using it is **optional**. Its purpose is to give
you a strong GPU to test the homework.

The server you log in to is a regular CPU machine that is available
24/7. Your GPU jobs run (through Slurm) on a **separate GPU machine
that you cannot log in to directly**. See [slurm-gpu.md](slurm-gpu.md)
for how to run jobs, and [git-on-the-server.md](git-on-the-server.md)
for getting your homework repository onto the server.

## Quick start

Your username is your **UNI**, and login is by **SSH key only** (there
are no passwords):

```
ssh <your-uni>@mv.cs.columbia.edu
```

If you set up the `cs6998` alias from
[github-ssh-key.md](github-ssh-key.md#7-the-ssh-config-file), this is
just:

```
ssh cs6998
```

## Which key does the server accept?

The public SSH key(s) on the **GitHub account you gave us in the
sign-up form**. The server re-reads your GitHub keys every 30 minutes,
so adding or removing a key on GitHub takes effect within about half an
hour.

To check what the server will see, run this from anywhere (use your own
GitHub handle). If it prints nothing, you have no key on GitHub yet:

```
curl https://github.com/<your-github-handle>.keys
```

On Windows PowerShell, use `curl.exe` instead of `curl` (plain `curl`
is an alias for a different command).

### If you already have a key on GitHub

Just run the `ssh` command above. If it says
`Permission denied (publickey)`, the key your computer offers is not
the one on GitHub. Compare fingerprints with:

```
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

or point ssh at the right file with `ssh -i ~/.ssh/<key> ...`.

### If you do not have a key on GitHub yet

Follow [github-ssh-key.md](github-ssh-key.md). In short:

1.  Generate a key: `ssh-keygen -t ed25519` (a passphrase is not
   needed).
2.  On GitHub go to Settings, then SSH and GPG keys, then New SSH key,
   and paste the contents of `~/.ssh/id_ed25519.pub` (the `.pub` file,
   never the private one).
3.  Wait up to 30 minutes, then log in as above.

## First connection

Your SSH client shows a fingerprint and asks you to confirm. It should
match one of these:

```
ED25519  SHA256:JC8SzfDRhJ+eC4jW1flcevNQcQimJaZTmNuGrQphLbI
ECDSA    SHA256:hIQloCb3/sLmzHxf537T2EQD9wkJWQlcNgcSPJMkab8
RSA      SHA256:FbKlx+7NX74uJ5Uxi4BMWZ4f5CGgrRa8qTpX3ppe4cc
```

If it matches, type `yes`. If it does not match, answer `no` and ask
the instructors on Ed.

## Wrong GitHub handle, or want to change it?

Post a **private** message to the instructors on Ed. Handle changes are
approved by hand, on purpose, so nobody can take over another student's
account.

## Rules of the road

-   No `sudo`. Your home directory is private to you.
-   Disk quota: 1 GB soft / 2 GB hard. Do not install large packages
  (for example your own copy of PyTorch); a shared environment is
  provided, see [slurm-gpu.md](slurm-gpu.md).
-   Each user is limited to 1 CPU, 512 MB of RAM and 100 processes on the
  login node. Use it for editing, small tests and submitting jobs, not
  for heavy compute.
-   The login server is up 24/7. The GPU machine is separate and is not
  reachable directly; no GPU jobs are scheduled overnight (1-7 a.m. ET).

## Copying files

`scp` and `rsync` run from **your own computer**, not from the server.
Examples assume the `cs6998` alias; otherwise use
`<your-uni>@mv.cs.columbia.edu` in its place.

macOS / Linux:

```
# laptop -> server (into your home directory)
scp results.csv cs6998:~/

# server -> laptop (into the current directory)
scp cs6998:~/hw1-out.txt .

# whole folder, only sending what changed
rsync -avz ./my-project/ cs6998:~/my-project/
```

Windows PowerShell has `scp` built in (same syntax):

```
scp results.csv cs6998:~/
scp cs6998:~/hw1-out.txt .
scp -r .\my-project cs6998:~/
```

`rsync` is not included with Windows; use `scp -r`, or run `rsync`
inside WSL.

Mind your 1 GB quota when copying data over.

## VS Code Remote-SSH

You can edit files on the server from VS Code on your laptop:

1.  Install the **Remote - SSH** extension (by Microsoft).
2.  Open the command palette and choose **Remote-SSH: Connect to
   Host...**, then pick `cs6998` (VS Code reads the alias from your
   `~/.ssh/config`).
3.  Open a folder on the server and work as usual.

A caution: the VS Code helper process runs on the login node and may
hit its memory limit (512 MB of RAM per user, 100 processes) and be
killed. If VS Code keeps disconnecting, use a plain terminal
(`ssh cs6998`) with an editor such as `vim` or `nano`, or edit locally
and push (or copy files over with `scp`/`rsync`).
Remember that the model and other heavy work must run through Slurm,
never in the VS Code terminal on the login node.

## Troubleshooting

-   Most login problems (`Permission denied (publickey)`, empty agent,
  wrong key, bad permissions, `Host key verification failed`) are
  covered in the table in
  [github-ssh-key.md](github-ssh-key.md#troubleshooting).
-   **No key on GitHub yet.** If `curl https://github.com/<handle>.keys`
  prints nothing, the server has nothing to accept. Add a key
  ([github-ssh-key.md](github-ssh-key.md)) and wait up to 30 minutes.
-   **Key was added recently.** Give it up to 30 minutes.
-   **Handle is wrong in the sign-up form.** Message the instructors
  privately on Ed (see above).
-   **Disk full.** Check usage
  with `du -sh ~` and remove large files; the hard limit is 2 GB.
-   Still stuck? Post on Ed with the output of `ssh -v cs6998` (it does
  not contain your private key), preferably in public.
