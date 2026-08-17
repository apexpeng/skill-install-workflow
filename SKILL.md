---
name: skill-install-workflow
description: |-
  Unified Skill Install Entry Point. MUST use this Skill when the user asks to install, import, add, upgrade, replace, update, or evaluate an AI Agent Skill (Claude Code / Codex / DeepSeek Harness / Agent Skill), or provides a Skill source: a GitHub repository URL, a skill subdirectory URL inside a repo, a local skill directory, a downloaded skill folder, or a skill ZIP. Trigger phrases include: install skill / skill install / install this skill / import skill / add skill / 安装 Skill / 安装一个 Skill / 帮我装这个 Skill / 导入 Skill / 添加 Skill / 新增 Skill / 从 GitHub 安装 Skill / 安装这个 GitHub Skill / 安装这个 repo 里的 Skill / update skill / upgrade skill / 更新 Skill / can this skill be installed / 这个 Skill 能不能装 / is this skill a duplicate / 这个 Skill 和现有 Skill 重复吗. Do NOT trigger on general GitHub / code / npm install / Python package / software installation requests that are not about AI Agent Skills.
whenToUse: |-
  User expresses intent to install, import, add, upgrade, replace, update, or evaluate an AI Agent Skill, or hands over a Skill source (GitHub URL / repo subpath URL / local dir / zip). Explicit invocation: use skill-install-workflow.
metadata:
  class: infrastructure
  governance: true
---

# Skill Install Workflow — Unified Skill Installation & Governance Entry Point

This Skill is the single **Skill Install Entry Point** on the user machine. When the user says "install this Skill <URL/path>", this Skill takes over the whole flow: review → judge → actually install → create consumer links → register provenance → validate → report.

It is **not** an audit-report generator, **not** advice-only, and **not** "go open CC Switch and do it manually".

## 1. Platform Support

The Skill and its scripts run on **Windows** (PowerShell 5.1 or PowerShell Core 7+) and **macOS** (PowerShell Core 7+, `pwsh`).

- All paths are derived from `$HOME` — no hardcoded user paths. The same scripts work on both platforms without edits.
- Scripts auto-detect the platform (`$env:OS -eq 'Windows_NT'` → Windows; otherwise Unix/macOS). No manual configuration.
- **Symlink policy (both platforms)**: per-skill `SymbolicLink` only. **Copy is never used as a fallback.** If link creation fails, stop and report.
  - Windows: `New-Item -ItemType SymbolicLink` (Developer Mode enabled), fallback `mklink /D`, then `mklink /J` (junction).
  - macOS: `New-Item -ItemType SymbolicLink` or `ln -s` (no privileges required).
- On macOS, run scripts with `pwsh -NoProfile -ExecutionPolicy Bypass -File <script>`. On Windows, either `powershell` or `pwsh` works.

## 2. Architecture Constants (do not redesign)

```text
Canonical root (single source of truth for Skill entities):
    Windows: $HOME\.cc-switch\skills          (e.g. C:\Users\<user>\.cc-switch\skills)
    macOS:   $HOME/.cc-switch/skills          (e.g. /Users/<user>/.cc-switch/skills)

Consumers (per-skill SymbolicLink → canonical):
    Claude:  $HOME/.claude/skills
    Codex:   $HOME/.codex/skills
    DSH/shared: $HOME/.agents/skills

Manifest (single provenance store):   $HOME/.cc-switch/skill-management/skills-manifest.json
Updater:                              $HOME/.cc-switch/skill-management/update-skills.ps1
Staging (install transactions only):  $HOME/.cc-switch/skill-management/staging
Backups:                              $HOME/.cc-switch/backups
This Skill's scripts:                 <canonical>/skill-install-workflow/scripts
```

- Consumer directories must contain **only per-skill SymbolicLinks** pointing at canonical. **Never copy entity copies**, **never link a whole consumer root**.
- **Never modify** `$HOME/.codex/skills/.system` or `$HOME/.codex/skills/_shared` (Codex system content) on either platform.
- Do not create a second manifest; do not recreate/delete `$HOME/.agents/.skill-lock.json` (owned by CC Switch).
- Run helper scripts with `pwsh`/`powershell -NoProfile -ExecutionPolicy Bypass -File <script>`. The LLM makes the judgments; PowerShell performs the deterministic operations.

## 3. Authorization Rules

A user's explicit "install" intent (e.g., "install this Skill: <URL>") is basic install authorization.

When the check result is **new Skill + no name conflict + no functional duplication + low risk**: **install directly without asking again**.

Interrupt and request user approval **only** in these cases:

- **A. Overwrite existing Skill** — Same Skill / Different Version requiring replacement of canonical.
- **B. Merge suggestion** — Near Duplicate requiring modification of an existing Skill's content.
- **C. Possible loss of local customizations** — existing Skill `local_modified = true`.
- **D. High-risk Skill** — credentials / tokens / SSH keys / browser credentials / bulk deletion / unrestricted recursive modification / uploading sensitive data.
- **E. Cannot determine the correct upstream** (supply-chain risk).

No meaningless confirmation steps beyond these.

## 4. Install Pipeline (run in order for every candidate)

```text
INSTALL REQUEST → RESOLVE SOURCE → STAGE → STRUCTURE CHECK → EXACT DUPLICATE CHECK
→ VERSION CHECK → FUNCTIONAL OVERLAP CHECK → LLM DECISION → RISK CHECK
→ INSTALL / STOP → REGISTER → ENABLE → VALIDATE
```

### Step 1 — Resolve Source
Inputs: GitHub repo URL / skill subdirectory URL inside a repo / local Skill path / downloaded Skill folder / ZIP.
Run: `scripts/resolve-candidate.ps1 -Source "<input>"` → resolves `name / source_type / repository / repository_url / branch / skill_subpath / commit`.
- GitHub monorepo: identify the **actual Skill subdirectory** (the dir containing SKILL.md). Do **not** treat the whole repository as one Skill. If the repo contains multiple candidates, the script lists them; the LLM picks one and re-runs with `-SubPath`.

### Step 2 — Staging
The candidate always goes to `$HOME/.cc-switch/skill-management/staging/<name>` first — **never directly into canonical**. Clean staging after the install completes.

### Step 3 — Structure Check
Verify: SKILL.md exists; name is recognizable (kebab-case); description exists; referenced scripts/references exist (check local files referenced by SKILL.md). Clearly broken → `INSTALL = STOP` with the reason.

### Step 4 — Exact Duplicate
Run: `scripts/inspect-existing.ps1 -CandidateName <name> -CandidateHash <hash>`.
Compare only against canonical entities; **do not** treat `.claude/.codex/.agents` SymbolicLinks as independent Skills.
If SKILL.md hash / core files / actual workflow are identical → `DO_NOT_INSTALL`, tell the user "an identical Skill already exists: <name>", and finish.

### Step 5 — Same Skill / Different Version
When the same name, same upstream, or an obviously identical Skill exists at a different version: **the LLM reads the meaningful diff** (description / trigger / workflow / tools / permissions / scripts / references / safety boundaries + Git commit + local modifications) and concludes: `UPDATE_EXISTING` / `KEEP_CURRENT` / `MERGE_REQUIRED` / `KEEP_AS_SEPARATE_FORK`.
Never say "two versions found, user compares". Never judge by LastWriteTime alone.

### Step 6 — Different Name / Same Function (core capability)
Even with a different name, run candidate recall with `scripts/inspect-existing.ps1 -Keywords "<keywords>"` and deep-compare only the most relevant existing Skills (do not re-read all Skills every time).
Classify by `purpose / trigger / workflow / inputs / outputs / tools / permissions / safety boundaries`:
`Exact Duplicate / Near Duplicate / Functional Overlap / Parent-Child / Complementary / Independent`.
- **Near Duplicate**: recommend `MERGE_INTO_EXISTING` with Target, the candidate's new capabilities X/Y, and the duplicate workflow to discard. **Stop and wait for user approval** of the actual merge (V1 delivers a merge plan only, no automatic complex content merge).
- **Functional Overlap**: if triggers / workflows / inputs-outputs differ, even within the same domain → `KEEP_SEPARATE`. Do not force merges to reduce Skill count.

### Step 7 — Risk Check
Semantically judge whether the candidate: deletes/moves files, bulk-modifies, recursively scans, executes shell, downloads external code, calls APIs, reads credentials/tokens/SSH keys/browser data, uploads, runs in background, loops/polls. Risk: `NONE / LOW / MEDIUM / HIGH`. HIGH → require user approval (interrupt case D). No keyword panic.

### Step 8 — LLM Decision
Only one of these tokens:

```text
INSTALL_NEW                    new Skill, install directly
DO_NOT_INSTALL                 duplicate / no value
UPDATE_EXISTING                overwrite-upgrade existing (needs approval, A)
MERGE_INTO_EXISTING            suggest merge into existing (needs approval, B)
KEEP_SEPARATE                  keep independent (e.g. Functional Overlap)
REJECT_INVALID                 invalid / broken structure
REJECT_HIGH_RISK               high risk
SOURCE_VERIFICATION_REQUIRED   cannot confirm upstream (needs approval, E)
```

No proliferation of fuzzy states.

### Step 9 — Actual Install (when INSTALL_NEW)
- Entity goes **only** to `$HOME/.cc-switch/skills/<skill-name>`; **never** copy entities into `.claude/.codex/.agents`.
- GitHub Skill: preserve provenance (repository / repository_url / branch / skill_subpath / installed_commit); monorepo: install only the needed subtree; no requirement to keep `.git`.
- Local Skill: `source_type = local`; **never** substitute a GitHub repo just because a name matches.
- Run: `scripts/install-canonical.ps1 -StagingPath <staging> -Name <name>` (auto-backs-up any existing version to backups first).

### Step 10 — Register (manifest)
Run: `scripts/update-manifest.ps1 -Name <name> -EntryJson '<json>'`.
- Maintain: name / canonical_path / source_type / repository / repository_url / branch / skill_subpath / installed_commit / content_hash / local_modified / aliases.
- The script validates the manifest schema (version + skills + canonical_root) before writing; never overwrite the structure on assumption.
- Never create a second manifest.

### Step 11 — Enable (consumer selection)
Recommend consumers by Skill tools, agent-specific instructions, purpose, and compatibility:
- Generic Agent Skill → default enable Claude + Codex + DSH.
- Clearly Claude-only → Claude only; clearly Codex-only → Codex only.
- Unknown → at least enable **the agent currently invoking this Skill**; list others as recommended consumers.
Run: `scripts/link-consumers.ps1 -Name <name> -Consumers claude,codex,agents`.
- Must be `SymbolicLink`; **Copy is forbidden as fallback**; if SymbolicLink creation fails → stop and report, never copy.
- Never touch `$HOME/.codex/skills/.system` and `_shared`.

### Step 12 — Validate
Run: `scripts/validate.ps1 -Name <name>`.
Must confirm: canonical entity dir + SKILL.md exists; each consumer link LinkType=SymbolicLink, Target=canonical, Target exists; SKILL.md hash read through the link equals canonical; no accidental entity copies in `.claude/.codex/.agents`; broken links = 0.

### Step 13 — `.agents/.skill-lock.json` consistency (read-only)
If this install touches the `.agents` consumer: read-only check of `$HOME/.agents/.skill-lock.json` against reality (e.g., lock does not record the Skill but the link exists). Report contradictions; **never modify the lock without approval**.

## 5. Output Formats (keep very short)

New install:
```text
Skill installed: xxx

Decision: INSTALL_NEW
Source: owner/repo @ commit
Canonical: OK
Claude: enabled
Codex: enabled
DSH: enabled
Manifest: updated
Validation: PASS
```

Duplicate:
```text
Skill not installed: xxx

Decision: DO_NOT_INSTALL
Reason: Exact duplicate of xxx
Existing canonical:
<canonical>/xxx
```

Upgrade / merge suggestions: output per decision with Existing/Candidate/Recommendation/Key changes, and note "awaiting your approval".

## 6. Self-Update Protection

If the candidate is `skill-install-workflow` itself (version conflict/update): **never self-overwrite directly**. Must: diff → LLM review → user approval → backup → update → validation.

## 7. Prohibitions

- No large audits: each install reviews only the candidate + recalled related Skills.
- Never hand the final judgment back to the user (the LLM compares and recommends; the user approves only high-impact decisions).
- Never copy entities into consumers; never modify Codex system dirs; never create a second manifest; never modify `.agents/.skill-lock.json`.
- Do not treat generic "GitHub / npm / Python / software installation" as a trigger for this Skill.
