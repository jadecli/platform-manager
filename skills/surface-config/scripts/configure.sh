#!/usr/bin/env bash
# Generate per-surface .claude/settings.json from manifest.xml.
# Usage: configure.sh [surface]  — omit surface to configure all 5.
set -euo pipefail

ECOSYSTEM="/Users/alexzh/jadecli-ecosystem"
MANIFEST="${ECOSYSTEM}/manifest.xml"
SCRIPTS="${ECOSYSTEM}/scripts"
FILTER="${1:-}"

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: manifest.xml not found at ${MANIFEST}" >&2
  exit 1
fi

# Parse members from manifest.xml using sed only (macOS awk lacks capture groups).
# Output: login\trole\tdir\tplatform\tapp\tsubscription  (one line per member)
parse_members() {
  local login="" role="" dir="" platform="" app="" sub=""
  while IFS= read -r line; do
    if [[ "$line" =~ \<member[[:space:]] ]]; then
      login=$(echo "$line" | sed -n 's/.*login="\([^"]*\)".*/\1/p')
      role=$(echo "$line" | sed -n 's/.*role="\([^"]*\)".*/\1/p')
    elif [[ "$line" =~ \<directory\> ]]; then
      dir=$(echo "$line" | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    elif [[ "$line" =~ \<surface[[:space:]] ]]; then
      platform=$(echo "$line" | sed -n 's/.*platform="\([^"]*\)".*/\1/p')
      app=$(echo "$line" | sed -n 's/.*app="\([^"]*\)".*/\1/p')
    elif [[ "$line" =~ \<subscription\> ]]; then
      sub=$(echo "$line" | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    elif [[ "$line" =~ \</member\> ]]; then
      [[ -n "$login" ]] && printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$login" "$role" "$dir" "$platform" "$app" "$sub"
      login="" role="" dir="" platform="" app="" sub=""
    fi
  done < "$MANIFEST"
}

shorten_tier() {
  case "$1" in
    *"Pro Max"*) echo "Pro Max" ;;
    *"Pro"*Premium*|*"Pro"*premium*) echo "Pro + Premium" ;;
    *"Pro"*) echo "Pro" ;;
    *) echo "TBD" ;;
  esac
}

generate_settings() {
  local email="$1" role="$2" dir="$3" platform="$4" app="$5" tier="$6"
  local target="${ECOSYSTEM}/${dir}/.claude"
  mkdir -p "$target"
  cat > "${target}/settings.json" <<SETTINGS
{
  "\$schema": "https://json.schemastore.org/claude-code-settings.json",
  "env": {
    "JADECLI_EMAIL": "${email}",
    "JADECLI_PLATFORM": "${platform}",
    "JADECLI_SURFACE": "${app}",
    "JADECLI_TIER": "${tier}",
    "JADECLI_ROLE": "${role}"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ${SCRIPTS}/statusline.sh"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SCRIPTS}/access-guard.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SCRIPTS}/session-init.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS
  echo "  ${dir}/.claude/settings.json  ← ${email} (${app}, ${tier})"
}

echo "Reading ${MANIFEST}"
configured=0
while IFS=$'\t' read -r login role dir platform app sub; do
  [[ -n "$FILTER" && "$dir" != "$FILTER" ]] && continue
  tier=$(shorten_tier "$sub")
  generate_settings "$login" "$role" "$dir" "$platform" "$app" "$tier"
  ((configured++))
done < <(parse_members)

if [[ $configured -eq 0 && -n "$FILTER" ]]; then
  echo "error: surface '${FILTER}' not found in manifest.xml" >&2
  exit 1
fi

echo "Done: ${configured} surface(s) configured."
