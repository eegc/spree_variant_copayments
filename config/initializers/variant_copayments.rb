config = Rails.application.config

#ACTIONS
config.spree.calculators.promotion_actions_create_item_adjustments << Spree::Calculator::CopaymentDiscountItem

#RULES
config.spree.promotions.rules << Spree::Promotion::Rules::Copayment
