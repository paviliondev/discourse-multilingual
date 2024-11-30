# frozen_string_literal: true
module Jobs
  class UpdateContentLanguageTags < ::Jobs::Base
    def execute(args = {})
      Multilingual::ContentTag.update_all if defined?(Multilingual::ContentLanguage) == "constant"
    end
  end
end
