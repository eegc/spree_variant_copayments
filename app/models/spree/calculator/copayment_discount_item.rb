module Spree
  class Calculator::CopaymentDiscountItem < Spree::Calculator
    def self.description
      Spree.t("copayment_discount_item")
    end

    # object is a Spree::LineItem
    def compute(object = nil)
      if eligible?(object)

        @line_item = object
        @order     = @line_item.order

        relatable_lines = relatables_from_order

        relatable = relatable_lines.first.variant

        all_relations = relatable.copayment_relations.active.where('discount_amount <> 0.0')

        @current_relation = all_relations.find_by(related_to: @line_item.variant)
        active_relations = all_relations.where(related_to: @order.variants).order(discount_amount: :desc)

        discount = @current_relation.discount_amount

        factor = get_factor(active_relations, relatable_lines.sum(:quantity))

        discount * factor
      else
        0
      end
    end

    def eligible?(line_item)
      possible_copayment  = line_item.variant.id
      relatable_ids = ( line_item.order.variants.ids - [possible_copayment] )
      Spree::CopaymentRelation.exists?(discount_query(relatable_ids, possible_copayment))
    end

    def relatables_from_order
      @order.line_items.includes(variant: :copayment_relations).where(spree_copayment_relations: {
        active: true,
        related_to_id: @line_item.variant.id
      }).reorder('spree_copayment_relations.discount_amount DESC')
    end

    def discount_query(relatable_ids, related_to_ids)
      [
        'discount_amount <> 0.0 AND active = ? AND relatable_id IN (?) AND related_to_id IN (?)',
        true,
        relatable_ids,
        related_to_ids
      ]
    end

    def copayments_quantity(relations)
      variant_ids = relations.pluck(:related_to_id)
      @order.line_items.where(variant_id: variant_ids).sum(:quantity)
    end

    def get_factor(active_relations, relatable_quant)
      all_quant = copayments_quantity(active_relations)

      if relatable_quant > all_quant
        relatable_quant < @line_item.quantity ? relatable_quant : @line_item.quantity
      else
        active_relations.each do |relation|
          break 0 if relatable_quant <= 0

          relation_quant = @order.line_items.joins(:variant).find_by(spree_variants: { id: relation.related_to }).quantity
          value = (relation_quant > relatable_quant) ? relatable_quant : relation_quant
          relatable_quant -= relation_quant

          break value if relation.id == @current_relation.id
        end
      end
    end

    def copayment_adjustments(line_item, relatable, product_ids)
      relations = Spree::Relation.where(*discount_query(relatable.id, product_ids))
      exists_relations_adjustments(line_item, relations)
    end

    def excluded_copayment_adjustments(line_item, relatable, product_ids)
      relations = Spree::Relation.where(*discount_query(relatable.id, product_ids)).excluding
      exists_relations_adjustments(line_item, relations)
    end

    def exists_relations_adjustments(line_item, relations)
      other_variant_ids = Spree::Variant.where(product_id: relations.pluck(:related_to_id)).ids

      line_item.order.line_item_adjustments.
        where(spree_line_items: { variant_id: other_variant_ids }).
        includes(source: :calculator).
        select{|adj| adj.source.try(:calculator).is_a?(Spree::Calculator::RelatedProductDiscountItem) }
    end
  end
end
