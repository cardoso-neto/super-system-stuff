# Shared source repositories

These helpers come from Genesis's `/usr/local/bin/add-src` and `update-src`.
They use Bash, Git, `flock`, `realpath`, and GNU `find` on Linux.

- `/src/bare/<org>/<repo>` owns Git objects and linked worktree metadata.
- `/src/read/<org>/<repo>` is a detached, read-only reference checkout.
- T3 projects point to the reference checkout and create their own editing worktrees.
- Services that write files use a linked worktree under the service owner's home directory.

Install both executable files together, for example in `/usr/local/bin`.
Create writable `/src/bare` and `/src/read` directories for the source maintainer first.
Run the helpers as that maintainer.

```sh
add-src org/repo
add-src git@github.com:org/repo.git
update-src org/repo
```

Schedule `update-src` without arguments hourly to discover every bare repository under `/src/bare`.
It fetches origin, prunes remote tracking refs, and advances reference checkouts to `origin/master`.
Repositories without master use origin's default branch.
Override a repository with `git --git-dir=/src/bare/org/repo config src.referenceBranch <branch>`.
Local branch refs are not advanced; base new worktrees on `origin/master` or the reference checkout's commit.

Both helpers share a lock.
A scheduled update exits if the lock is busy; explicit repository updates wait.
Updates refuse reference checkouts with tracked changes, untracked or ignored files, an attached branch, an unrelated repository, or a history that cannot fast-forward.
Reference checkout commands disable hooks for that command only.
Other worktrees retain their hooks.

`add-src` creates `/src/git-trust.config` with explicit safe-directory entries for each bare repository and reference checkout, then includes it in the maintainer's global Git configuration.
Other users need to include that trust file in their own Git configuration.
The helpers grant group write access to bare repositories; provision their ownership and group separately.

The helpers do not migrate existing clones, initialize git-annex, or download annex payloads.
For annex repositories, preserve the existing annex store before use.
When a common annex object store exists, new reference worktrees link their administrative annex directory to the common store and use a `.git` directory symlink.
This lets tracked annex symlinks resolve without changing annex configuration or the repository UUID.
A normal Git clone alone does not provide annex content.
Git-annex worktrees may use a `.git` directory symlink; the updater accepts this and checks its common Git directory before updating.

For isolated checks, set `SRC_BARE_ROOT`, `SRC_REFERENCE_ROOT`, `SRC_TRUST_CONFIG`, and `SRC_UPDATE_LOCK` to temporary paths.
