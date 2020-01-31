class ::Multilingual::Interface
  EXCLUSION_KEY = 'interface_exclusions'.freeze
  
  def self.exclusions
    if exclusions = Multilingual::Cache.read(EXCLUSION_KEY)
      exclusions
    else
      data = PluginStore.get(Multilingual::PLUGIN_NAME, EXCLUSION_KEY) || ''
      exclusions = data.split(',')
      Multilingual::Cache.write(EXCLUSION_KEY, exclusions)
      exclusions
    end
  end
  
  def self.enabled?(code)
    self.exclusions.exclude?(code)
  end
  
  def self.supported?(code)
    Multilingual::Locale.supported.include?(code)
  end
  
  def self.exists?(code)
    Multilingual::Locale.all.include?(code)
  end
end 
