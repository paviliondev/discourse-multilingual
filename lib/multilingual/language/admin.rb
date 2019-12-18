class Multilingual::Admin
  def self.add_all(languages = {})
    added = []
    
    languages.each do |k, v|
      if Multilingual::Language.create(k, v)
        added.push(k)
      end
    end
    
    set_tags(added, "create")
    
    refresh!
    
    added
  end
  
  def self.update_all(languages)    
    [*languages].each { |l| Multilingual::Language.update(l) }
    
    update_all_tags
    
    refresh!
    
    languages.map { |l| l['code'] }
  end
  
  def self.remove_all(codes)
    removed = []
    
    [*codes].each do |c|
      if Multilingual::Language.destroy(c)
        removed.push(c)
      end
    end
    
    set_tags(removed, "destroy")
    
    refresh!
    
    removed
  end
  
  def self.update_all_tags
    Multilingual::Language.all.each do |l|
      set_tags(l.code, l.content ? "create" : "destroy" )
    end
  end
  
  def self.set_tags(codes, action)
    [*codes].each do |c|
      Multilingual::Tag.send(action, c)
    end
  end
    
  def self.refresh!
    Multilingual::Base.reload!
    Multilingual::Content.reload!
    Multilingual::Locale.reload!
    Multilingual::Language.reload!
    Multilingual::Tag.reload!
  end
  
  def self.initialize
    extensions = SiteSetting.authorized_extensions_for_staff.split('|')
    extensions.push('yml') unless extensions.include?('yml')
    SiteSetting.authorized_extensions_for_staff = extensions.join('|')
    
    update_all_tags
    refresh!
  end
end