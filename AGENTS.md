# AGENTS.md — deepseek-commandcode-tech

## Purpose

Hand off an unresolved issue from DeepSeek to Command Code (GLM 5.2).
Reads issue context from `_saved/deepseek-google-tech/README.md`
and opens a new Konsole tab with `command-code` so the user can
continue investigating interactively with GLM 5.2.

## Editing rules

- Keep `run.sh` as the stable entry point; do not rename or replace it.
- Do not add comments unless explicitly requested.
- The model is set to `glm-5.2`; change the `MODEL` variable in `run.sh` to switch.
- The issue context is read from `_saved/deepseek-google-tech/README.md` (shared with deepseek-google-tech).
- API key is optionally sourced from `_saved/deepseek-google-tech/gemini-api-key.env` for compatibility.
- Never commit secrets or API keys to the repository.
