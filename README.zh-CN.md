<p align="center">
  <img src="assets/banner.zh-CN.svg" width="100%" alt="skill-install-workflow 中文横幅">
</p>

<div align="center">

[![AI Agent Skill](https://img.shields.io/badge/AI-Agent%20Skill-6C63FF?style=flat-square)](#)
[![Claude Code](https://img.shields.io/badge/Claude-Code-D97757?style=flat-square)](#)
[![Codex](https://img.shields.io/badge/OpenAI-Codex-111111?style=flat-square)](#)
[![Windows PowerShell](https://img.shields.io/badge/Windows-PowerShell-0078D4?style=flat-square)](#)
[![Status](https://img.shields.io/badge/status-active-2EA44F?style=flat-square)](#)

[English](./README.md) · **简体中文**

</div>

---

## 📌 概述

随着本地 AI Agent 生态不断扩展，同一个 Skill 很容易被重复安装、分叉成多个版本、失去 GitHub 来源，或者与另一个不同名称的 Skill 出现功能重叠。

`skill-install-workflow` 把 Skill 安装变成一条可治理的生命周期：

> **识别 → 比较 → 决策 → 安装 → 链接 → 登记 → 验证**

目标不是让 Skill 越多越好，而是让整个 Skill 生态保持**干净、可追溯、可维护、可复现**。

## 📦 安装

### 推荐：使用 CC Switch 统一管理 Skill

对于同时使用 Claude Code、Codex、DeepSeek Harness 等多个 Agent 的本地环境，推荐由 **CC Switch 统一管理 Skill**，而不是分别向各 Agent 目录复制多份实体 Skill。CC Switch 可以集中保存 Skill 源，并通过软链接分发到不同 Agent。

使用 CC Switch 官方 Deep Link 导入本 Skill：

**Windows PowerShell**

```powershell
Start-Process "ccswitch://v1/import?resource=skill&name=skill-install-workflow&repo=apexpeng/skill-install-workflow&branch=main"
```

**macOS**

```bash
open "ccswitch://v1/import?resource=skill&name=skill-install-workflow&repo=apexpeng/skill-install-workflow&branch=main"
```

也可以直接打开：

```text
ccswitch://v1/import?resource=skill&name=skill-install-workflow&repo=apexpeng/skill-install-workflow&branch=main
```

导入后，在 **CC Switch → Skills** 中选择需要使用该 Skill 的 Agent 并完成安装/同步。对于多 Agent 环境，推荐采用 **CC Switch 内置存储 + SymbolicLink（软链接）同步**。

### 三个 Skill 的推荐安装顺序

```text
1. skill-install-workflow
        ↓
2. r-data-lineage-plotting
        ↓
3. write-human-r-code
```

推荐理由：

1. **先安装 `skill-install-workflow`**：先建立后续 Skill 的审查、去重、版本判断、安装、来源登记与验证治理入口。
2. **再安装 `r-data-lineage-plotting`**：先建立科研 R 项目的数据血缘、目录职责与可复现性基础。
3. **最后安装 `write-human-r-code`**：在数据血缘基础上进一步约束 R 代码的可读性、科研透明性和重构方式；当任务涉及数据文件或分析对象时，它会与 `r-data-lineage-plotting` 配合使用。

## 🔄 工作流程

```mermaid
flowchart LR
    A["1 · 安装请求"] --> B["2 · 解析来源"]
    B --> C["3 · 暂存与检查"]
    C --> D["4 · 比较"]
    D --> E["5 · LLM 决策"]
    E --> F["6 · 安装与链接"]
    F --> G["7 · 登记来源"]
    G --> H["8 · 完整验证"]
```

### 三层职责

| 层级 | 职责 |
|---|---|
| 🧠 **LLM** | 理解用途、版本差异、功能重叠与风险 |
| ⚙️ **工作流 / 脚本** | 执行确定性的安装、链接和元数据操作 |
| ✅ **验证** | 检查 canonical、Hash、链接和 provenance |

## 🧭 决策模型

| Decision | 含义 |
|---|---|
| 🟢 `INSTALL_NEW` | 安装真正新的 Skill |
| 🔴 `DO_NOT_INSTALL` | 已有能力覆盖，不重复安装 |
| 🔵 `UPDATE_EXISTING` | 候选版本更适合作为主版本 |
| 🟣 `MERGE_INTO_EXISTING` | 吸收有效能力，不新增重复 Skill |
| 🟡 `KEEP_SEPARATE` | 领域相近，但职责不同 |
| ⛔ `REJECT_INVALID` | Skill 残缺或结构无效 |
| 🛡️ `REJECT_HIGH_RISK` | 风险超过可接受边界 |
| 🔎 `SOURCE_VERIFICATION_REQUIRED` | upstream 来源需要进一步确认 |

## 🔬 真正比较的是什么？

这个工作流不会只根据文件夹名、Hash 或时间戳做判断。

它会实际比较：

```text
用途
trigger
workflow
输入 / 输出
工具
权限
安全边界
scripts / references
upstream provenance
本地修改
```

并区分：

```mermaid
flowchart TD
    A["候选 Skill vs 现有 Skill"] --> B["完全重复"]
    A --> C["同 Skill / 不同版本"]
    A --> D["Near Duplicate"]
    A --> E["功能重叠"]
    A --> F["Parent / Child"]
    A --> G["互补"]
    A --> H["独立"]
```

## 🏗 推荐架构

```mermaid
flowchart TD
    C["📚 Canonical Skill Library"] -. SymbolicLink .-> A["Claude Code"]
    C -. SymbolicLink .-> B["Codex"]
    C -. SymbolicLink .-> D["DeepSeek Harness"]
```

目标不是维护多份实体副本，而是：

```text
一个 Skill
+ 一个 canonical source
+ 一份 provenance
+ 多个 Agent consumer
```

## 🧾 来源追踪

GitHub Skill 应持续保留来源信息：

```yaml
name: example-skill
repository: owner/repository
branch: main
skill_subpath: skills/example-skill
installed_commit: abc123
content_hash: ...
local_modified: false
```

这样未来才能可靠完成更新检查、回滚和审计。

## 🛡 安全与审批边界

用户明确说“安装这个 Skill”时，对于**新、独立、低风险** Skill，不需要反复确认。

只有以下情况进入人工审批：

- 替换已有 canonical Skill；
- 合并两个 Skill；
- 可能覆盖本地修改；
- 高风险 Skill；
- upstream 来源无法可靠确认。

## 💬 理想交互

```text
用户：
安装这个 Skill：
https://github.com/example/example-skill

AI：
Decision: UPDATE_EXISTING

已有版本：abc123
候选版本：def456

模型判断：
- trigger 更准确
- 旧版安全边界得到保留
- 未检测到本地修改

由于需要替换已有 canonical Skill，等待批准。
```

## ✨ 核心特性

- 🔁 完全重复检测
- 🧬 多版本语义比较
- 🧠 功能重叠判断
- 🛡 风险门控
- 🔗 适配 SymbolicLink 的多 Agent 共享
- 🧾 Git provenance 追踪
- ✅ 安装后完整性验证

## 🤝 面向

Claude Code · OpenAI Codex · DeepSeek Harness · CC Switch · 本地多 Agent Skill 环境

---

> **Skill 安装不是一次文件复制，而是一项生命周期决策。**
