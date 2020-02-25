class Multilingual::Cache
  class << self
    attr_accessor :state
  end

  LISTABLE_CLASSES ||= []
    
  def self.load_classes
    %w[
      translation_file
      content_tag
      language_exclusion
      custom_language
      language
      content_language
      interface_language
    ].each do |klass|
      class_name = "Multilingual::#{klass.classify}".constantize
      LISTABLE_CLASSES.push(class_name) if LISTABLE_CLASSES.exclude?(class_name)
    end
  end
  
  def self.setup
    @state = nil
    load_classes
    reset
    instantiate
  end
  
  def initialize(key)
    @key = "#{Multilingual::PLUGIN_NAME}_#{key}"
  end
  
  def read
    synchronize { cache.read(@key) }
  end
  
  def write(data)
    synchronize { cache.write(@key, data) }
  end
  
  def delete
    synchronize { cache.delete(@key) }
  end
  
  def synchronize
    DistributedMutex.synchronize(@key) { yield }
  end
  
  def cache
    @cache ||= Discourse.cache
  end
  
  def self.wrap(key, &block)
    c = Multilingual::Cache.new(key)
        
    if (@state != 'changing') && (cached = c.read)
      cached
    else
      result = block.call()
      c.write(result)
      result
    end
  end
  
  def self.clear_i18n!
    ExtraLocalesController.clear_cache!
    I18n.config.clear_available_locales_set
    Site.clear_anon_cache!
  end
  
  def self.reload_i18n!
    I18n.config.backend.reload!
    I18n.reload!
  end
  
  def self.reset_core(opts)
    LocaleSiteSetting.reset!
    JsLocaleHelper.clear_cache!
    JsLocaleHelper.reset_context
  
    clear_i18n! if opts[:reload_i18n]
  end
  
  def self.instantiate_core(opts)
    if opts[:action] === :remove && (I18n.locale.to_s === opts[:locale].to_s)
      I18n.locale = SiteSettings::DefaultsProvider::DEFAULT_LOCALE
    end
    
    if opts[:action] === :save && (I18n.locale.to_s != opts[:locale].to_s)
      I18n.locale = opts[:locale]
      I18n.load_locale(opts[:locale])
    end
    
    reload_i18n! if opts[:reload_i18n]
  end
  
  def self.reset
    LISTABLE_CLASSES.each { |klass| Multilingual::Cache.new(klass::KEY).delete }
    
    Multilingual::Translation::CUSTOM_TYPES.each do |type|
      Multilingual::Cache.new("#{Multilingual::Translation::KEY}_#{type}").delete
    end
  end
  
  def self.instantiate
    LISTABLE_CLASSES.each { |klass| klass.send(:all) if klass.respond_to?(:all) }
    @state = 'chached'
  end
  
  def self.refresh!(opts = {})
    load_classes
    reset
    reset_core(opts)
    instantiate
    instantiate_core(opts)
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