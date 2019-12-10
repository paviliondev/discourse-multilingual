module ::Multilingual
  PLUGIN_NAME = 'discourse-multilingual'.freeze
  
  class Engine < ::Rails::Engine
    engine_name "multilingual"
    isolate_namespace Multilingual
  end
end