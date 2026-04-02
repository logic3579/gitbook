---
description: Claude Code, Gemini CLI, and Codex CLI references
tags:
  - devops/command
---

# AI Coding

## Claude Code

Anthropic's agentic coding CLI. Runs in the terminal, understands project context, and can edit files, run commands, and interact with GitHub.

### session

```bash
# start interactive REPL (auto-detects project context)
claude

# start with an initial prompt
claude "explain this codebase"

# one-shot mode: run a prompt and exit (non-interactive)
claude -p "what does src/main.ts do?"

# pipe input for processing
cat error.log | claude -p "explain this error"
git diff | claude -p "review this diff"

# resume the most recent conversation
claude --continue
# resume with a new prompt appended
claude --continue "now write tests for it"

# resume a specific conversation by session ID
claude --resume <session-id>
```

### model and configuration

```bash
# use a specific model
claude --model sonnet

# print current configuration
claude config list

# set default model
claude config set model sonnet

# set a permission (allowedTools)
claude config set allowedTools '["Bash(npm test:*)","Read","Write"]'
```

### non-interactive / CI usage

```bash
# output as JSON for scripting
claude -p "list all TODO comments" --output-format json

# output as streaming JSON
claude -p "summarize changes" --output-format stream-json

# limit max turns for automated pipelines
claude -p "fix lint errors" --max-turns 10

# use a specific system prompt
claude -p "review code" --system-prompt "You are a security auditor"

# disable all tools (chat-only, no file edits)
claude -p "explain this concept" --allowedTools ""
```

### slash commands (in REPL)

```bash
# manage conversation
/clear               # clear conversation history
/compact             # summarize and compact context

# review and undo
/diff                # show pending file changes
/undo                # revert last file edit

# project context
/init                # create or update CLAUDE.md
/memory              # edit project memory

# other
/help                # show available commands
/cost                # show token usage and cost
/doctor              # troubleshoot configuration issues
/review              # code review shortcut
/commit              # create a git commit
```

### MCP (Model Context Protocol)

```bash
# add an MCP server (stdio transport)
claude mcp add my-server -- npx -y @example/mcp-server

# add with environment variables
claude mcp add my-server -e API_KEY=xxx -- npx -y @example/mcp-server

# add a remote (SSE) MCP server
claude mcp add my-server --transport sse https://example.com/mcp

# list / remove MCP servers
claude mcp list
claude mcp remove my-server
```

## Gemini CLI

Google's AI coding assistant CLI powered by Gemini models. Open-source, runs in terminal with access to tools and MCP.

### session

```bash
# start interactive REPL
gemini

# start with an initial prompt
gemini "explain this codebase"

# non-interactive single prompt
echo "explain this error" | gemini

# pipe file content for analysis
cat main.go | gemini "review this code"
```

### model and configuration

```bash
# use a specific model
gemini -m gemini-2.5-pro

# check current configuration
gemini --check_connection

# set default model via environment variable
export GEMINI_MODEL=gemini-2.5-pro

# authenticate (uses Google Cloud Application Default Credentials or API key)
export GEMINI_API_KEY=your-api-key
# or use gcloud auth
gcloud auth application-default login
```

### tools and extensions

```bash
# list available tools
gemini /tools

# enable/disable specific tools
gemini /tool shell on
gemini /tool shell off

# use sandbox mode for safer execution
gemini --sandbox
```

### slash commands (in REPL)

```bash
/help                # show available commands
/quit                # exit the session
/clear               # clear conversation history
/chat                # start a new chat
/tools               # list available tools
/memory              # manage memory and context
/stats               # show token usage statistics
/theme               # change terminal theme
```

### MCP integration

```bash
# configure MCP servers in settings.json (~/.gemini/settings.json)
# example settings.json:
# {
#   "mcpServers": {
#     "my-server": {
#       "command": "npx",
#       "args": ["-y", "@example/mcp-server"]
#     }
#   }
# }

# or add via command
gemini --mcp-server "npx -y @example/mcp-server"
```

## Codex CLI

OpenAI's lightweight coding agent CLI. Runs locally, supports multiple models, and provides configurable autonomy levels for file edits and command execution.

### session

```bash
# start interactive REPL
codex

# start with a prompt
codex "explain this project structure"

# non-interactive: run a single prompt and exit
codex --quiet "fix the type errors in src/"

# pipe input for processing
git diff | codex "review this diff"
```

### model and configuration

```bash
# specify a model
codex --model o4-mini

# set approval policy (how autonomous the agent is)
codex --approval-mode full-auto     # auto-approve all actions
codex --approval-mode auto-edit     # auto-approve file edits, ask for commands
codex --approval-mode suggest       # ask before every action (default)

# configure via environment
export OPENAI_API_KEY=your-api-key

# use a custom base URL (for compatible APIs)
export OPENAI_BASE_URL=https://custom-api.example.com/v1
```

### project context

```bash
# Codex reads project instructions from:
# - AGENTS.md (project root and subdirectories)
# - codex.md
# - .github/copilot-instructions.md

# initialize project instructions
codex --init
```

### sandbox mode

```bash
# run with network-disabled sandbox (macOS: Apple Seatbelt, Linux: Docker)
codex --full-auto "run tests and fix failures"

# disable sandbox (use with caution)
codex --no-sandbox "deploy to staging"
```

> Reference:
>
> 1. [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
> 2. [Gemini CLI Repository](https://github.com/google-gemini/gemini-cli)
> 3. [Codex CLI Repository](https://github.com/openai/codex)
