import {
  languageTags,
  languageTag,
  addLanguageTags,
  userContentLanguageCodes
} from '../../lib/multilingual';

export default {
  setupComponent(attrs, component) {
    if (!Discourse.SiteSettings.multilingual_enabled) return;
    
    const composer = attrs.model;
    const user = attrs.model.user;
    const userTags = userContentLanguageCodes();
    
    let languageTags = composer.draftKey == 'new_topic' ?
      [...userTags]
      : languageTags(composer.tags);
          
    component.set('languageTags', languageTags);
    
    component.addObserver('languageTags.[]', () => {
      if (this._state === 'destroying') return;
      addLanguageTags(composer, component.get('languageTags'));
    });
    
    Ember.run.scheduleOnce('afterRender', () => {
      $('.content-languages-selector').appendTo('.title-and-category');
    });
  }
}