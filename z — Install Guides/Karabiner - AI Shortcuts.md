# Karabiner - AI Shortcuts & Symbols

A comprehensive guide to configuring Karabiner Elements with custom shortcuts for AI prompting and common symbols.

---

## 🤖 AI-FIRST INSTALL GUIDE

**Copy and paste this prompt to your AI assistant to get installation help:**

```
I want to set up Karabiner Elements with custom shortcuts for AI prompting and symbols.

Please help me:
1. Check if Karabiner Elements is installed on my macOS (install via brew if missing).
2. Locate the configuration file at ~/.config/karabiner/karabiner.json.
3. Configure a "complex modification" rule that maps:
   - Cmd+Ctrl+1: Paste "Think really hard about this... Use ultrathink"
   - Cmd+Ctrl+2: Paste "Think really hard about this... Use Sequantial Thinking MCP"
   - Cmd+Ctrl+3: Paste "Delegate simultaneously to up to {x} {Model Name} sub-agents."
   - Cmd+Ctrl+4: Paste the "Senior Orchestrator" prompt
   - Cmd+Ctrl+8: Paste "◻︎"
   - Cmd+Ctrl+9: Paste "Skills Scanner" prompt
   - Cmd+Ctrl+0: Paste "Commands Scanner" prompt
4. Verify the shortcuts work by testing them in a text editor.

Guide me through editing the JSON file safely to add these rules to my "Default profile".
```

**What the AI will do:**
-   Verify Karabiner Elements installation
-   Backup your existing `karabiner.json`
-   Inject the specific JSON structure for the "Symbol shortcuts" rule
-   Ensure the `osascript` commands are correctly escaped for clipboard manipulation
-   Help you verify the shortcuts are active

**Expected setup time:** 5 minutes

---

#### 📋 TABLE OF CONTENTS

- [Karabiner - AI Shortcuts \& Symbols](#karabiner---ai-shortcuts--symbols)
  - [🤖 AI-FIRST INSTALL GUIDE](#-ai-first-install-guide)
      - [📋 TABLE OF CONTENTS](#-table-of-contents)
    - [1. 📖 OVERVIEW](#1--overview)
    - [2. 📋 PREREQUISITES](#2--prerequisites)
    - [3. 📥 INSTALLATION](#3--installation)
    - [4. ⚙️ CONFIGURATION](#4-️-configuration)
      - [Manual Setup](#manual-setup)
    - [5. ✅ VERIFICATION](#5--verification)
    - [6. 🚀 USAGE](#6--usage)

---

### 1. 📖 OVERVIEW

This setup uses **Karabiner Elements** to create system-wide shortcuts that paste predefined text snippets. This is particularly useful for:
-   **AI Prompting:** Quickly inserting complex system prompts or "thinking" directives.
-   **Documentation:** Easily typing special symbols used in technical writing or UI descriptions.

The configuration uses `osascript` (AppleScript) to set the clipboard content and then simulate a `Cmd+V` keystroke to paste it immediately.

### 2. 📋 PREREQUISITES

-   **macOS** (Karabiner Elements is macOS only)
-   **Karabiner Elements** installed and running
-   **Permissions:** Karabiner-Elements must be granted Input Monitoring permissions in System Settings.

### 3. 📥 INSTALLATION

If you don't have Karabiner Elements installed, you can install it via the official website or Homebrew.

**Option A: Official Website (Recommended)**
1.  Download the installer from [karabiner-elements.pqrs.org](https://karabiner-elements.pqrs.org/).
2.  Open the `.dmg` file and run the installer.

**Option B: Homebrew**
```bash
brew install --cask karabiner-elements
```

**Setup & Permissions:**
1.  **Launch Karabiner-Elements** from your Applications folder.
2.  **Grant Permissions:** macOS requires explicit permissions for keyboard modification tools.
    *   Follow the on-screen "Driver Alert" or "Input Monitoring" prompts.
    *   Go to **System Settings > Privacy & Security > Input Monitoring** and enable **Karabiner-Elements**.
    *   Go to **System Settings > Privacy & Security > Accessibility** and enable **Karabiner-Elements** (if requested).

### 4. ⚙️ CONFIGURATION

The configuration is stored in `~/.config/karabiner/karabiner.json`.

#### Manual Setup

1.  Open the configuration file:
    ```bash
    code ~/.config/karabiner/karabiner.json
    ```

2.  Locate the `profiles` array. Inside your active profile (usually "Default profile"), look for `complex_modifications` -> `rules`.

3.  Add the following rule object to the `rules` array:

```json
{
    "description": "AI & Symbol Shortcuts (Cmd+Ctrl+1-4, 8-0)",
    "manipulators": [
        {
            "description": "Cmd+Ctrl+1: Ultrathink Prompt",
            "from": {
                "key_code": "1",
                "modifiers": { "mandatory": ["left_command", "left_control"] }
            },
            "to": [{
                "shell_command": "osascript -e 'set the clipboard to \"Think really hard about this... Use ultrathink\"' -e 'tell application \"System Events\" to keystroke \"v\" using command down'"
            }],
            "type": "basic"
        },
        {
            "description": "Cmd+Ctrl+2: Sequential Thinking Prompt",
            "from": {
                "key_code": "2",
                "modifiers": { "mandatory": ["left_command", "left_control"] }
            },
            "to": [{
                "shell_command": "osascript -e 'set the clipboard to \"Think really hard about this... Use Sequantial Thinking MCP\"' -e 'tell application \"System Events\" to keystroke \"v\" using command down'"
            }],
            "type": "basic"
        },
        {
            "description": "Cmd+Ctrl+3: Sub-agents Setup",
            "from": {
                "key_code": "3",
                "modifiers": { "mandatory": ["left_command", "left_control"] }
            },
            "to": [{
                "shell_command": "osascript -e 'set the clipboard to \"Delegate simultaneously to up to {x} {Model Name} sub-agents.\"' -e 'tell application \"System Events\" to keystroke \"v\" using command down'"
            }],
            "type": "basic"
        },
        {
            "description": "Cmd+Ctrl+4: Orchestrator Execution",
            "from": {
                "key_code": "4",
                "modifiers": { "mandatory": ["left_command", "left_control"] }
            },
            "to": [{
                "shell_command": "osascript -e 'set the clipboard to \"You are the senior orchestration agent with full authority over task delegation and final delivery. Analyze my previously mentioned request to identify components that can execute in parallel versus those requiring sequential processing due to dependencies. Before decomposing tasks, scan available commands, tools, and skills to determine which capabilities are relevant to completing this request — leverage these explicitly in your task assignments rather than relying on general reasoning alone.\" & return & return & \"Decompose into discrete tasks with explicit scope, expected output format, and success criteria, utilizing the sub-agents defined earlier.\" & return & return & \"Assign tasks based on which available skills or commands each sub-agent should utilize.\" & return & return & \"Evaluate each sub-agent output against three gates: accuracy, completeness, and consistency with other workstreams. Accept outputs meeting thresholds, request revisions for partial failures, or reassign entirely if misaligned. If a sub-agent fails, redistribute the task or execute directly.\" & return & return & \"Synthesize accepted outputs into a unified response that reads as single authoritative delivery, not assembled fragments. Resolve conflicts by evaluating evidence quality and alignment with user intent. Present your final output with attribution showing which sub-agent contributed each component, and flag any unresolved ambiguities or intentional exclusions.\"' -e 'tell application \"System Events\" to keystroke \"v\" using command down'"
            }],
            "type": "basic"
        },
        {
            "description": "Cmd+Ctrl+8: Checkbox Symbol",
            "from": {
                "key_code": "8",
                "modifiers": { "mandatory": ["left_command", "left_control"] }
            },
            "to": [{
                "shell_command": "osascript -e 'set the clipboard to \"◻︎\"' -e 'tell application \"System Events\" to keystroke \"v\" using command down'"
            }],
            "type": "basic"
        },
        {
            "description": "Cmd+Ctrl+9: Skills Scanner Prompt",
            "from": {
                "key_code": "9",
                "modifiers": { "mandatory": ["left_command", "left_control"] }
            },
            "to": [{
                "shell_command": "osascript -e 'set the clipboard to \"Before diving in, use a parallel sub-agent to scan all available skills and identify which ones are relevant to completing this task. Apply these skills directly in your approach rather than relying on general reasoning alone.\" & return & return & \"After completing the task, report which skills you utilized and how each one contributed to the outcome.\"' -e 'tell application \"System Events\" to keystroke \"v\" using command down'"
            }],
            "type": "basic"
        },
        {
            "description": "Cmd+Ctrl+0: Commands Scanner Prompt",
            "from": {
                "key_code": "0",
                "modifiers": { "mandatory": ["left_command", "left_control"] }
            },
            "to": [{
                "shell_command": "osascript -e 'set the clipboard to \"Before diving in, use a parallel sub-agent to scan all available commands and identify which ones are relevant to completing this task.\" & return & return & \"Treat these commands as reference patterns rather than literal instructions. Extract their underlying logic, sequencing, or workflow structure and adapt what'\\''s useful to build an approach tailored to this specific task. Only apply a command directly as-is when it'\\''s 80% or more relevant to what you'\\''re trying to accomplish.\" & return & return & \"After completing the task, report which commands you referenced or applied and how each one contributed to the outcome.\"' -e 'tell application \"System Events\" to keystroke \"v\" using command down'"
            }],
            "type": "basic"
        }
    ]
}
```

4.  Save the file. Karabiner Elements will automatically reload the configuration.

### 5. ✅ VERIFICATION

1.  Open a text editor (e.g., VS Code, Notes).
2.  Press `Cmd` + `Ctrl` + `1`.
    -   **Expected:** "Think really hard about this... Use ultrathink" is pasted.

### 6. 🚀 USAGE

| Shortcut       | Output                                                        | Description                      |
| :------------- | :------------------------------------------------------------ | :------------------------------- |
| **Cmd+Ctrl+1** | `Think really hard about this... Use ultrathink`              | Trigger deep thinking mode       |
| **Cmd+Ctrl+2** | `Think really hard about this... Use Sequantial Thinking MCP` | Trigger sequential thinking      |
| **Cmd+Ctrl+3** | `Delegate simultaneously to up to {x}...`                     | Orchestrator: Define sub-agents  |
| **Cmd+Ctrl+4** | `You are the senior orchestration agent...`                   | Orchestrator: Execute delegation |
| **Cmd+Ctrl+8** | `◻︎`                                                           | Checkbox symbol                  |
| **Cmd+Ctrl+9** | `Before diving in, use a parallel sub-agent...`               | Trigger skills scanner prompt    |
| **Cmd+Ctrl+0** | `Before diving in, use a parallel sub-agent...`               | Trigger commands scanner prompt  |
