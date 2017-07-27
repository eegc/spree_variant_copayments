module Spree
  class Promotion
    module Rules
      class Copayment < PromotionRule
        preference :related,  :integer

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        def eligible?(order, options = {})
          return false unless ( variants.present? && all_variants_copayments.present? )

          order.variants.exists?(variants) && order.variants.exists?(all_variants_copayments)
        end

        def product
          Spree::Product.find(preferred_related) if preferred_related.present? && preferred_related > 0
        end

        def variants
          product.variants_including_master if product.present?
        end

        def all_variants_copayments
          product.all_active_copayments
        end
      end
    end
  end
end
