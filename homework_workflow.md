# Homework Workflow Guide

This guide walks you through setup, development, and submission for the
assignments in COMS 6998 Networks for AI. It applies to the reading responses
and the homework assignments.

> **Critical:** Your submission is what is on GitHub in your assignment
> repository when the deadline passes. Work that exists only on your laptop or
> on the course server will **not** be graded.

## How assignments work

-   Every assignment gets **one private GitHub repository per student**, named
  `<assignment>-<uni>` (all lowercase), in the organization
  `networks-for-ai-coms6998-hw`. For example, `hw1-abc1234` is the HW1
  repository for the student with UNI `abc1234`.
-   Each repository is created for you from a template that contains the
  assignment README and any starter code. Read the README first: it is the
  authority on what to submit, what to name your files, and the deadline.
-   You submit by **pushing to your repository before the deadline**.
-   The deadline is authoritative: pushes made after the deadline do not count,
  even if GitHub still accepts them. Repositories are locked around or after
  the deadline. There are **no extensions**, and the deadline is the same for
  everyone.
-   Each assignment's README states its own deadline. Reading responses are due
  one hour before class begins (class meets Tuesdays at 6:10 PM Eastern, so
  the deadline is Tuesday 5:10 PM Eastern). A successful push after the
  deadline does not make your submission on time, so push early.
-   Assignments other than the course project are individual.

Do not wait until the last minute to push your first commit. Push early,
push often, and verify (see [Verify your submission](#verify-your-submission)).

## First-time setup

Complete these one-time steps before your first assignment.

### 1. Set up an SSH key for GitHub

You need an SSH key registered with your GitHub account to clone and push over
SSH. Follow [GitHub SSH key setup](github-ssh-key.md). If you also want to
push from the course server, see [Git on the server](git-on-the-server.md).

### 2. Configure Git

```bash
git config --global user.name "Your Full Name"
git config --global user.email your_uni@columbia.edu
```

New to Git? Read the [Git Guide](git.md).

### 3. Decide where you will work

You can develop wherever is convenient:

-   **Your own machine.** Fine for writing code, running on CPU, and writing
  your report. HW1 requires Python 3.10+ and uses a virtual
  environment; check each assignment README for exact requirements and setup
  commands.
-   **The course server** (`mv.cs.columbia.edu`), for CPU work and for queuing
  GPU jobs. See [Connecting to the course server](connect-to-server.md) and
  [Using the GPU with Slurm](slurm-gpu.md).
-   **Your own cloud GPU**, optionally, using your own credit. See
  [Using your own GCP GPU credit](gcp-personal-gpu.md).

If you like editing in VS Code, see the [VS Code and Docker guide](vscode_docker.md).

## Starting each assignment

### 1. Clone your assignment repository

Once your repository exists, clone it (replace `hw1` and `abc1234` with the
assignment and your UNI):

```bash
git clone git@github.com:networks-for-ai-coms6998-hw/hw1-abc1234.git
cd hw1-abc1234
```

If you cannot find your repository on GitHub or cannot clone it, ask the
teaching staff rather than creating one yourself.

### 2. Read the README

Read the assignment `README.md` in the root of the repository. It describes the
task, the files to submit (for example `UNI-hw1-report.md`, with `UNI`
replaced by your UNI), and the deadline.

### 3. Pull the latest instructions

Assignment READMEs may be updated after the repository is created. Before you
start, and again from time to time, run:

```bash
git pull origin main
```

## Development cycle

Before you write any code, make sure you understand the problem. Break it into
parts, plan your approach in pseudocode or plain English, then implement and
test one part at a time. For measurement-heavy assignments, get a small,
fast version of each experiment working before running the full sweep.

Follow this cycle as you work:

### Pull, code, commit, push

1.  Pull the latest changes (especially important if you work from more than
   one machine):

    ```bash
    git pull
    ```

1.  Make your changes, then stage and commit:

    ```bash
    git add <files>
    git commit -m "Descriptive message of your changes"
    ```

1.  Push to GitHub:

    ```bash
    git push
    ```

1.  Run and test your code, then repeat.

> **Tip:** Commit frequently with meaningful messages. This creates a clear
> history and makes it easier to find when something broke.

Do not commit virtual environments, model weights, or large data files. See
[Ignoring files](git.md#ignoring-files).

## Completing your assignment

Before your final push, check:

-   The deliverables listed in the README exist, with exactly the file names it
  asks for.
-   Your code runs from a clean checkout, following the setup steps in the
  README.
-   Your report includes the header information the README asks for (for
  example your UNI, full name, GitHub handle, and date).
-   Any figures or results the report refers to are committed alongside it.
-   Debug output and dead code are removed.

Then commit and push:

```bash
git add .
git commit -m "hw1 final submission"
git push
```

The commit message can be anything descriptive.

### Using LLMs

The syllabus permits the use of large language models as writing or coding
aids provided that:

1. all AI-assisted content is clearly labeled, and
1. you can explain any submitted work in detail.

Presenting AI-generated content as original analysis without attribution is an
honor code violation. See the Academic Integrity section of the syllabus for
the authoritative wording. Follow the collaboration and LLM-use rules in the
syllabus and each assignment README; LLM use is allowed if you disclose it
and can explain your work.

## Verify your submission

After your final push, confirm it arrived. See
[Submission Clarifications](submission.md) for the full checklist. In short,
open your repository on github.com and check that the files, and the latest
commit, are what you expect.

## Quick reference

| Task                    | Command                                                                       |
| ----------------------- | ----------------------------------------------------------------------------- |
| Clone your repository   | `git clone git@github.com:networks-for-ai-coms6998-hw/<assignment>-<uni>.git` |
| Get the latest README   | `git pull origin main`                                                        |
| Check repository status | `git status`                                                                  |
| Stage changes           | `git add <files>` or `git add .`                                              |
| Commit changes          | `git commit -m "message"`                                                     |
| Push to GitHub          | `git push`                                                                    |
| View commit history     | `git log --oneline`                                                           |
| Log in to course server | `ssh <uni>@mv.cs.columbia.edu` (see [connect guide](connect-to-server.md))    |

## Related guides

- [Connecting to the course server](connect-to-server.md)
- [GitHub SSH key setup](github-ssh-key.md)
- [Git Guide](git.md)
- [Git on the server](git-on-the-server.md)
- [Using the GPU with Slurm](slurm-gpu.md)
- [Submission Clarifications](submission.md)
- [VS Code and Docker](vscode_docker.md)
- [Using your own GCP GPU credit](gcp-personal-gpu.md)

---

_Remember: only work pushed to GitHub before the deadline will be graded. When
in doubt, push your work early._

### Acknowledgments

This guide was developed by TA Amit Aharoni in Spring 2026, updated in Summer
2026, and adapted for COMS 6998 in Fall 2026.
