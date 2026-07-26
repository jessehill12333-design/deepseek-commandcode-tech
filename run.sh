#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="${SCRIPT_DIR##*/}"
SCRIPT_NAME="${SCRIPT_NAME^}"

if [[ -t 1 ]]; then
    printf '\033]0;%s\007' "$SCRIPT_NAME"
fi

SAVED_DIR="/tumble-storage/tumble-script/_saved/deepseek-google-tech"
README_FILE="$SAVED_DIR/README.md"
KEY_FILE="$SAVED_DIR/gemini-api-key.env"

usage() {
    cat <<'EOF'
Usage: ./run.sh

Hands off an unresolved issue from DeepSeek to Command Code (GLM 5.2).
Reads issue context from _saved/deepseek-google-tech/README.md
and opens a new Konsole tab with command-code investigating it.

The user can continue the conversation interactively inside command-code.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

if ! command -v command-code &>/dev/null; then
    printf 'ERROR: command-code not found.\nInstall: npm i -g command-code\n' >&2
    exit 1
fi

if ! command -v konsole &>/dev/null; then
    printf 'ERROR: konsole not found.\n' >&2
    exit 1
fi

if [[ ! -f "$README_FILE" ]]; then
    printf 'ERROR: No issue context found at %s\n' "$README_FILE" >&2
    printf 'Write the issue that DeepSeek could not solve into that file and re-run.\n' >&2
    exit 1
fi

COMMANDCODE_API_KEY="${COMMANDCODE_API_KEY:-}"
if [[ -f "$KEY_FILE" ]]; then
    KEY_MODE="$(stat -c '%a' "$KEY_FILE" 2>/dev/null || echo '???')"
    if (( (8#$KEY_MODE & 0077) != 0 )); then
        printf 'ERROR: API key file permissions must be 600 or stricter: %s (mode %s)\n' "$KEY_FILE" "$KEY_MODE" >&2
        exit 1
    fi
    while IFS= read -r line; do
        case "$line" in
            ''|'#'*) ;;
            GEMINI_API_KEY=*)
                COMMANDCODE_API_KEY="${line#GEMINI_API_KEY=}"
                ;;
            *)
                printf 'ERROR: %s may contain only GEMINI_API_KEY and comments.\n' "$KEY_FILE" >&2
                exit 1
                ;;
        esac
    done < "$KEY_FILE"
fi

if [[ -z "$COMMANDCODE_API_KEY" ]]; then
    printf 'WARNING: No API key found. Command Code may use its own auth.\n' >&2
fi

MODEL="glm-5.2"

LAUNCHER="$(mktemp)"
trap 'rm -f -- "$LAUNCHER"' EXIT

cat > "$LAUNCHER" << EOF
#!/usr/bin/env bash
set -euo pipefail
TITLE="${SCRIPT_NAME^}"
if [[ -t 1 ]]; then printf '\033]0;%s\007' "\$TITLE"; fi
cd "$SAVED_DIR"
command-code --model "$MODEL" --yolo "\$(cat "$README_FILE")"
EXIT_CODE=\$?
if [[ \$EXIT_CODE -eq 0 ]]; then
    printf '\nSuccess.\n'
else
    printf '\nExited with code %d.\n' \$EXIT_CODE
fi
if [[ -t 1 ]]; then
    printf 'Press any key to exit...'
    read -r -n 1 -s < /dev/tty
fi
exit \$EXIT_CODE
EOF

chmod +x "$LAUNCHER"

printf 'Opening new Konsole tab with command-code (GLM 5.2) investigating the issue from %s...\n' "$README_FILE"
konsole --new-tab -e "$LAUNCHER"
