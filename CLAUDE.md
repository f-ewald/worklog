# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Worklog is a Ruby CLI application for tracking work achievements locally. It uses Thor for CLI commands, stores data in human-readable YAML files, and prioritizes privacy by keeping all data local. The app is distributed as the `fewald-worklog` gem and provides the `wl` command.

## Development Commands

### Setup
```bash
bundle install
```

### Testing
```bash
# Run all tests with default rake task
rake test

# Run a single test file
ruby test/worklog_test.rb

# Run tests with coverage (SimpleCov)
rake test  # Coverage is automatically generated

# Watch mode for development (Guard)
bundle exec guard
```

### Linting
```bash
# Run RuboCop
rake rubocop

# Auto-correct violations
rubocop -a
```

### Documentation
```bash
# Generate YARD documentation
rake yard

# View documentation (generates to doc/ directory)
```

### Local Development
Set `WL_PATH` environment variable to load the local version instead of installed gem:
```bash
export WL_PATH=/path/to/worklog
wl add "Test entry"
```

### Building & Packaging
```bash
# Build the gem
gem build worklog.gemspec

# Install locally
gem install fewald-worklog-*.gem

# Package task (defined but minimal implementation)
rake package
```

## Architecture

### Data Storage
- **Storage path**: `~/.worklog/` (configurable via `~/.worklog.yaml`)
- **Daily logs**: One YAML file per day (`YYYY-MM-DD.yaml`) containing `DailyLog` objects with array of `LogEntry` objects
- **People**: `~/.worklog/people.yaml` - Person objects with handles, real names, teams, GitHub usernames, notes
- **Projects**: `~/.worklog/projects.yaml` - Project objects with keys, names, descriptions
- **Configuration**: `~/.worklog.yaml` - App settings (storage path, log level, timezone, webserver port, GitHub credentials)

### Key Classes

**Entry Point Flow**:
- `bin/wl` → `WorklogCLI` (Thor) → `Worklog::Worklog` (business logic)

**Core Classes**:
- `Worklog::Worklog` (`lib/worklog.rb`): Main business logic, coordinates all operations
- `Worklog::Storage` (`lib/storage.rb`): File I/O for daily logs, loads/writes YAML files, date range queries
- `Worklog::LogEntry` (`lib/log_entry.rb`): Individual entry with time, message, tags, ticket, URL, epic flag, project
- `Worklog::DailyLog` (`lib/daily_log.rb`): Collection of entries for a single day
- `Worklog::Configuration` (`lib/configuration.rb`): Config management with nested `ProjectConfig` and `GithubConfig`

**Storage Classes**:
- `Worklog::PeopleStorage` (`lib/people_storage.rb`): Manages people YAML file
- `Worklog::ProjectStorage` (`lib/project_storage.rb`): Manages projects YAML file
- `Worklog::Person` (`lib/person.rb`): Person model with handle, name, team, GitHub username
- `Worklog::Project` (`lib/project.rb`): Project model with key, name, description

**Formatters & Display**:
- `Worklog::Printer` (`lib/printer.rb`): Console output formatting for logs
- `LogEntryFormatters` (`lib/log_entry_formatters.rb`): Multiple formatters (Console, HTML, JSON) for different output contexts

**Integrations**:
- `Github::Client` (`lib/github/client.rb`): Fetches GitHub events via API
- `Github::PullRequestEvent`, `Github::PullRequestReviewEvent`, `Github::PushEvent`: Event parsers that convert to `LogEntry` objects

**Utilities**:
- `DateParser` (`lib/date_parser.rb`): Flexible date parsing (today, yesterday, last Monday, ISO dates)
- `Hasher` (`lib/hasher.rb`): SHA256 key generation for entries
- `Statistics` (`lib/statistics.rb`): Calculates stats (total days, entries, averages)
- `Standup` (`lib/standup.rb`): Generates standup summaries using OpenAI API
- `Summary` (`lib/summary.rb`): AI-powered summaries using Ollama/LangChain
- `Takeout` (`lib/takeout.rb`): Exports all data as tar.gz archive
- `Webserver` (`lib/webserver.rb`): Rack/Puma server for viewing logs in browser

### Important Patterns

**Date Handling**:
- User input times are converted to UTC for storage using `Time.strptime(...).utc`
- Dates are stored as YAML filenames (`YYYY-MM-DD.yaml`)
- Timezone configured in `~/.worklog.yaml` (default: America/Los_Angeles)

**Entry Keys**:
- Generated using first 7 chars of SHA256 hash of message via `Hasher.sha256(message)`
- Used for deduplication (e.g., GitHub sync won't create duplicate entries)

**People Mentions**:
- Extracted from messages using regex `/(?:\s|^)[~@](\w+)/`
- Format: `~jdoe` or `@jdoe` in message text
- Validated against `people.yaml` file, warnings shown for unknown handles

**Project Validation**:
- Projects must exist in `projects.yaml` before use
- Raises `ProjectNotFoundError` if invalid project key provided

**File Organization**:
- All main code in `lib/`, tests mirror structure in `test/`
- GitHub-related code in `lib/github/` and `test/github/`
- Thor CLI in `lib/cli.rb`, business logic in `lib/worklog.rb`

### Testing

**Test Setup**:
- Uses Minitest with SimpleCov for coverage
- Helper in `test/test_helper.rb` provides `configuration_helper`, `storage_helper`, `teardown_configuration`
- Tests use temp directories (`Dir.tmpdir/worklog_test`) to avoid affecting real data

**Test Structure**:
- One test file per source file (e.g., `worklog_test.rb` for `worklog.rb`)
- GitHub integration tests use fixture JSON files in `test/github/data/`

**Coverage**:
- Goal is 100% test coverage
- SimpleCov generates reports in `coverage/` directory
- CI uses Cobertura formatter

### Dependencies

**Runtime**:
- `thor` - CLI framework
- `rainbow` - Terminal colors
- `rack`, `rackup`, `puma` - Webserver
- `httparty`, `faraday` - HTTP clients for GitHub API
- `ruby-openai`, `langchainrb` - AI features (standup, summary)
- `tzinfo` - Timezone handling

**Development/Test**:
- `minitest` - Testing framework
- `rubocop`, `rubocop-minitest`, `rubocop-rake` - Linting
- `guard`, `guard-minitest`, `guard-rubocop` - Watch mode
- `simplecov`, `simplecov-cobertura` - Coverage
- `webmock` - HTTP mocking for tests
- `yard`, `rdoc` - Documentation

### Gem Distribution

- Gem name: `fewald-worklog`
- Executable: `wl`
- Version stored in `.version` file and loaded via `lib/version.rb`
- Requires Ruby >= 3.4.0
- Files included: `lib/**/*.{erb,rb}`, `assets/**/*.{erb,rb}`, `.version`
- Homepage: https://github.com/f-ewald/worklog
- Documentation: https://f-ewald.github.io/worklog
