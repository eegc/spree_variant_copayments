Spree::Variant.class_eval do

  has_many :copayment_relations, -> { order(:position) }, source: :relatable, dependent: :destroy, foreign_key: :relatable_id

  has_many :copayments, source: :related_to, through: :copayment_relations
  has_many :active_copayments, -> { where(spree_copayment_relations: { active: true }) }, source: :related_to, through: :copayment_relations

  def discount_copayments
    copayment_relations.active.with_discount
  end
end
