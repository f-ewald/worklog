# Worklog

Track your work right in your terminal and prepare for performance reviews.

This application stores all data in human-readable [YAML](https://yaml.org) files.
This is a conscious descision to allow migration to and from this application and to prevent a vendor lock-in. All data is stored in `~/.worklog/`.

## Installation

Clone the application from Github in a convenient location:

```shell
git clone git@github.com:f-ewald/worklog.git
```

Install the application by running the following command from the root directory. This requires the Ruby version defined in the [.tool-versions](.tool-versions) file (for ASDF) and in the [Gemfile](Gemfile)

```shell
bundle install
```

## Usage

To add an entry with todays date and the current time, run the following command:

```shell
./worklog.rb add "This is an example"
```

Then verify that it is saved by printing all logs from the current day:

```shell
./worklog.rb show
```

To show information about all available commands run

```shell
./worklog.rb help
```
