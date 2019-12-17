class Multilingual::AdminLanguageSerializer < Multilingual::BasicLanguageSerializer
  attributes :content,
             :locale,
             :locale_supported,
             :custom
end