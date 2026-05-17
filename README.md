# 🍄 MushChain PH

### *A Farm-to-Market Agricultural Traceability System for Philippine Mushroom Farms*

> **Blockchain-powered supply chain transparency** — from harvest to market stall, every hand that touches a mushroom batch is permanently recorded on an immutable ledger.

---

<div align="center">

| 🏫 Institution | 📅 Submitted | 👨‍🏫 Submitted To |
|:---:|:---:|:---:|
| Dr. Yanga's Colleges, Inc. (DYCI) | May 2, 2026 | Peter Paul Ocampo |

**Prepared by:** Patricia Mae Polintan · Franc Alvenn Dela Cruz  
**College of Computer Studies** — Bocaue, Bulacan

</div>

---

## 📖 Table of Contents

- [What is MushChain PH?](#-what-is-mushchain-ph)
- [The Problem It Solves](#-the-problem-it-solves)
- [What the Smart Contract Simulates](#-what-the-smart-contract-simulates)
- [The Supply Chain Model](#-the-supply-chain-model)
- [How It Works](#-how-it-works)
- [Smart Contract Functions](#-smart-contract-functions)
- [Roles & Permissions](#-roles--permissions)
- [Mushroom Varieties Covered](#-mushroom-varieties-covered)
- [Technology Stack](#-technology-stack)
- [Running the Simulation in Remix IDE](#-running-the-simulation-in-remix-ide)
- [Audit Trail & Traceability](#-audit-trail--traceability)
- [Scope & Limitations](#-scope--limitations)
- [Regulatory Compliance](#-regulatory-compliance)
- [Project Roadmap](#-project-roadmap)

---

## 🌿 What is MushChain PH?

**MushChain PH** is a prototype blockchain-based **Farm-to-Market Traceability System** built specifically for the Philippine mushroom industry. It digitizes the full lifecycle of a mushroom product — from the moment it is harvested and registered on a farm, through its sale to a trader, its transport by a hauler, and its final delivery to a vendor or market outlet.

At its core, MushChain PH uses a **permissioned blockchain ledger** to ensure that once data is recorded, it cannot be altered retroactively — creating a trustworthy, auditable trail of custody for every batch of mushrooms that passes through the supply chain.

The system is designed for **practical deployment in the Philippine context**, requiring no specialized hardware beyond a standard internet connection, making it accessible even to small-scale rural growers with low-to-moderate digital literacy.

---

## 🚨 The Problem It Solves

The Philippine mushroom industry is one of the most rapidly expanding segments of the country's agricultural sector, reaching a market value of **USD 1,518.9 million in 2025** and projected to grow at a CAGR of **5.31% through 2034**.

Despite this growth, the industry continues to operate with:

| Pain Point | Impact |
|---|---|
| 📄 Fragmented, paper-based supply chain documentation | Impossible to verify product origin |
| 🔍 No standardized traceability system | Cannot trace quality incidents or contamination |
| 💰 Traders underprice batches | Farmers lack origin verification leverage |
| 🏷️ Mislabeled or adulterated products in market | Erodes consumer trust |
| ⚖️ Difficulty complying with food safety standards | Regulatory exposure for producers |
| 🌐 Centralized record-keeping | Vulnerable to manipulation and data loss |

MushChain PH directly addresses every one of these gaps by replacing paper logbooks and verbal agreements with **cryptographically signed, tamper-proof blockchain transactions**.

---

## 🖥️ What the Smart Contract Simulates

The Solidity smart contract (`MushChainPH.sol`) deployed in **Remix IDE** simulates the complete business logic of the MushChain PH system in a controlled test environment. Specifically, it demonstrates:

- ✅ **Token minting** — A mushroom batch is minted as a digital product token when the farmer registers a harvest
- ✅ **Ownership transfer** — The token moves from Farmer → Trader, logged permanently on-chain
- ✅ **Shipment logging** — The Transporter appends a logistics record to the batch's blockchain history
- ✅ **Delivery confirmation** — The Vendor finalizes and closes the chain of custody with a delivery receipt
- ✅ **Role enforcement** — The contract enforces who can call which function; wrong-role calls revert automatically
- ✅ **Workflow order enforcement** — Steps cannot be skipped; a batch cannot be delivered before it is shipped
- ✅ **Immutable audit trail** — Every action is permanently logged with actor address, role, details, and timestamp
- ✅ **Full provenance query** — Any caller can read the complete history of a batch in one function call
- ✅ **Human-readable audit report** — A formatted text report can be generated for any batch at any stage

> **Note:** This is a prototype simulation. No real payments, IoT sensors, or external integrations are used. All transactions run in the Remix JavaScript VM — no wallet or gas fees required.

---

## 🔗 The Supply Chain Model

MushChain PH covers a sequential four-stage supply chain. **No stage can be skipped** — the contract enforces workflow order at the code level.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MUSHCHAIN PH SUPPLY CHAIN                        │
└─────────────────────────────────────────────────────────────────────┘

  🌾 FARMER / GROWER          🧺 TRADER / BUYER
  ─────────────────           ─────────────────
  Harvests mushroom    ──▶    Purchases batch
  batch & registers           from farmer
  on blockchain               
        │                           │
        ▼                           ▼
  ⛓️ Genesis block           ⛓️ Ownership transfer
     minted                     logged on chain
  
        ─────────────────────────────
  
  🚛 TRANSPORTER / HAULER     🏪 VENDOR / RETAILER
  ───────────────────         ────────────────────
  Picks up batch &     ──▶   Receives batch &
  logs shipment route         confirms delivery
        │                           │
        ▼                           ▼
  ⛓️ Shipment record         ⛓️ Chain of custody
     appended                   permanently closed

        ─────────────────────────────

                  📱 CONSUMER
                  ──────────
           Scans QR code to view
           full product provenance
           (farm → trader → route → vendor)
```

### Blockchain Events Per Stage

| Stage | Actor | Key Action | Blockchain Event Emitted |
|:---:|---|---|---|
| **1** | Farmer / Grower | Harvest and register batch | `BatchMinted` |
| **2** | Trader / Buyer | Purchase and record acquisition | `OwnershipTransferred` |
| **3** | Transporter / Hauler | Log pickup, route, and condition | `ShipmentLogged` |
| **4** | Vendor / Retailer | Confirm delivery and close chain | `DeliveryConfirmed` |

Each stage corresponds to a **discrete, cryptographically signed transaction** on the blockchain ledger, ensuring that no single actor can modify the record of any other participant's entry.

---

## ⚙️ How It Works

### 1. 🌾 Batch Registration (Farmer)
The farmer logs into MushChain PH and fills out a batch registration form with:
- Mushroom variety
- Total harvest quantity (kg)
- Harvest date and time
- Farm name, barangay, and municipality
- Optional growing conditions or substrate notes

Upon submission, the system generates a unique **Batch ID** (e.g., `FTPH-2026-00001`) and writes a signed **genesis transaction** to the blockchain — permanently recording the farm of origin and all harvest metadata. This is equivalent to minting a product token.

### 2. 💼 Ownership Transfer (Farmer → Trader)
When a trader agrees to purchase the batch, they confirm the acquisition by providing:
- Purchase quantity
- Agreed price per kilogram
- Transaction date and notes

This triggers a **blockchain ownership transfer event**, re-assigning the batch record from the farmer's account to the trader's. Both parties receive a transaction confirmation — an unalterable record of the commercial exchange.

### 3. 🚛 Shipment Recording (Transporter)
The transporter logs pickup of the batch, entering:
- Vehicle plate number
- Departure location
- Intended destination (market, distribution hub, cold storage)
- Estimated time of arrival
- Condition observations (e.g., temperature at pickup, packing method)

Each entry **appends a new block** to the chain, building a real-time logistics trail for the batch.

### 4. 🏪 Delivery Confirmation (Vendor)
Upon receiving the batch, the vendor confirms delivery by logging:
- Actual quantity received (may differ from shipped quantity)
- Condition at arrival
- Any discrepancy notes

This creates the **final, closing transaction** on the blockchain. The provenance record is now complete and the chain of custody is permanently sealed.

---

## 📋 Smart Contract Functions

### Admin Functions
| Function | Description |
|---|---|
| `registerParticipant()` | Onboards a new user and assigns their role (Farmer/Trader/Transporter/Vendor) |
| `deactivateParticipant()` | Revokes a participant's access |
| `reactivateParticipant()` | Restores a deactivated participant |

### Supply Chain Functions
| Function | Who Calls It | Description |
|---|---|---|
| `registerBatch()` | Farmer | Mints a new mushroom batch token on the blockchain |
| `transferToTrader()` | Farmer | Transfers batch ownership to a registered Trader |
| `logShipment()` | Transporter | Records pickup, route, vehicle, and condition data |
| `confirmDelivery()` | Vendor | Finalizes delivery and closes the chain of custody |

### Read / Traceability Functions
| Function | Description |
|---|---|
| `getProvenance(batchId)` | Returns full origin summary — simulates consumer QR scan |
| `getBatchAuditTrail(batchId)` | Returns all audit events as labeled parallel arrays |
| `getAuditReport(batchId)` | Returns a formatted, human-readable audit report string |
| `getAuditEntry(entryId)` | Returns a single specific audit entry |
| `getTransferRecord(batchId)` | Returns the ownership transfer details |
| `getShipmentRecord(batchId)` | Returns the logistics record |
| `getDeliveryRecord(batchId)` | Returns the delivery confirmation details |
| `getBatchStatus(batchId)` | Returns the current status as a readable label |
| `getParticipant(address)` | Returns a participant's profile and role |
| `getAllBatches()` | Returns all batch IDs ever registered |

---

## 👥 Roles & Permissions

| Role | Access Level | Key Permissions |
|---|---|---|
| 🔑 **Admin** | Full access | Onboard users, monitor all transactions, manage participants |
| 🌾 **Farmer** | Own batches only | Register batches, generate batch codes, initiate ownership transfer |
| 🧺 **Trader** | Purchased batches only | Confirm purchases, record acquisition details |
| 🚛 **Transporter** | Assigned shipments only | Log shipment pickups, record route and condition data |
| 🏪 **Vendor** | Received batches only | Confirm delivery, flag discrepancies |
| 📱 **Consumer** | Public read-only | Scan QR code to view product provenance (no login required) |

### Role Enforcement in Action
The contract **automatically reverts** any transaction that violates role rules:

```
❌ Trader calls registerBatch()
   → Reverts: "MushChain: incorrect role for this action"

❌ Vendor calls confirmDelivery() before logShipment()
   → Reverts: "MushChain: batch must be InTransit before delivery can be confirmed"

❌ Farmer calls transferToTrader() on a batch they don't own
   → Reverts: "MushChain: caller does not own this batch"
```

---

## 🍄 Mushroom Varieties Covered

| Code | Variety | Scientific Name | Market Segment |
|:---:|---|---|---|
| `0` | **Oyster** | *Pleurotus ostreatus* | Mass market — most widely grown in the Philippines |
| `1` | **Shiitake** | *Lentinula edodes* | Premium market and export quality |
| `2` | **Button** | *Agaricus bisporus* | Mass-market retail segment |
| `3` | **Reishi** | *Ganoderma lucidum* | Medicinal / specialty market |
| `4` | **Lion's Mane** | *Hericium erinaceus* | Premium / emerging health market |

> The system is designed to be extensible to additional varieties in future iterations.

**Geographic Focus (Initial Prototype):**
Central Luzon (Region III) — particularly **Bulacan, Nueva Ecija, and Pampanga**, identified as major mushroom-producing areas. Architecture supports future expansion to Cordillera Administrative Region, Calabarzon, and Davao Region.

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Smart Contract** | Solidity ^0.8.20 | Core business logic and blockchain ledger |
| **Blockchain** | Hyperledger Fabric *(target)* / Remix VM *(simulation)* | Permissioned distributed ledger |
| **Frontend** *(planned)* | React.js | Mobile-first, responsive web interface with Filipino-language support |
| **Backend** *(planned)* | Node.js + Express.js | RESTful API, authentication, blockchain interface |
| **Database** *(planned)* | MySQL | Off-chain storage for profiles, sessions, and reports |
| **QR Codes** *(planned)* | qrcode.js | Printable/digital QR labels linked to provenance portal |
| **Hosting** *(planned)* | AWS Asia Pacific (Singapore) | Low-latency access from Philippine farms |

> **For the Remix IDE prototype**, the Solidity contract runs entirely in the browser using the JavaScript VM. No external dependencies, wallet, or gas fees are needed.

---

## 🚀 Running the Simulation in Remix IDE

### Prerequisites
- A browser — go to **[remix.ethereum.org](https://remix.ethereum.org)**
- No wallet, no MetaMask, no installation needed

### Setup

**Step 1 — Load the contract**
Create a new file in Remix and paste the contents of `MushChainPH.sol`.

**Step 2 — Compile**
Select Solidity compiler version `0.8.20` and click **Compile**.

**Step 3 — Deploy**
Under *Deploy & Run Transactions*, select **Remix VM (London)** and deploy from **Account[0]**.

**Step 4 — Assign test accounts**
```
Account[0] → Admin       (auto-registered on deploy)
Account[1] → Farmer
Account[2] → Trader
Account[3] → Transporter
Account[4] → Vendor
```

---

### Full Simulation Walkthrough

#### 🔑 [A] Register All Participants — call from Account[0]

```
registerParticipant(
    "<Account[1] address>",
    "Juan dela Cruz",
    2,                          ← Farmer
    "PMGA Bulacan Chapter",
    "Lolomboy",
    "Bocaue Bulacan"
)
```
Repeat for Trader (role `3`), Transporter (role `4`), and Vendor (role `5`).

---

#### 🌾 [1] Register Batch — switch to Account[1] (Farmer)

```
registerBatch(
    0,                          ← Oyster mushroom
    50,                         ← 50 kg
    "Dela Cruz Mushroom Farm",
    "Lolomboy",
    "Bocaue Bulacan",
    "Grown on rice straw. No pesticides used."
)
```
✅ **Expected:** `BatchMinted` event fires. `getBatchStatus(1)` → `"Registered (At Farm)"`

---

#### 💼 [2] Transfer to Trader — stay on Account[1] (Farmer)

```
transferToTrader(
    1,                          ← batchId
    "<Account[2] address>",     ← Trader wallet
    85,                         ← ₱85/kg agreed price
    "Agreed price locked at harvest-day market rate."
)
```
✅ **Expected:** `OwnershipTransferred` event fires. `getBatchStatus(1)` → `"Transferred to Trader"`

---

#### 🚛 [3] Log Shipment — switch to Account[3] (Transporter)

```
logShipment(
    1,                          ← batchId
    "ABC-1234",                 ← vehicle plate
    "Lolomboy Bocaue",          ← departure point
    "Divisoria Market Manila",  ← destination
    4,                          ← estimated 4 hours
    "Packed in ventilated crates. Ambient temp ~24C."
)
```
✅ **Expected:** `ShipmentLogged` event fires. `getBatchStatus(1)` → `"In Transit"`

---

#### 🏪 [4] Confirm Delivery — switch to Account[4] (Vendor)

```
confirmDelivery(
    1,                          ← batchId
    49,                         ← 49 kg received (1 kg variance)
    1,                          ← Condition: Good
    "1 kg short from declared 50 kg. Quality acceptable."
)
```
✅ **Expected:** `DeliveryConfirmed` event fires. `getBatchStatus(1)` → `"Delivered — Chain of Custody Closed"`

---

#### 📊 [5] Read the Full Audit Trail

```
getBatchAuditTrail(1)
```
Returns 6 labeled arrays — `actions`, `actors`, `actorRoles`, `details`, `timestamps` — all events at once.

```
getAuditReport(1)
```
Returns a formatted text block showing all 4 events with full details, ideal for presentations.

> **Tip for strings with commas:** Remix's input parser splits on commas even inside quoted strings. Always write locations without commas — use `Bocaue Bulacan` instead of `Bocaue, Bulacan`.

---

## 📜 Audit Trail & Traceability

Every supply chain event automatically appends an entry to the batch's **immutable audit log**. A fully completed batch will have exactly **4 audit entries**:

```
========================================
  MUSHCHAIN PH — AUDIT REPORT
  Batch: FTPH-2026-00001
  Status: Delivered — Chain of Custody Closed
  Total Events: 4
========================================

[1] BATCH_REGISTERED
    Role    : Farmer
    Actor   : 0xAB..cd
    Details : Farm: Dela Cruz Mushroom Farm | Variety: Oyster | Qty: 50 kg | Barangay: Lolomboy, Bocaue Bulacan
    Time    : 1746000000
----------------------------------------
[2] OWNERSHIP_TRANSFERRED
    Role    : Farmer
    Actor   : 0xAB..cd
    Details : From Farmer: 0xAB..cd -> Trader: 0xCD..ef | Price/kg: 85 | Qty: 50 kg
    Time    : 1746000120
----------------------------------------
[3] SHIPMENT_LOGGED
    Role    : Transporter
    Actor   : 0xEF..12
    Details : Vehicle: ABC-1234 | From: Lolomboy Bocaue | To: Divisoria Market Manila | ETA: 4 hr(s)
    Time    : 1746000300
----------------------------------------
[4] DELIVERY_CONFIRMED
    Role    : Vendor
    Actor   : 0x34..56
    Details : Vendor: 0x34..56 | Qty Received: 49 kg | Condition: Good | Notes: 1 kg short...
    Time    : 1746014400
----------------------------------------
```

### Data Entities on the Ledger

| Entity | Key Fields | Role on Chain |
|---|---|---|
| **Product Batch** | Batch ID, Variety, Qty, Harvest Date, Farm ID, Status | Genesis record — root of the chain |
| **Transaction** | Type, Actor ID, Timestamp, Digital Signature | Each supply chain event |
| **Participant** | Full Name, Role, Organization, Barangay | Trusted identity anchor |
| **Shipment Record** | Vehicle, Departure, Destination, Condition | Logistics sub-record |
| **Ownership Record** | From/To Participant, Price, Date | Immutable commercial custody record |
| **Delivery Confirmation** | Vendor, Qty Received, Condition, Discrepancy | Final closing event |

---

## 🗺️ Scope & Limitations

### ✅ In Scope (Prototype)
- Oyster, Shiitake, and Button mushroom varieties (Reishi and Lion's Mane extensible)
- Central Luzon farms — Bulacan, Nueva Ecija, Pampanga
- All four supply chain roles: Farmer, Trader, Transporter, Vendor
- Batch registration, QR code generation, ownership transfer, shipment tracking, delivery confirmation
- Consumer provenance portal (simulated via `getProvenance()`)
- Admin dashboard and audit reports (simulated via `getAuditReport()`)

### ⚠️ Known Limitations
| Limitation | Reason | Future Plan |
|---|---|---|
| No live deployment | Controlled prototype simulation only | Full deployment after UAT sign-off |
| Manual data entry | No IoT sensor integration | Offline-sync module in roadmap |
| Max 20–30 test participants | Prototype scope | Scale to 500+ on cloud deployment |
| Internet required | No offline mode yet | Offline-sync module planned |
| No BPI/FDA/DA integration | Regulatory APIs not yet connected | Phase 2 integration |

---

## ⚖️ Regulatory Compliance

MushChain PH is developed in full respect of applicable Philippine laws:

| Law / Order | Relevance |
|---|---|
| 🔒 **RA 10173** — Data Privacy Act of 2012 | Participant personal data stored with safeguards; sensitive pricing data excluded from public portal |
| 🥬 **RA 10611** — Food Safety Act of 2013 | System explicitly designed to meet traceability mandates for food producers in formal markets |
| 🌱 **DA AO No. 8, s. 2017** — Good Agricultural Practices | Batch registration module aligns with DA-GAP farm-level record-keeping requirements |
| 🎓 **CHED CMO No. 20, s. 2020** — Research Ethics | IRB clearance from DYCI required before participant-based testing |

---

## 📅 Project Roadmap

| Phase | Activities | Deliverables | Timeline |
|:---:|---|---|---|
| **1** | Requirements gathering, stakeholder interviews with PAMSG & PMGA | Finalized System Requirements Document | Month 1–2 |
| **2** | System design — database schema, blockchain architecture, UI wireframes | Design Documents, Wireframes, ERD | Month 2–3 |
| **3** | Frontend & backend development, blockchain node setup, QR module | Working Prototype (internal) | Month 3–5 |
| **4** | User acceptance testing with 20–30 selected participants across all four roles | Test Reports, Bug Fixes, UAT Sign-Off | Month 5–6 |
| **5** | Final refinement, documentation, staging deployment, board presentation | Final System, Full Documentation, Presentation Deck | Month 6–7 |

---

## 🤝 Institutional Partners & Stakeholders

| Stakeholder | Type | Role in MushChain PH |
|---|---|---|
| **PAMSG** — Philippine Association of Mushroom Suppliers and Growers | Institutional Client | System governance and deployment champion |
| **PMGA** — Philippine Mushroom Growers Association | Institutional Client | Member network for participant onboarding |
| **Bureau of Plant Industry (BPI)** | Regulator | Future regulatory database integration |
| **Food and Drug Administration (FDA)** | Regulator | Food safety compliance monitoring |
| **Department of Agriculture (DA)** | Regulator | Digital Agriculture Roadmap alignment |
| **Central Luzon State University** | Research Partner | MOA signed June 2025 for mushroom R&D piloting |
| **Aurora State College of Technology** | Research Partner | MOA signed June 2025 for mushroom R&D piloting |

---

## 📚 References

- Androulaki, E., et al. (2018). *Hyperledger Fabric: A distributed operating system for permissioned blockchains.* EuroSys Conference.
- Bosona, T., & Gebresenbet, G. (2023). *The role of blockchain technology in promoting traceability systems in agri-food production and supply chains.* Sensors, 23(11), 5342.
- IMARC Group. (2025). *Philippines mushroom market: Size, share, trends, and forecast 2025–2034.*
- Iglesia, J. P. (2025). *Market assessment on white oyster mushroom in Luzon, Philippines.* JMSD, 4(1), 1–23.
- UNDP. (2023). *Blockchain for agri-food traceability.* UNDP Publications.
- VISTA Initiative. (2024). *IFAD partnership with the Department of Agriculture for 350,000 smallholder farmers.* Department of Agriculture, Republic of the Philippines.

---

<div align="center">

---

*MushChain PH — Semfinals Project Proposal*  
*College of Computer Studies · Dr. Yanga's Colleges, Inc. (DYCI) · Bocaue, Bulacan*  
*© 2026 Patricia Mae Polintan & Franc Alvenn Dela Cruz — All rights reserved*

</div>
