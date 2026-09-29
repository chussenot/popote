---
title: Release the crate
description: Publish a new version of the popote crate to crates.io, including the one-time first publish and trusted publishing setup.
type: how-to
status: current
audience: operators
last_reviewed: 2026-09-29
tags: [release, crates-io, rust, ci]
---

# Release the crate

A release puts a new version of the `popote` crate on crates.io and on docs.rs,
with a matching git tag and GitHub Release. After a one-time setup, pushing a
`v*` tag is the whole release: the release workflow checks, publishes and
writes the release notes. Why the workflow publishes with trusted publishing
instead of a stored token: [decision 0005](../decisions/0005-crates-publish-from-ci-with-trusted-publishing.md).

Agents do not run releases. The Bash guard denies `cargo publish` without
`--dry-run` ([harness reference](../reference/harness.md#commands-the-bash-guard-denies)),
so every step that uploads is done by a human.

## Prerequisites

- The toolchain installed (`mise install`) and a clean checkout of an
  up-to-date `main`. `cog bump` refuses to run with uncommitted changes.
- Push access to `chussenot/popote`, including tags.
- For the one-time setup only: a crates.io account that will own the crate.

## First release, once

crates.io only lets you add a trusted publisher to a crate that already
exists, so version 0.1.0 is published by hand with a personal token. The
release workflow cannot publish it, and its run for `v0.1.0` fails; the steps
below account for that.

1. Create the release commit and tag locally:

   ```sh
   mise run release
   ```

   `cog bump --auto` computes `v0.1.0` from the commit history, writes
   `CHANGELOG.md`, sets the crate version (already `0.1.0`), proves the crate
   packages, commits `chore(version): v0.1.0` and creates the annotated tag
   `v0.1.0`. Nothing is pushed.

2. On crates.io, create an API token under Account Settings, API Tokens, with
   the `publish-new` scope. Keep the expiry short; you revoke it in step 6.

3. Log in and publish from the release commit:

   ```sh
   cargo login
   cargo publish --locked -p popote
   ```

   `cargo login` reads the token from standard input and stores it in
   `~/.cargo/credentials.toml`.

4. On crates.io, open the crate's Settings, Trusted Publishing, and add a
   GitHub publisher:

   | Field | Value |
   | --- | --- |
   | Repository owner | `chussenot` |
   | Repository name | `popote` |
   | Workflow filename | `release.yml` |
   | Environment | `release` |

   Every value must match exactly. A mismatch makes the authentication step of
   every later release fail.

5. Push the release commit and the tag:

   ```sh
   git push --atomic --follow-tags origin main
   ```

   `--follow-tags` sends the annotated tag that `mise run release` created
   along with the commit it points to. `--atomic` makes the push all or
   nothing: if `main` on GitHub has moved and rejects the push, the tag is not
   pushed either, so no release starts from a commit that is not on `main`.

   The release workflow runs for `v0.1.0`. It passes the tag check, the
   quality gate and the crates.io authentication step, then fails at Publish
   because version 0.1.0 already exists. This failure is expected. A green
   authentication step confirms that the trusted publisher from step 4 works.

   Because the workflow stopped before its last step, create the GitHub
   Release by hand:

   ```sh
   cog changelog --at v0.1.0 > release-notes.md
   gh release create v0.1.0 --title v0.1.0 --notes-file release-notes.md --verify-tag
   rm -f release-notes.md
   ```

6. Remove the personal token: run `cargo logout`, then revoke the token on
   crates.io under Account Settings, API Tokens. From here on no crates.io
   credential exists outside a running workflow.

7. Optional: in the GitHub repository, open Settings, Environments, `release`
   and add required reviewers. Each release then waits for an approval before
   the job starts. GitHub creates the `release` environment on the first
   workflow run that references it, so it exists after step 5.

## Every later release

1. From a clean, up-to-date `main`, create the release commit and tag:

   ```sh
   mise run release
   ```

   `cog bump --auto` picks the next version from the Conventional Commits since
   the last tag, sets it in `crates/popote/Cargo.toml`, commits and creates an
   annotated `v*` tag.

2. Push the commit and the tag together, as in step 5 of the first release:

   ```sh
   git push --atomic --follow-tags origin main
   ```

3. If the `release` environment has required reviewers, approve the run in the
   Actions tab.

The workflow checks that the tag matches the crate version, runs
`mise run check`, exchanges a GitHub OIDC token for a short-lived crates.io
token, runs `cargo publish`, and creates the GitHub Release from
`cog changelog --at <tag>`.

Whether a direct push to `main` is allowed depends on the branch protection
rules in GitHub, which this repository does not record (unverified). If
`main` only accepts pull requests, merge the release commit through a pull
request with a merge commit or a rebase, not a squash, so the tagged commit
stays in the history of `main`, then push the tag by name with
`git push origin v<version>`, where `v<version>` is the tag `mise run release`
created (for example `v0.2.0`).

## Verify

| Where | What you should see |
| --- | --- |
| `https://crates.io/crates/popote` | The new version listed as the latest |
| `https://docs.rs/crate/popote/latest` | A successful build for the new version. docs.rs queues the build after the publish, so it can lag behind crates.io |
| `https://github.com/chussenot/popote/releases` | A release named after the tag, with the changelog section as its notes |

## If the release workflow fails

Nothing reaches crates.io before the Publish step, so a failure before it
leaves no partial release. Open the failed run in the Actions tab and find
the first red step.

| Failed step | Cause | Fix |
| --- | --- | --- |
| Tag matches the crate version | The tag was created by hand, or `crates/popote/Cargo.toml` changed after `cog bump` | Delete the tag on GitHub and locally (`git push origin :refs/tags/v<version>` and `git tag -d v<version>`, with the failed tag in place of `v<version>`), then release again with `mise run release` so the version and the tag are set together |
| Quality gate | The tagged commit does not pass `mise run check` | Fix it on `main` with a `fix:` commit, then run `mise run release` again. The failed tag stays with no crate version behind it, and the next release takes the next patch number |
| Authenticate to crates.io | The trusted publisher on crates.io does not match the repository, workflow filename or environment, or it was never added | Correct the publisher on crates.io (see step 4 of the first release), then use Re-run jobs on the failed run |
| Publish | The version already exists on crates.io, or crates.io rejected the package | For an existing version, nothing is wrong with the published crate; create the GitHub Release by hand as in step 5 of the first release. Otherwise read the cargo error, fix on `main` and release again |
| GitHub Release | The crate is published but the release notes step failed | Create the GitHub Release by hand as in step 5 of the first release. Do not re-run the job: it would fail at Publish |

Re-running a job uses the same commit and tag, so it only helps when the
cause was outside the repository (crates.io configuration, a network
failure). A cause inside the repository needs a new commit and a new release.
