class ::Multilingual::Locale
    
  EXCLUSION_KEY = 'locale_exclusions'.freeze

  def self.exclusions
    @exclusions ||= begin
      data = PluginStore.get(Multilingual::PLUGIN_NAME, EXCLUSION_KEY) || ''
      data.split(',')
    end
  end
  
  def self.active?(code)
    self.exclusions.exclude?(code)
  end
  
  def self.supported?(code)
    Multilingual::Base.locales.include?(code)
  end
  
  def self.reload!
    @exclusions = nil
  end
end 
