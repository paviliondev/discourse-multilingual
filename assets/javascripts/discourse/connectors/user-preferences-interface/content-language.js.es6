export default {
  setupComponent(attrs, component) {
    if (!Discourse.SiteSettings.multilingual_enabled) return;
        
    Ember.run.scheduleOnce('afterRender', () => {
      const content = '.control-group.content-languages';
      const locale = '.control-group.pref-locale';
      const text = '.control-group.text-size';
      const form = '.user-preferences form';
            
      if ($(text).length &&
         !$(form).children(content).length) {
        $(content).prependTo(form)
      }
      if (!$(content).next(locale).length) {
        $(locale).insertAfter(content);
      }
    });
  }
}