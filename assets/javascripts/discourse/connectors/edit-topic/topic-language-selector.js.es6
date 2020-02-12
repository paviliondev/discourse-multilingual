export default {  
  shouldRender(attrs, ctx) {
    return ctx.siteSettings.multilingual_enabled;
  }
}