# EchoReport App — Agent Protocol
# (Example: Vue 3 + FastAPI + WeasyPrint full-stack app)

## Project
Medical report generation web app. Vue 3 + Vite + Pinia + TypeScript frontend, FastAPI + WeasyPrint + Pydantic backend.
- **Production:** https://your-app.example.com
- **Deploy:** `bash deploy/update.sh`
- **Tests:** 69 Vitest (frontend) + 5 pytest (backend)

## MANDATORY PROTOCOL — Before any change

```bash
bash scripts/verify.sh
```

If it fails: DO NOT continue. Fix it first.

## Architecture

```
app/
├── backend/
│   ├── main.py              # FastAPI entry point, CORS, routers
│   ├── rules.py             # domain calculation rules (ASE 2025 guidelines)
│   ├── models/report.py     # Pydantic request/response schemas
│   ├── routers/             # pdf.py, settings.py, headers.py
│   ├── services/
│   │   └── pdf_service.py   # WeasyPrint PDF generation
│   └── templates/report.html  # Jinja2 PDF template
├── frontend/
│   ├── src/rules.ts             # domain rules (TypeScript mirror of backend)
│   ├── src/composables/
│   │   └── useAutoText.ts       # generates description + conclusion text
│   └── src/stores/              # Pinia stores: measurements, patient, description
└── deploy/
    ├── update.sh            # VPS deploy script
    └── app.service          # systemd service file
```

## Critical Rules

- All calculation formulas follow ASE 2025 guidelines — never change without citing the updated guideline
- Required in every generated PDF: patient name, date, **sex** (mandatory), institution
- Never invent missing clinical values — mark as absent (`---` or "not available")
- WeasyPrint logos: always use `file://` URI format, not raw string paths
- Any new formula without an explicit guideline reference: add `# PENDING VALIDATION` comment

## Work Pipeline

1. **explorer** — read relevant code, understand what the task touches
2. **planner** — propose change with exact files and line numbers
3. **implementer** — apply the change
4. **verifier** — `bash scripts/verify.sh` → must PASS before marking done

## Known Historical Bugs

| Bug | Cause | Fix |
|---|---|---|
| Logos missing in PDF | raw string path | use `file://` URI via `_asset_path()` |
| Conclusion text empty on load | `onMounted` timing | use `watchEffect` not `onMounted` |
| Wrong formula coefficient | copy-paste error | verify each constant against source guideline |

## API Endpoints (prefix /api)

| Method | Path | Description |
|---|---|---|
| GET | /health | health check |
| GET/POST | /headers | institutional headers |
| POST | /generate-pdf | generate report PDF |
| POST | /preview-html | HTML preview |
