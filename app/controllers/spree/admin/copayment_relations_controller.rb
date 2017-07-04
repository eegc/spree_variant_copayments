module Spree
  module Admin
    class CopaymentRelationsController < BaseController
      respond_to :js, :html

      def create
        @relation = CopaymentRelation.new(copayment_relation_params)

        @variant = Spree::Variant.find(copayment_relation_params[:relatable_id])
        @product = @variant.product

        @relation.save

        respond_with(@relation)
      end

      def update
        @relation = Spree::CopaymentRelation.find(params[:id])
        @relation.update_attributes(copayment_relation_params)

        @variant = @relation.relatable
        @product = @variant.product

        respond_to do |format|
          format.html { redirect_to(related_admin_product_url(@relation.relatable)) }
          format.js   { }
        end
      end

      def update_positions
        params[:positions].each do |id, index|
          Spree::CopaymentRelation.where(id: id).update_all(position: index)
        end

        respond_to do |format|
          format.js { render text: 'Ok' }
        end
      end

      def destroy
        @relation = Spree::CopaymentRelation.find(params[:id])

        @variant = @relation.relatable
        @product = @variant.product

        if @relation.destroy
          flash[:success] = flash_message_for(@relation, :successfully_removed)

          respond_with(@relation) do |format|
            format.html { redirect_to location_after_destroy }
            format.js   { render_js_for_destroy }
          end
        else
          respond_with(@relation) do |format|
            format.html { redirect_to location_after_destroy }
          end
        end
      end

      private

      def copayment_relation_params
        params.require(:copayment_relation).permit(*permitted_attributes)
      end

      def permitted_attributes
        [
          :related_to_id,
          :relatable_id,
          :discount_amount,
          :position,
          :active
        ]
      end
    end
  end
end
