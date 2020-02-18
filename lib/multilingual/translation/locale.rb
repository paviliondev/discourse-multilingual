class ::Multilingual::TranslationLocale
  JS_PATH = "#{Multilingual::PLUGIN_PATH}/assets/locales".freeze
  
  def self.js_locale_path(code)
    "#{JS_PATH}/#{code.to_s}.js.erb"
  end
  
  def self.register(file)      
    code = file.code.to_s
    type = file.type.to_s
    opts = {}
    is_client = type === 'client'
    
    opts["#{type}_locale_file".to_sym] = file.path
    js_path = js_locale_path(code)
    
    if is_client && !File.file?(js_path)
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
    
    add_to_csp(code) if is_client
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
  
  def self.add_to_csp(code)
    public_js_url = "#{ContentSecurityPolicy.base_url}/locales/#{code}.js"
    
    Discourse.plugins.each do |p|
      if p.metadata.name === Multilingual::PLUGIN_NAME && p.csp_extensions.exclude?(public_js_url)
        p.csp_extensions.push(script_src: [public_js_url]) 
      end
    end
  end
  
  def self.refresh!
    LocaleSiteSetting.reset!
    JsLocaleHelper.clear_cache!
    SiteSetting.refresh! 
  end
end