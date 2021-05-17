export default {
  shouldRender(_, ctx) {
    return ctx.siteSettings.multilingual_enabled &&
      ctx.siteSettings.multilingual_content_languages_enabled;
  }
};
