---
name: block-external-file-ops
enabled: true
event: file
action: block
conditions:
  - field: file_path
    operator: regex_match
    pattern: ^(?!{{PROJECT_DIR}}/|/tmp/claude/)
---

**File operation outside project directory blocked**

You attempted to modify a file outside the allowed directories.

**Allowed locations ONLY:**
- `{{PROJECT_DIR}}/` (this project)
- `/tmp/claude/` (temporary files)

**Everything else is blocked** - including:
- Other projects
- Home directory files
- System directories
- Any path outside the current working directory

**If you need to modify an external file:**
Ask the user for explicit permission first. Explain what file and why.
