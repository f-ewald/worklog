# Hourly GitHub Sync (worklogd)

`worklogd` is a companion executable that runs the GitHub sync (`wl github`) on a
schedule so your worklog stays current without you remembering to run it. On macOS
it is driven by [launchd](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html).

| Concern | How it is handled |
|---------|-------------------|
| Scheduling | launchd fires `worklogd run` every hour; the process runs once and exits |
| Reboots | A user `LaunchAgent` reloads at login |
| Sleep/wake | launchd runs the missed job once on wake (a plain `sleep` loop would drift) |
| Crashes | launchd restarts the job on the next interval |
| Overlap | A non-blocking lock makes a run skip if another sync is already in flight |

## Commands

```shell
worklogd install [--interval N]   # write + load the LaunchAgent, then sync once
worklogd uninstall                # unload and remove the LaunchAgent
worklogd status                   # show whether it is loaded + tail recent logs
worklogd sync                     # run one sync now (foreground); what launchd invokes
```

Bare `worklogd` is equivalent to `worklogd sync`.

## Prerequisites

`worklogd` reuses the same configuration as `wl github`. Set your GitHub
credentials in `~/.worklog.yaml` (see the main README), or `worklogd install`
will warn that syncs will no-op until they are present:

```yaml
github:
  api_key: your_github_personal_access_token
  username: your_github_username
```

## Installation

```shell
worklogd install
```

This:

1. Writes `~/Library/LaunchAgents/com.fewald.worklogd.plist`.
2. Loads it with `launchctl bootstrap gui/<uid>` (re-installing first boots out any
   existing copy, so it is idempotent).
3. Triggers an immediate first sync via `RunAtLoad`.

Change the cadence with `--interval` (seconds):

```shell
worklogd install --interval 1800   # every 30 minutes
```

### What the plist contains

The interpreter and script paths are resolved to absolute paths at install time —
launchd runs with a minimal environment (no shell `PATH`, no asdf shims), so the
plist invokes the exact Ruby and `worklogd` the gem is installed under:

```xml
<key>ProgramArguments</key>
<array>
  <string>/Users/you/.asdf/installs/ruby/3.4.7/bin/ruby</string>
  <string>/Users/you/.asdf/installs/ruby/3.4.7/.../bin/worklogd</string>
  <string>sync</string>
</array>
<key>StartInterval</key><integer>3600</integer>
<key>RunAtLoad</key><true/>
<key>StandardErrorPath</key><string>/Users/you/Library/Logs/worklogd.err</string>
<key>ProcessType</key><string>Background</string>
```

When the Postgres storage engine is selected, `WORKLOG_DATABASE_URL` is baked into
the plist's `EnvironmentVariables` (taken from the environment or
`storage.postgres.url`) so the background job can reach the database.

## Logs

| File | Written by | Rotation |
|------|------------|----------|
| `~/Library/Logs/worklogd.log` | the app logger | daily |
| `~/Library/Logs/worklogd.err` | launchd (stderr) | none — only used for crashes before the logger starts |

`worklogd status` tails the former. Logs are also visible in **Console.app** under
`~/Library/Logs`.

## Verifying it is running

```shell
worklogd status
launchctl print gui/$(id -u)/com.fewald.worklogd   # full launchd view
```

`launchctl print` shows the configured `StartInterval`, `RunAtLoad`, and the last
exit status.

## Error handling

`worklogd sync` is deliberately quiet about expected, transient problems. Missing
credentials, no network, and GitHub `403`/VPN errors are logged to
`worklogd.log` and the process exits `0` so launchd does not treat the run as a
crash. The sync is idempotent (events are de-duplicated by a content hash), so the
next interval simply tries again.

## Upgrading

After `gem update fewald-worklog`, the absolute path baked into the plist may point
at the previous gem version. Re-run `worklogd install` to refresh it.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `worklogd status` shows "not loaded" | Never installed, or booted out | Run `worklogd install` |
| No new entries in the log | `github.api_key`/`username` unset | Configure `~/.worklog.yaml`, then `worklogd install` |
| `launchctl bootstrap failed` | A stale copy is still loaded | `worklogd uninstall` then `worklogd install` |
| Works manually but not on schedule | Plist points at an old Ruby after an upgrade | Re-run `worklogd install` |
| "Another worklogd sync is in progress; skipping." | A previous run or manual `wl github` holds the lock | Expected; the lock is `~/.worklog/worklogd.lock` |

## Notes

- `worklogd` is a macOS-focused agent. On other platforms, schedule `wl github`
  with the platform's native scheduler (e.g. a systemd timer).
- It currently runs only the GitHub sync. The install/scheduling plumbing is
  separate from the synced task, so additional periodic tasks can be added later.
