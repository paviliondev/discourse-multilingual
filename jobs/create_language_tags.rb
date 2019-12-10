module Jobs
  class UpdateLanguageTags < ::Jobs::Base
    def execute(args)
      group = Multilingual::Tag.group
            
      Multilingual::Language.all.each do |language|
        Multilingual::Tag.create(language.code, group) if language.content
      end  
    end
  end
end