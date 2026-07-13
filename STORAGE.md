# Storage Engines

Worklog supports two storage engines for daily logs, people, and projects:

| Engine     | Default? | Where data lives                                    |
|------------|----------|-----------------------------------------------------|
| `yaml`     | Yes      | One file per day under `~/.worklog/` plus `people.yaml` and `projects.yaml` |
| `postgres` | No       | Tables in a PostgreSQL database (`daily_logs`, `log_entries`, `people`, `projects`) |

The choice is made in `~/.worklog.yaml`. Everything else (CLI commands, web server, GitHub sync, statistics) works the same regardless of which engine is selected.

## Selecting an Engine

Edit `~/.worklog.yaml` (created by `wl init`):

```yaml
storage:
  engine: yaml          # or 'postgres'
  yaml:
    path: /Users/you/.worklog
  postgres:
    url: postgres://user:pass@localhost:5432/worklog
    # The URL can reference environment variables:
    # url: "${WORKLOG_DATABASE_URL}"
    pool: 5
```

Only the block matching the selected engine needs to be populated. The other block is ignored at runtime.

### Backward Compatibility

Configurations that pre-date the storage engine support — a flat `storage_path:` key at the root with no `storage:` block — are read as if they had:

```yaml
storage:
  engine: yaml
  yaml:
    path: <the old storage_path value>
```

No manual upgrade is required.

## PostgreSQL Setup

1. Create a database:

   ```shell
   createdb worklog
   ```

2. Point the configuration at it (see above) or export `WORKLOG_DATABASE_URL`, which takes precedence over the value in the config file when present.

3. The schema is created automatically on the first run via [Sequel migrations](https://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html) shipped in `db/migrations/`.

The schema:

```
daily_logs  (id, date)
log_entries (id, daily_log_id, key, source, time, tags TEXT[], ticket, url, epic, message, project)
people      (id, handle, name, github_username, email, team, notes TEXT[], inactive)
projects    (id, key, name, description, start_date, end_date, status, repositories JSONB)
```

On non-PostgreSQL adapters (e.g., SQLite, used by the test suite), the `text[]` and `jsonb` columns degrade gracefully to `TEXT` columns holding JSON-encoded payloads. The storage backend transparently handles both representations.

### Optional Dependencies

The `sequel` and `pg` gems are declared in `worklog.gemspec` but are only loaded when the Postgres engine is selected. YAML-only users pay no startup cost. If the gems are missing at runtime, you'll see:

```
Storage requires a database adapter: cannot load such file -- pg. Install the 'sequel' and 'pg' gems and retry.
```

## Migrating Between Engines

The `wl storage` subcommands move data between engines via YAML files. The engine in your configuration is always the "current" engine — `export` reads from it, `import` writes to it.

### YAML → PostgreSQL

```shell
# 1. Export the YAML data to a backup directory (still on the YAML engine)
wl storage export --format=yaml --path=/tmp/worklog_backup

# 2. Switch the engine in ~/.worklog.yaml to 'postgres'

# 3. Import the backup into PostgreSQL
wl storage import --format=yaml --path=/tmp/worklog_backup
```

### PostgreSQL → YAML

```shell
# Engine is currently 'postgres'
wl storage export --format=yaml --path=/tmp/worklog_yaml_backup

# Switch the engine back to 'yaml' in ~/.worklog.yaml
# Optionally copy the backup into ~/.worklog/
cp /tmp/worklog_yaml_backup/* ~/.worklog/
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Cannot connect to the database: …` | Wrong URL or DB not running | Check `storage.postgres.url`; verify `psql <url>` works |
| `Storage requires a database adapter: …` | `sequel` or `pg` gem missing | `gem install sequel pg` |
| Empty data after switching engines | New engine starts empty | Run `wl storage import --format=yaml --path=…` |
| `Unknown storage engine: …` | Typo in `storage.engine` | Must be `yaml` or `postgres` |

## Tests

The PostgreSQL storage backend is exercised against an in-memory SQLite database in the test suite. The same migrations and storage classes are used; the only difference is which Sequel adapter is loaded. See `test/storage/postgres_test.rb` and `test/db_test.rb` for examples.

To run the tests against a real PostgreSQL instance set `WORKLOG_DATABASE_URL`:

```shell
WORKLOG_DATABASE_URL=postgres://localhost/worklog_test bundle exec rake test
```
