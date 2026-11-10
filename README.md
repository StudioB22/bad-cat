# bad-cat
Modular AI-based system for real-time detection of cats to protect plants. Deployed on Raspberry Pi. Part of StudioB22's autonomous garden defense line.

## Development

Every check runs locally, no GitHub workflow (ADR-0006, skill `local-ci`). Once per clone:

```bash
mise trust && mise x -- just setup
```

Then `just --list`: `just check` before a push (the pre-push hook runs it too), `just gate` on
the pushed head before a merge, `just merge <pr>`.
