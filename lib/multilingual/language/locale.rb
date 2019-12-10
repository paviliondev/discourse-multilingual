class ::Multilingual::Locale
    
  EXCLUSION_KEY = 'locale_exclusions'

  def self.exclusions
    @@exclusions ||= begin
      data = PluginStore.get(Multilingual::PLUGIN_NAME, EXCLUSION_KEY) || ''
      data.split(',')
    end
  end
  
  def self.reload!
    @@exclusions = nil
  end
end 
