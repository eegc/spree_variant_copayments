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

        relatable_lines  = relatables_from_order
        relatables       = Spree::Variant.where(id: relatable_lines.pluck(:variant_id))
        relatables_quant = relatable_lines.sum(:quantity)

        all_relations      = get_order_relations(relatables)

        current_relations = all_relations.where(related_to: @line_item.variant)

        total_discount   = 0

        all_relations.each do |relation|
          break total_discount if relatables_quant == 0

          copayments_quant = copayments_quantity(relation)
          relatable_quant  = relatable_lines.where(variant_id: relation.relatable_id).sum(:quantity)

          discount = relation.discount_amount

          factor = get_factor(relation, relatable_quant, copayments_quant)

          relatables_quant -= factor

          total_discount += (discount * factor) if relation.related_to.id == @line_item.variant.id
        end

        total_discount
      else
        0
      end
    end

    def eligible?(line_item)
      possible_copayment  = line_item.variant.id
      relatable_ids = line_item.order.variants.flat_map{ |x| [x.product.master.id, x.id]}
      final_relatable_ids = ( relatable_ids - [possible_copayment] )
      Spree::CopaymentRelation.exists?(discount_query(final_relatable_ids, possible_copayment))
    end

    def relatables_from_order
      @order.line_items.includes(variant: :copayment_relations).where(spree_copayment_relations: {
        active: true,
        related_to_id: @line_item.variant.id
      }).
      where('spree_copayment_relations.discount_amount <> 0.0').
      reorder('spree_copayment_relations.discount_amount DESC')
    end

    def discount_query(relatable_ids, related_to_ids)
      [
        'active = ? AND relatable_id IN (?) AND related_to_id IN (?)',
        true,
        relatable_ids,
        related_to_ids
      ]
    end

    def get_order_relations(relatables)
      all_relations_ids = relatables.flat_map{ |v| v.all_copayment_relations.active.with_discount.ids }
      Spree::CopaymentRelation.where(id: all_relations_ids, related_to: @order.variants.ids).order(discount_amount: :desc)
    end

    def copayments_quantity(current_relation)
      @order.line_items.where(variant_id: current_relation.related_to).sum(:quantity)
    end

    def get_factor(current_relation, relatable_quant, copayments_quant)
      return 0 if relatable_quant  <= 0
      return 0 if copayments_quant <= 0

      if relatable_quant < copayments_quant
        return relatable_quant
      else
        return copayments_quant
      end

      0
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
