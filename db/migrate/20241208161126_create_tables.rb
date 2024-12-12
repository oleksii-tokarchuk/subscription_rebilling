# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :subscriptions do
      primary_key :id
      column :amount_cents, :integer, null: false
      column :next_renewal_at, :date, null: false
      column :status, :string, null: false, default: 'pending'

      check(status: %w[pending paid partially_paid failed])
    end

    create_table :renewal_invoices do
      primary_key :id
      foreign_key :subscription_id, :subscriptions, null: false, on_delete: :restrict
      column :amount_cents, :integer, null: false
      column :amount_cents_left, :integer, null: false
      column :invoiced_at, :date, null: false
      column :status, :string, null: false, default: 'pending'

      unique %i[subscription_id invoiced_at]
      check(status: %w[pending paid partially_paid failed])
    end

    create_table :payments do
      primary_key :id
      foreign_key :renewal_invoice_id, :renewal_invoices, null: false, on_delete: :restrict
      column :amount_cents, :integer, null: false
      column :status, :string, null: false, default: 'pending'
      column :paid_at, :datetime
      column :is_partial, :boolean, default: false

      check(status: %w[pending paid insufficient_funds failed])
    end
  end
end
