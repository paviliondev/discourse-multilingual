export default {
  showRender(_, ctx) {
    return ctx.siteSettings.multilingual_enabled;
  },
  
  setupComponent(attrs, component) {
    Ember.run.scheduleOnce('afterRender', () => {
      const content = '.control-group.content-languages';
      const int = '.control-group.pref-locale';
      const text = '.control-group.text-size';
      const form = '.user-preferences form';
            
      if ($(text).length && !$(form).children(content).length) {
        $(content).prependTo(form);
      }
      
      if (!$(content).next(int).length) {
        $(int).insertAfter(content);
      }
    });
  }
}