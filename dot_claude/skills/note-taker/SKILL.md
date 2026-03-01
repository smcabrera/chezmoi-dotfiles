---
name: note-taker
description: Use when the user wants to take a note, write something down, jot something down, remember something, or says phrases like "take a note", "write this down", "jot this down", "note that", "remember this", "write a note about".
---

# Note Taker

Save notes as markdown files to `/Users/stephen/Dropbox/GoatBot/notes/`.

## When Triggered

The user has expressed intent to write something down. Capture the content and persist it.

## Steps

1. **Identify the content** — what does the user want noted? If no content is discernible, ask: "What would you like me to note down?"
2. **Infer a filename** — derive a short, descriptive sentence-case name from the subject (e.g. `Goatbot auth ideas.md`, `Meeting with alex.md`, `Rust learning.md`). 2-5 words, no date prefix. Whitespace is welcome
3. **Check for existing file** — use Glob to look for `/Users/stephen/Dropbox/GoatBot/notes/<filename>.md`
4. **Write or append:**
   - **New file:** Use Write tool to create the file
   - **Existing file:** Use Edit tool to append a new section
5. **Confirm** — tell the user what was written and the full file path

## File Format

### New file
```markdown

Content here...

---
*Added: YYYY-MM-DD*
```

### Appending to existing file
Add at the end of the file:

```markdown

---

New content here...

---
*Added: YYYY-MM-DD*
```

> Replace `YYYY-MM-DD` with today's actual date in `YYYY-MM-DD` format.

## Notes Directory

```
/Users/stephen/Dropbox/GoatBot/notes/
```

Create it if it doesn't exist:
```bash
mkdir -p /Users/stephen/Dropbox/GoatBot/notes
```

## Filename Rules

- kebab-case, no date prefix
- 2-5 words describing the subject
- Always `.md` extension
- Infer from context — don't ask the user unless truly ambiguous
