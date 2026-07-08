---
description: Fix all open review comments on a storypad PR, resolve each thread, commit as a new commit, and push
argument-hint: "<PR number or full GitHub PR URL>"
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# Fix PR Review Comments

Fix all open review comments on a pull request, resolve each thread, commit the fixes as a new commit, and push.

## Arguments

`$ARGUMENTS` — PR number or full GitHub PR URL (e.g. `123` or `https://github.com/theachoem/storypad/pull/123`)

## Steps

1. **Parse PR number** from `$ARGUMENTS` (strip URL if needed, extract the trailing integer).

2. **Confirm repo** — this command targets `theachoem/storypad` only:

   ```
   git remote get-url origin
   ```

   If the current repo doesn't match, stop and ask the user for clarification.

3. **Checkout the PR branch**:

   ```
   gh pr checkout {number}
   ```

   Before switching, run `git status` — if there are uncommitted changes, stash them (`git stash -u`) rather than discarding.

4. **Fetch open review comments** and their thread IDs:

   ```
   gh api repos/theachoem/storypad/pulls/{number}/comments \
     --jq '.[] | {id, user: .user.login, body, path, line}'
   ```

   Then fetch thread node IDs via GraphQL:

   ```
   gh api graphql -f query='{ repository(owner:"theachoem", name:"storypad") {
     pullRequest(number: {number}) {
       reviewThreads(first: 50) {
         nodes { id isResolved comments(first:1) { nodes { author { login } body } } }
       }
     }
   }}'
   ```

5. **Fix each comment** — read the flagged file+line, apply the suggested change using Edit. Group fixes by file. While fixing, follow this project's critical rules (see `CLAUDE.md`):
   - Never put a condition inside `tr()` → use `cond ? tr("a") : tr("b")`, not `tr(cond ? "a" : "b")`.
   - Never use `Icons.*` or `CupertinoIcons.*` → use `SpIcons.*`.
   - Keep Provider + ChangeNotifier / MVVM structure intact.
   - Use `adaptive_dialog` for any dialog changes.
   - If a fix touches an in-progress feature's design, update the matching `docs/implementations/<feature>/plan.md` rather than leaving it stale.

   Sort every comment into exactly one bucket before moving on — don't leave any comment unclassified:
   - **Real issue, fixable** → apply the code change (this section).
   - **False positive** (you've verified the flagged code is actually correct — e.g. checked the installed package version, ran `flutter analyze`, or otherwise confirmed there's no bug) → no code change; instead reply on the thread explaining why with the evidence, then resolve it in step 9. Don't leave a verified-non-issue thread open indefinitely just because nothing was edited.
   - **Genuine design decision** (a real tradeoff only the user can make, not something you can verify as right or wrong) → flag it to the user in the final report and leave the thread unresolved. This is the only bucket that stays open.

6. **Format and analyze** the changed Dart files, then fix any remaining issues manually:

   ```
   ./bin/format
   flutter analyze
   ```

   If offenses remain, fix them manually before proceeding.

7. **Run relevant tests** for the changed files (see `docs/development/testing-basics.md`) and confirm they pass:

   ```
   flutter test <changed test paths>
   ```

8. **Stage fixed files and commit as a new commit** — never amend. Amending rewrites a commit that may already be pushed/open as a PR and forces a rewritten history the user didn't explicitly ask for in this run; a plain new commit is always safe to add on top:

   ```
   git add <changed files>
   git commit -m "Address PR review comments"
   ```

9. **Reply to false positives, then resolve fixed + false-positive threads** — do this BEFORE pushing so that CI (which may block on unresolved comments) sees threads resolved when the push triggers it:

   For each **false positive**, first post a reply on the original review comment explaining why no change was needed (cite the version/analyzer output/evidence you checked):

   ```
   gh api repos/theachoem/storypad/pulls/{number}/comments \
     -f body="<explanation>" -F in_reply_to={original_comment_id}
   ```

   Then, for every thread in the **fixed** and **false positive** buckets (not the design-decision bucket), resolve it:

   ```
   gh api graphql -f query='mutation { resolveReviewThread(input:{threadId:"{id}"}) { thread { id isResolved } } }'
   ```

   Confirm every thread you intended to resolve returns `isResolved: true` before proceeding to the push step. Threads in the design-decision bucket are the only ones that should remain unresolved — call them out explicitly in the final report so they don't get mistaken for stragglers.

10. **Push** — only after all threads are confirmed resolved:

    ```
    git push
    ```

    If no upstream is set, add `--set-upstream origin <branch-name>`. No `--force`/`--force-with-lease` is needed since this is a new commit, not a rewrite — unless the remote branch has independently diverged, in which case stop and ask the user rather than force-pushing.

11. Report: list each resolved thread (author, file, fix applied) and confirm the push succeeded.

## Notes

- Resolve a thread only when you've fixed the code OR verified (with cited evidence) that the flagged code is already correct — never resolve without one of those two.
- If a comment requires a design decision rather than a simple fix, flag it to the user instead of resolving it — that's the only case that should stay unresolved.
- Don't leave a verified false positive unresolved just because you didn't touch code — reply with your reasoning, then resolve it, so nothing lingers on GitHub without an explanation.
- I may pass some test errors copied from CI runs — fix them and ensure tests pass before pushing.
- This is a single Flutter repo with no submodules or worktrees — all commands run from the repo root.
- Always commit fixes as a new commit, never `git commit --amend`. Amending rewrites history that may already be shared (open PR, pushed branch) and requires a force-push; a new commit keeps history additive and only needs a regular push.
