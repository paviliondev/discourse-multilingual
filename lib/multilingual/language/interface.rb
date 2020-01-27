class ::Multilingual::Interface
  EXCLUSION_KEY = 'interface_exclusions'.freeze
  
  def self.exclusions
    @exclusions ||= begin
      data = PluginStore.get(Multilingual::PLUGIN_NAME, EXCLUSION_KEY) || ''
      data.split(',')
    end
  end
  
  def self.enabled?(code)
    self.exclusions.exclude?(code)
  end
  
  def self.reload!
    @exclusions = nil
  end
  
  def self.supported?(code)
    Multilingual::Locale.supported.include?(code)
  end
  
  def self.exists?(code)
    Multilingual::Locale.all.include?(code)
  end
end 
