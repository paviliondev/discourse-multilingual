class ::Multilingual::TranslationLocale
  JS_PATH = "#{Multilingual::PLUGIN_PATH}/assets/locales".freeze
  
  def self.js_locale_path(code)
    "#{JS_PATH}/#{code.to_s}.js.erb"
  end
  
  def self.register(file)      
    code = file.code.to_s
    type = file.type.to_s
    opts = {}
    
    opts["#{type}_locale_file".to_sym] = file.path
    js_path = js_locale_path(code)
    
    if type === 'client' && !File.file?(js_path)
      File.open(js_path, "w") do |f| 
        f.puts(
          [
            "//= require locales/i18n",
            "<%= JsLocaleHelper.output_locale(:#{code}) %>"
          ]
        )
      end
      
      opts[:js_locale_file] = js_path
    end
    
    locale_chain = code.split('_')
    
    opts[:fallbackLocale] = locale_chain.first if locale_chain.length === 2
    
    current_locale = DiscoursePluginRegistry.locales[code] || {}
    new_locale = current_locale.merge(opts)
    
    DiscoursePluginRegistry.register_locale(code, new_locale)
  end
  
  def self.deregister(file)
    code = file.code.to_s
    type = file.type.to_s
    
    js_path = js_locale_path(code)
    
    if type === 'client' && File.file?(js_path)
      File.delete(js_path)
    end
    
    DiscoursePluginRegistry.locales.delete(code)
  end
  
  def self.load
    files.each { |file| register(file) }
  end
  
  def self.files
    Multilingual::TranslationFile.by_type([:client, :server])
  end
  
  def self.refresh!
    LocaleSiteSetting.reset!
    JsLocaleHelper.clear_cache!
    Discourse.cache.delete(SiteSettingExtension.client_settings_cache_key)
    Site.clear_anon_cache!
  end
end