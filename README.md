# DTC Raid Tracker (Disney Trip Champion)

**DTC Raid Tracker** is a World of Warcraft addon designed to gamify raid attendance and performance. It allows raid members to vote for a "Champion" after every boss kill, tracking points over time to determine who wins an all-expenses-paid trip to Disney World.

Current Version: **4.15.1**

## 🚀 Features

### 🗳️ Voting System
* **Automatic Popup:** The voting window opens automatically after a boss encounter ends.
* **Voting:** Every raid member gets 3 votes to distribute to their peers.
* **Roster Awareness:** Shows current raid members with class colors.
* **Test Mode:** Leaders can simulate a vote via the Config menu to test the UI.

### 🏆 Leaderboard
* **Dynamic Filtering:** Filter scores by Time (All Time/Today/Trips Won), Expansion, Raid, Boss, and **Difficulty** (Normal/Heroic/Mythic).
* **View Modes:** Toggle between Character Names and Nicknames.
* **Award Trip:** A dedicated button for the Raid Leader to declare a winner.
    * *Customizable Broadcast Message:* Configure the shout-out text in the settings.
    * *Default Message:* "CONGRATULATIONS [Name]! You have won an all expenses paid trip to Disney World!"

### 📜 History Log
* **Detailed Records:** Keeps a permanent log of every finalized vote.
* **Raid Difficulty:** Tracks the difficulty setting (LFR, Normal, Heroic, Mythic) for every kill.
* **Filters:** Filter history by Date or specific Character Name.
* **Export:** One-click CSV export for external spreadsheet analysis.

### ⚙️ Configuration (`/dtc config`)
A fully integrated, RCLC-style settings menu with three tabs:
1.  **General:** Maintenance tools (Test Vote, Version Check, Sync).
2.  **Nicknames:** Assign custom nicknames to characters (e.g., "Voltrizzy" -> "Mike").
3.  **Leaderboard:**
    * Reset Data (Local or Global).
    * **Announcement Format:** Choose how names appear in chat (Character, Nickname, or Both).
    * **Award Message:** Customize the text displayed when awarding a trip.

---

## 💻 Slash Commands

| Command | Description |
| :--- | :--- |
| `/dtc lb` | Opens the **Leaderboard** window. |
| `/dtc vote` | Manually opens the **Voting** window. |
| `/dtc history` | Opens the **History Log** (with CSV export). |
| `/dtc config` | Opens the **Configuration** panel (Nicknames, Settings). |
| `/dtc ver` | Checks the current version installed. |
| `/dtc reset` | Quick command to reset local data (Emergency use). |

---

## 📦 Installation

1.  Download the latest release.
2.  Extract the `DTC_RaidTracker` folder into your WoW Addons directory:
    * `_retail_/Interface/AddOns/DTC_RaidTracker`
3.  (Optional) If you are the Raid Leader, ensure you have the latest version to broadcast Sync data correctly.

---

## 🛠️ Configuration Guide

### Setting up Nicknames
1.  Type `/dtc config` and select the **Nicknames** tab.
2.  You will see a list of everyone in your current group, plus any previously saved characters.
3.  Type a nickname in the box next to their name and press Enter.
    * *Note:* Only the Raid Leader (or solo users) can edit nicknames. Raid members can view them in read-only mode.

### Customizing the Award Message
1.  Type `/dtc config` and select the **Leaderboard** tab.
2.  Scroll down to **Award Configuration**.
3.  Edit the text in the box. Use `%s` as a placeholder for the winner's name.
    * *Example:* `Winner winner chicken dinner! %s takes it home!`

---

## 🔄 Syncing Data
Data is automatically shared between users when the Raid Leader creates a "Finalize" event.
* **Manual Sync:** If you join late or miss data, the Raid Leader can click **"Broadcast Sync"** in the `/dtc config` -> **General** tab to push their database to the entire raid.

---

## 📝 Recent Changelog

* **v4.15.1:** Updated default trip award message.
* **v4.15.0:** Fixed award message variable `%s` to respect name formatting settings.
* **v4.14.0:** Added customizable Award Messages and Announcement Name formats.
* **v4.13.0:** Updated rules.
* **v4.12.0:** Added Difficulty filtering to the Leaderboard.
* **v4.11.0:** Split Raid and Difficulty into separate columns in the History view.
* **v4.10.0:** Added Raid Difficulty tracking (Normal/Heroic/Mythic) to history logs.
