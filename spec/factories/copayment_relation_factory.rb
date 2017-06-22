FactoryGirl.define do
  factory :copayment_relation, class: Spree::CopaymentRelation do
    association :relatable, factory: :variant
    association :related_to, factory: :variant
    active true
  end
end
