import Site from "discourse/models/site";

function isContentLanguage(locale, siteSettings) {
  if (!locale || !siteSettings.multilingual_content_languages_enabled) {
    return false;
  }

  const site = Site.current();
  if (!site.content_languages) {
    return false;
  }

  return site.content_languages.find((cl) => cl.locale === locale);
}

export { isContentLanguage };
