class Multilingual::LanguageSerializer < Multilingual::BasicLanguageSerializer
  attributes :custom,
             :nativeName,
             :content_enabled,
             :content_tag_conflict,
             :interface_enabled,
             :interface_supported
end