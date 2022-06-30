# frozen_string_literal: true
class Multilingual::CustomTranslationSerializer < ::ApplicationSerializer
  attributes :code, :file_type

  def code
    object[:code]
  end

  def file_type
    object[:file_type]
  end

end
