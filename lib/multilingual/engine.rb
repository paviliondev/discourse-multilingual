module ::Multilingual
  PLUGIN_NAME = 'discourse-multilingual'.freeze
  PLUGIN_PATH = "#{Rails.root}/plugins/discourse-multilingual"
  
  class Engine < ::Rails::Engine
    engine_name "multilingual"
    isolate_namespace Multilingual
  end
  
  def self.refresh_clients(codes)
    codes = [*codes].map(&:to_s)
    changing_default = codes.include?(SiteSetting.default_locale.to_s)
    user_ids = nil
        
    if !changing_default && SiteSetting.allow_user_locale
      user_ids = User.where(locale: codes).pluck(:id)
    end
                
    if changing_default || user_ids
      Discourse.request_refresh!(user_ids: user_ids)
    end
  end
end