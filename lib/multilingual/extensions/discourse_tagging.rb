module DiscourseTaggingMultilingualExtension
  def filter_allowed_tags(guardian, opts = {})
    result = super(guardian, opts)
    
    if opts[:for_input] && Multilingual::ContentLanguage.enabled
      result = result.select { |tag| Multilingual::ContentTag.all.exclude? tag.name }
    end
    
    result
  end
  
  def filter_visible(query, guardian = nil)
    result = super(query, guardian)
    
    if Multilingual::ContentLanguage.enabled
      result = result.where("tags.id NOT IN (#{Multilingual::ContentTag::QUERY})")
    end
    
    result
  end
end