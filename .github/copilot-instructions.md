# Copilot Instructions for Worklog

## Build, Test, and Lint

```sh
# Run all tests
bundle exec rake test

# Run a single test file
bundle exec ruby -Ilib -Itest test/log_entry_test.rb

# Run linter
bundle exec rake rubocop

# Watch mode (runs tests + rubocop on file changes)
bundle exec guard
```

Ruby version is managed via asdf: `ruby 3.4.7` (see `.tool-versions`).

## Architecture

The codebase follows a layered CLI architecture:

- **`bin/wl`** → **`lib/cli.rb`** (`WorklogCLI < Thor`): Thin Thor-based CLI layer. Each command instantiates `Worklog::Worklog` and delegates immediately.
- **`lib/worklog.rb`** (`Worklog::Worklog`): Business logic hub. Owns `Storage`, `PeopleStorage`, `ProjectStorage`, and coordinates all commands.
- **`lib/storage.rb`** (`Worklog::Storage`): Reads/writes one YAML file per day to `~/.worklog/YYYY-MM-DD.yaml`. Log entries are sorted by time on write.
- **`lib/daily_log.rb`** / **`lib/log_entry.rb`**: Core data model. `DailyLog` holds a date and an array of `LogEntry` objects.
- **`lib/configuration.rb`** (`Worklog::Configuration`): Loads `~/.worklog.yaml`. Provides `GithubConfig` and `ProjectConfig` subconfigs.
- **`lib/github/`**: Fetches GitHub events (PRs, reviews, pushes) via HTTParty and converts them to `LogEntry` objects.
- **`lib/llm/`**: LangChain-based LLM integration for AI-powered summaries.
- **`lib/webserver.rb`**: Rack/Puma server for web-based log viewing.
- **`lib/log_entry_formatters.rb`**: `ConsoleFormatter` (colored, with emoji) and `SimpleFormatter` (plain text) for rendering entries.

## Key Conventions

### Frozen string literals
Every file must start with `# frozen_string_literal: true`.

### Serialization pattern
Classes include the `Hashify` module (`lib/hash.rb`) to get `to_hash` / `to_yaml`. Deserialization uses a `from_hash(hash)` class method that takes a symbolized-key hash. YAML files always use `stringify_keys` (string keys, not symbols) so they're language-agnostic.

```ruby
# Adding a new serializable class:
class MyModel
  include Hashify
  attr_accessor :field1, :field2

  def self.from_hash(hash)
    new(**hash)
  end
end
```

### Testing
- Framework: **Minitest** (not RSpec).
- Each `lib/foo.rb` has a corresponding `test/foo_test.rb`.
- `test/test_helper.rb` provides `configuration_helper`, `storage_helper`, and `teardown_configuration` for isolated test setup using a temp directory.
- RuboCop is **excluded** from `test/` (see `.rubocop.yml`), but `rubocop-minitest` and `rubocop-rake` plugins are active for lib.

### People references
Users are mentioned in log messages with `@handle` or `~handle`. `LogEntry#people` extracts them via `PERSON_REGEX = /(?:\s|^)[~@](\w+)/`. Known people are loaded from `~/.worklog/people.yaml` at startup.

### Entry deduplication
Log entries are keyed by a 7-character SHA256 hash of their message (`Worklog::Hasher.sha256(message)`). The GitHub sync uses this key to skip duplicate entries.

### MCP server
The app exposes itself as an MCP server via `wl mcp`. The local config is at `.mcp.json`.
