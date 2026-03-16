# DTC Raid Tracker (v7.3.17)

**DTC Raid Tracker** is a modular World of Warcraft addon designed to track raid attendance, performance voting, and leaderboard stats. Version 7.1 introduces major architectural improvements and a new **"Game Theory"** module that allows players to leverage gold to influence the vote via Bribes, Propositions, and Lobbying.

## 🚀 Key Features

### 1. Voting System
* **Weighted Voting:** Every raider gets 3 votes per boss kill.
* **Role Sorting:** View the roster sorted by Tank, Healer, and DPS/Other.
* **Smart Validation:** Blocks self-voting and prevents voting if a player has disconnected or has an outdated addon version.
* **Secure Session:** Only the Raid Leader can finalize or announce results. Includes a "Force Start" option for unrecognized raid zones.
* **Tie-Breakers:** Standardized sorting (highest vote count wins).

### 2. "Game Theory" & Commerce
Turn your raid into a marketplace! Players can now leverage their gold to influence the outcome.
* **💰 Bribes:** Offer gold to a specific player to secure one of their votes.
* **📜 Propositions:** Selling your own vote? Broadcast a "Proposition" to the raid, setting a price for your support.
* **🤝 Lobbying:** Fund a campaign! Pay other players to vote for a specific candidate.
* **💸 Corruption Fee:** A configurable tax (default 10%) on all bribes and lobbying is funneled to the Raid Leader.
* **Debt Tracking:** The addon tracks who has paid and who owes money.
    * *Deadbeat Protocol:* If you have unpaid debts from a previous boss, your ability to bribe/lobby is disabled until you settle up.
    * *Secure Payments:* Only the creditor can mark a debt as paid, preventing fraud.
* **Automated Trading:** Clicking "Trade" in the Bribe Ledger automatically opens the trade window and fills in the correct gold amount.
* **Solo Mode:** All features are available while Solo to facilitate testing.

### 3. Leaderboards & History
* **Leaderboard:** Track who has the most votes across the entire expansion, specific raids, or bosses.
* **Detailed History:** A searchable log of every vote cast, complete with dates, difficulty settings, and winners.
* **Export:** Export history data to CSV for external spreadsheet tracking.

### 4. Roster Management
* **Auto-Nicknames:** Automatically populates nicknames based on character names when entering a valid raid instance (excludes LFR).
* **Guild Sorting:** Groups players by Guild in the configuration menu for easier management.
* **One-Click Clean:** Delete players or reset the entire database with a single click.

---

## 📂 Installation

1.  Download the latest release.
2.  Extract the `DTC_RaidTracker` folder to your WoW Addons directory:
    `_retail_\Interface\AddOns\DTC_RaidTracker`
3.  **Restart WoW** (Do not just reload UI) to ensure new files are loaded.

---

## 🛠️ Configuration

Type `/dtc config` to open the options panel.

* **General:** Test buttons for Voting, Leaderboard, and Bribe simulation.
* **Nicknames:** Set custom nicknames for your raiders.
* **Bribes:** Configure expiration timers for Bribes (Default: 90s), Propositions (90s), and Lobbying (120s).

### Slash Commands
| Command | Description |
| :--- | :--- |
| `/dtc vote` | Toggle the Voting Window |
| `/dtc lb` | Toggle the Leaderboard |
| `/dtc history` | Toggle the Vote History Log |
| `/dtc bribes` | Toggle the Bribe Ledger (Debt Tracker) |
| `/dtc config` | Open Settings |
| `/dtc reset` | **WIPE** all data (Use with caution) |

---

## 🏗️ Developer Notes (Folder Structure)

This addon uses a modular architecture to separate Logic, UI, and Data.

```text
DTC_RaidTracker/
├── DTC_RaidTracker.toc      # Addon Manifest
├── Core.lua                 # Init, Slash Commands, Database Handling
├── Config.lua               # Options Panel & Tab Logic
├── Localization.lua         # String Constants
│
├── Utils/
│   └── Helpers.lua          # Shared Utilities
│
├── Models/
│   ├── StaticData.lua       # Raid/Boss ID tables
│   ├── Vote.lua             # Voting Logic & Session State
│   ├── Leaderboard.lua      # Stat Calculation
│   ├── History.lua          # Logging & Syncing
│   └── Bribe.lua            # Commerce Logic (Bribes/Props/Lobbying)
│
└── UI/
    ├── Widgets.xml          # Shared Window Templates
    ├── VoteFrame.xml/lua    # Main Voting Window
    ├── Leaderboard.xml/lua  # Ranking Window
    ├── History.xml/lua      # Log Window
    └── BribeUI.xml/lua      # Popups, Trackers & Lists
```

---

## 🗺️ Logic Flow Diagrams

### System Architecture Overview

```mermaid
graph TD
    subgraph Core["Core.lua — Entry Point"]
        ADDON_LOADED["ADDON_LOADED event"]
        InitDB["InitDatabase()"]
        Events["Event Routing\n(Roster, Zone, Encounter, Chat)"]
        Slash["Slash Commands\n/dtc vote | lb | history | bribes | config"]
    end

    subgraph Models["Models/"]
        Vote["Vote.lua\nSession State & Voting Logic"]
        Bribe["Bribe.lua\nCommerce Engine"]
        History["History.lua\nArchival & Sync"]
        Leaderboard["Leaderboard.lua\nRankings & Trips"]
        StaticData["StaticData.lua\nRaid/Boss Reference Tables"]
    end

    subgraph UI["UI/"]
        VoteFrame["VoteFrame.lua\nRoster, Timer, Vote Buttons"]
        BribeUI["BribeUI.lua\nOffers, Propositions, Ledger"]
        HistoryUI["History.lua\nLog Window & Export"]
        LeaderboardUI["Leaderboard.lua\nRankings Window"]
    end

    subgraph Persistence["SavedVariables — DTCRaidDB"]
        DB_History["history[]"]
        DB_Bribes["bribes[]"]
        DB_Trips["trips{}"]
        DB_Identities["identities{}"]
        DB_Settings["settings{}"]
    end

    subgraph Network["Addon Messaging — DTCTRACKER prefix"]
        Raid["Raid Channel\nSAY/RAID broadcasts"]
        Whisper["Whisper Channel\nDirect offers"]
    end

    ADDON_LOADED --> InitDB
    ADDON_LOADED --> Events
    Events --> Vote
    Events --> Bribe
    Events --> History
    Events --> Leaderboard

    Vote <--> VoteFrame
    Bribe <--> BribeUI
    History <--> HistoryUI
    Leaderboard <--> LeaderboardUI

    Vote --> DB_History
    Bribe --> DB_Bribes
    Leaderboard --> DB_Trips
    Core --> DB_Identities
    Core --> DB_Settings

    Vote <--> Raid
    Bribe <--> Whisper
    Bribe <--> Raid
    History <--> Whisper
    Leaderboard <--> Raid

    Leaderboard --> StaticData
    HistoryUI --> StaticData

    Slash --> VoteFrame
    Slash --> LeaderboardUI
    Slash --> HistoryUI
    Slash --> BribeUI
```

---

### Vote Session Lifecycle

```mermaid
sequenceDiagram
    participant WoW as WoW Engine
    participant Core as Core.lua
    participant Vote as Vote.lua
    participant VF as VoteFrame.lua
    participant Raid as Raid Channel
    participant Hist as History.lua

    WoW->>Core: ENCOUNTER_END (boss kill)
    Core->>Vote: StartSession(bossName)
    Vote->>Raid: PING_ADDON:VERSION (version check)
    Vote->>Raid: SYNC_VOTE_START:BossName||Token
    Vote->>VF: Open window, start countdown timer

    loop Voting Open
        Note over VF: Raider clicks Vote / Bribe / Lobby
        VF->>Vote: CastVote(targetName)
        Vote->>Vote: Validate (self, already voted, votes left)
        Vote->>Raid: VOTE:TargetName||Token
        Raid-->>Vote: VOTE received by all players
        Vote->>VF: UpdateDisplay() — increment tally
    end

    alt Timer expires OR Leader clicks Finalize
        Vote->>Vote: Finalize()
        Vote->>Raid: FINALIZE:Winner||Points||Boss||Raid||Date||Difficulty
        Raid-->>Hist: OnComm(FINALIZE) — insert to DTCRaidDB.history
        Vote->>VF: Show results, enable Announce button
    end

    Note over VF: Leader clicks Announce
    VF->>Raid: /raid announcement with winner name
```

---

### Commerce (Bribe / Proposition / Lobby) Flow

```mermaid
flowchart TD
    A([Player opens Vote Window]) --> B{Choose action}

    B --> C[Direct Bribe]
    B --> D[Proposition]
    B --> E[Lobby]

    subgraph Direct_Bribe["💰 Direct Bribe"]
        C --> C1[Enter gold amount]
        C1 --> C2[Bribe:OfferBribe — whisper BRIBE_OFFER to target]
        C2 --> C3{Target receives offer}
        C3 -->|Accept| C4[Bribe:AcceptOffer]
        C3 -->|Decline / Expires| C5[Offer removed from queue]
        C4 --> C6[Vote:CastVote for offerer]
        C6 --> C7[Broadcast BRIBE_FINAL]
        C7 --> C8[All players: TrackBribe — add to DTCRaidDB.bribes]
        C8 --> C9[Add corruption fee entry for leader]
    end

    subgraph Proposition["📜 Proposition"]
        D --> D1[Enter asking price]
        D1 --> D2[Bribe:SendProposition — broadcast PROP_OFFER to raid]
        D2 --> D3{Another player accepts}
        D3 -->|PROP_ACCEPT whisper| D4[OnPropositionAcceptedByMe]
        D4 --> D5[Cast vote for acceptor]
        D5 --> D6[Broadcast BRIBE_FINAL]
        D6 --> C8
    end

    subgraph Lobby["🤝 Lobby"]
        E --> E1[Enter candidate name + gold amount]
        E1 --> E2[Bribe:SendLobby — broadcast LOBBY_OFFER to raid]
        E2 --> E3{Raid member accepts lobby}
        E3 --> E4[Cast vote for specified candidate]
        E4 --> E6[Broadcast BRIBE_FINAL with type=LOBBY]
        E6 --> C8
    end

    subgraph Debt_Resolution["💸 Debt Resolution"]
        C8 --> DR1[entry.paid = false in DTCRaidDB.bribes]
        DR1 --> DR2{Creditor opens Bribe Ledger}
        DR2 --> DR3[Click Initiate Trade]
        DR3 --> DR4[Bribe:InitiateTrade — open trade window]
        DR4 --> DR5{TRADE_CLOSED — enough gold?}
        DR5 -->|Yes| DR6[entry.paid = true]
        DR6 --> DR7[Broadcast DEBT_PAID to raid]
        DR7 --> DR8[All players mark entry paid]
        DR5 -->|No| DR9[Trade cancelled — debt remains]
    end

    style Direct_Bribe fill:#2d1f00,stroke:#c8860a
    style Proposition fill:#001f2d,stroke:#0a7ec8
    style Lobby fill:#1f2d00,stroke:#6ac80a
    style Debt_Resolution fill:#2d0000,stroke:#c80a0a
```

---

### Data Persistence & Sync

```mermaid
erDiagram
    DTCRaidDB {
        table history
        table bribes
        map trips
        map identities
        map classes
        map guilds
        map settings
    }

    HISTORY_ENTRY {
        string d "Date (YYYY-MM-DD)"
        string r "Raid name"
        string diff "Difficulty"
        string b "Boss name"
        string w "Winner nickname"
        int p "Points (votes received)"
        string v "Total voter count"
    }

    BRIBE_ENTRY {
        string offerer "Who paid"
        string recipient "Who received"
        int amount "Gold in copper"
        string boss "Boss context"
        bool paid "Settlement status"
        string timestamp "ISO datetime"
    }

    SETTINGS {
        string voteSortMode "ROLE or ALPHA"
        int voteTimer "Seconds 30-600"
        int votesPerPerson "Max votes 1-10"
        int corruptionFee "Tax percent 0-100"
        int debtLimit "0 = no limit"
        int bribeTimer "Offer expiry seconds"
        bool secureVoteMode "Token validation"
    }

    DTCRaidDB ||--o{ HISTORY_ENTRY : "history[]"
    DTCRaidDB ||--o{ BRIBE_ENTRY : "bribes[]"
    DTCRaidDB ||--|| SETTINGS : "settings{}"
```

---

### Network Message Protocol

```mermaid
graph LR
    subgraph Leader["Raid Leader"]
        L1[SYNC_VOTE_START]
        L2[FINALIZE]
        L3[SYNC_VOTES / SYNC_FEE / SYNC_TIMERS]
        L4[SESSION_STATUS]
        L5[SYNC_DATA:TRIP]
    end

    subgraph Raider["Any Raider"]
        R1[VOTE]
        R2[PROP_OFFER]
        R3[LOBBY_OFFER]
        R4[BRIBE_FINAL]
        R5[DEBT_PAID]
        R6[SESSION_QUERY]
        R7[PING_ADDON / PONG_ADDON]
    end

    subgraph Whisper["Whisper Only"]
        W1[BRIBE_OFFER]
        W2[PROP_ACCEPT]
        W3[SYNC_PUSH history]
    end

    subgraph All["All Players receive"]
        A1[(DTCRaidDB updated)]
        A2[(UI refreshed)]
    end

    L1 -->|Raid Channel| All
    L2 -->|Raid Channel| All
    L3 -->|Raid Channel| All
    L4 -->|Raid Channel| All
    L5 -->|Raid Channel| All

    R1 -->|Raid Channel| All
    R2 -->|Raid Channel| All
    R3 -->|Raid Channel| All
    R4 -->|Raid Channel| All
    R5 -->|Raid Channel| All
    R6 -->|Raid Channel → Leader responds| L4

    W1 -->|Direct whisper to target| Raider
    W2 -->|Direct whisper to offerer| Raider
    W3 -->|Whisper history sync| Raider
```

---

## 📜 License
Author: Voltrizzy

Version: 7.3.17

Project ID: 1442970 (CurseForge) / 56ndd5G9 (Wago)
