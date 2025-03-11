# Worklog

The documentation is hosted on [Github Pages](https://f-ewald.github.io/worklog).

Track your work right in your terminal and prepare for performance reviews.

This application stores all data in human-readable [YAML](https://yaml.org) files.
This is a conscious descision to allow migration to and from this application and to prevent a vendor lock-in. All data is stored in `~/.worklog/`.

Worklog is currently (early 2025) in active development. The main functionality is implemented and works stable. Test coverage is currently around 80%.

## Features

* Track line items of work and add urls, ticket ids, tags, people, milestones (epics)
* Show past entries with multiple filters
* Show interactions with people
* Show statistics
* Show log as website, including a mode for presentation / screen sharing

## Installation

Clone the application from Github in a convenient location:

```shell
git clone git@github.com:f-ewald/worklog.git
```

Install the application by running the following command from the root directory. This requires the Ruby version defined in the [.tool-versions](.tool-versions) file (for [ASDF](https://asdf-vm.com)) and referenced in the [Gemfile.lock](Gemfile.lock).

```shell
bundle install
```

## Usage

To add an entry with todays date and the current time, run the following command:

```shell
./cli.rb add "This is an example" --tags tag1,tag2,tag3 --epic --url "http://example.com" --ticket WL-123
```

Then verify that it is saved by printing all logs from the current day:

```shell
./cli.rb show
```

To show all the people you interacted with, type:

```shell
./cli.rb people
```

Run a basic webserver on port 9292 via:

```shell
./cli.rb serve
```

Show all used tags:

```shell
./cli.rb tags
```

Create an AI summary (experimental). Requires [Ollama](https://www.ollama.com) with `llama3.2`:

```shell
./cli.rb summary
```


```shell
./cli.rb help [subcommand]
```
