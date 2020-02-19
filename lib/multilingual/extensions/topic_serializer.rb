module TopicSerializerMultilingualExtension
  def tags
    super - content_language_tags
  end
end