Spree::Variant.class_eval do

  has_many :copayment_relations, -> { order(:position) }, source: :relatable, dependent: :destroy, foreign_key: :relatable_id
  has_many :copayments, source: :related_to, through: :copayment_relations

end