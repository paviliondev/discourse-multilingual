class ::Multilingual::Language
  CUSTOM_KEY = 'custom_language'.freeze
  LANGUAGE_KEY = 'language'.freeze
  
  include ActiveModel::Serialization
  
  attr_accessor :code,
                :name,
                :nativeName,
                :content_enabled,
                :interface_enabled,
                :interface_supported,
                :custom
  
  def initialize(code, opts = {})
    opts = opts.is_a?(String) ? { name: opts } : opts.with_indifferent_access
    
    @code = code.to_s
    @name = opts[:name].to_s
    @nativeName = opts[:nativeName].to_s
    @content_enabled = Multilingual::Content.enabled?(@code)
    @interface_enabled = Multilingual::Interface.enabled?(@code)
    @interface_supported = Multilingual::Interface.supported?(@code)
    @custom = Multilingual::Language.is_custom?(@code)
  end
  
  def self.create(code, opts = {}, run_hooks: false)
    if PluginStore.set(Multilingual::PLUGIN_NAME, "#{CUSTOM_KEY}_#{code.to_s}", opts)
      after_create([code]) if run_hooks
    end
  end
  
  def self.destroy(code, run_hooks: false)
    set_exclusion(code, 'interface', true)
    set_exclusion(code, 'content', true)
    
    if PluginStore.remove(Multilingual::PLUGIN_NAME, "#{CUSTOM_KEY}_#{code.to_s}")
      after_destroy([code]) if run_hooks
    end
  end
  
  def self.after_create(created)
    Multilingual::Language.refresh!
    Multilingual::ContentTag.bulk_update(created, "create")
    Multilingual::TranslationLocale.load
    Multilingual::Language.refresh!
  end
  
  def self.after_destroy(destroyed)
    Multilingual::Language.refresh!
    Multilingual::ContentTag.bulk_update(destroyed, "destroy")
    Multilingual::TranslationLocale.load
    Multilingual::Language.refresh!
  end
   
  def self.update(language)
    language = language.with_indifferent_access
        
    ['interface', 'content'].each do |type|
      prop = "#{type}_enabled".to_sym
    
      if language[prop].in? ["true", "false", true, false]
        set_exclusion(language[:code], type, language[prop])
      end
    end
    
    self.refresh!
  end
  
  def self.get(codes)
    [*codes].map { |code| self.new(code, self.all[code]) }
  end
  
  def self.list
    self.all.map { |k, v| self.new(k, v) }.sort_by(&:code)
  end
  
  def self.exists?(code)
    self.all[code.to_s].present?
  end
  
  def self.all
    Multilingual::Cache.wrap(LANGUAGE_KEY) do
      base_languages.merge(custom_languages)
    end
  end
  
  def self.custom_languages
    Multilingual::Cache.wrap(CUSTOM_KEY) do 
      result = {}
      
      PluginStoreRow.where("
        plugin_name = '#{Multilingual::PLUGIN_NAME}' AND
        key LIKE '#{Multilingual::Language::CUSTOM_KEY}_%'
      ").each do |record|
        begin
          code = record.key.split("#{Multilingual::Language::CUSTOM_KEY}_").last
          result[code] = JSON.parse(record.value)
        rescue JSON::ParserError => e
          puts e.message
        end
      end
      
      result
    end
  end
  
  def self.base_languages
    ::LocaleSiteSetting.language_names
  end
  
  def self.filter(params = {})
    languages = self.list
        
    if params[:query].present?
      q = params[:query].downcase
      
      languages = languages.select do |l|
        l.code.downcase.include?(q) ||
        l.name.downcase.include?(q)
      end
    end
    
    type = params[:order].present? ? params[:order].to_sym : :code
        
    languages = languages.sort_by do |l|
      val = l.send(type)
      
      if [:code, :name, :nativeName].include?(type)
        val
      elsif [:content_enabled, :custom].include?(type)
        ( val ? 0 : 1 )
      elsif type == :interface_enabled
        [ (val ? 0 : 1), (l.interface_supported ? 0 : 1) ] 
      end
    end
        
    if params[:order].present? && 
       !ActiveModel::Type::Boolean.new.cast(params[:ascending])
      languages = languages.reverse
    end
                    
    languages
  end
  
  def self.refresh!
    Multilingual::Cache.refresh([
      Multilingual::Interface::INTERFACE_KEY,
      Multilingual::Interface::EXCLUSION_KEY,
      Multilingual::Content::EXCLUSION_KEY,
      Multilingual::Content::CONTENT_KEY,
      Multilingual::Language::CUSTOM_KEY,
      Multilingual::Language::LANGUAGE_KEY,
      Multilingual::ContentTag::NAME_KEY
    ])
        
    true
  end
  
  def self.set_exclusion(code, type, enabled)
    code = code.to_s
    klass = "Multilingual::#{type.to_s.classify}".constantize
    key = klass::EXCLUSION_KEY
    enabled = ActiveModel::Type::Boolean.new.cast(enabled)
    exclusions = PluginStore.get(Multilingual::PLUGIN_NAME, key) || []
    
    return if enabled && exclusions.empty?

    exclusions = exclusions.split(',')
  
    if enabled
      exclusions.delete(code)
    else
      exclusions.push(code) unless (exclusions.include?(code) || code == 'en')
    end
    
    PluginStore.set(Multilingual::PLUGIN_NAME, key, exclusions.join(','))
  end
  
  def self.is_custom?(code)
    custom_languages.keys.include?(code.to_s)
  end
  
  def self.bulk_create(languages = {})
    created = []
    
    PluginStoreRow.transaction do
      languages.each do |k, v|
        if self.create(k, v)
          created.push(k)
        end
      end
      
      after_create(created)
    end
        
    self.get(created)
  end
  
  ## TODO make this more targeted
  def self.bulk_update(languages)
    PluginStoreRow.transaction do  
      [*languages].each { |l| update(l) }
      
      Multilingual::ContentTag.bulk_update_all
    end
    
    self.refresh!
    
    languages.map { |l| get(l['code']) }
  end
  
  def self.bulk_destroy(codes)
    destroyed = []
    
    PluginStoreRow.transaction do
      [*codes].each do |c|
        if self.destroy(c)
          destroyed.push(c)
        end
      end
      
      after_destroy(destroyed)
    end
        
    destroyed
  end
  
  def self.setup
    extensions = SiteSetting.authorized_extensions_for_staff.split('|')
    extensions.push('yml') unless extensions.include?('yml')
    SiteSetting.authorized_extensions_for_staff = extensions.join('|')
    
    Multilingual::Language.refresh!
    Multilingual::ContentTag.bulk_update_all
  end
end