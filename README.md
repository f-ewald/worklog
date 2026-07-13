# Worklog

[![Gem Version](https://badge.fury.io/rb/fewald-worklog.svg)](https://badge.fury.io/rb/fewald-worklog)

The documentation, including this readme, is hosted on [Github Pages](https://f-ewald.github.io/worklog).

**Worklog** is a command line interface (CLI) to track your achievements right from your terminal.
I created this application initially for myself to have a permanent record on my local computer for **performance reviews**. Often times, those reviews ask me to summarize my achievements over the past 6-12 months and I realized it's very easy to forget something. Not everything I do has a ticket assigned to it.
I don't write down every interaction or time that I help out others on the team or outside. Using this CLI allows me to keep track of minor and major work items and interactions so that I am prepared when performance reviews are due.

The app has been created with the following **design principles** in mind:

* Use only **human-readable files** to store information. This prevents vendor lock in and allows everybody to take their files with them at any time. It also makes it very clear what data is stored
* Prioritize **privacy** by keeping all data local and not enabling any telemetry
* Use **reasonable defaults**. The application should work for the user, not the other way around
* High **unit test coverage**, with the goal of 100%.

Worklog is currently (late 2025) in **active development**. The main functionality is implemented and works reliably. I am using the app multiple times per day.

## Features

An (incomplete) list of the currently available features.

* Track line items of work and add urls, ticket ids, tags, people, milestones (epics)
* Show past entries with multiple filters, see `wl help show`
* Manage projects
* Show interactions with people, add notes, real names and organizational details
* Show statistics
* Show log as website, including a mode for presentation well suited for screen sharing
* Export all entries and settings as a tar.gz archive
* Synchronization of Github pull requests and reviews as worklog entries

## Installation

The most straightforward way to install this CLI is to use [Rubygems](https://rubygems.org).

```shell
gem install fewald-worklog
```

This installs the worklog globally and adds the CLI as `wl`. Refer to the section "usage" on how to use the CLI or run `wl help`.

As a next step it is recommended to run `wl init` to initialize the storage in your home directory (`~/.worklog`).
Additionally, this will create:

* a default configuration file at `~/.worklog.yaml`
* a default people file at `~/.worklog/people.yaml`
* a default projects file at `~/.worklog/projects.yaml`

## Usage

To add an entry with todays date and the current time, run the following command:

```shell
wl add "This is an example" --tags tag1,tag2,tag3 --epic --url "http://example.com" --ticket WL-123 --project renovation
```

Then verify that it is saved by printing all logs from the current day:

```shell
wl show
```

This commands prints by default the current day, depending on the system time. It is also possible to show a date range, show only epics or filter by tag or project. To view all possible options and filters, run `wl help show`.

To show all the people you interacted with, type the following command. In addition, you can show details about a specific person by providing their handle (e.g. `jdoe`):

```shell
wl people [--inactive] [handle]
```

Show all currently active projects/initiatives, optionally as one line for a quick overview

```shell
wl projects [--oneline]
```

Github pull requests and reviews can be synchronized as worklog entries. This downloads up to 30 days and 300 events (whichever is less) as worklog entries. Duplicate entries are ignored, so it is safe to run this command multiple times. This command requires a configured username and token.

You will need to set the follwing configuration options in your `~/.worklog.yaml` file:

```yaml
github:
  api_key: your_github_personal_access_token
  username: your_github_username
```

To synchronize the Github account, run the following command:

```shell
wl github
```

On macOS you can run this automatically every hour — see [Running the GitHub sync hourly on macOS](#running-the-github-sync-hourly-on-macos).

### Standup

Create a standup message for the current day. This will generate a message based on the entries of the current day and print it to the console. The message is generated ChatGPT and can be used as a template for your daily standup. You can also specify a date range to generate a message for a specific day or week.
See `wl help standup` for more details.

```shell
wl standup
```

For example, to generate a standup message for the past week, run:

```shell
wl standup --days 7
```

### Webserver

Run a webserver on [localhost:9292](http://localhost:9292) via:

```shell
wl serve
```

Show all used tags or list all entries with a specific tags. By default, this shows tags used in the current day. To show tags over a different date range, use the `--date`, `--from`, `--to`, or `--days` options.

```shell
wl tags
wl tags bugfix
```

Export all worklog data as a `tar.gz` archive:

```shell
wl takeout
```

Create an AI summary (experimental). Requires [Ollama](https://www.ollama.com) with `llama3.2`:

```shell
wl summary
```

Remove the latest entry (**use with caution**):

```shell
wl remove|rm
```


```shell
wl help [subcommand]
```

Fuzzy searching is not directly implemented in worklog. It is recommended to use a third-party tool, like [`skim`](https://github.com/skim-rs/skim), or [`fzf`](https://github.com/junegunn/fzf) to search. Fuzzy searching over the past 180 days can be done like this:

```shell
wl show --days 180 2>/dev/null | sk
```

### Storage Engines

By default, worklog stores everything in human-readable YAML files under `~/.worklog/`. A PostgreSQL backend is also available and can be selected in `~/.worklog.yaml`:

```yaml
storage:
  engine: postgres
  postgres:
    url: postgres://user:pass@localhost:5432/worklog
```

Use `wl storage export --path=DIR` and `wl storage import --path=DIR` to move data between engines (via YAML files). See [STORAGE.md](STORAGE.md) for the full reference, schema, troubleshooting, and migration walkthroughs.

### Running the GitHub sync hourly on macOS

On macOS, the `worklogd` companion agent keeps your worklog in sync automatically by running the GitHub sync once an hour via [launchd](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html). launchd — not a long-running process — owns the schedule, so syncing survives reboots, catches up after the Mac sleeps, and restarts on failure.

```shell
worklogd install      # write + load the hourly LaunchAgent (runs a first sync now)
worklogd status       # is it loaded? prints recent log lines
worklogd uninstall    # unload and remove it
worklogd sync         # run one sync in the foreground (what launchd invokes)
```

Pass `worklogd install --interval 1800` to sync more often than the default hour. Logs are written to `~/Library/Logs/worklogd.log` (rotated daily). The sync is idempotent and reuses the `github:` configuration from `~/.worklog.yaml`, so it is safe to run alongside manual `wl github` runs.

Re-run `worklogd install` after upgrading the gem so the LaunchAgent points at the current Ruby. See [DAEMON.md](DAEMON.md) for the full reference, plist details, and troubleshooting.

## Development

Clone the application from Github in a convenient location:

```shell
git clone git@github.com:f-ewald/worklog.git
```

Install the application by running the following command from the root directory. This requires the Ruby version defined in the [.tool-versions](.tool-versions) file (for [ASDF](https://asdf-vm.com)) and referenced in the [Gemfile.lock](Gemfile.lock).

```shell
bundle install
```

### Ruby version

This project uses [asdf](https://asdf-vm.com) to manage the Ruby version.
The required version is pinned in `.tool-versions`. To install it:

```shell
# Install the asdf Ruby plugin (once)
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git

# Install the exact Ruby version declared in .tool-versions
asdf install
```

### Running tests

```shell
# Run the full test suite
bundle exec rake test

# Run a single test file
bundle exec ruby -Ilib -Itest test/log_entry_test.rb

# Run linter
bundle exec rake rubocop
```

### Watch mode

Guard automatically runs tests and RuboCop when files change:

```shell
bundle exec guard
```

### Local development

Set the `WL_PATH` environment variable to point to your checkout so that
`wl` loads from local source instead of the installed gem:

```shell
export WL_PATH=$(pwd)
wl add "Testing a local change"
```

Unset `WL_PATH` to switch back to the installed gem.

