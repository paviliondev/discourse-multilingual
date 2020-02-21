export default {
  shouldRender(attrs, ctx) {
    return ctx.siteSettings.multilingual_enabled &&
           ctx.siteSettings.multilingual_locale_switcher === "footer" &&
           !ctx.siteSettings.login_required &&
           !ctx.currentUser;
  }
}