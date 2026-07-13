# frozen_string_literal: true

Sequel.migration do
  change do
    is_postgres = database_type == :postgres

    create_table :projects do
      primary_key :id
      String :key, null: false, unique: true
      String :name
      String :description, text: true
      Date :start_date
      Date :end_date
      String :status

      if is_postgres
        column :repositories, :jsonb
      else
        String :repositories, text: true # JSON-encoded array fallback for non-PG adapters
      end
    end
  end
end
