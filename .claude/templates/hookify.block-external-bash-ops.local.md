---
name: block-external-bash-ops
enabled: true
event: bash
action: block
pattern: (\s|^)["']?/(?!({{PROJECT_DIR}}/|tmp/claude/|dev/null|dev/stdout|dev/stderr))|(\s|^)["']?~(?!/Projects/)|\.\.(/|$)
---

**Bash operation outside project directory blocked**

You attempted to run a command that references paths outside allowed directories.

**Allowed locations ONLY:**
- `{{PROJECT_DIR}}/` (this project)
- `/tmp/claude/` (temporary files)
- `/dev/null`, `/dev/stdout`, `/dev/stderr` (standard streams)

**Blocked patterns detected:**
- Absolute paths outside project directory
- Home directory shortcuts: `~` (except `~/Projects/`)
- Parent directory traversal: `../`

**If you need to run a command affecting external files:**
Ask the user for explicit permission first. Explain what operation and why.
