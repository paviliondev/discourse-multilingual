import { CREATE_TOPIC, EDIT } from 'discourse/models/composer';

export default {  
  shouldRender(attrs, ctx) {
    return ctx.siteSettings.multilingual_enabled && attrs.model.topicFirstPost;
  },
  
  setupComponent(attrs, component) {
    Ember.run.scheduleOnce('afterRender', () => {
      $('.content-languages-selector').appendTo('.title-and-category');
    });
  }
}