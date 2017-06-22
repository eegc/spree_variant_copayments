class AddActiveToSpreeCopaymentRelations < ActiveRecord::Migration
  def change
    add_column :spree_copayment_relations, :active, :boolean
  end
end
