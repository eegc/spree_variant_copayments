module Spree
  module Admin
    ProductsController.class_eval do
      def copayment_relations
        load_resource
        @variant = @product.master
      end
    end
  end
end
