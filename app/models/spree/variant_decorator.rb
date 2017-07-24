Spree::Variant.class_eval do

  has_many :copayment_relations, -> { order(:position) }, source: :relatable, dependent: :destroy, foreign_key: :relatable_id
  has_many :active_copayments, -> { where(spree_copayment_relations: { active: true }) }, source: :related_to, through: :copayment_relations
  has_many :copayments, source: :related_to, through: :copayment_relations

  def all_copayment_relations
    Spree::CopaymentRelation.where(relatable_id: [self.product.master.id, self.id])
  end

  def all_active_copayments
    ids = product.master.active_copayments.ids + active_copayments.ids
    Spree::Variant.where(id: ids)
  end
end
