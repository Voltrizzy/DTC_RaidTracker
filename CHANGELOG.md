# DTC Raid Tracker

## [v7.3.14](https://github.com/Voltrizzy/DTC_RaidTracker/tree/v7.3.14) (2026-01-29)
[Full Changelog](https://github.com/Voltrizzy/DTC_RaidTracker/compare/v7.3.13...v7.3.14)

### Fixes & Improvements
- **API Compliance:** Fixed invalid WoW API calls in Bribe module.
- **Optimization:** Removed redundant API calls in Vote module.
- **UI:** Fixed redundant frame definitions in VoteFrame.

## [v7.3.13](https://github.com/Voltrizzy/DTC_RaidTracker/tree/v7.3.13) (2026-01-29)
[Full Changelog](https://github.com/Voltrizzy/DTC_RaidTracker/compare/v7.3.12...v7.3.13)

## [v7.3.12](https://github.com/Voltrizzy/DTC_RaidTracker/tree/v7.3.12) (2026-01-29)
[Full Changelog](https://github.com/Voltrizzy/DTC_RaidTracker/compare/v7.3.9...v7.3.12)

### Fixes & Improvements
- **Security:** Fixed a critical vulnerability where players could spoof debt payments. Now only the creditor can mark a debt as paid.
- **Logic:** Fixed a potential self-voting exploit via addon messages.
- **Logic:** Fixed a potential self-lobbying inconsistency.
- **Stability:** Improved unique ID generation for bribe/lobby offers to prevent collisions.
- **Code Quality:** Refactored helper functions (GetFullName, GetCanonicalName) to a shared utility module for better maintainability.

## [v7.3.9](https://github.com/Voltrizzy/DTC_RaidTracker/tree/v7.3.9) (2026-01-29)
[Full Changelog](https://github.com/Voltrizzy/DTC_RaidTracker/compare/v7.3.7...v7.3.9)

### Fixes & Improvements
- **Testing:** Enabled Bribe/Debt module functionality when Solo (not in a group) to facilitate testing.
- **UX:** Closing the Incoming Bribe popup via the 'X' button now correctly declines the offer.
- **UI:** Fixed title display on the Incoming Bribe window.

## [v7.3.7](https://github.com/Voltrizzy/DTC_RaidTracker/tree/v7.3.7) (2026-01-29)
[Full Changelog](https://github.com/Voltrizzy/DTC_RaidTracker/compare/v7.3.6...v7.3.7)

### Polish
- **Nicknames:** Standardized nickname display across all windows (Vote, Leaderboard, History, Bribe Ledger). Now consistently shows "Name (Nickname)" or just "Name" if they match.

## [v7.3.6](https://github.com/Voltrizzy/DTC_RaidTracker/tree/v7.3.6) (2026-01-29)
[Full Changelog](https://github.com/Voltrizzy/DTC_RaidTracker/compare/v7.3.5...v7.3.6)

### Fixes & Improvements
- **UI Layouts:** Fixed XML anchoring issues in Bribe/Lobby rows where text was missing.
- **Vote Window:** Moved Boss Name to a dedicated label to prevent title overflow; fixed footer button layout.
- **Configuration:** Increased size of General Options frame; added "Reset Defaults" for Voting.
- **Logic:** Fixed voting session lifecycle to prevent chat spam; ensured "Votes Per Person" setting syncs correctly.
- **Export:** Fixed Bribe Ledger export to respect active filters.

## [v7.3.1](https://github.com/Voltrizzy/DTC_RaidTracker/tree/v7.3.1) (2026-01-29)
[Full Changelog](https://github.com/Voltrizzy/DTC_RaidTracker/compare/v7.3...v7.3.1)

## [v7.3](https://github.com/Voltrizzy/DTC_RaidTracker/tree/v7.3) (2026-01-29)
[Full Changelog](https://github.com/Voltrizzy/DTC_RaidTracker/compare/v7.2...v7.3)

### Stability & Polish
- **Cross-Realm:** Fixed issues with whispering and tracking players from other realms.
- **Memory Optimization:** Implemented frame pooling for UI lists to prevent memory leaks.
- **Data Integrity:** Added input sanitization for CSV exports and fixed database pollution in the Bribe Ledger.
- **Raid Validation:** Added strict checks to ensure Voting and Bribe features only activate in valid raid instances.
- **UI Polish:** Improved number formatting (commas for large amounts) and sorting stability.

## [v7.2](https://github.com/Voltrizzy/DTC_RaidTracker/tree/v7.2) (2026-01-29)
[Full Changelog](https://github.com/Voltrizzy/DTC_RaidTracker/compare/v6.8.0...v7.2)

### New Features
- **Game Theory Module:** Added Bribes, Propositions, and Lobbying mechanics.
- **Debt Tracking:** New Bribe Ledger to track debts, taxes, and payments.
- **Deadbeat Protocol:** Blocks players with unpaid debts from participating in commerce.
- **State Corruption Fee:** Configurable tax on all bribes/lobbying paid to the leader.
- **UI Improvements:** Added visual indicators for debts, search/filter for ledger, and CSV export.

## [v6.8.0](https://github.com/Voltrizzy/DTC_RaidTracker/tree/v6.8.0) (2026-01-28)
[Full Changelog](https://github.com/Voltrizzy/DTC_RaidTracker/compare/v6.4.1.1...v6.8.0) 

- Update README.md  
- Update DTC\_RaidTracker.toc  
- Update DisneyTripWorker.lua  
    big updates  