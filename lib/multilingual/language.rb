class ::Multilingual::Language
  CUSTOM_KEY = 'custom_language'.freeze
  LANGUAGE_KEY = 'language'.freeze
  
  include ActiveModel::Serialization
  
  attr_accessor :code,
                :name,
                :content_enabled,
                :interface_enabled,
                :interface_supported,
                :custom
  
  def initialize(attrs)
    @code = attrs[:code].to_s
    @name = attrs[:name].to_s
    @content_enabled = Multilingual::Content.enabled?(@code)
    @interface_enabled = Multilingual::Interface.enabled?(@code)
    @interface_supported = Multilingual::Interface.supported?(@code)
    @custom = Multilingual::Language.is_custom?(@code)
  end
  
  def self.create(code, name)
    if PluginStore.set(Multilingual::PLUGIN_NAME, "#{CUSTOM_KEY}_#{code.to_s}", name.to_s)
      Multilingual::Language.reload!
    end
  end
  
  def self.destroy(code)
    set_exclusion(code, 'interface', true)
    set_exclusion(code, 'content', true)
    
    if PluginStore.remove(Multilingual::PLUGIN_NAME, "#{CUSTOM_KEY}_#{code.to_s}")
      Multilingual::Language.reload!
    end
  end
   
  def self.update(language)
    language = language.with_indifferent_access
        
    ['interface', 'content'].each do |type|
      prop = "#{type}_enabled".to_sym
    
      if language[prop].in? ["true", "false", true, false]
        set_exclusion(language[:code], type, language[prop])
      end
    end
    
    Multilingual::Language.reload!
  end
  
  def self.get(codes)
    [*codes].map do |code|
      self.new(code: code, name: Multilingual::Locale.all[code])
    end      
  end
  
  def self.all
    if languages = Multilingual::Cache.read(LANGUAGE_KEY)
      languages
    else
      languages = Multilingual::Locale.all.map do |k, v|
        Multilingual::Language.new(code: k, name: v)
      end.sort_by(&:code)
      Multilingual::Cache.write(LANGUAGE_KEY, languages)
      languages
    end
  end
  
  def self.filter(params = {})
    languages = self.all
        
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
      
      if [:code, :name].include?(type)
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
  
  def self.reload!
    [
      Multilingual::Locale::CUSTOM_KEY,
      Multilingual::Interface::EXCLUSION_KEY,
      Multilingual::ContentTag::NAME_KEY,
      Multilingual::Content::EXCLUSION_KEY,
      Multilingual::Content::CONTENT_KEY,
      Multilingual::Language::LANGUAGE_KEY
    ].each { |key| Multilingual::Cache.delete(key) }
    
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
    Multilingual::Locale.custom.keys.include?(code.to_s)
  end
  
  def self.bulk_create(languages = {})
    added = []
    
    PluginStoreRow.transaction do
      languages.each do |k, v|
        if Multilingual::Language.create(k, v)
          added.push(k)
        end
      end
      
      Multilingual::ContentTag.bulk_update(added, "create")
    end
    
    Multilingual::Language.reload!
    
    Multilingual::Language.get(added)
  end
  
  ## TODO make this more targeted
  def self.bulk_update(languages)
    PluginStoreRow.transaction do  
      [*languages].each { |l| Multilingual::Language.update(l) }
      
      Multilingual::ContentTag.bulk_update_all
    end
    
    Multilingual::Language.reload!
    
    languages.map { |l| Multilingual::Language.get(l['code']) }
  end
  
  def self.bulk_destroy(codes)
    removed = []
    
    PluginStoreRow.transaction do
      [*codes].each do |c|
        if Multilingual::Language.destroy(c)
          removed.push(c)
        end
      end
      
      Multilingual::ContentTag.bulk_update(removed, "destroy")
    end
    
    Multilingual::Language.reload!
    
    removed
  end
  
  def self.setup!
    extensions = SiteSetting.authorized_extensions_for_staff.split('|')
    extensions.push('yml') unless extensions.include?('yml')
    SiteSetting.authorized_extensions_for_staff = extensions.join('|')
    
    Multilingual::ContentTag.bulk_update_all
    Multilingual::Language.reload!
  end
end