class CreateCopaymentRelations < ActiveRecord::Migration
  def change
    create_table :copayment_relations do |t|
      t.integer :relatable_id
      t.integer :related_to_id
      t.decimal :discount_amount, precision: 8, scale: 2, default: 0.0
      t.integer :position

      t.timestamps null: false
    end

    add_index :copayment_relations, :relatable_id
    add_index :copayment_relations, :related_to_id
    add_index :copayment_relations, [:relatable_id, :related_to_id], name: 'index_copayment_relations_ids'
  end
end
