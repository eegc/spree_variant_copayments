Spree::AppConfiguration.class_eval do
  preference :shared_copayments, :boolean, default: true
end
