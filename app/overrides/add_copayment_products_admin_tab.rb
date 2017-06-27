Deface::Override.new(
  virtual_path: 'spree/admin/shared/_product_tabs',
  name: 'add_copayment_products_admin_tab',
  insert_bottom: '[data-hook="admin_product_tabs"]',
  partial: 'spree/admin/products/copayment_products_tab.html.erb'
)
