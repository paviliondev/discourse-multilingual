class ::Multilingual::Translation
  TYPES ||= %w{tag category_name}
  CLIENT_TYPES ||= %w{tag}
  
  TYPES.each do |t|
    method_name = t.pluralize
    self.class.__send__(:attr_accessor, method_name)
    self.__send__("#{method_name}=", {})
  end
    
  def self.validate_type(type)
    TYPES.include?(type)
  end
  
  def self.load_server(code)
    files = Multilingual::TranslationFile.all.select do |f|
      f.code == code && CLIENT_TYPES.exclude?(f.type)
    end
    
    files.each { |f| self.send("#{f.type.to_s.pluralize}=", f.open) }
  end
  
  def self.reset_server!
    types = TYPES.select { |t| CLIENT_TYPES.exclude?(t) }
    types.each { |t| self.send("#{t.pluralize}=", {}) }
  end
  
  def self.setup!
    Multilingual::Translation.reset_server!
    Multilingual::TranslationFile.reset!
  end
end