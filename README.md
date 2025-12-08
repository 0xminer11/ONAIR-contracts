

# **AIR Protocol – Phase 1 Smart Contracts**

A decentralized truth infrastructure built on **Base**.
Phase-1 provides the minimum on-chain components required to anchor **trust scores**, **claim provenance**, **staking-based Sybil resistance**, and **weekly AIR token rewards**.

This repository contains the complete MVP smart contract suite for AIR Protocol.

---

## 📌 **Overview**

AIR Protocol’s Phase-1 consists of the following Solidity modules:

| Contract                   | Description                                                                                       |
| -------------------------- | ------------------------------------------------------------------------------------------------- |
| **AIRToken**               | ERC-20 + Permit token (100B fixed supply). Powers staking, rewards, and economic alignment.       |
| **SimpleStaking**          | Minimal, farm-resistant staking contract. Users must stake AIR to become reward-eligible.         |
| **TreasuryVault**          | Holds community rewards and streams tokens securely to EmissionsController.                       |
| **EmissionsController**    | Manages weekly AIR emissions and funds MerkleDistributor once per epoch.                          |
| **MerkleDistributorEpoch** | Gas-efficient reward distribution contract using Merkle proofs.                                   |
| **AIRProtocolCore**        | On-chain truth ledger. Stores claim hashes, trust scores, validator attestations, and provenance. |

This forms the **minimum viable truth layer** for AIR Protocol.

---

## 🧱 **Architecture**

```
src/
 ├─ AIRToken.sol
 ├─ SimpleStaking.sol
 ├─ TreasuryVault.sol
 ├─ EmissionsController.sol
 ├─ MerkleDistributorEpoch.sol
 └─ AIRProtocolCore.sol

test/
 ├─ AIRToken.t.sol
 ├─ SimpleStaking.t.sol
 ├─ TreasuryVault.t.sol
 ├─ EmissionsController.t.sol
 ├─ MerkleDistributorEpoch.t.sol
 └─ AIRProtocolCore.t.sol
```

---

## 🔗 **How Phase-1 Works**

### 1️⃣ **Truth Commitment Flow**

1. Story submitted via ONAIR
2. Backend extracts claims → scores them
3. Genesis Validator signs the result
4. Calls `AIRProtocolCore.commitStory()`
5. Trust score + claim hashes become immutable on Base

### 2️⃣ **Staking Flow**

* Users stake AIR inside `SimpleStaking`
* Must stake **≥ 500 AIR** to unlock AIR reward extraction
* Unstake anytime (no lockups)

### 3️⃣ **Reward Epoch Flow**

1. Backend computes AIRPoints for all users
2. Filters eligible stakers
3. Calculates proportional AIR reward
4. Builds Merkle tree → sets Merkle root on-chain
5. `EmissionsController` funds epoch exactly once
6. Users claim AIR via Merkle proof (gasless supported)

---

## ⚙️ **Installation**

### Install OpenZeppelin Contracts

```sh
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

### Install Dependencies

```sh
forge install
```

### Compile

```sh
forge build
```

### Run All Tests

```sh
forge test -vvv
```

---

## 🛡️ **Security Features**

* No unbounded loops in critical methods
* Checks-effects-interactions pattern
* Reentrancy protection on staking
* Strict owner & validator access control
* Pull-based reward funding
* Bitmap-based anti-replay for Merkle claims
* Immutable variables where possible
* Permit-enabled token (EIP-2612)

---

## 🧪 **Testing**

Every contract has full Foundry test coverage:

```
forge test -vvv
```

Tests include:

* Positive & negative test cases
* Revert checks
* Multi-user scenarios
* Merkle proof validation
* Epoch isolation
* Eligibility & staking state logic

---

## 🚀 **Deployment Order**

1. Deploy `AIRToken`
2. Deploy `TreasuryVault`
3. Deploy `MerkleDistributorEpoch`
4. Deploy `EmissionsController`
5. Set EmissionsController in TreasuryVault
6. Deploy `SimpleStaking`
7. Deploy `AIRProtocolCore`
8. Transfer ownerships to multisig

---

## 📚 **Contract Summary**

### **AIRToken.sol**

* ERC-20 token with permit support
* Fixed supply (100B AIR)
* Minted once to deployer → moved to TreasuryVault

### **SimpleStaking.sol**

* Stake AIR → become reward-eligible
* Unstake anytime
* Tracks individual and total stakes

### **TreasuryVault.sol**

* Stores community & reward allocations
* Only EmissionsController can pull funds

### **EmissionsController.sol**

* Funds weekly reward epochs
* Prevents double-funding
* Owner can adjust weekly emission amount

### **MerkleDistributorEpoch.sol**

* Stores Merkle roots for each epoch
* Verifies Merkle proof on claim
* Prevents double claiming via bitmap

### **AIRProtocolCore.sol**

* On-chain truth registry
* Stores story metadata, claim hashes, trust score, provenance
* Only Genesis Validator can commit during Phase-1

---

## 📝 **Phase-1 Goals**

* Verifiable trust score commitments
* Farm-proof staking mechanism
* Secure weekly reward distribution
* Minimal on-chain footprint
* Audit-ready modular design
* Gas-efficient architecture

This completes the **MVP truth layer** for AIR Protocol.

---

## 📄 **License**

MIT or Apache-2.0 (depending on project requirements)



