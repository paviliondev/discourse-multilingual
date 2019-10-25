const languagesField = 'model.custom_fields.content_languages';

export default {
  setupComponent(attrs, component) {
    Ember.run.scheduleOnce('afterRender', () => {
      $(".control-group.pref-content-languages").insertAfter(
        $('.control-group.pref-locale')
      )
    });
  }
}