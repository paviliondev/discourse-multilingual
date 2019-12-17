class Multilingual::Admin
  def self.add_all(languages = {})
    languages.each { |k, v| Multilingual::Language.create(k, v) }
    refresh_all
  end
  
  def self.update_all(languages)    
    [*languages].each { |l| Multilingual::Language.save(l) }
    refresh_all
  end
  
  def self.remove_all(codes)
    [*codes].each { |l| Multilingual::Language.destroy(l) }
    refresh_all
  end
  
  def self.update_tags
    Jobs.enqueue(:update_language_tags)
  end
    
  def self.refresh!
    Multilingual::Base.reload!
    Multilingual::Content.reload!
    Multilingual::Locale.reload!
    Multilingual::Language.reload!
  end
  
  def self.refresh_all
    refresh!
    update_tags
  end
  
  def self.initialize
    extensions = SiteSetting.authorized_extensions_for_staff.split('|')
    extensions.push('yml') unless extensions.include?('yml')
    SiteSetting.authorized_extensions_for_staff = extensions.join('|')
      
    refresh_all
  end
end