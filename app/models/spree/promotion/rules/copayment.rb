module Spree
  class Promotion
    module Rules
      class Copayment < PromotionRule
        preference :related,  :integer

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        def eligible?(order, options = {})
          return false unless ( variant.present? && copayment_relations )

          order.variants.exists?(variant)
        end

        def variant
          Spree::Variant.find(preferred_related) if preferred_related
        end

        def copayment_relations
          variant.try(:relations).try(:copayments)
        end
      end
    end
  end
end
