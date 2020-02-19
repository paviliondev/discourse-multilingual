class Multilingual::Translation
  CORE ||= %w{client server}
  EXTRA ||= %w{tag category_name}
  TYPES = CORE + EXTRA
  
  EXTRA.each do |t|
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
  
  def self.load_extra(code)
    Multilingual::TranslationFile.by_type(EXTRA)
      .select { |f| f.code == code }
      .each { |f| set(f.type, f.open) }
  end
  
  def self.setup
    Multilingual::TranslationFile.load
    Multilingual::TranslationLocale.load
  end
end