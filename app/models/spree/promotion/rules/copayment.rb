module Spree
  class Promotion
    module Rules
      class Copayment < PromotionRule
        preference :related,  :integer

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        def eligible?(order, options = {})
          return false unless ( variant.present? && variant.active_copayments.present? )

          order.variants.exists?(variant) && order.variants.exists?(variant.active_copayments)
        end

        def product
          Spree::Product.find(preferred_related) if preferred_related.present? && preferred_related > 0
        end

        def variants
          product.variants_including_master if product.present?
        end
      end
    end
  end
end
