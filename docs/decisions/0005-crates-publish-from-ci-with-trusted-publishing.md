---
title: Crates publish from CI with trusted publishing
description: Why the popote crate is published by the release workflow on a v* tag with crates.io trusted publishing, and what that costs.
type: decision
status: current
audience: everyone
last_reviewed: 2026-09-29
tags: [decisions, release, crates-io, ci, security]
---

# Crates publish from CI with trusted publishing

**Status:** accepted
**Date:** 2026-09-29

## Context

The repository now contains a library crate, `popote`, meant for crates.io. A
crates.io publish is irreversible: a version can be yanked but never replaced
or deleted. Whoever holds a publish credential can push any code under the
crate's name, and several coding agents work in this checkout. The release
needs to publish only code that passed the quality gate, with a version that
matches its tag, and without a long-lived credential that an agent, a
workstation or a leaked log could expose.

## Decision

A `v*` tag, created by `mise run release` (`cog bump --auto`), triggers
`.github/workflows/release.yml`. The job runs in the `release` GitHub
environment. It refuses a tag that differs from the crate version, runs
`mise run check`, then uses `rust-lang/crates-io-auth-action`, pinned by
commit (v1.0.5), to exchange a GitHub OIDC token for a crates.io token that
expires when the job ends. It runs `cargo publish` with that token and creates
the GitHub Release from `cog changelog --at <tag>`. crates.io accepts the
token only from the repository, workflow file and environment registered as
the crate's trusted publisher. Agents are kept out of the path: the Bash guard
denies `cargo publish` without `--dry-run`.

## Alternatives

- **A long-lived `CARGO_REGISTRY_TOKEN` repository secret.** Works from the
  first version, with no manual step. Rejected because the token is valid
  until someone revokes it, is readable by any workflow that can reference
  the secret, and must be rotated by hand. A leak publishes as the owner with
  no binding to this repository or workflow.
- **Publishing from a workstation.** No CI to configure. Rejected because it
  depends on the maintainer's local state: an uncommitted change or an
  unpushed commit can ship, the gate is only as reliable as the person running
  it, and a personal token sits in `~/.cargo/credentials.toml` on a machine
  where agents run commands.

## Consequences

- No crates.io credential is stored anywhere. A publish needs a push of a `v*`
  tag to this repository, and each published version corresponds to a tagged
  commit that passed the gate in CI.
- The first version is published by hand. crates.io only allows a trusted
  publisher on a crate that exists, so 0.1.0 goes out with a personal token,
  revoked afterwards, and the workflow run for `v0.1.0` fails at Publish. The
  sequence is in [Release the crate](../how-to/release-the-crate.md#first-release-once).
- The trusted publisher configuration lives on crates.io, outside the
  repository. Renaming `release.yml`, renaming the `release` environment or
  moving the repository breaks authentication until the publisher is updated.
- The auth action mints publish credentials, so it is pinned to a commit SHA,
  not a tag that could be moved. Upgrading it is a deliberate edit of the SHA.
- The `release` environment is the place for a human gate: required reviewers
  in the GitHub settings make each publish wait for approval. That setting is
  in GitHub, not in the repository.
- Revisit if crates.io trusted publishing stops supporting GitHub
  environments, if releases need to publish several crates in dependency
  order, or if the manual first publish recurs for each new crate often enough
  to automate differently.
