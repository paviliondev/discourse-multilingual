# frozen_string_literal: true

module Multilingual::LocaleSiteSetting
  def self.values
    @values ||= super.select { |v| Multilingual::Locale.active?(v[:locale]) }
  end
end

class ::LocaleSiteSetting
  prepend Multilingual::LocaleSiteSetting if SiteSetting.multilingual_enabled
end

