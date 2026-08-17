# skill-install-workflow

A governance workflow for installing, updating, validating, and maintaining AI Agent Skills.

## Overview

As AI Agent workflows become increasingly complex, Skills are often installed repeatedly across different agents, resulting in:

- duplicated Skills;
- conflicting versions;
- lost Git provenance;
- uncontrolled updates;
- inconsistent environments.

`skill-install-workflow` transforms Skill installation from a simple file operation into a reproducible governance workflow.

## Core Philosophy

> LLM decides. Workflow executes. Validation verifies.

The LLM is responsible for semantic judgment:

- Is this Skill new or duplicated?
- Should two Skills be merged?
- Is an update safe?
- Does this Skill overlap with existing capabilities?

Deterministic scripts are responsible for:

- installation;
- file operations;
- symbolic links;
- manifest updates;
- validation.

## Workflow

```text
Install request
      ↓
Source identification
      ↓
Skill staging
      ↓
Structure validation
      ↓
Duplicate detection
      ↓
Version comparison
      ↓
Functional overlap analysis
      ↓
LLM recommendation
      ↓
Risk assessment
      ↓
Installation
      ↓
Provenance registration
      ↓
Validation
```

## Decision Types

The workflow produces explicit decisions:

- INSTALL_NEW
- DO_NOT_INSTALL
- UPDATE_EXISTING
- MERGE_INTO_EXISTING
- KEEP_SEPARATE
- REJECT_INVALID
- REJECT_HIGH_RISK
- SOURCE_VERIFICATION_REQUIRED

## Supported Environments

Designed for:

- Claude Code
- Codex
- DeepSeek Harness
- CC Switch based Skill management

## Design Principles

- One Skill, one canonical source.
- Avoid duplicated installations.
- Preserve Git provenance.
- Prefer symbolic linking over copying.
- Separate AI reasoning from deterministic execution.

## Status

This project provides a reusable framework for sustainable AI Skill management.
