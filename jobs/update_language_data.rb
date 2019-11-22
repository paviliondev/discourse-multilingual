module Jobs
  class UpdateLanguageData < ::Jobs::Base
    def execute(args)
      ::Multilingual::Languages.import
    end
  end
end