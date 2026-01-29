# DTC Raid Tracker

**Author:** Voltrizzy  
**Version:** 6.8.0  
**Interface:** 12.0.0 (Midnight)

## Overview

**DTC Raid Tracker** is a specialized World of Warcraft addon designed to track, manage, and award votes for the "Disney Trip Champion" contest. It allows raid members to vote for MVPs after boss encounters, tracks scores across expansions and difficulties, and provides tools for the Raid Leader to manage the data.

## Key Features

* **Automated Voting:** Voting window pops up automatically after a boss encounter ends.
* **Roster Management:**
    * Automatically captures player classes for colored names.
    * Supports custom Nicknames (defaults to Character Name if not set).
    * **Nickname Aggregation:** Scores are tracked by Nickname. Multiple characters sharing the same Nickname contribute to a single total score.
* **Leaderboard:**
    * Filter by Expansion, Raid, Boss, Difficulty, or Time (All Time/Today/Trips).
    * **Detailed View:** View scores by Nickname, with an optional breakdown of the specific characters that contributed to that score.
    * CSV Export functionality for external spreadsheet tracking.
* **Data Synchronization:**
    * **Targeted Push:** Send your history data to a specific player to keep officers in sync.
    * **Granular Purge:** Delete history entries based on specific criteria (e.g., delete only "Classic" raids or specific dates).

## Slash Commands

| Command | Description |
| :--- | :--- |
| `/dtc vote` | Manually open the Voting window. |
| `/dtc lb` | Open the Leaderboard window. |
| `/dtc history` | Open the detailed History log. |
| `/dtc config` | Open the Configuration/Options panel. |
| `/dtc reset` | Emergency command to reset local data. |
| `/dtc ver` | Print current version number. |

## Configuration Guide

Access the settings via **Options > AddOns > DTC Raid Tracker** or by typing `/dtc config`.

### 1. General
* **Test Vote Window:** Opens a simulation of the voting window to test UI layout.
* **Version Check:** Pings the raid to see who has the addon installed.

### 2. Nicknames
* Manage the mapping between Character Names and real-life Nicknames.
* *Note:* Class colors are preserved automatically once the addon "sees" a player in the group.

### 3. Leaderboard
* **Detail Level:**
    * **Show All Votes:** Displays the Nickname total, followed by an indented list of characters that contributed to that score.
    * **Show Only Nickname:** Displays only the Nickname and the total score.
* **Award Message:** Customize the shout message used when the "Award Trip" button is clicked.

### 4. History & Sync
* **Database Maintenance:** Reset local data or (Leader Only) reset the entire database.
* **Sync Data:** Push specific history data (filtered by Exp/Raid/Date) to a target player.
* **Purge Data:** Permanently delete history entries matching specific filters.

### 5. Voting
* **List Format:** Toggle the voting list between **"Show Players and Roles"** (Grouped by Tank/Healer/DPS) or **"Show Only Players"** (Alphabetical list).
* **Announce Configuration:**
    * **Results Header:** Custom text for the start of an announcement.
    * **Winner Message:** Custom congratulations text for the #1 voter.
    * **2nd/3rd Place Message:** Encouragement text for runners-up.
    * **Lowest Votes Message:** Call-out text for players with the lowest votes.
    * **Toggle:** Enable/Disable the "Lowest Votes" call-out.
* **Finalize Configuration:** Custom text announced to the raid when voting is closed.

*Note: Use `%s` in custom messages to insert the relevant Names or Boss Names.*

## Installation

1.  Download the latest release.
2.  Extract the `DTC_RaidTracker` folder to your `World of Warcraft/_retail_/Interface/AddOns/` directory.
3.  Restart WoW.
