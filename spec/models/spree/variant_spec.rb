require 'spec_helper'

RSpec.describe Spree::Variant, type: :model do
  context 'relations' do
    it { is_expected.to have_many(:copayment_relations) }
    it { is_expected.to have_many(:copayments).through(:copayment_relations) }
  end
end
