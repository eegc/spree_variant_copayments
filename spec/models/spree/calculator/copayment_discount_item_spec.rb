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

        let(:variant)  { create(:product, currency: 'CLP').master }
        let(:variant2) { create(:product, currency: 'CLP').master }
        let(:variant3) { create(:product, currency: 'CLP').master }

        let(:copayment)  { create(:product, currency: 'CLP').master }
        let(:copayment2) { create(:product, currency: 'CLP').master }

        let(:relatable_line_1) { create(:line_item, variant: variant , order: order, quantity: 2) }
        let(:relatable_line_2) { create(:line_item, variant: variant2, order: order, quantity: 2) }
        let(:relatable_line_3) { create(:line_item, variant: variant3, order: order, quantity: 1) }

        let(:copayment_line_1) { create(:line_item, variant: copayment , order: order) }
        let(:copayment_line_2) { create(:line_item, variant: copayment2, order: order) }

        let(:relation)  { create(:copayment_relation, relatable: variant , related_to: copayment , active: true , discount_amount: 1.0) }
        let(:relation2) { create(:copayment_relation, relatable: variant2, related_to: copayment , active: true , discount_amount: 2.0) }
        let(:relation3) { create(:copayment_relation, relatable: variant3, related_to: copayment , active: false, discount_amount: 2.0) }
        let(:relation4) { create(:copayment_relation, relatable: variant , related_to: copayment2, active: true , discount_amount: 2.0) }

        before do
          relation.reload
          relation2.reload
          relation3.reload
          relation4.reload
        end

        it "computed with only relatable in cart" do
          order.line_items = [relatable_line_1]
          expect(subject.eligible?(relatable_line_1)).to be false
          expect(subject.compute(relatable_line_1)).to eq 0
        end

        it "computed with only copayment in cart" do
          order.line_items = [copayment_line_1]
          expect(subject.eligible?(copayment_line_1)).to be false
          expect(subject.compute(copayment_line_1)).to eq 0
        end

        it "computed with relatable and copayment in cart" do
          # relatable 1 -> copayment

          order.line_items = [relatable_line_1, copayment_line_1]
          expect(subject.eligible?(relatable_line_1)).to be false
          expect(subject.eligible?(copayment_line_1)).to be true
          expect(subject.compute(copayment_line_1)).to eq 1
        end

        it "compute when exists more than one copayment quantity" do
          # relatable 2 -> copayment
          copayment_line_1.update_attribute(:quantity, 2)

          order.line_items = [relatable_line_2, copayment_line_1]
          expect(subject.eligible?(copayment_line_1)).to be true
          expect(subject.compute(copayment_line_1)).to eq 4
        end

        it "computed with relatable and inactive relation in cart" do
          # relatable 3 -> copayment (inactive)

          copayment_line_1.update_attribute(:quantity, 1)

          order.line_items = [relatable_line_3, copayment_line_1]
          expect(subject.eligible?(relatable_line_3)).to be false
          expect(subject.eligible?(copayment_line_1)).to be false
          expect(subject.compute(copayment_line_1)).to eq 0
        end

        it "computed with relatable and inactive copayment in cart" do
          # relatable 1 -> copayment
          # relatable 3 -> copayment (inactive)

          order.line_items = [relatable_line_1, relatable_line_3, copayment_line_1]
          expect(subject.eligible?(relatable_line_1)).to be false
          expect(subject.eligible?(relatable_line_3)).to be false
          expect(subject.eligible?(copayment_line_1)).to be true
          expect(subject.compute(copayment_line_1)).to eq 1
        end

        it "computed more than one relatables with the same copayment" do
          # relatable 1 -> copayment 1
          # relatable 2 -> copayment 1

          relatable_line_1.update_attribute(:quantity, 1)
          relatable_line_2.update_attribute(:quantity, 1)
          copayment_line_1.update_attribute(:quantity, 2)

          order.line_items = [relatable_line_1, relatable_line_2, copayment_line_1]
          expect(subject.eligible?(relatable_line_1)).to be false
          expect(subject.eligible?(relatable_line_2)).to be false
          expect(subject.eligible?(copayment_line_1)).to be true
          expect(subject.compute(relatable_line_1)).to eq 0
          expect(subject.compute(relatable_line_2)).to eq 0
          expect(subject.compute(copayment_line_1)).to eq 3
        end


        it "computed with more than one relatables with relations with different discounts" do
          # relatable 1 -> copayment 1 (relation  $1) (x2)
          # relatable 2 -> copayment 1 (relation2 $2) (x2)

          # relatable 1 -> copayment 2 (relation4 $2) (x1)

          relatable_line_1.update_attribute(:quantity, 3)
          relatable_line_2.update_attribute(:quantity, 2)

          copayment_line_1.update_attribute(:quantity, 3)
          copayment_line_2.update_attribute(:quantity, 1)

          order.line_items = [relatable_line_1, relatable_line_2, copayment_line_1, copayment_line_2]

          expect(subject.eligible?(relatable_line_1)).to be false
          expect(subject.eligible?(relatable_line_2)).to be false
          expect(subject.eligible?(copayment_line_1)).to be true
          expect(subject.eligible?(copayment_line_2)).to be true

          expect(subject.compute(relatable_line_1)).to eq 0
          expect(subject.compute(relatable_line_2)).to eq 0
          expect(subject.compute(copayment_line_1)).to eq 6
          expect(subject.compute(copayment_line_2)).to eq 2
        end
      end
    end
  end
end
