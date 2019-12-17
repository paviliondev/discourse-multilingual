class ::Multilingual::Language
  CUSTOM_KEY = 'custom_language'.freeze
  
  include ActiveModel::Serialization
  
  attr_accessor :code,
                :name,
                :content,
                :locale,
                :locale_supported,
                :custom
  
  def initialize(attrs)
    @code = attrs[:code]
    @name = attrs[:name]
    @content = Multilingual::Content.active?(attrs[:code])
    @locale = Multilingual::Locale.active?(attrs[:code])
    @locale_supported = Multilingual::Locale.supported?(attrs[:code])
    @custom = Multilingual::Language.is_custom?(attrs[:code])
  end
  
  def self.create(code, name)
    if !Multilingual::Base.list[code]
      PluginStore.set(Multilingual::PLUGIN_NAME, "#{CUSTOM_KEY}_#{code}", name)
    end
  end
  
  def self.destroy(code)
    PluginStore.remove(Multilingual::PLUGIN_NAME, "#{CUSTOM_KEY}_#{code}")
  end
   
  def self.update(language)
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
  
  def self.toggle_exclusion(code, key, include)
    include = ActiveModel::Type::Boolean.new.cast(include)
    exclusions = PluginStore.get(Multilingual::PLUGIN_NAME, key)
    
    if exclusions.blank?
      return if include
      exclusions = []
    else
      exclusions = exclusions.split(',')
    end
  
    if include
      exclusions.delete(code)
    else
      exclusions.push(code) unless exclusions.include?(code)
    end
    
    PluginStore.set(Multilingual::PLUGIN_NAME, key, exclusions.join(','))
  end
  
  def self.all
    @all ||= Multilingual::Base.list.map do |k, v|
      Multilingual::Language.new(code: k, name: v)
    end
  end
  
  def self.reload!
    @all = nil
  end
  
  def self.is_custom?(code)
    Multilingual::Base.custom.keys.include?(code)
  end
  
  def self.filter(params)
    languages = self.all
        
    if params[:filter].present?
      f = params[:filter].downcase
      
      languages = languages.select do |l|
        l.code.downcase.include?(f) ||
        l.name.downcase.include?(f)
      end
    end
    
    type = params[:order].present? ? params[:order].to_sym : :code
        
    languages = languages.sort_by do |l|
      val = l.send(type)
      
      if [:code, :name].include?(type)
        val
      elsif type == :content
        ( val ? 0 : 1 )
      elsif type == :locale
        [ (val ? 0 : 1), (l.locale_supported ? 0 : 1) ] 
      end
    end
        
    if params[:order].present? && 
       !ActiveModel::Type::Boolean.new.cast(params[:ascending])
      languages = languages.reverse
    end
            
    languages
  end
end