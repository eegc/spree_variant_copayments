require 'spec_helper'

RSpec.describe Spree::CopaymentRelation, type: :model do
  context 'relations' do
    it { is_expected.to belong_to(:relatable) }
    it { is_expected.to belong_to(:related_to) }
  end

  context 'attributes' do
    it { is_expected.to respond_to(:discount_amount) }
    it { is_expected.to respond_to(:position) }
    it { is_expected.to respond_to(:active) }
    it { is_expected.to respond_to(:exclude) }
  end

  context 'validation' do
    it { is_expected.to validate_presence_of(:relatable) }
    it { is_expected.to validate_presence_of(:related_to) }
  end

  context 'scopes' do
    let(:variant)    { create(:product, name: "variant"  , currency: 'CLP').master }
    let(:copayment)  { create(:product, name: "copayment", currency: 'CLP').master }
    let(:copayment2) { create(:product, name: "copayment2", currency: 'CLP').master }
    let(:copayment3) { create(:product, name: "copayment2", currency: 'CLP').master }

    let!(:relation)  { create(:copayment_relation, relatable: variant, related_to: copayment, discount_amount: 5) }
    let!(:relation2) { create(:copayment_relation, relatable: variant, related_to: copayment2, active: false) }
    let!(:relation3) { create(:copayment_relation, relatable: variant, related_to: copayment3, active: true, discount_amount: 0 ) }

    context '.active' do
      it "return active relations" do
        expect(Spree::CopaymentRelation.active).to eq([relation, relation3])
      end
    end

    context '.with_discount' do
      it "return realtions with discount amount != 0" do
        expect(Spree::CopaymentRelation.with_discount).to eq([relation, relation2])
      end
    end
  end

end
