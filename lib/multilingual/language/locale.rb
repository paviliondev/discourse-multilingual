class Multilingual::Locale
  def self.custom
    @custom ||= begin
      custom = {}
      PluginStoreRow.where("
        plugin_name = '#{Multilingual::PLUGIN_NAME}' AND
        key LIKE '#{Multilingual::Language::CUSTOM_KEY}_%'
      ").each do |record|
        custom[record.key.split('_').last] = record.value
      end
      custom
    end
  end
  
  def self.reload!
    @custom = nil
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