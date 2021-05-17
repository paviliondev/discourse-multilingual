# frozen_string_literal: true
module Jobs
  class UpdateContentLanguageTags < ::Jobs::Base
    def execute(args = {})
      if defined?(Multilingual::ContentLanguage) == 'constant'
        Multilingual::ContentTag.update_all
      end
    end
  end
end
