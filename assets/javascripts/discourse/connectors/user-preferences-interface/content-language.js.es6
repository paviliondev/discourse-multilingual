import { scheduleOnce } from "@ember/runloop";

export default {
  shouldRender(_, ctx) {
    return ctx.siteSettings.multilingual_enabled &&
      ctx.siteSettings.multilingual_content_languages_enabled;
  },
  
  setupComponent(attrs, component) {
    scheduleOnce('afterRender', () => {
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