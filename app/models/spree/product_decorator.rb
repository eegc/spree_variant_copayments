Spree::Product.class_eval do

  def all_active_relatables
    variant_ids = has_variants? ? variant_ids : variants_including_master_ids

    Spree::Variant.joins(:active_copayments).where(spree_copayment_relations: {
      relatable_id: variant_ids,
    }).
    where('spree_copayment_relations.discount_amount <> 0.0').
    uniq
  end

  def all_active_copayments
    ids = Spree::CopaymentRelation.where(relatable_id: all_active_relatables.ids, active: true).pluck(:related_to_id)
    Spree::Variant.where(id: ids).uniq
  end

end