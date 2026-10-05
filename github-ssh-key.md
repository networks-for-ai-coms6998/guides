# Using an SSH key with GitHub

An SSH key is a pair of files on your computer: a **private key** that
never leaves your machine, and a **public key** that you give to
services (GitHub, and through GitHub, the course server). This guide
shows how to create one on macOS and Windows (with a short Linux note),
add it to GitHub, and set up `~/.ssh/config` so that
`ssh cs6998` is all you type to reach the course server.

If you already have a key on your GitHub account, skip to
[step 5 (load the key into the agent)](#5-load-the-key-into-the-ssh-agent)
and still do [step 7 (the `~/.ssh/config` file)](#7-the-ssh-config-file),
because the other guides assume the `cs6998` alias.

## 1. Check for an existing key

Open a terminal (macOS: Terminal; Windows: PowerShell) and run:

```
ls ~/.ssh
```

On Windows PowerShell, `ls ~/.ssh` works too (`~` is your user folder,
`C:\Users\<you>`). If you see `id_ed25519` and `id_ed25519.pub`, you
already have a key and can reuse it. If the folder does not exist or is
empty, generate one.

## 2. Generate an ed25519 key

```
ssh-keygen -t ed25519
```

-   Press Enter to accept the default location
  (`~/.ssh/id_ed25519`).
-   A passphrase is **optional**. The course does not require one for the
  homework. If you do set one, the SSH agent (below) remembers it so you
  do not retype it constantly.

This creates two files:

| File | What it is | Share it? |
| --- | --- | --- |
| `~/.ssh/id_ed25519` | Private key | **Never.** Not on Ed, not by email, not on the server |
| `~/.ssh/id_ed25519.pub` | Public key | Yes, this is what you give to GitHub |

On Windows the folder is `C:\Users\<you>\.ssh\`.

## 3. Add the public key to GitHub

1.  Print the public key and copy it:
    - macOS: `pbcopy < ~/.ssh/id_ed25519.pub`
    - Windows PowerShell: `Get-Content ~/.ssh/id_ed25519.pub | Set-Clipboard`
    - Linux: `cat ~/.ssh/id_ed25519.pub` and copy the output
2.  On GitHub go to **Settings**, then **SSH and GPG keys**, then
   **New SSH key**.
3.  Give it a title (for example "my laptop"), paste the key (one line
   starting with `ssh-ed25519`), and save.

Make sure you paste the `.pub` file, never the private one.

## 4. Test the key

```
ssh -T git@github.com
```

The first time, ssh asks whether to trust `github.com`. Compare the
fingerprint with the ones GitHub publishes in its documentation, then
type `yes`. A successful test prints something like:

```
Hi <your-github-handle>! You've successfully authenticated, but GitHub does not provide shell access.
```

That message is the success case, even though it looks like an error.

## 5. Load the key into the SSH agent

The SSH agent is a small background program that holds your unlocked
key so you do not have to type a passphrase for every connection. It is
also what makes agent forwarding work (see the
[config section](#7-the-ssh-config-file)).

### macOS

```
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

This stores the passphrase (if you set one) in the macOS keychain. Also
add `UseKeychain yes` to your config file (below) so it is loaded again
after a reboot.

### Windows 10/11 (built-in OpenSSH)

The agent service is installed but disabled by default. Open PowerShell
**as Administrator** (right-click, Run as administrator) and run:

```
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
```

Then, in a **normal** (non-admin) PowerShell:

```
ssh-add $env:USERPROFILE\.ssh\id_ed25519
ssh-add -l
```

`ssh-add -l` should list your key. `Automatic` makes the agent start
again after every reboot. If `Get-Service ssh-agent` errors because the
service does not exist, install the "OpenSSH Client" optional feature
(Settings, Apps, Optional features) and try again.

Pitfalls on Windows:

-   Git Bash and WSL each have their **own** `~/.ssh` and their own
  agent. A key created in PowerShell is not visible inside WSL, and the
  reverse. Pick one environment for your course work and generate and
  load the key there.
-   Windows PowerShell and the built-in `ssh` use
  `C:\Users\<you>\.ssh`. If a tool complains it cannot find your key,
  check which environment it is running in.

### Linux

Most desktop Linux systems start an agent for you. If not:

```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

## 6. File permissions

ssh refuses to use a private key that other users can read.

-   macOS and Linux:

    ```
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_ed25519 ~/.ssh/config
    chmod 644 ~/.ssh/id_ed25519.pub
    ```

-   Windows: files you create with `ssh-keygen` in your own profile are
  normally fine. If you copied the key from elsewhere and see
  `Bad permissions` or `UNPROTECTED PRIVATE KEY FILE`, right-click the
  private key file, open Properties, Security, Advanced, disable
  inheritance, and make sure only your own user has access.

## 7. The SSH config file

Typing `ssh <your-uni>@mv.cs.columbia.edu` every time is tedious. A
config file lets you define a short alias. The file lives at:

- macOS and Linux: `~/.ssh/config`
- Windows: `C:\Users\<you>\.ssh\config` (no file extension)

Create it if it does not exist (`mkdir -p ~/.ssh && touch ~/.ssh/config`
on macOS/Linux; on Windows create it with Notepad and make sure it is
not saved as `config.txt`). Add this block, replacing `<your-uni>` with
your UNI:

```
Host cs6998
    HostName mv.cs.columbia.edu
    User <your-uni>
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddKeysToAgent yes
    ForwardAgent yes
```

On macOS, also add this line inside the block:

```
    UseKeychain yes
```

(UseKeychain is macOS-only; on Windows and Linux leave it out, because
it is not recognized there.)

Line by line:

-   `Host cs6998`: the alias you will type. `ssh cs6998` now means "use
  everything in this block". You can pick any name.
-   `HostName mv.cs.columbia.edu`: the real server address.
-   `User <your-uni>`: your username on the server is your UNI, so you
  do not need to type `uni@`.
-   `IdentityFile ~/.ssh/id_ed25519`: which private key to offer.
-   `IdentitiesOnly yes`: offer only the key named above, not every key
  in your agent. This avoids being rejected for "too many
  authentication failures" if you have many keys.
-   `AddKeysToAgent yes`: the first time you use the key, ssh adds it to
  the agent for you.
-   `ForwardAgent yes`: see below.
-   `UseKeychain yes` (macOS): save/read the passphrase from the keychain.

After this, connecting is just:

```
ssh cs6998
```

### What `ForwardAgent` does

With agent forwarding, the server can ask **your laptop's** SSH agent to
prove your identity, without your private key ever leaving your laptop.
That means that on the server you can run `git clone`, `git pull` and
`git push` against GitHub using the key on your GitHub account, with
**no key, token, or password copied onto the server**. See
[git-on-the-server.md](git-on-the-server.md) for the workflow.

You do **not** need `SendEnv` or any environment variable or token for
this course's git workflow. Agent forwarding is all it takes.

### Security note

-   Enable `ForwardAgent` for this one host only. **Never** put it under
  `Host *`, which would forward your agent to every server you ever
  connect to.
-   While you are connected, administrators of the server could in
  principle use your forwarded agent to authenticate as you (they
  cannot copy the private key, but they can use it while the connection
  is open). Disconnect when you are done, and never forward your agent
  to a host you do not trust.

## Troubleshooting

| Symptom | Likely cause and fix |
| --- | --- |
| `Permission denied (publickey)` | The server or GitHub did not accept any key you offered. Check that the key is on your GitHub account (`curl https://github.com/<handle>.keys`), that you are offering the right file (`ssh -v cs6998` shows which keys are tried), and, for the course server, that up to 30 minutes have passed since you added the key |
| `ssh-add -l` says `The agent has no identities` | The agent is running but empty. Run `ssh-add ~/.ssh/id_ed25519` (macOS: `ssh-add --apple-use-keychain ...`). On Windows make sure the `ssh-agent` service is started. Then reconnect, because forwarding only sees keys loaded when you connect |
| `Could not open a connection to your authentication agent` | No agent is running. macOS/Linux: `eval "$(ssh-agent -s)"`. Windows: start the service as described above |
| Wrong key being used | Compare fingerprints: `ssh-keygen -lf ~/.ssh/id_ed25519.pub` (local) and the keys listed on your GitHub settings page. Point ssh at the right file with `IdentityFile` in your config, or `ssh -i ~/.ssh/<key> ...` |
| `WARNING: UNPROTECTED PRIVATE KEY FILE!` or `Bad permissions` | Private key is readable by others. Fix with `chmod 600 ~/.ssh/id_ed25519` (Windows: see file permissions above) |
| `Host key verification failed` | The fingerprint the server showed does not match what your computer remembered in `~/.ssh/known_hosts`. Do not just ignore it: check the course fingerprints in [connect-to-server.md](connect-to-server.md#first-connection). If they match and you know the server was rebuilt, remove the old entry with `ssh-keygen -R mv.cs.columbia.edu`; otherwise ask on Ed |
| `Bad configuration option: usekeychain` | You have `UseKeychain yes` on Windows or Linux. Delete that line |
| Config seems ignored (Windows) | The file was saved as `config.txt` or is in the wrong folder. It must be `C:\Users\<you>\.ssh\config` with no extension |
