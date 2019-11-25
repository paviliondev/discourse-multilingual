const languagesField = 'model.custom_fields.content_languages';

export default {
  setupComponent(attrs, component) {
    if (!Discourse.SiteSettings.multilingual_enabled) return;
    
    Ember.run.scheduleOnce('afterRender', () => {
      $(".control-group.pref-content-languages").insertAfter(
        $('.control-group.pref-locale')
      )
    });
  }
}