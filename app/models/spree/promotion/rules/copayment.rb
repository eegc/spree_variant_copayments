module Spree
  class Promotion
    module Rules
      class Copayment < PromotionRule
        preference :related,  :integer

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        def eligible?(order, options = {})
          return false unless ( variant.present? && copayment_relations.present? )

          order.variants.exists?(variant) && order.variants.exists?(variant.active_copayments)
        end

        def variant
          Spree::Variant.find(preferred_related) if preferred_related
        end

        def copayment_relations
          variant.try(:copayment_relations).active
        end
      end
    end
  end
end
