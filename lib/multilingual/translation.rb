class Multilingual::Translation
  KEY ||= "translation"
  CORE_TYPES ||= %w{client server}
  CUSTOM_TYPES ||= %w{tag category_name}
  TYPES = CORE_TYPES + CUSTOM_TYPES
    
  def self.validate_type(type)
    TYPES.include?(type)
  end
  
  def self.get_custom(type)
    Multilingual::Cache.wrap("#{KEY}_#{type.to_s}") do
      result = {}
      Multilingual::TranslationFile.by_type(type).each do |f|
        data = f.open
        data.keys.each do |key|
          result[key] ||= {}
          result[key][f.code] = data[key]
        end
      end
      result
    end
  end
  
  def self.is_custom(type)
    CUSTOM_TYPES.include?(type)
  end
  
  def self.get(type, key)
    if is_custom(type)
      get_custom(type)[key]
    end
  end
  
  def self.setup
    Multilingual::TranslationFile.load
    Multilingual::TranslationLocale.load
  end
end