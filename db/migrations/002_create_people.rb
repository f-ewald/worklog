# frozen_string_literal: true

Sequel.migration do
  change do
    is_postgres = database_type == :postgres

    create_table :people do
      primary_key :id
      String :handle, null: false, unique: true
      String :name, null: false
      String :github_username
      String :email
      String :team

      if is_postgres
        column :notes, 'text[]'
      else
        String :notes, text: true # JSON-encoded array fallback for non-PG adapters
      end

      TrueClass :inactive, default: false

      index :github_username
    end
  end
end
