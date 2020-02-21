class Multilingual::Translation
  CORE_TYPES ||= %w{client server}
  CUSTOM_TYPES ||= %w{tag category_name}
  TYPES = CORE_TYPES + CUSTOM_TYPES
  
  CUSTOM_TYPES.each do |t|
    method_name = t.pluralize
    self.class.__send__(:attr_accessor, method_name)
    self.__send__("#{method_name}=", {})
  end
  
  def self.set(attr, value)
    self.send("#{attr.to_s.pluralize}=", value)
  end
    
  def self.validate_type(type)
    TYPES.include?(type)
  end
  
  def self.clear_custom_types
    CUSTOM_TYPES.each { |type| set(type, {}) }
  end
  
  def self.load_custom_types(code)
    clear_custom_types
        
    Multilingual::TranslationFile.by_type(CUSTOM_TYPES)
      .select { |f| f.code == code.to_sym }
      .each { |f| set(f.type, f.open) }
  end
  
  def self.setup
    Multilingual::TranslationFile.load
    Multilingual::TranslationLocale.load
  end
end