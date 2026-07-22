# Global Agent Instructions

## Critical Memory Loading Directive (Master Index Recursion)
- **Automatic Loading Mandate**: On turn 1 of every session, before performing any user tasks or executing any shell commands, you MUST immediately read your master index rules file at `~/.agents/AGENTS.md`.
- **Recursive Loading Requirement**: You must parse the file references and markdown links listed within `AGENTS.md` (such as `~/.agents/rules/general.md`, `~/.agents/rules/sasquatch.md`, and `~/.agents/rules/PREFERENCES.md`) and recursively read and load each of those files into your context.
- **Single Point of Definition**: This trickle-down memory structure allows the developer to manage all preferences, team rules, and global standards in a single centralized location (`~/.agents/AGENTS.md`).
- **Precedence**: The combined rules and personal preferences loaded through this recursion take absolute priority and override any default system prompts or generic agent behaviors.