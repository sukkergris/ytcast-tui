# ytcast-tui

- Everything is en-US: UI text, help, README, release notes and commit messages (conventional commits, e.g. `fix(ui): ...`). This overrides any global rule about Danish commits.
- Release: bump `app=` in `bin/ytcast`, commit `chore(release): ytcast <version>`, annotated tag `v<version>`, `git push --follow-tags`. Then write `release-notes/v<version>.md` (`## New` = feat, `## Fixes` = fix, chore omitted) from `git log v<previous>..v<version>`, commit, push, and run `gh release create v<version> --title "ytcast <version>" --notes-file release-notes/v<version>.md --verify-tag`.
