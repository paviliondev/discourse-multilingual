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
        result[f.code.to_s] = f.open
      end
      result
    end
  end
  
  def self.is_custom(type)
    CUSTOM_TYPES.include?(type)
  end
  
  def self.get(type, val, by_key: false)
    if is_custom(type)
      result = get_custom(type)
      
      if by_key
        key_result = {}
      
        result.each do |code, data|
          data.keys.each do |key|
            key_result[key.to_s] ||= {}
            key_result[key][code.to_s] = data[key]
          end
        end
        
        result = key_result
      end
      
      result[val.to_s]
    end
  end
  
  def self.setup
    Multilingual::TranslationFile.load
    Multilingual::TranslationLocale.load
  end
end