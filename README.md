# skill-install-workflow

[中文说明](./README.zh-CN.md)

A governance-oriented AI Agent Skill for installing, updating, deduplicating, and validating other Skills in a controlled and reproducible way.

## Why this project exists

As local AI workflows grow, the same Skill can easily end up:

- installed in multiple Agent directories;
- duplicated under different names;
- stored as several conflicting versions;
- detached from its original GitHub source;
- copied instead of linked, making future updates difficult;
- installed without checking whether an equivalent Skill already exists.

`skill-install-workflow` is intended to turn Skill installation from a simple file-copy operation into a governed workflow.

## Design goal

The target workflow is:

```text
Install request
    ↓
Resolve source
    ↓
Stage candidate
    ↓
Validate Skill structure
    ↓
Check exact duplicates
    ↓
Check same-Skill version conflicts
    ↓
Check functional overlap with existing Skills
    ↓
LLM recommendation
    ↓
Risk check
    ↓
Install / update / reject / request approval
    ↓
Register provenance
    ↓
Create consumer links
    ↓
Post-install validation
```

The central idea is simple:

> **The LLM makes semantic decisions; deterministic scripts perform file operations; validation confirms the final state.**

## What the Skill should decide

A candidate Skill should be classified into one of a small number of outcomes:

- `INSTALL_NEW`
- `DO_NOT_INSTALL`
- `UPDATE_EXISTING`
- `MERGE_INTO_EXISTING`
- `KEEP_SEPARATE`
- `REJECT_INVALID`
- `REJECT_HIGH_RISK`
- `SOURCE_VERIFICATION_REQUIRED`

This prevents the user from having to manually compare every similar or duplicated Skill.

## Duplicate and version handling

The workflow should distinguish between:

- **Exact duplicate** — same effective Skill already exists;
- **Same Skill / different version** — compare workflows and capabilities rather than trusting timestamps alone;
- **Near duplicate** — different names, substantially the same role;
- **Functional overlap** — some shared responsibilities, but potentially valid separation;
- **Parent / child** — related but intentionally different layers;
- **Complementary** — separate Skills that belong to the same workflow;
- **Independent** — no meaningful conflict.

The goal is not to minimize the number of Skills. The goal is to keep one clear responsibility per Skill and avoid accidental duplication.

## Provenance and reproducibility

For GitHub-hosted Skills, the workflow is designed to preserve provenance such as:

```text
repository
repository_url
branch
skill_subpath
installed_commit
content_hash
local_modified
```

This makes future update checks and rollback decisions reproducible.

## Safety model

An explicit user request to install a new, independent, low-risk Skill should normally be sufficient authorization to proceed.

The workflow should stop for explicit approval when an operation would:

- replace an existing Skill;
- merge into an existing Skill;
- overwrite local modifications;
- install a high-risk Skill;
- rely on an unverified upstream source.

## Intended environment

This Skill is designed for local AI Agent environments such as:

- Claude Code
- Codex
- DeepSeek Harness
- CC Switch-based Skill management

It is especially useful when multiple Agents share one canonical Skill library through symbolic links.

## Status

This repository is intended to host the reusable `skill-install-workflow` Skill and its supporting validation logic. The implementation may evolve as real installation and update cases are tested.

## Philosophy

> **Skill installation is a governed workflow, not a file-copy operation.**
