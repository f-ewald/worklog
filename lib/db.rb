# frozen_string_literal: true

require 'worklogger'

module Worklog
  # Database connection helpers for the Postgres (and test-only SQLite)
  # storage backends. Provides a single memoized Sequel::Database per
  # process and runs migrations on first connect.
  #
  # Sequel and the underlying adapter (`pg` or `sqlite3`) are loaded
  # lazily so YAML users do not pay the cost of requiring them.
  module DB
    # Raised when the user has selected the Postgres engine but no
    # connection URL has been configured.
    class ConfigurationError < StandardError; end

    class << self
      # Return a memoized Sequel::Database instance for the given config.
      # On first call, connects, verifies the connection, and runs any
      # pending migrations.
      # @param config [Worklog::Configuration]
      # @return [Sequel::Database]
      def connection(config)
        @connection ||= connect!(config)
      end

      # Reset the memoized connection. Intended for tests that need a
      # fresh in-memory database between cases.
      # @return [void]
      def reset!
        @connection&.disconnect
      rescue StandardError
        # Ignore disconnect errors; the connection may already be gone.
      ensure
        @connection = nil
      end

      # Absolute path to the directory containing Sequel migrations.
      # @return [String]
      def migrations_path
        File.expand_path('../db/migrations', __dir__)
      end

      # Connect to the database based on the configured engine, run
      # pending migrations, and return the Sequel::Database.
      # @param config [Worklog::Configuration]
      # @return [Sequel::Database]
      def connect!(config)
        require 'sequel'
        url = connection_url(config)
        require_adapter(url)

        WorkLogger.debug "Connecting to database (engine=#{config.storage_engine})"
        db = Sequel.connect(url, max_connections: config.postgres_pool || 5)
        db.test_connection
        run_migrations!(db)
        db
      rescue LoadError => e
        abort_with("Storage requires a database adapter: #{e.message}. " \
                   "Install the 'sequel' and 'pg' gems and retry.")
      rescue Sequel::DatabaseConnectionError => e
        abort_with("Cannot connect to the database: #{e.message}. " \
                   'Check storage.postgres.url in ~/.worklog.yaml.')
      end

      # Apply any pending Sequel migrations in `db/migrations/`.
      # @param db [Sequel::Database]
      # @return [void]
      def run_migrations!(db)
        require 'sequel/extensions/migration'
        Sequel::Migrator.run(db, migrations_path)
      end

      private

      # Resolve the connection URL from the configuration. Tests inject
      # `sqlite::memory:` via the `WORKLOG_DATABASE_URL` env var.
      # @param config [Worklog::Configuration]
      # @return [String]
      def connection_url(config)
        env_url = ENV.fetch('WORKLOG_DATABASE_URL', nil)
        return env_url if env_url && !env_url.empty?

        url = config.postgres_url
        if url.nil? || url.empty?
          raise ConfigurationError,
                'Postgres engine selected but storage.postgres.url is not set.'
        end

        url
      end

      # Ensure the right driver gem is loadable for the given URL.
      # @param url [String]
      # @return [void]
      def require_adapter(url)
        return require 'sqlite3' if url.start_with?('sqlite')

        require 'pg'
      end

      # Print a user-friendly error and exit non-zero.
      # @param message [String]
      def abort_with(message)
        WorkLogger.error(message)
        raise SystemExit.new(1), message
      end
    end
  end
end
