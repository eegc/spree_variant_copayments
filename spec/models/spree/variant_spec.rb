require 'spec_helper'

RSpec.describe Spree::Variant, type: :model do
  context 'relations' do
    it { is_expected.to have_many(:copayment_relations) }
    it { is_expected.to have_many(:copayments).through(:copayment_relations) }
    it { is_expected.to have_many(:active_copayments) }
  end

  context 'methods' do
    let(:variant)    { create(:product, name: "variant"  , currency: 'CLP').master }
    let(:copayment)  { create(:product, name: "copayment", currency: 'CLP').master }
    let(:copayment2) { create(:product, name: "copayment2", currency: 'CLP').master }
    let(:copayment3) { create(:product, name: "copayment2", currency: 'CLP').master }

    let!(:relation)  { create(:copayment_relation, relatable: variant, related_to: copayment, discount_amount: 5) }
    let!(:relation2) { create(:copayment_relation, relatable: variant, related_to: copayment2, active: false) }
    let!(:relation3) { create(:copayment_relation, relatable: variant, related_to: copayment3, active: true, discount_amount: 0 ) }

    context "#discount_copayments" do
      it "return active relatables variants" do
        expect(variant.discount_copayments).to eq([relation])
      end
    end
  end
end
