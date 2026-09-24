#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
fail=0
err() { printf 'FAIL: %b\n' "$*"; fail=1; }

required=(
  README.md
  AGENTS.md
  PROJECT-INDEX.md
  .ai/AI-ASSISTANT-RULES.md
  .ai/context/project-overview.md
  docs/00-project-context/PROJECT-CONTEXT.md
  docs/01-concept/CONCEPT-NOTE.md
  docs/02-specification/SPECIFICATION.md
  docs/03-context/BUSINESS-TECH-CONTEXT.md
  docs/03-context/PENDING-DECISIONS.md
  docs/03-context/API-REGISTRY.md
  docs/03-context/adr/ADR-001-platform-and-stack.md
  docs/03-context/adr/ADR-002-mvvm-architecture.md
  docs/03-context/adr/ADR-003-build-flavors-and-config.md
  docs/03-context/adr/ADR-004-networking-and-auth.md
  docs/03-context/adr/ADR-005-logging-and-crash-reporting.md
  docs/03-context/adr/ADR-006-design-system-and-adaptive-layout.md
  docs/05-breakdown/modules/FOUND.md
  docs/05-breakdown/sprints/sprint-0.md
  docs/06-development/TEST-CONTEXT.md
  docs/06-development/impact-analyses/README.md
  templates/IMPACT-ANALYSIS-template.md
  templates/ADR-template.md
)
for f in "${required[@]}"; do
  [[ -s "$f" ]] || err "missing or empty: $f"
done

hits="$(grep -rnwE 'TBD|TODO|FIXME' --include='*.md' . \
  --exclude-dir=templates --exclude-dir=superpowers --exclude-dir=.git 2>/dev/null || true)"
[[ -z "$hits" ]] || err "placeholder markers found:\n$hits"

trace_files=(
  docs/02-specification/SPECIFICATION.md
  docs/05-breakdown/modules/FOUND.md
  docs/05-breakdown/sprints/sprint-0.md
)
for n in $(seq -w 1 20); do
  id="FR-FOUND-0$n"
  for f in "${trace_files[@]}"; do
    if [[ -f "$f" ]] && ! grep -q "$id" "$f"; then err "$id not found in $f"; fi
  done
done

if [[ -f PROJECT-INDEX.md ]]; then
  for adr in $(grep -oE 'ADR-[0-9]{3}' PROJECT-INDEX.md | sort -u); do
    compgen -G "docs/03-context/adr/$adr-*.md" >/dev/null || err "$adr referenced in PROJECT-INDEX.md has no file in docs/03-context/adr/"
  done
  for pdr in $(grep -oE 'PDR-[0-9]{3}' PROJECT-INDEX.md | sort -u); do
    if [[ -f docs/03-context/PENDING-DECISIONS.md ]] && ! grep -q "$pdr" docs/03-context/PENDING-DECISIONS.md; then
      err "$pdr referenced in PROJECT-INDEX.md is missing from PENDING-DECISIONS.md"
    fi
  done
fi

if [[ -f AGENTS.md ]]; then
  for hot in PROJECT-INDEX.md .ai/context/project-overview.md .ai/AI-ASSISTANT-RULES.md; do
    grep -qF "$hot" AGENTS.md || err "AGENTS.md does not reference Tier-1 file $hot"
  done
fi

if [[ $fail -eq 0 ]]; then echo "OK: context repo checks passed"; fi
exit $fail
