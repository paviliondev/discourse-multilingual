module DiscourseTaggingMultilingualExtension
  def filter_allowed_tags(guardian, opts = {})
    result = super(guardian, opts)
    
    if opts[:for_input]
      result.select { |tag| Multilingual::ContentTag.all.exclude? tag.name }
    else
      result
    end
  end
end