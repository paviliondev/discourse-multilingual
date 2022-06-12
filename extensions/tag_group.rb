# frozen_string_literal: true
module TagGroupMultilingualExtension
  def visible(guardian)
    result = super(guardian)
    result = result.where.not(name: Multilingual::ContentTag.groups) if Multilingual::ContentLanguage.enabled
    result
  end
end
