# Telegram Automation Bot — Agent Protocol
# (Example: Python bot + Claude API + WeasyPrint + Google Drive)

## Project
Automated document processing bot. Receives files via Telegram, processes with Claude API, generates PDF reports, delivers via Telegram and Gmail.
- **VPS:** your.vps.ip — `/root/bot/`
- **Service:** `bot-listener` (systemd)
- **Deploy:** `ssh root@your.vps.ip` → `cd /root/bot && git pull && systemctl restart bot-listener`

## MANDATORY PROTOCOL — Before any change

```bash
bash scripts/verify.sh
```

If it fails on the VPS: check service status and env vars first.

## Architecture

```
bot/
├── main.py                  # entry point — Telegram loop
├── claude_service.py        # Claude API calls — document processing
│                              IMPORTANT: max_pages=4 on all PDFs (some have 3+ pages)
├── pdf_generator.py         # WeasyPrint PDF generation
├── telegram_listener.py     # Telegram callbacks, editable fields (FIELD_LABELS)
├── drive_watcher.py         # Google Drive file watcher
├── templates/               # HTML Jinja2 report templates by institution
└── .env                     # credentials — NEVER commit
```

## Critical Rules

### PDF reading
- Some documents span 3 pages — content is on page 3, not page 1
- `claude_service.py`: `max_pages = min(len(doc), 4)` — NEVER lower this value
- If documents get longer in the future: raise the limit, never lower it

### Multi-document batches
- When processing multiple PDFs in one request: pass per-document context from filename to Claude
- Format: `"This PDF corresponds ONLY to patient: {name_from_filename}"`
- Without this: Claude confuses patients when batch has 10+ PDFs

### Required fields in all outputs
- Patient name, **sex** (ALWAYS), age, study date, institution
- Editable fields in `telegram_listener.py` (FIELD_LABELS) must match report fields
- When adding new report fields: add them to FIELD_LABELS too

### Data privacy
- Never log patient names, IDs, or dates to system logs
- Temp files: clean up after PDF generation
- `.env` file: never commit, never log its contents

## Work Pipeline

1. **explorer** — read relevant code on VPS
2. **planner** — propose change with exact files and line numbers
3. **implementer** — apply the change
4. **verifier** — `bash scripts/verify.sh` → PASSED

## Known Historical Bugs

| Bug | Cause | Fix |
|---|---|---|
| Numeric fields show `---` | max_pages=2 missed page 3 content | `max_pages = min(len(doc), 4)` |
| Field shows default value | hardcoded fallback in `or 'default'` | change to `or '---'` |
| Wrong patient on batch | no per-document context | pass filename as patient context in prompt |
| Logo missing in PDF | string path not URI | use `file://` URI format |
| Drive folder not found | case-sensitive path mismatch | match exact folder casing in Drive |
