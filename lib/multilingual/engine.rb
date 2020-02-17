module ::Multilingual
  PLUGIN_NAME = 'discourse-multilingual'.freeze
  PLUGIN_PATH = "#{Rails.root}/plugins/discourse-multilingual"
  
  class Engine < ::Rails::Engine
    engine_name "multilingual"
    isolate_namespace Multilingual
  end
end