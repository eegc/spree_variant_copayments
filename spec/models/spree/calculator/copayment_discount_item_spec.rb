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

        let(:variant)  { create(:product, name: "variant",  currency: 'CLP').master }
        let(:variant2) { create(:product, name: "variant2", currency: 'CLP').master }
        let(:variant3) { create(:product, name: "variant3", currency: 'CLP').master }

        let(:copayment)  { create(:product, name: "copayment", currency: 'CLP').master }
        let(:copayment2) { create(:product, name: "copayment2", currency: 'CLP').master }

        let(:relatable_line_1) { create(:line_item, variant: variant , order: order, quantity: 2) }
        let(:relatable_line_2) { create(:line_item, variant: variant2, order: order, quantity: 2) }
        let(:relatable_line_3) { create(:line_item, variant: variant3, order: order, quantity: 1) }

        let(:copayment_line_1) { create(:line_item, variant: copayment , order: order) }
        let(:copayment_line_2) { create(:line_item, variant: copayment2, order: order) }

        let!(:relation)  { create(:copayment_relation, relatable: variant , related_to: copayment , active: true , discount_amount: 1.0) }
        let!(:relation2) { create(:copayment_relation, relatable: variant2, related_to: copayment , active: true , discount_amount: 2.0) }
        let!(:relation3) { create(:copayment_relation, relatable: variant3, related_to: copayment , active: false, discount_amount: 2.0) }
        let!(:relation4) { create(:copayment_relation, relatable: variant , related_to: copayment2, active: true , discount_amount: 2.0) }

        let!(:promotion) { Spree::Promotion.create name: "promo" }
        let(:subject)    { Spree::Calculator::CopaymentDiscountItem.new }
        let!(:action)    { Spree::Promotion::Actions::CreateItemAdjustments.create(promotion: promotion, calculator: subject) }
        let!(:rule)      { Spree::Promotion::Rules::Copayment.new(promotion: promotion) }

        it "computed with only relatable in cart" do
          rule.preferred_related = variant.product_id
          rule.save

          order.line_items = [relatable_line_1]
          expect(subject.eligible?(relatable_line_1)).to be false
          expect(subject.compute(relatable_line_1)).to eq 0
        end

        it "computed with only copayment in cart" do
          rule.save

          order.line_items = [copayment_line_1]
          expect(subject.eligible?(copayment_line_1)).to be false
          expect(subject.compute(copayment_line_1)).to eq 0
        end

        it "computed with relatable and copayment in cart" do
          # variant -> copayment

          rule.preferred_related = variant.product_id
          rule.save

          order.line_items = [relatable_line_1, copayment_line_1]
          expect(subject.eligible?(relatable_line_1)).to be false
          expect(subject.eligible?(copayment_line_1)).to be true
          expect(subject.compute(copayment_line_1)).to eq 1
        end

        it "compute when exists more than one copayment quantity" do
          # relatable 2 -> copayment

          rule.preferred_related = variant2.product_id
          rule.save

          copayment_line_1.update_attribute(:quantity, 2)

          order.line_items = [relatable_line_2, copayment_line_1]
          expect(subject.eligible?(copayment_line_1)).to be true
          expect(subject.compute(copayment_line_1)).to eq 4
        end

        it "computed with relatable and inactive relation in cart" do
          # relatable 3 -> copayment (inactive)

          rule.preferred_related = variant3.product_id
          rule.save

          copayment_line_1.update_attribute(:quantity, 1)

          order.line_items = [relatable_line_3, copayment_line_1]
          expect(subject.eligible?(relatable_line_3)).to be false
          expect(subject.eligible?(copayment_line_1)).to be false
          expect(subject.compute(copayment_line_1)).to eq 0
        end

        context "More than one proomtions with copayments" do

          let!(:promotion2) { Spree::Promotion.create(name: "promo2") }
          let(:subject2)    { Spree::Calculator::CopaymentDiscountItem.new }
          let!(:action2)    { Spree::Promotion::Actions::CreateItemAdjustments.create(promotion: promotion2, calculator: subject2) }
          let!(:rule2)      { Spree::Promotion::Rules::Copayment.create(promotion: promotion2) }

          before(:each) do
            rule.preferred_related = variant.product_id
            rule.save
            promotion.reload
          end

          it "computed with relatable and inactive copayment in cart" do
            # variant -> copayment
            # relatable 3 -> copayment (inactive)

            rule2.preferred_related = variant3.product_id
            rule2.save
            promotion2.reload

            order.line_items = [relatable_line_1, relatable_line_3, copayment_line_1]

            expect(subject.eligible?(copayment_line_1)).to be true
            expect(subject2.eligible?(copayment_line_1)).to be false

            expect(subject.compute(copayment_line_1)).to eq 1
            expect(subject2.compute(copayment_line_1)).to eq 0
          end

          it "computed more than one relatables with the same copayment" do
            # variant  -> copayment
            # variant2 -> copayment

            rule2.preferred_related = variant2.product_id
            rule2.save
            promotion2.reload

            relatable_line_1.update_attribute(:quantity, 1)
            relatable_line_2.update_attribute(:quantity, 1)

            copayment_line_1.update_attribute(:quantity, 2)

            order.line_items = [relatable_line_1, relatable_line_2, copayment_line_1]

            expect(subject.eligible?(copayment_line_1)).to be true
            expect(subject2.eligible?(copayment_line_1)).to be true

            expect(subject.compute(copayment_line_1)).to eq 1
            expect(subject2.compute(copayment_line_1)).to eq 2
          end

          it "computed with more than one relatables with relations with different discounts" do
            # variant  -> copayment 2 (relation4 $2) (x1)
            # variant2 -> copayment   (relation2 $2) (x2)
            # variant  -> copayment   (relation  $1) (x1)

            rule2.preferred_related = variant2.product_id
            rule2.save
            promotion2.reload

            relatable_line_1.update_attribute(:quantity, 5)
            relatable_line_2.update_attribute(:quantity, 2)

            copayment_line_1.update_attribute(:quantity, 3)
            copayment_line_2.update_attribute(:quantity, 1)

            order.line_items = [relatable_line_1, relatable_line_2, copayment_line_1, copayment_line_2]

            expect(subject.eligible?(copayment_line_1)).to be true
            expect(subject.eligible?(copayment_line_2)).to be true

            expect(subject.compute(copayment_line_1)).to eq 1
            expect(subject.compute(copayment_line_2)).to eq 2

            expect(subject2.compute(copayment_line_1)).to eq 4
            expect(subject2.compute(copayment_line_2)).to eq 0
          end
        end
      end
    end
  end
end
