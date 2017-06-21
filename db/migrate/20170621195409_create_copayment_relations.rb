class CreateCopaymentRelations < ActiveRecord::Migration
  def change
    create_table :copayment_relations do |t|
      t.references :relatable, index: true, foreign_key: true
      t.references :related_to, index: true, foreign_key: true
      t.decimal :discount_amount, precision: 8, scale: 2, default: 0.0
      t.integer :position

      t.timestamps null: false
    end
  end
end
