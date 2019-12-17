class Multilingual::Base 
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
  
  def self.list
    list = {}
    ::LocaleSiteSetting.language_names.each do |k, v|
      list[k] = v['nativeName']
    end    
    list.merge(custom)
  end
  
  def self.locales
    ::LocaleSiteSetting.supported_locales + custom.keys
  end
end