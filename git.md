# Git Tutorial

Git is a source code version control system. It is most useful when you work
in a team, but even when you are working alone it is a very useful tool for
keeping track of the changes you have made to your code.

In this course you use Git and GitHub for your assignments: you get your
starter code from a repository that the teaching staff creates for you, you
commit your work to it, and you submit by pushing to it. See
[Using git on the server](git-on-the-server.md) and [Submission](submission.md) for how that
works end to end.
This guide covers the Git basics you need.

## Configure your Git environment

Tell Git your name and email:

```bash
git config --global user.name "Your Full Name"
git config --global user.email your_uni@columbia.edu
```

Git stores this information in `~/.gitconfig`. If you commit from the course
server, see [Git on the server](git-on-the-server.md) for anything specific to
that machine.

Optionally, set the editor Git opens for commit messages (vim, emacs, nano,
or `code --wait` for VS Code):

```bash
git config --global core.editor nano
```

## Creating a project

Let's create a new directory, `~/tmp/test1`, for a practice project.

```bash
mkdir -p ~/tmp/test1
cd ~/tmp/test1
```

Put the directory under Git revision control:

```bash
git init
```

**Important note:** `git init` should only be executed when setting up a new
repository. You should never run `git init` inside a cloned assignment
repository.

A Git repository exists alongside the normal file system. It tracks changes to
files in the directory you initialized it in and its subdirectories. You could
create another repository in `~/tmp/test2`, and the two repositories would
have nothing to do with each other.

If you run `ls -a`, you will see a `.git` directory. The repository for the
current directory is stored there.

Let's start a tiny Python project. Create `hello.py` with your editor:

```python
print("hello world")
```

Run it:

```bash
python3 hello.py
```

Let's see what Git thinks about what we are doing:

```bash
git status
```

`git status` reports that `hello.py` is "Untracked". We can have Git track it
by adding it to the "staging area" (more on this later):

```bash
git add hello.py
```

Run `git status` again. It now reports that `hello.py` is "a new file to be
committed." Let's commit it:

```bash
git commit
```

Git opens your editor for you to type a commit message. A commit message
should succinctly describe what you are committing in the first line. If you
have more to say, follow the first line with a blank line and then a more
thorough description.

For now, type in the one-line message `Added hello-world program`, save, and
exit the editor. You can also do this in one command with `-m`, which gives
the message directly without opening an editor:

```bash
git commit -m "Added hello-world program"
```

Run `git status` again. When Git says nothing about a file, it means the file
is tracked and has not changed since it was last committed.

We have successfully put our first project under Git revision control.

## Modifying files

Modify `hello.py` to print "bye world" instead, and run `git status`. It
reports that the file is "Changes not staged for commit." This means the file
has been modified since the last commit, but it is not ready to be committed
because it has not been moved into the staging area. In Git, a change must
first go to the staging area before it can be committed.

Before we stage it, let's see what we changed:

```bash
git diff
```

The output should tell you that you took out the "hello world" line and added
a "bye world" line, like this:

```diff
-print("hello world")
+print("bye world")
```

Stage the change with `git add`:

```bash
git add hello.py
```

In Git, "add" means: move the change you made to the staging area. The change
could be a modification to a tracked file or the creation of a brand new file.

At this point, `git diff` reports no change, because `git diff` reports the
difference between the staging area and the working copy. To see the
difference between the last commit and the staging area, add `--cached`:

```bash
git diff --cached
```

Let's commit the change:

```bash
git commit -m "Changed hello to bye"
```

To see your commit history:

```bash
git log
```

Useful variations:

```bash
git log --oneline       # one line per commit
git log --stat          # which files changed in each commit
git log -p              # the full diff of each commit
```

## The tracked, the modified, and the staged

A file in a directory under Git revision control is in one of four states:

1.  Untracked
    -   Files that should not be in the repository, such as virtual
      environments, model weights, datasets, and generated output, are
      usually left untracked (see [`.gitignore`](#ignoring-files) below).
1.  Tracked, unmodified
    -   The file is in the repository and has not been modified since the last
      commit. `git status` says nothing about it.
1.  Tracked, modified, but unstaged
    -   You modified the file but did not `git add` it, so it is not ready for
      commit yet.
1.  Tracked, modified, and staged
    -   You modified the file and ran `git add`. The change is in the staging
      area, ready for commit.

The staging area is also called the "index".

## Ignoring files

Some files should never be committed: your virtual environment (`.venv/`),
Python caches (`__pycache__/`), downloaded model weights, large datasets, and
anything secret such as tokens or API keys. List patterns for them in a file
named `.gitignore` at the root of your repository:

```text
.venv/
__pycache__/
*.pt
*.safetensors
.env
```

Then `git add .gitignore` and commit it like any other file. Large files
committed by accident bloat your repository, so check `git status` before you
`git add .`.

## Other useful Git commands

To rename a tracked file:

```bash
git mv old-filename new-filename
```

To remove a tracked file from the repository:

```bash
git rm filename
```

These are automatically staged for you, but you still need to `git commit`.

To discard your uncommitted changes to a file and go back to the last
committed version:

```bash
git restore filename
```

To unstage a file that you staged (keeping your edits):

```bash
git restore --staged filename
```

To read the manual for a command:

```bash
git help status
```

To search for a pattern in all files in the repository:

```bash
git grep pattern
```

## Cloning a project

More often than not, you start from an existing code base. When the code base
is under Git version control, you can _clone_ the whole repository. This is
what you do to start each assignment from the starter code. Let's clone
`test1` into `test2`:

```bash
cd ..
git clone test1 test2
cd test2
```

Run `ls` to see that `hello.py` is here. If you run `git log`, you will see
that the whole commit history is replicated. `git clone` copies not only the
latest version of the files but the entire repository, including its history.

Let's make a change and commit it:

```bash
echo 'print("rock my world")' > hello.py
git add hello.py
git commit -m "Print rock my world"
```

Run `git log` to see your commit on top of the cloned history. To see only the
commits made since cloning:

```bash
git log origin/main..
```

(If your default branch is called `master` rather than `main`, use
`origin/master..`.)

## Pushing commits to a remote repository

The `git push` command takes a remote name (for example `origin`) and a branch
name (for example `main`):

```bash
git push origin main
```

This sends your new commits to the remote repository. For an assignment
repository on GitHub, that is your submission. (You cannot practice this
between the two local directories above, because Git refuses to push into the
checked-out branch of another working copy.)

## Pulling changes from a remote repository

To retrieve changes that were made in the remote repository since you cloned
it, "pull" them:

```bash
git pull
```

`git pull` fetches all the changes made on the remote since your last pull and
merges them into your current branch. Assignment READMEs tell you to run
`git pull origin main` before you start, so that you have the latest
instructions and starter code.

## Working with GitHub

Each assignment in this course lives in a private GitHub repository under the
`networks-for-ai-coms6998-hw` organization, named `<assignment>-<uni>`, for
example `hw1-abc1234`. To work on it, clone it over SSH:

```bash
git clone git@github.com:networks-for-ai-coms6998-hw/hw1-abc1234.git
cd hw1-abc1234
```

For this to work you must have an SSH key registered with your GitHub account.
See [GitHub SSH key setup](github-ssh-key.md). Once you have committed your
work, `git push` sends it to GitHub, and you can confirm it arrived by looking
at your repository on github.com.

## Branches

A branch is an independent line of commits. For the individual assignments in
this course you can simply work on `main`; that is the branch to push. If you
work in a group (for example on the course project), we recommend pushing work
to branches first and merging into `main` after your teammates have reviewed
it:

```bash
git switch main
git switch -c <branch-name>
```

Commit your changes, then push the branch:

```bash
git push -u origin <branch-name>
```

When the feature is complete, open a pull request on GitHub so your teammates
can review the code, then merge it into `main`. See
[GitHub's documentation on pull requests](https://docs.github.com/en/pull-requests)
for details.

## Learning more about Git

This tutorial covers everything you need for the assignments. If you want to
learn more, start with the official tutorial:

```bash
man gittutorial
```

The [Git documentation site](https://git-scm.com/doc) has many more links.

### Acknowledgments

This guide was originally developed by Jae Woo Lee, adapted by Leslie Chang in
Spring 2023, and adapted for this course in Fall 2026.
