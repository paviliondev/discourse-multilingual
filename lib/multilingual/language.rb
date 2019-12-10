class ::Multilingual::Language
  CUSTOM_KEY = 'custom_language'
  
  include ActiveModel::Serialization
  
  attr_accessor :code,
                :name,
                :content,
                :locale
  
  def initialize(attrs)
    @code = attrs[:code]
    @name = attrs[:name]
    @content = Multilingual::Content.exclusions.exclude?(attrs[:code])
    @locale = Multilingual::Locale.exclusions.exclude?(attrs[:code])
  end
  
  def self.create(code, name)
    PluginStore.set(Multilingual::PLUGIN_NAME, CUSTOM_KEY, code: code, name: name)
    self.register(code, name)
  end
  
  def self.register(code, name)
    ::DiscoursePluginRegistry.register_locale(code, name: name, nativeName: name)
  end
  
  def self.refresh_core_locales!
    ::LocaleSiteSetting.reset!
  end
   
  def self.save(language)
    language = language.with_indifferent_access
        
    if language[:locale].in? ["true", "false", true, false]
      toggle_exclusion(
        language[:code],
        Multilingual::Locale::EXCLUSION_KEY,
        language[:locale]
      )
    end
        
    if language[:content].in? ["true", "false", true, false]
      toggle_exclusion(
        language[:code],
        Multilingual::Content::EXCLUSION_KEY,
        language[:content]
      )
    end
  end
  
  def self.update(languages)    
    [*languages].each do |l|
      Multilingual::Language.save(l)
    end
    
    refresh_associated_models
  end
  
  def self.refresh_associated_models
    Multilingual::Content.reload!
    Multilingual::Locale.reload!
    self.refresh_core_locales!
    Jobs.enqueue(:update_language_tags)
  end
  
  def self.toggle_exclusion(code, key, include)
    include = ActiveModel::Type::Boolean.new.cast(include)
    exclusions = PluginStore.get(Multilingual::PLUGIN_NAME, key)
    
    if exclusions.blank?
      return if include
      exclusions = []
    else
      exclusions = exclusions.split(',')
    end
  
    include ? exclusions.delete(code) : exclusions.push(code)
    
    PluginStore.set(Multilingual::PLUGIN_NAME, key, exclusions.join(','))
  end
  
  def self.all
    @all ||= ::LocaleSiteSetting.language_names.map do |k, v|
      Multilingual::Language.new(code: k, name: v['nativeName'])
    end
  end
  
  def self.query(params)
    languages = self.all
    
    if params[:filter].present?
      f = params[:filter].downcase
      languages = languages.select do |l|
        l.code.downcase.include?(f) ||
        l.name.downcase.include?(f)
      end
    end
    
    if params[:order].present?
      languages.sort_by { |l| l.send(params[:order].to_sym) }
    end
    
    if params[:ascending] == false
      languages.reverse!
    end
        
    languages
  end
  
  def self.load_custom!
    PluginStoreRow.where("
      plugin_name = '#{Multilingual::PLUGIN_NAME}' AND
      key = '#{CUSTOM_KEY}'
    ").each do |record|
      l = JSON.parse(record.value)
      puts "LANGUAGE: #{l}"
      self.register(l["code"], l["name"])
    end
    
    self.refresh_core_locales!
  end
  
  def self.initialize_settings!
    extensions = SiteSetting.authorized_extensions_for_staff.split('|')
    extensions.push('yml')
    SiteSetting.authorized_extensions_for_staff = extensions.join('|')
  end
end