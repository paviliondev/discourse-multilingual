module TagGroupMultilingualExtension
  def visible(guardian)
    result = super(guardian)
    result.where.not(name: Multilingual::ContentTag::GROUP) if Multilingual::ContentLanguage.enabled
    result
  end
end