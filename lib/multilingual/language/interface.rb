class ::Multilingual::Interface
  INTERFACE_KEY = 'interface'.freeze
  EXCLUSION_KEY = 'interface_exclusions'.freeze
  
  def self.exclusions
    Multilingual::Cache.wrap(EXCLUSION_KEY) do
      [*(PluginStore.get(Multilingual::PLUGIN_NAME, EXCLUSION_KEY) || '').split(',')]
    end
  end
  
  def self.enabled?(code)
    Multilingual::Interface.exclusions.exclude?(code.to_s)
  end
  
  def self.supported?(code)
    Multilingual::Interface.all.include?(code.to_s)
  end
  
  def self.all
    Multilingual::Cache.wrap(INTERFACE_KEY) do
      ::LocaleSiteSetting.supported_locales
    end
  end
  
  def self.list_enabled
    self.all.select { |l| Multilingual::Interface.enabled?(l) }
  end
end 
