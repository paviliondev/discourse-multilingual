function isContentLanguage(code) {
  if (!code || !Discourse.SiteSettings.multilingual_content_languages_enabled) {
    return false;
  }
  const site = Discourse.Site.current();
  return site.content_languages.find(cl => cl.code == code);
}

export { isContentLanguage }