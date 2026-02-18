# Release Process

This repository uses Release Drafter to maintain a draft GitHub release.

## One-time setup
- Ensure the default branch is `main`.
- Add labels used by the release config: `feature`, `enhancement`, `fix`, `bug`, `chore`, `refactor`, `docs`, `ci`.

## Regular release steps
1. Merge PRs as usual. Release Drafter will update a draft release on each merge.
2. When ready to ship, open the draft release in GitHub, edit if needed, and publish.
3. Publishing the release will create the version tag (e.g., `v0.1.0`).

## Notes
- If you want a different versioning scheme, adjust `.github/release-drafter.yml`.
