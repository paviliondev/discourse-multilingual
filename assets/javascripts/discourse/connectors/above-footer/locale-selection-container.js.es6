export default {
  shouldRender(attrs, ctx) {
    return ctx.siteSettings.multilingual_enabled &&
           ctx.siteSettings.multilingual_language_switcher !== "off" &&
           !ctx.currentUser;
  }
}