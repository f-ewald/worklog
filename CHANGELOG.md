# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [0.4.0] — Best-Practices Improvements

### Added
- `StorageFactory` helper centralises backend selection for all three storage modules
- Minimum 80% code-coverage threshold enforced via SimpleCov
- Unique temporary directories per test to prevent test interference
- `CHANGELOG.md` following Keep a Changelog format
- CLI command reference table in README
- Complete developer onboarding section in README

### Fixed
- `days_between` no longer mutates loaded `DailyLog` entries in place
- `pull_request_data` and `pull_request_comments` now use the configured API key instead of the undefined `TOKEN` constant
- `WL_PATH` dev override now validates the target directory exists before adding it to `$LOAD_PATH`

### Changed
- `puma` is now an optional runtime dependency; `wl serve` prints a helpful install hint if it is missing
- CI workflows now use minimum required GitHub token permissions instead of `write-all`
- CI now runs tests and linting before publishing the gem
- CI tests against Ruby 3.4 and 3.5 (matrix)
- `.rubocop_todo.yml` reduced from 149 to 95 lines

### Security
- Upgraded `actions/checkout` from v2 to v4 in all CI workflows

---

## [0.3.27] — Activity Graph

### Added
- Activity graph displayed in `wl stats` output

## [0.3.26] — Ticket URL Extraction

### Added
- Automatic ticket extraction from issue tracker URLs when adding entries with `--url`

## [0.3.25] — Postgres Storage Backend

### Added
- Postgres storage backend as an alternative to the default YAML backend
- `wl storage` command for import/export between backends

## [0.3.0] — MCP Server

### Added
- MCP server mode (`wl mcp`) for AI assistant integration

## [0.2.0] — Daemon & GitHub Sync

### Added
- `worklogd` daemon for macOS (launchd integration)
- Hourly GitHub event sync (pull requests, reviews, pushes)

## [0.1.0] — Initial Release

### Added
- Core `wl add`, `wl show`, `wl stats`, `wl people`, `wl tags` commands
- YAML-backed daily log storage
- Rack/Puma web server (`wl serve`)
- LLM-powered summary (`wl summary`)

[Unreleased]: https://github.com/f-ewald/worklog/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/f-ewald/worklog/compare/v0.3.28...v0.4.0
[0.3.27]: https://github.com/f-ewald/worklog/compare/v0.3.26...v0.3.27
[0.3.26]: https://github.com/f-ewald/worklog/compare/v0.3.25...v0.3.26
[0.3.25]: https://github.com/f-ewald/worklog/compare/v0.3.0...v0.3.25
[0.3.0]: https://github.com/f-ewald/worklog/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/f-ewald/worklog/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/f-ewald/worklog/releases/tag/v0.1.0
