<p align="center">
  <img src="assets/banner.svg" width="100%" alt="skill-install-workflow banner">
</p>

<div align="center">

# 🧩 skill-install-workflow

**Govern AI Skills before they govern your agents.**

[![AI Skill](https://img.shields.io/badge/AI-Agent%20Skill-6C63FF?style=flat-square)](#)
[![Claude Code](https://img.shields.io/badge/Claude-Code-D97757?style=flat-square)](#)
[![Codex](https://img.shields.io/badge/OpenAI-Codex-111111?style=flat-square)](#)
[![Windows](https://img.shields.io/badge/Windows-PowerShell-0078D4?style=flat-square)](#)
[![Status](https://img.shields.io/badge/status-active-success?style=flat-square)](#)

**English** · [简体中文](./README.zh-CN.md)

</div>

---

## 🌱 Why?

Installing an AI Skill looks simple:

```text
Download → Copy → Done
```

Until your local environment becomes:

```text
~/.claude/skills/
~/.codex/skills/
~/.agents/skills/
~/.cc-switch/skills/

skill-a
skill-a-new
skill-a-v2
another-skill-doing-the-same-thing
...
```

Then the real questions begin:

> Which copy is the real one?  
> Which version is better?  
> Is this capability already installed under another name?  
> Will an update overwrite local changes?

`skill-install-workflow` turns Skill installation from a file-copy operation into a **governed lifecycle decision**.

## 🧠 Core idea

> **LLM decides. Deterministic tools execute. Validation verifies.**

```mermaid
flowchart LR
    A["📦 Candidate Skill"] --> B["🔎 Resolve source"]
    B --> C["🧪 Stage & inspect"]
    C --> D["🔁 Duplicate check"]
    D --> E["🧬 Version comparison"]
    E --> F["🧠 Functional analysis"]
    F --> G{"LLM decision"}
    G -->|Install| H["📥 Canonical install"]
    G -->|Update| I["♻️ Update existing"]
    G -->|Merge| J["🧩 Merge proposal"]
    G -->|Reject| K["⛔ Stop"]
    H --> L["🔗 Consumer links"]
    I --> L
    L --> M["🧾 Provenance"]
    M --> N["✅ Validation"]
```

## 🎯 Explicit decisions

| Decision | Meaning |
|---|---|
| `INSTALL_NEW` | Install a genuinely new Skill |
| `DO_NOT_INSTALL` | Existing capability already covers it |
| `UPDATE_EXISTING` | Candidate is a better version |
| `MERGE_INTO_EXISTING` | Absorb useful capabilities without adding another Skill |
| `KEEP_SEPARATE` | Similar domain, different responsibility |
| `REJECT_INVALID` | Incomplete or malformed Skill |
| `REJECT_HIGH_RISK` | Risk exceeds the accepted boundary |
| `SOURCE_VERIFICATION_REQUIRED` | Upstream provenance is uncertain |

## 🔬 More than filename matching

The workflow compares:

```text
purpose
trigger
workflow
inputs / outputs
tools
permissions
safety boundaries
scripts / references
upstream provenance
```

and distinguishes:

```mermaid
flowchart TD
    A["Candidate vs Existing"] --> B["Exact Duplicate"]
    A --> C["Same Skill / Different Version"]
    A --> D["Near Duplicate"]
    A --> E["Functional Overlap"]
    A --> F["Parent / Child"]
    A --> G["Complementary"]
    A --> H["Independent"]
```

## 🏗 Recommended architecture

```mermaid
flowchart TD
    C["📚 Canonical Skill Library"] -. SymbolicLink .-> A["Claude Code"]
    C -. SymbolicLink .-> B["Codex"]
    C -. SymbolicLink .-> D["DeepSeek Harness"]
```

The goal is:

```text
one Skill
+ one canonical source
+ one provenance record
+ multiple Agent consumers
```

## 🔗 Provenance matters

A GitHub-installed Skill should remain traceable:

```yaml
name: example-skill
repository: owner/repository
branch: main
skill_subpath: skills/example-skill
installed_commit: abc123
content_hash: ...
local_modified: false
```

That makes future updates, rollback and auditing reproducible.

## 🛡 Safety gate

A new independent low-risk Skill should install without redundant confirmation. Approval is required when an operation would:

- replace an existing Skill;
- merge workflows;
- overwrite local modifications;
- introduce high-risk behavior;
- rely on an unverified source.

## 💬 Intended experience

```text
User:
Install this Skill:
https://github.com/example/example-skill

Agent:
Decision: UPDATE_EXISTING

Existing:  example-skill @ abc123
Candidate: example-skill @ def456

Why:
- more precise trigger
- existing safety boundary retained
- no local modifications detected

Approval required because this replaces the canonical version.
```

## 🤝 Designed for

- Claude Code
- OpenAI Codex
- DeepSeek Harness
- CC Switch
- local multi-agent Skill environments

## 🧭 Philosophy

> **Skill installation is not a file-copy operation. It is a lifecycle decision.**
