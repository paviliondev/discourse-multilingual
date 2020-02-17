class ::Multilingual::Translation
  SERVER ||= %w{category_name server}
  CLIENT ||= %w{tag client}
  TYPES = SERVER + CLIENT
  
  TYPES.each do |t|
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
  
  def self.load_server(code)
    Multilingual::TranslationFile.by_type(SERVER)
      .select { |f| f.code == code }
      .each { |f| set(f.type, f.open) }
  end
  
  def self.refresh_server!
    SERVER.each { |t| set(t, {}) }
  end
  
  def self.refresh!
    Multilingual::Translation.refresh_server!
    Multilingual::TranslationFile.refresh!
    Multilingual::TranslationLocale.refresh!
  end
  
  def self.setup
    Multilingual::TranslationLocale.load
    Multilingual::Translation.refresh!
  end
end