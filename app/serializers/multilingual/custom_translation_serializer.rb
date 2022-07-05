# frozen_string_literal: true
class Multilingual::CustomTranslationSerializer < ::ApplicationSerializer
  attributes :locale, :file_type

  def locale
    object[:locale]
  end

  def file_type
    object[:file_type]
  end

end
