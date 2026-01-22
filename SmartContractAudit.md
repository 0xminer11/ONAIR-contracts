# AUDIT_REPORT.md

## 1. Overview

This document summarizes a static analysis of the AIR protocol contracts using Slither, with a focus on contract complexity, ERC standard compliance, and issue severity distribution.

The scope includes 13 in-repo contracts and 26 dependency contracts, covering ERC20 / ERC2612 token logic and supporting protocol components.

***

## 2. Scope and Metrics

**Project-wide statistics**

- Total number of contracts in source files: **13**
- Number of contracts in dependencies: **26**
- Source lines of code (SLOC) in source files: **357**
- Source lines of code (SLOC) in dependencies: **2160**
- Number of assembly lines: **0**
- Number of optimization issues: **0**
- Number of informational issues: **67**
- Number of low issues: **6**
- Number of medium issues: **9**
- Number of high issues: **1**
- ERCs implemented: **ERC20, ERC2612**

These metrics indicate a relatively small core codebase, no inline assembly, and no compiler-level optimization flags raised, which simplifies review and reduces low-level attack surface.

***

## 3. Contract Inventory

### 3.1 Contract summary

| Contract | \# Functions | ERCs | ERC20 Notes | Complex Code | Features |
| :-- | --: | :-- | :-- | :-- | :-- |
| AIRProtocolCore | 4 | – | – | No | – |
| AIRToken | 55 | ERC20, ERC2612 | No minting, approve race pattern | No | `ecrecover` usage |
| Counter | 2 | – | – | No | – |
| EmissionsController | 12 | – | – | No | – |
| IAIRProtocolCore | 3 | – | – | No | – |
| IAIRToken | 6 | ERC20 | No minting, approve race pattern | No | – |
| IEmissionsController | 4 | – | – | No | – |
| IMerkleDistributorEpoch | 4 | – | – | No | – |
| IStaking | 5 | – | – | No | – |
| ITreasuryVault | 2 | – | – | No | – |
| MerkleDistributorEpoch | 15 | – | – | No | Token interactions |
| Staking | 12 | – | – | No | Token interactions |
| TreasuryVault | 12 | – | – | No | Token interactions |

Interface contracts (`I*`) define ABIs only and contain no business logic, reducing their attack surface to mis-specification risks rather than runtime vulnerabilities.

***

## 4. Issue Summary

### 4.1 Severity distribution

| Severity | Count | High-level meaning |
| :-- | --: | :-- |
| High | 1 | Direct impact on funds or critical invariants |
| Medium | 9 | Potentially exploitable or serious logic concerns |
| Low | 6 | Minor safety, style, or non-critical checks |
| Informational | 67 | Code quality, readability, and minor best practices |

The single high-severity item should be treated as a blocker before deployment; medium issues should be triaged next, as they may become exploitable under ecosystem or integration changes.

***

## 5. ERC20 / ERC2612 Notes

### 5.1 ERC20 approve race pattern

Slither flags the standard ERC20 `approve` pattern because an allowance change from non‑zero to another non‑zero amount can be front‑run, allowing a spender to use the old allowance just before it is updated. This is a well-known issue in the ERC20 design and is typically mitigated by:

- Requiring allowance to be set to zero before setting a new non-zero value.
- Preferentially using `increaseAllowance` / `decreaseAllowance` flows in integrator contracts.

Given the “Approve Race Cond.” note on `AIRToken` and `IAIRToken`, make sure external documentation clearly explains safe allowance management for integrators.

### 5.2 ERC2612 permit

`AIRToken` implements ERC2612, enabling off-chain signed approvals and gasless approval flows via `permit`, which uses `ecrecover` (or equivalent) to validate signatures. This improves UX by allowing users to approve and act in a single transaction and should be documented for dApp integrators and frontends.

***

## 6. Observations and Recommendations

- **No assembly and no optimization issues**: The absence of inline assembly and optimizer-level findings simplifies the trust model and reduces low-level risk surface.
- **Token interaction contracts** (`MerkleDistributorEpoch`, `Staking`, `TreasuryVault`): These contracts coordinate ERC20 transfers and should receive extra attention in manual review for re-entrancy, accounting correctness, and reward distribution math, even though no complex code was flagged.
- **High / medium issues**:
    - Identify the exact locations from Slither’s detailed output and track them in an issue tracker (e.g., GitHub Issues) with clear remediation steps and test cases.
    - Re-run Slither (`slither <target> --checklist`) after fixes to ensure the severity counts converge and no regressions are introduced.

