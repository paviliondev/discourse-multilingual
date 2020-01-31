class Multilingual::LanguageSerializer < Multilingual::BasicLanguageSerializer
  attributes :custom,
             :content_enabled,
             :interface_enabled,
             :interface_supported
end