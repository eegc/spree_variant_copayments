require 'spec_helper'

RSpec.describe Spree::CopaymentRelation, type: :model do
  context 'relations' do
    it { is_expected.to belong_to(:relatable) }
    it { is_expected.to belong_to(:related_to) }
  end

  context 'attributes' do
    it { is_expected.to respond_to(:discount_amount) }
    it { is_expected.to respond_to(:position) }
  end

  context 'validation' do
    it { is_expected.to validate_presence_of(:relatable) }
    it { is_expected.to validate_presence_of(:related_to) }
  end
end
