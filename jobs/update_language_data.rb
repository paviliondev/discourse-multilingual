module Jobs
  class UpdateLanguageData < ::Jobs::Scheduled
    every 1.day
    
    def execute(args)
      ::Multilingual::Languages.import
    end
  end
end