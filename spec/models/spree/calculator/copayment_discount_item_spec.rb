require 'spec_helper'

module Spree
  class Calculator
    describe CopaymentDiscountItem, type: :model do
      context '.description' do
        it 'outputs copayment discount' do
          expect(subject.description).to eq Spree.t(:copayment_discount_item)
        end
      end

      context '.compute' do
        let(:order) { create(:order, currency: 'CLP') }
        let(:variant)   { create(:product, currency: 'CLP').master }
        let(:variant2)  { create(:product, currency: 'CLP').master }
        let(:variant3)  { create(:product, currency: 'CLP').master }
        let(:copayment) { create(:product, currency: 'CLP').master }

        let(:line_item_1) { create(:line_item, variant: variant , order: order, quantity: 2) }
        let(:line_item_2) { create(:line_item, variant: copayment, order: order) }

        let(:line_item_3) { create(:line_item, variant: variant2 , order: order, quantity: 2) }
        let(:line_item_4) { create(:line_item, variant: copayment, order: order, quantity: 2) }

        let(:line_item_5) { create(:line_item, variant: variant3 , order: order, quantity: 1) }
        let(:line_item_6) { create(:line_item, variant: copayment, order: order, quantity: 1) }

        let(:line_item_7) { create(:line_item, variant: variant  , order: order, quantity: 1) }
        let(:line_item_8) { create(:line_item, variant: variant2 , order: order, quantity: 1) }

        let(:relation)  { create(:copayment_relation, relatable: variant, related_to: copayment, active: true, discount_amount: 1.0) }
        let(:relation2) { create(:copayment_relation, relatable: variant2, related_to: copayment, active: true, discount_amount: 2.0) }
        let(:relation3) { create(:copayment_relation, relatable: variant3, related_to: copayment, active: false, discount_amount: 2.0) }

        let(:promotion)  { Spree::Promotion.create(name: "COPAYMENT Test") }
        let(:calculator) { Spree::Calculator::CopaymentDiscountItem.new }
        let(:action) { Spree::Promotion::Actions::CreateItemAdjustments.create(calculator: calculator, promotion: promotion) }

        before do
          relation.reload
          relation2.reload
          relation3.reload
        end

        it "computed with only relatable in cart" do
          order.line_items = [line_item_1]
          expect(subject.eligible?(line_item_1)).to be false
          expect(subject.compute(line_item_1)).to eq 0
        end

        it "computed with only copayment in cart" do
          order.line_items = [line_item_2]
          expect(subject.eligible?(line_item_2)).to be false
          expect(subject.compute(line_item_2)).to eq 0
        end

        it "computed with relatable and copayment in cart" do
          order.line_items = [line_item_1, line_item_2]
          expect(subject.eligible?(line_item_1)).to be false
          expect(subject.eligible?(line_item_2)).to be true
          expect(subject.compute(line_item_2)).to eq 1
        end

        it "compute when exists more than one copayment quantity" do
          order.line_items = [line_item_3, line_item_4]
          expect(subject.eligible?(line_item_4)).to be true
          expect(subject.compute(line_item_4)).to eq 4
        end

        it "computed with relatable and inactive relation in cart" do
          order.line_items = [line_item_5, line_item_6]
          expect(subject.eligible?(line_item_5)).to be false
          expect(subject.eligible?(line_item_6)).to be false
          expect(subject.compute(line_item_6)).to eq 0
        end

        it "computed with relatable and inactive copayment in cart" do
          order.line_items = [line_item_1, line_item_5, line_item_2]
          expect(subject.eligible?(line_item_1)).to be false
          expect(subject.eligible?(line_item_5)).to be false
          expect(subject.eligible?(line_item_2)).to be true
          expect(subject.compute(line_item_2)).to eq 1
        end

        it "computed with more than one relatables with relations with different discounts" do
          # relatable 1 -> copayment 1
          # relatable 1 -> copayment 2
          order.line_items = [line_item_7, line_item_8, line_item_4]
          expect(subject.eligible?(line_item_7)).to be false
          expect(subject.eligible?(line_item_8)).to be false
          expect(subject.eligible?(line_item_4)).to be true
          expect(subject.compute(line_item_7)).to eq 0
          expect(subject.compute(line_item_8)).to eq 0
          expect(subject.compute(line_item_4)).to eq 3
        end
      end
    end
  end
end
