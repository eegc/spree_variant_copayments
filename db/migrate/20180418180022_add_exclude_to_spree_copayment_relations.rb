class AddExcludeToSpreeCopaymentRelations < ActiveRecord::Migration
  def change
    add_column :spree_copayment_relations, :exclude, :boolean, default: false
  end
end
