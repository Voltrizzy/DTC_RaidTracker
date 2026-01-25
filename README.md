# DTC Raid Tracker (Disney Trip Controller)

**Current Version:** 4.2.0 (Updated for WoW 12.0 Midnight)

## Overview
DTC Raid Tracker is a specialized World of Warcraft addon designed to gamify raid attendance and performance. It allows raid members to vote on a "Winner" after every boss kill. Points are aggregated into a comprehensive leaderboard to determine who wins the ultimate prize: **A Trip to Disney!**

This addon handles everything from the voting popup to long-term database tracking across Expansions, Raids, and Bosses.

## Key Features

### 🗳️ Voting System
* **Auto-Trigger:** Voting window automatically pops up after a boss kill (Encounter End).
* **Optimistic Voting:** Instant visual feedback when casting votes.
* **One-Click Finalize:** Raid Leader can lock votes and broadcast results to chat instantly.

### 🏆 Advanced Leaderboard
* **Quad-Filter System:** Drill down data by **Time** (All Time/Today/Trips Won), **Expansion**, **Raid**, and **Boss**.
* **Detailed History:** Tracks exactly who voted for whom, timestamps, and boss names.
* **Trips Won Tracker:** A dedicated "Lifetime Wins" counter for players who have successfully claimed a Disney Trip.
* **Exportable:** One-click CSV export for external spreadsheet tracking.

### 🎭 Nickname Support
* Assign custom nicknames to characters (e.g., "Garrana" -> "Sondenn").
* Leaderboards can toggle between Character Names and Nicknames.
* *Configurable via `/dtc config`.*

## Slash Commands

| Command | Description |
| :--- | :--- |
| **/dtc vote** | Manually opens the voting window (Read-only if no active vote). |
| **/dtc lb** | Opens the Leaderboard / History window. |
| **/dtc config** | Opens the Nickname configuration (Leader only). |
| **/dtc reset** | Resets your local data (use with caution). |
| **/dtc ver** | Checks the addon version of everyone in the raid. |

## How to Use

1.  **Install:** Place the `DTC_RaidTracker` folder into your `World of Warcraft/_retail_/Interface/AddOns/` directory.
2.  **Raid:** Kill a boss! The voting window will appear for everyone running the addon.
3.  **Vote:** Click "Vote" next to the player you think deserves the point.
4.  **Finalize (Leader):** The Raid Leader clicks "Finalize" to lock votes and record the data.
5.  **Award (Leader):** When ready, select the "Today" filter on the leaderboard and click **"Award Trip"** to announce the winner and increment their Trip Count.

## Supported Content
* **Classic through The War Within:** Full raid and boss lists included.
* **Midnight (12.0):** Includes support for *The Voidspire*, *The Dreamrift*, and *March on Quel'Danas*.

## Installation
1.  Download the latest Release.
2.  Unzip the file.
3.  Copy the `DTC_RaidTracker` folder to `\World of Warcraft\_retail_\Interface\AddOns\`.
4.  Launch WoW.

---
*Author: Voltrizzy*
