# Submission Clarifications

This guide explains what counts as a submission in this course and how to
check yours.

**Only what is pushed to your assignment repository on GitHub before the
deadline is graded.** The deadline is authoritative: pushes made after it do
not count, even if GitHub still accepts them. There are no extensions, so we
cannot make exceptions.

Use these checks to make sure that:

1.  Your work is pushed to your repository (the default branch, normally
   `main`, unless the assignment README says otherwise).
1.  Your files have the names and locations the assignment asks for.
1.  Your code runs from a clean checkout, so anyone can reproduce your results.
1.  You pushed before the deadline.

## Your repository and the deadline

Your repository is named `<assignment>-<uni>` and lives in the
`networks-for-ai-coms6998-hw` organization on GitHub, for example
`hw1-abc1234`. See the [Homework Workflow Guide](homework_workflow.md) for how
to clone it and work in it.

Each assignment README states its deadline (for example, HW1 is due Thursday,
October 1, 2026 at 11:55 PM Eastern). Reading responses are due one hour
before class begins (Tuesday 5:10 PM Eastern). Repositories are locked around
or after the deadline, but a successful push after the deadline does not make
your submission on time. Push early, and submit before the deadline.

## The main branch

After you push, the easiest way to confirm your work arrived is to open your
repository on github.com (`https://github.com/networks-for-ai-coms6998-hw/<assignment>-<uni>`)
and check:

- You are looking at the branch you pushed to (normally `main`).
- The files listed are the files you want the teaching staff to see.
- The latest commit message and timestamp are your final push.
- Any file you edited shows your latest edits (open it and read it).

## File names and structure

The assignment README lists what to submit. For example, HW1 asks for a report
named `UNI-hw1-report.md` in the root of the repository (with `UNI` replaced by
your UNI), your code in `code/`, and a `plots/` folder for figures; reading
responses ask for `UNI-reading-response-N.md` in the root. Get the names
exactly right, since a misnamed file may not be found.

To check your structure from a clean copy, clone your repository into a fresh
directory and look at it:

```bash
git clone git@github.com:networks-for-ai-coms6998-hw/hw1-abc1234.git /tmp/hw1-check
cd /tmp/hw1-check
ls -R | head -50
```

If `tree` is installed, `tree -I .git` gives a nicer view. The layout should
match what the README describes. Note that files that should not be in the
repository (virtual environments, model weights, large datasets) make your
repository slow to clone; keep them out with a `.gitignore` (see
[Ignoring files](git.md#ignoring-files)).

## Report and figures

If your assignment includes a written report:

-   Include the header information the README requests (for example UNI, full
  name, GitHub handle, and date).
-   If you embed images (for example `![](plots/latency.png)`), commit the image
  files too, and check on github.com that the images render.
-   Label AI-assisted content, as required by the course's
  academic integrity policy (see the syllabus).

## Running your code from a clean checkout

So that anyone can reproduce your results from the setup instructions in the
assignment README, test a clean copy. Do this **on your own computer, not on
the course server**: PyTorch is several GB and exceeds the server disk quota.
On the server, use the shared environment instead
(`source /home/coms6998-shared/env.sh`; see [slurm-gpu.md](slurm-gpu.md)).

On your own computer, in your clean copy create a fresh virtual environment,
install from the requirements file, and run your code once:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r code/requirements.txt
```

Then run the command the README tells you to run. If something you needed was
never committed (a helper script, a config file), this is where you will find
out. If your results depend on a GPU, note in your report what hardware you
used.

## Commits

Commit and push regularly while you work, rather than once at the end. A
useful history protects you: if a late change breaks something, you can go
back. Check your history with `git log --oneline` in your clean copy, or in
the commit history on github.com.

## Very important reminder

Submitting and verifying your work is as important as the work itself. Push
early, check on github.com, and do not wait until the last minutes before the
deadline.

### Acknowledgements

This guide was developed by Xurxo Riesco and edited by Phillip Le for Spring
2023, modified by Palash Sharma for Summer 2024, and adapted for COMS 6998 in
Fall 2026.
