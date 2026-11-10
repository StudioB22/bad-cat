# Branch protection — `main`

`main` only moves through squash-merged pull requests whose head carries the `gate` attestation.
This file documents the ruleset to apply and the exact commands; the configuration itself lives
on GitHub (repository ruleset `main`), not in the repository.

## Policy

| Setting | Value |
| --- | --- |
| Require a pull request before merging | yes, squash only, every review thread resolved |
| Required status checks | `gate` — the commit status written by `just gate` on the pushed head together with its signed note (ADR-0006, skill `local-ci`); branch up to date before merge (strict) |
| Required approving reviews | 0 (no reviewer bot; 1 once a second maintainer reviews) |
| Dismiss stale approvals on new commits | yes |
| Bypass actors | none |
| Force push (`non_fast_forward`) | blocked |
| Branch deletion | blocked |

The required check is a commit status, not a workflow job: no GitHub workflow exists (ADR-0006).
`scripts/attest.sh write gate` posts `gate` = success through the REST Statuses API, last, after
the signed note is pushed, so a green status always has its note; `just merge <pr>` verifies both
on the exact head SHA before `gh pr merge`. Run `just merge` from an up-to-date `main` checkout,
so the `merge` recipe itself is the trusted one.

On the bootstrap pull request (the one that introduces ADR-0006): run `just gate` on its pushed
head first (the first `gate` report), then apply the ruleset below, then merge with
`gh pr merge` under the owner's explicit waiver (`.github/allowed_signers` is not on `main` yet,
so `just merge` cannot verify the note). Every later merge goes through `just merge <pr>`.

## Apply (one-time, by owner)

```bash
gh api repos/StudioB22/bad-cat/rulesets --method POST --input - <<'EOF2'
{
  "name": "main",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [],
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": {
        "allowed_merge_methods": ["squash"],
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_approving_review_count": 0,
        "required_review_thread_resolution": true } },
    { "type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": true,
        "do_not_enforce_on_create": false,
        "required_status_checks": [ { "context": "gate" } ] } }
  ]
}
EOF2
```

`integration_id` is omitted on the `gate` check so GitHub accepts the status from whoever last
reported it (the owner's `gh`, through `scripts/attest.sh`).

## Verify

```bash
gh api repos/StudioB22/bad-cat/rulesets --jq '.[] | select(.name == "main") | .id' \
  | xargs -I{} gh api repos/StudioB22/bad-cat/rulesets/{} --jq '{
  enforcement,
  checks: [.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context],
  strict: [.rules[] | select(.type == "required_status_checks") | .parameters.strict_required_status_checks_policy][0],
  reviews: [.rules[] | select(.type == "pull_request") | .parameters.required_approving_review_count][0],
  methods: [.rules[] | select(.type == "pull_request") | .parameters.allowed_merge_methods][0],
  rules: [.rules[].type] }'
```

Expected: `enforcement` active, `checks` `["gate"]`, `strict` true, `reviews` 0, `methods`
`["squash"]`, rules `deletion`, `non_fast_forward`, `pull_request`, `required_status_checks`.

## Remove (emergency only)

```bash
gh api repos/StudioB22/bad-cat/rulesets/<id> --method PATCH -f enforcement=disabled
```

Re-enable (`-f enforcement=active`) immediately after the emergency; log the reason in
`PROJECT_LOG.md`.
