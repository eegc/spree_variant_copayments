Spree::Variant.class_eval do

  has_many :copayment_relations, -> { order(:position) }, as: :relatable
  has_many :copayments, trought: :copayment_relations

end