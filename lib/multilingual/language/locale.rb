class Multilingual::Locale
  CUSTOM_KEY = "custom_locale".freeze
  
  def self.custom
    if custom = Multilingual::Cache.read(CUSTOM_KEY)
      custom
    else
      custom = {}
      PluginStoreRow.where("
        plugin_name = '#{Multilingual::PLUGIN_NAME}' AND
        key LIKE '#{Multilingual::Language::CUSTOM_KEY}_%'
      ").each do |record|
        custom[record.key.split("#{Multilingual::Language::CUSTOM_KEY}_").last] = record.value
      end
      Multilingual::Cache.write(CUSTOM_KEY, custom)
      custom
    end
  end
  
  def self.all
    all = {}
    ::LocaleSiteSetting.language_names.each { |k, v| all[k] = v['nativeName'] }
    all.merge(custom)
  end
  
  def self.supported
    ::LocaleSiteSetting.supported_locales
  end
end