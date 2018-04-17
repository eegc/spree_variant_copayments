// Placeholder manifest file.
// the installer will append this file to the app vendored assets here: vendor/assets/javascripts/spree/backend/all.js'


$.fn.variantPicker = function (options) {
  'use strict';

  // Default options
  options = options || {};
  var multiple = typeof(options.multiple) !== 'undefined' ? options.multiple : true;

  this.select2({
    minimumInputLength: 3,
    multiple: multiple,
    initSelection: function (element, callback) {
      $.get(Spree.routes.variants_api, {
        ids: element.val().split(','),
        token: Spree.api_key
      }, function (data) {
        callback(data.variants);
      });
    },
    ajax: {
      url: Spree.routes.variants_api,
      datatype: 'json',
      data: function (term) {
        return {
          q: {
            sku_cont: term
          },
          token: Spree.api_key
        };
      },
      results: function (data) {
        var variants = data.variants ? data.variants : [];
        return {
          results: variants
        };
      }
    },
    formatResult: function (variant) {
      return variant.name;
    },
    formatSelection: function (variant) {
      return variant.name;
    }
  });
};

$(document).ready(function () {
  $('.variant_picker').variantPicker();
});
