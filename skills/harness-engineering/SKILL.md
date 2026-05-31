---
name: harness-engineering
description: Guía completa para estructurar, mantener y auditar un harness de Claude Code. Cubre setup global (~/.claude/), setup por proyecto (AGENTS.md + verify.sh), los 3 pilares, gestión de memoria, hooks, skills y el pipeline de trabajo. Invocar al configurar un proyecto nuevo, auditar el harness existente, o incorporar un nuevo proyecto al sistema.
metadata:
  type: reference
---

# Harness Engineering — Guía Completa

## ¿Qué es el harness?

El harness es todo lo que rodea al modelo de IA: el contexto que recibe, las herramientas que puede usar, la memoria que tiene, y las reglas que sigue. El modelo es el cerebro. El harness es el sistema nervioso que lo controla.

**Principio central:** A más herramientas complejas = peor rendimiento. Herramientas simples + contexto preciso = mejor rendimiento. (Vercel eliminó 80% de sus tools y mejoró 3x la velocidad con 37% menos tokens.)

---

## Los 3 pilares

### Pilar 1 — El repositorio ES el sistema
Los archivos del repo definen el comportamiento de la IA. No el chat, no el prompt manual: los archivos.
- `CLAUDE.md` global → identidad y preferencias del usuario
- `AGENTS.md` por proyecto → protocolo, arquitectura, reglas del proyecto
- `settings.json` → hooks, permisos, plugins

### Pilar 2 — Orquestación multiagente
Nunca un solo agente hace todo. Roles separados con contexto mínimo cada uno:
1. **explorer** — solo lectura, entiende el repo
2. **planner** — arma plan/spec con archivos y líneas exactas
3. **implementer** — aplica el cambio
4. **reviewer** — revisa diff y riesgos
5. **verifier** — corre quality gate, confirma que pasó

### Pilar 3 — Verificación obligatoria
La IA no puede declarar "terminé" sin demostración. Cada proyecto necesita un `verify.sh` que valide el estado objetivamente.

---

## Estructura del harness global (~/.claude/)

```
~/.claude/
├── CLAUDE.md              # System prompt global — quién sos, cómo responderte, stack, proyectos
├── settings.json          # Hooks, permisos, plugins habilitados
├── settings.local.json    # Permisos MCP y Bash específicos (no commitear con secretos)
├── agents/                # Agentes especializados (48 definidos)
├── commands/              # Slash commands (80 disponibles)
├── skills/                # Skills on-demand (~320 activos)
└── projects/
    └── -Users-tu-usuario/
        └── memory/
            ├── MEMORY.md  # Índice de memorias (max 200 líneas)
            ├── user_*.md
            ├── feedback_*.md
            ├── project_*.md
            └── reference_*.md
```

### CLAUDE.md global — qué incluir

```markdown
## Quién soy
[perfil: rol, experiencia, nivel técnico]

## Cómo responderme — SIEMPRE
[idioma, estilo, formato preferido]

## Stack de herramientas activas
[herramientas, infraestructura, plataformas]

## Proyectos activos
[tabla: proyecto | estado]

## Metas que guían las decisiones
[objetivos de largo plazo]

## Reglas específicas del dominio
[ej: datos médicos, trading, credenciales]
```

### settings.json — hooks recomendados

```json
{
  "permissions": {
    "allow": ["Bash(*)", "Read", "Edit", "Write", "Glob", "Grep"]
  },
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "cd ~ && git pull --rebase 2>/dev/null || true" }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash|Edit|Write", "hooks": [{ "type": "command", "command": "ruta/observe.sh pre" }] }
    ],
    "PostToolUse": [
      { "matcher": "Bash|Edit|Write", "hooks": [{ "type": "command", "command": "ruta/observe.sh post" }] }
    ],
    "PostCompact": [
      { "matcher": "manual", "hooks": [{ "type": "command", "command": "git add memory/ && git commit -m 'auto: /compact'" }] },
      { "matcher": "auto",   "hooks": [{ "type": "command", "command": "git add memory/ && git commit -m 'auto: auto-compact'" }] }
    ],
    "SessionEnd": [
      { "hooks": [
        { "type": "command", "command": "python3 ~/.claude/session-summarizer.py", "async": true },
        { "type": "command", "command": "git add memory/ && git commit -m 'auto: session end' && git push 2>/dev/null || true", "async": true }
      ]}
    ]
  }
}
```

### Reglas de gestión de skills

- **Mantener activos:** solo skills relevantes al stack real del usuario
- **Eliminar:** skills de dominios completamente ajenos (bioinformática si no es biólogo, etc.)
- **Target:** 250–320 skills es manejable; 400+ empieza a generar ruido contextual
- **Los hooks de observación:** usar matcher `"Bash|Edit|Write"`, NO `"*"` — evita disparar en Read/Glob/Grep

### Gestión de memoria

- **MEMORY.md:** índice solamente — máximo 200 líneas, una línea por memoria
- **Archivo por tipo:** `user_*.md`, `feedback_*.md`, `project_*.md`, `reference_*.md`
- **Revisar mensualmente:** actualizar estados de proyecto, archivar los terminados
- **Nunca guardar:** credenciales, API keys, IPs en memorias que se sincronicen a repos públicos
- **Política de datos sensibles:** separar state activo de histórico si el proyecto creció mucho

---

## Estructura del harness por proyecto

```
mi-proyecto/
├── AGENTS.md              # Protocolo de agentes para este proyecto
├── scripts/
│   └── verify.sh          # Quality gate ejecutable
└── .claude/               # (opcional) settings locales del proyecto
    └── settings.json
```

### AGENTS.md por proyecto — qué incluir

```markdown
# Nombre del Proyecto — Protocolo de Agentes

## Proyecto
[qué hace, URL producción, deploy command]

## PROTOCOLO — Antes de empezar cualquier cambio
\`\`\`bash
bash scripts/verify.sh
\`\`\`
Si falla: NO continuar.

## Arquitectura
[árbol de directorios comentado con qué hace cada archivo clave]

## Reglas CRÍTICAS
[reglas de negocio / clínicas / técnicas que NO se pueden romper sin validación]

## Pipeline de trabajo
1. explorer — leer código relevante
2. planner — proponer con archivos y líneas exactas
3. implementer — aplicar cambio
4. verifier — bash scripts/verify.sh → PASSED

## Errores históricos conocidos
[tabla: error | causa | fix]
```

### verify.sh por proyecto — estructura base

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

echo "=== Proyecto — Quality Gate ==="

# Tests backend (ejemplo Python)
echo "→ Backend: pytest..."
if "$REPO_ROOT/venv/bin/python3" -m pytest "$REPO_ROOT/tests" --tb=short -q; then
  echo "✓ Backend OK"; PASS=$((PASS+1))
else
  echo "✗ Backend FAILED"; FAIL=$((FAIL+1))
fi

# Tests frontend (ejemplo Node)
echo "→ Frontend: vitest..."
cd "$REPO_ROOT/frontend"
if npm run test:unit -- --run; then
  echo "✓ Frontend OK"; PASS=$((PASS+1))
else
  echo "✗ Frontend FAILED"; FAIL=$((FAIL+1))
fi

# TypeScript check
echo "→ TypeScript..."
if npm run type-check; then
  echo "✓ TypeScript OK"; PASS=$((PASS+1))
else
  echo "⚠ TypeScript errors"; FAIL=$((FAIL+1))
fi

echo "================================="
[ "$FAIL" -eq 0 ] && echo "✓ PASSED ($PASS checks)" && exit 0
echo "✗ FAILED ($FAIL fallas)" && exit 1
```

Para proyectos Python puro (bot, API):
```bash
# Reemplazar la sección frontend por:
echo "→ Servicio activo..."
if systemctl is-active --quiet nombre-servicio; then
  echo "✓ Servicio OK"; PASS=$((PASS+1))
else
  echo "✗ Servicio caído"; FAIL=$((FAIL+1))
fi

echo "→ Variables de entorno..."
for var in ANTHROPIC_API_KEY TELEGRAM_BOT_TOKEN; do
  if [ -z "${!var:-}" ]; then
    echo "✗ Falta $var"; FAIL=$((FAIL+1))
  fi
done
```

---

## Checklist — Setup harness global (desde cero)

- [ ] Crear `~/.claude/CLAUDE.md` con perfil, estilo, stack, proyectos, reglas de dominio
- [ ] Configurar `~/.claude/settings.json` con hooks SessionStart/PostCompact/SessionEnd
- [ ] Filtrar hooks de observación a `"Bash|Edit|Write"` (no `"*"`)
- [ ] Instalar Superpowers plugin (orchestration, subagents, brainstorming)
- [ ] Crear sistema de memoria en `~/.claude/projects/{path}/memory/`
- [ ] Crear `MEMORY.md` como índice (no guardar contenido directamente ahí)
- [ ] Configurar git sync: `git init` en home, remote a repo privado (ej: alfred-brain)
- [ ] Instalar skills relevantes al stack real; eliminar skills de dominios ajenos
- [ ] Target: 250–320 skills máximo

## Checklist — Onboarding de proyecto al harness

- [ ] Crear `AGENTS.md` en la raíz del proyecto
- [ ] Crear `scripts/verify.sh` y hacer `chmod +x`
- [ ] Probar que `verify.sh` pasa en estado limpio del repo
- [ ] Agregar el proyecto a la tabla de proyectos activos en `~/.claude/CLAUDE.md`
- [ ] Crear memoria del proyecto: `~/.claude/projects/.../memory/project_nombre.md`
- [ ] Si el proyecto tiene reglas clínicas o de negocio: documentarlas en AGENTS.md
- [ ] Si el proyecto vive en VPS: crear verify.sh compatible (systemctl + env vars)

---

## Anti-patrones — qué evitar

| Anti-patrón | Por qué | Solución |
|---|---|---|
| Dar 400+ herramientas/skills | Degrada el modelo | Podar a lo relevante |
| Hooks PreToolUse con matcher `"*"` | Dispara en lecturas triviales | Usar `"Bash\|Edit\|Write"` |
| Un solo agente hace todo | Contexto se llena, calidad cae | Pipeline de 5 roles |
| Sin verify.sh | Claude declara done sin prueba | Quality gate obligatorio |
| AGENTS.md solo global | Proyectos diferentes necesitan reglas distintas | AGENTS.md por proyecto |
| Memoria sin revisión | Se vuelve "basurero inteligente" | Auditar mensualmente |
| Push automático sin filtro en repos públicos | Puede filtrar datos sensibles | Solo sync repos privados |
| Ventana de contexto >40% sin /compact | Degradación de calidad | Compactar proactivamente |

---

## Señales de que el harness necesita auditoría

- Claude ignora reglas que están en CLAUDE.md
- Claude "olvida" bugs conocidos documentados en AGENTS.md
- Los tests empiezan a fallar silenciosamente
- Claude declara "done" sin verificar
- Respuestas genéricas en proyectos con contexto muy específico
- Latencia notoria entre mensajes (hooks pesados)

---

## Referencias

- Concepto: Harness Engineering — Betta Tech (YouTube, 2026)
- Repo educativo: https://github.com/betta-tech/byo-coding-agent
- Anthropic multi-agent guide: https://docs.anthropic.com/en/docs/build-with-claude/agents
- Repo de templates: https://github.com/alfremeza/claude-harness-template
