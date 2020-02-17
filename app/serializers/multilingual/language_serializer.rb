class Multilingual::LanguageSerializer < Multilingual::BasicLanguageSerializer
  attributes :custom,
             :nativeName,
             :content_enabled,
             :interface_enabled,
             :interface_supported
end