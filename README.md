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

Worklog is currently (early/mid 2025) in **active development**. The main functionality is implemented and works reliably. I am using the app multiple times per day.

## Features

An (incomplete) list of the currently available features.

* Track line items of work and add urls, ticket ids, tags, people, milestones (epics)
* Show past entries with multiple filters
* Show interactions with people
* Show statistics
* Show log as website, including a mode for presentation well suited for screen sharing

## Installation

The most straightforward way to install this CLI is to use [Rubygems](https://rubygems.org).

```shell
gem install fewald-worklog
```

This installs the worklog globally and adds the CLI as `wl`. Refer to the section "usage" on how to use the CLI or run `wl help`.

## Usage

To add an entry with todays date and the current time, run the following command:

```shell
wl add "This is an example" --tags tag1,tag2,tag3 --epic --url "http://example.com" --ticket WL-123
```

Then verify that it is saved by printing all logs from the current day:

```shell
wl show
```

To show all the people you interacted with, type:

```shell
wl people
```

Run a basic webserver on port 9292 via:

```shell
wl serve
```

Show all used tags:

```shell
wl tags
```

Create an AI summary (experimental). Requires [Ollama](https://www.ollama.com) with `llama3.2`:

```shell
wl summary
```


```shell
wl help [subcommand]
```

## Development

Clone the application from Github in a convenient location:

```shell
git clone git@github.com:f-ewald/worklog.git
```

Install the application by running the following command from the root directory. This requires the Ruby version defined in the [.tool-versions](.tool-versions) file (for [ASDF](https://asdf-vm.com)) and referenced in the [Gemfile.lock](Gemfile.lock).

```shell
bundle install
```

