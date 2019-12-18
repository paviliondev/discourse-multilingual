class Multilingual::AdminLanguageSerializer < Multilingual::BasicLanguageSerializer
  attributes :content,
             :locale,
             :locale_translations,
             :custom
end