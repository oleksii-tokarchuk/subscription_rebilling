# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :subscriptions do
      primary_key :id
    end
  end
end
