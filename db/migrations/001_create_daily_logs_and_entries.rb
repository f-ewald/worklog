# frozen_string_literal: true

Sequel.migration do
  change do
    # `database_type` is only available in this outer block. Capture it
    # so the nested create_table generator can branch on it.
    is_postgres = database_type == :postgres

    create_table :daily_logs do
      primary_key :id
      Date :date, null: false, unique: true
    end

    create_table :log_entries do
      primary_key :id
      foreign_key :daily_log_id, :daily_logs, null: false, on_delete: :cascade
      String :key
      String :source, default: 'manual'
      DateTime :time, null: false

      if is_postgres
        column :tags, 'text[]'
      else
        String :tags, text: true # JSON-encoded array fallback for non-PG adapters
      end

      String :ticket
      String :url
      TrueClass :epic, default: false
      String :message, text: true
      String :project

      index :daily_log_id
      index :project
    end
  end
end
