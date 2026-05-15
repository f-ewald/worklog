# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Worklog is a Ruby CLI application for tracking work achievements locally. It uses Thor for CLI commands, stores data in human-readable YAML files, and prioritizes privacy by keeping all data local. Distributed as the `fewald-worklog` gem, it provides the `wl` command.

## Development Commands

```bash
bundle install                # Install dependencies
rake test                     # Run all tests (default rake task), includes coverage
ruby test/worklog_test.rb     # Run a single test file
rake rubocop                  # Run linter
rubocop -a                    # Auto-correct lint violations
rake yard                     # Generate YARD documentation
bundle exec guard             # Watch mode (tests + linting)
```

### Local Development

Set `WL_PATH` to load the local version instead of the installed gem:
```bash
export WL_PATH=/path/to/worklog
wl add "Test entry"
```

### Building

```bash
gem build worklog.gemspec
gem install fewald-worklog-*.gem
```

## Architecture

### Entry Point Flow

`bin/wl` -> `WorklogCLI` (Thor, `lib/cli.rb`) -> `Worklog::Worklog` (`lib/worklog.rb`, business logic)

### Data Storage

All data lives in `~/.worklog/` (configurable via `~/.worklog.yaml`):
- **Daily logs**: One YAML file per day (`YYYY-MM-DD.yaml`) containing `DailyLog` with array of `LogEntry` objects
- **People**: `people.yaml` - Person objects with handles, real names, teams, GitHub usernames
- **Projects**: `projects.yaml` - Project objects with keys, names, descriptions
- **Config**: `~/.worklog.yaml` - storage path, log level, timezone, webserver port, GitHub credentials

### Key Classes

- `Worklog::Worklog` (`lib/worklog.rb`): Main business logic, coordinates all operations
- `Worklog::Storage` (`lib/storage.rb`): File I/O for daily logs, YAML read/write, date range queries
- `Worklog::LogEntry` (`lib/log_entry.rb`): Individual entry (time, message, tags, ticket, URL, epic flag, project)
- `Worklog::DailyLog` (`lib/daily_log.rb`): Collection of entries for a single day
- `Worklog::Configuration` (`lib/configuration.rb`): Config management with nested `ProjectConfig` and `GithubConfig`
- `Worklog::PeopleStorage` / `Worklog::ProjectStorage`: Manage people/projects YAML files
- `Worklog::Printer` (`lib/printer.rb`): Console output formatting
- `LogEntryFormatters` (`lib/log_entry_formatters.rb`): Multiple formatters (Console, HTML, JSON)
- `Github::Client` (`lib/github/client.rb`): Fetches GitHub events via API; event parsers (`PullRequestEvent`, `PullRequestReviewEvent`, `PushEvent`) convert to `LogEntry` objects
- `DateParser` (`lib/date_parser.rb`): Flexible date parsing (today, yesterday, last Monday, ISO dates)
- `Hasher` (`lib/hasher.rb`): SHA256 key generation for entries
- `StringHelper` (`lib/string_helper.rb`): String utility methods, mixed into CLI
- `Worklogger` (`lib/worklogger.rb`): Logging utility

### MCP Server

`Worklog::McpServer` (`lib/mcp_server.rb`) exposes worklog data to LLMs via the Model Context Protocol (stdio transport). Uses `fast-mcp` gem.

- **Entry point**: `wl mcp` CLI command starts the stdio server
- **Shared state**: `Worklog::McpContext` module holds config, storage, people, and projects as class-level accessors
- **Tools** (`lib/mcp/tools/`): 7 read-only tools (query_entries, search_entries, list_tags, list_epics, list_people, list_projects, get_statistics)
- **Resources** (`lib/mcp/resources/`): 2 resources (people directory, projects list)
- **Helpers** (`lib/mcp/`): `DateHelper` (date range resolution), `EntrySerializer` (JSON serialization using `SimpleFormatter`)
- **Tests**: `test/mcp/` with shared `McpTestHelper` for context setup

### Important Patterns

**Date Handling**: User input times are converted to UTC for storage using `Time.strptime(...).utc`. Dates are stored as YAML filenames (`YYYY-MM-DD.yaml`). Timezone configured in `~/.worklog.yaml` (default: America/Los_Angeles).

**Entry Keys**: Generated using first 7 chars of SHA256 hash of message via `Hasher.sha256(message)`. Used for deduplication (e.g., GitHub sync won't create duplicate entries).

**People Mentions**: Extracted from messages using regex `/(?:\s|^)[~@](\w+)/`. Format: `~jdoe` or `@jdoe`. Validated against `people.yaml`; warnings shown for unknown handles.

**Project Validation**: Projects must exist in `projects.yaml` before use. Raises `ProjectNotFoundError` if invalid project key provided.

## Testing

- Uses Minitest with SimpleCov for coverage (goal: 100%)
- Test helper (`test/test_helper.rb`) provides `configuration_helper`, `storage_helper`, `teardown_configuration`
- Tests use temp directories (`Dir.tmpdir/worklog_test`) to avoid affecting real data
- One test file per source file; GitHub tests use fixture JSON in `test/github/data/`
- RuboCop excludes `test/` directory (see `.rubocop.yml`)

## Gem Distribution

- Gem name: `fewald-worklog`, executable: `wl`
- Version in `.version` file, loaded via `lib/version.rb`
- Requires Ruby >= 3.4.0 (version managed via `.tool-versions` for ASDF)
