module Spree
  class Promotion
    module Rules
      class Copayment < PromotionRule
        preference :related,  :integer

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        def eligible?(order, options = {})
          return false unless product.present?
          return false unless ( variants.present? && copayments.present? )

          order.variants.exists?(variants) && order.variants.exists?(copayments) && active_relations
        end

        def product
          Spree::Product.find(preferred_related) if preferred_related.present? && preferred_related > 0
        end

        def variants
          product.all_active_relatables if product
        end

        def copayments
          product.all_active_copayments if product
        end

        def active_relations
          Spree::CopaymentRelation.exists?(relatable_id: variants.ids, related_to_id: copayments.ids, active: true)
        end
      end
    end
  end
end
