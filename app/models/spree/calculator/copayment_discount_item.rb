module Spree
  class Calculator::CopaymentDiscountItem < Spree::Calculator
    def self.description
      Spree.t("copayment_discount_item")
    end

    # object is a Spree::LineItem
    def compute(object = nil)
      if eligible?(object)

        @line_item  = object
        @order      = @line_item.order
        @variant    = @line_item.variant

        #All order lines with copayment related to the current variant
        @relatable_lines  = relatable_lines_from_order

        #Order variants with copayment related to the current variant
        @relatables = Spree::Variant.where(id: @relatable_lines.pluck(:variant_id))

        #Total quantity for relatables
        @relatables_quant = @relatable_lines.sum(:quantity)

        #All active relations in this order
        all_relations = get_order_relations

        #Relations related to current variant
        current_relations = all_relations.where(related_to: @line_item.variant)

        #Item quantity (this is max factor to applied differents discounts)
        @item_quant = @line_item.quantity

        @total_discount = 0

        # Go through all the relations (order by discount),
        # check if it belong to the current damn variant and add the motherfucker discount
        apportionment(all_relations)

        @total_discount
      else
        0
      end
    end

    def relatables_promotion
      self.calculable.promotion.rules.find_by(type: "Spree::Promotion::Rules::Copayment").variants
    end

    def copayments_promotion
      self.calculable.promotion.rules.find_by(type: "Spree::Promotion::Rules::Copayment").copayments
    end

    def eligible?(line_item)
      return false unless relatables_promotion.present?

      possible_copayment  = line_item.variant.id
      relatable_ids       = line_item.order.variants.ids - [possible_copayment]
      final_relatable_ids = relatable_ids & relatables_promotion.ids

      Spree::CopaymentRelation.exists?(discount_query(final_relatable_ids, possible_copayment))
    end

    def discount_query(relatable_ids, related_to_ids)
      [
        'active = ? AND relatable_id IN (?) AND related_to_id IN (?)',
        true,
        relatable_ids,
        related_to_ids
      ]
    end

    def relatable_lines_from_order
      @order.line_items.includes(variant: :copayment_relations).where(spree_copayment_relations: {
        active: true,
        related_to_id: @variant.id
      }).
      where('spree_copayment_relations.discount_amount <> 0.0').
      reorder('spree_copayment_relations.discount_amount DESC')
    end

    def get_order_relations
      all_relations_ids = @relatables.flat_map{ |v| v.discount_copayments.ids }
      Spree::CopaymentRelation.where(id: all_relations_ids, related_to: @order.variants.ids).order(exclude: :desc, discount_amount: :desc)
    end

    def apportionment(all_relations)
      exists_excluded = false

      all_relations.each do |relation|
        relatable_id = relation.relatable_id
        related_to_id = relation.related_to_id

        # Avoid relation if it not related with the promotion
        next unless is_relatable_promotion?(relatable_id) || is_copayment_promotion?(related_to_id)

        # Avoid if exists discount with exclude copayment and is the same relatable
        next if exists_excluded && is_relatable_promotion?(relatable_id)

        break if @relatables_quant <= 0
        break if @item_quant < 0

        # Copayment quantity for this relation
        copayment_quant = copayments_quantity_by_relation(relation)

        # Relatables for this relation
        relation_relatables = relatables_by_relation(relation)
        relatable_quant  = relation_relatables.sum(:quantity)

        discount = relation.discount_amount

        factor = final_factor_by_relation(relatable_quant, copayment_quant)

        # Add discount to the total of the promotion:
        # If the copayment of the relationship is the evaluated variant
        # If the relatable of the relationship belongs to the variants of the promotion
        if related_to_id == @variant.id && is_relatable_promotion?(relatable_id)
          @total_discount += (discount * factor)
        end

        exists_excluded = true if relation.exclude && is_relatable_promotion?(relatable_id)

        # For non-shared co-payments change non_shared_copayments config
        unless Spree::Config[:shared_copayments]
          # Discounting of the evaluated relatable copayment:
          # If it is part of the relatables of the relationship
          if (@relatables.ids & relation_relatables.pluck(:variant_id)).present?
            @relatables_quant -= factor
          end

          # Discount the amount factor of the copayment evaluated:
          # If the copayment of the relationship is the evaluated variant
          # If it is within the copayments of the promo
          if ([@variant.id] & [related_to_id] & copayments_promotion.ids).present?
            @item_quant -= factor
          end
        end
      end
    end

    def is_relatable_promotion?(relatable_id)
      relatables_promotion.ids.include?(relatable_id)
    end

    def is_copayment_promotion?(related_to_id)
      copayments_promotion.ids.include?(related_to_id)
    end

    def copayments_quantity_by_relation(relation)
      @order.line_items.where(variant_id: relation.related_to_id).sum(:quantity)
    end

    def relatables_by_relation(relation)
      @relatable_lines.where(variant_id: relation.relatable_id)
    end

    def final_factor_by_relation(relatable_quant, copayment_quant)
      return 0 if @relatables_quant <= 0
      return 0 if @item_quant <= 0
      return 0 if relatable_quant  <= 0
      return 0 if copayment_quant <= 0


      [@relatables_quant, relatable_quant, copayment_quant, @item_quant].min rescue 0
    end
  end
end
