class CopaymentRelation < ActiveRecord::Base
  belongs_to :relatable, class_name: 'Spree::Variant', touch: true
  belongs_to :related_to, class_name: 'Spree::Variant'

  validates :relatable_id, uniqueness: { scope: [:related_to_id] }
end
