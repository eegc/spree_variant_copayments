require 'spec_helper'

RSpec.describe Spree::Product, type: :model do
  context "methods" do
    let(:product)  { create(:product, name: "variant",  currency: 'CLP') }
    let(:variant)  { product.master }

    let(:copayment)  { create(:product, name: "copayment", currency: 'CLP').master }

    let!(:relation)  { create(:copayment_relation, relatable: variant, related_to: copayment) }

    context '#all_active_relatables' do
      it "return active relatables variants" do
        expect(product.all_active_relatables).to eq([variant])
      end
    end

    context '#all_active_copayments' do
      it "return active copayment variants" do
        expect(product.all_active_copayments).to eq([copayment])
      end
    end
  end
end
