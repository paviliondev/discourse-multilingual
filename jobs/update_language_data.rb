module Jobs
  class UpdateLanguageData < ::Jobs::Scheduled
    every 1.day
    
    def execute(args)
      if SiteSetting.multilingual_enabled
        ::Multilingual::Languages.import
      end
    end
  end
end