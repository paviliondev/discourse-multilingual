module Jobs
  class UpdateLanguageTags < ::Jobs::Base
    def execute(args)
      Multilingual::Tag.reload!
      
      Multilingual::Language.all.each do |l|
        Multilingual::Tag.send(l.content ? "create" : "destroy", l.code)
      end 
    end
  end
end