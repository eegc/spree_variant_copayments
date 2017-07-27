Spree::Product.class_eval do

  def all_active_copayments
    ids = Spree::CopaymentRelation.where(relatable_id: variants_including_master).pluck(:related_to_id)
    Spree::Variant.where(id: ids)
  end

end