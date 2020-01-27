import {
  contentLanguageTags,
  contentLanguageTag,
  addContentLanguageTags,
  userContentLanguageCodes
} from '../../lib/multilingual';

export default {
  setupComponent(attrs, component) {
    if (!Discourse.SiteSettings.multilingual_enabled) return;
    
    const composer = attrs.model;
    const user = attrs.model.user;
    const userTags = userContentLanguageCodes();
    
    let contentLanguageTags = composer.draftKey == 'new_topic' ?
      [...userTags]
      : contentLanguageTags(composer.tags);
          
    component.set('contentLanguageTags', contentLanguageTags);
    
    component.addObserver('contentLanguageTags.[]', () => {
      if (this._state === 'destroying') return;
      addContentLanguageTags(composer, component.get('contentLanguageTags'));
    });
    
    Ember.run.scheduleOnce('afterRender', () => {
      $('.content-languages-selector').appendTo('.title-and-category');
    });
  }
}