import { languageTags, languageTag, addLanguageTags } from '../../lib/multilingual';

export default {
  setupComponent(attrs, component) {
    const composer = attrs.model;
    const user = attrs.model.user;
    const userContentLanguages = user.content_languages.map(l => l.code) || [];
    
    let languageTags = composer.draftKey == 'new_topic' ?
      [...userContentLanguages]
      : languageTags(composer.tags);
    
    component.set('languageTags', languageTags);
    
    component.addObserver('languageTags', () => {
      if (this._state === 'destroying') return;
      addLanguageTags(composer, component.get('languageTags'));
    });
    
    Ember.run.scheduleOnce('afterRender', () => {
      $('.content-languages-selector').appendTo('.title-and-category');
    });
  }
}