import { default as computed, observes } from "discourse-common/utils/decorators";
import MultilingualLanguage from '../models/multilingual-language';

export default Ember.Component.extend({
  tagName: 'tr',
  classNames: 'language',
  
  didInsertElement() {
    this.currentLanguage = JSON.parse(JSON.stringify(this.language));
  },
  
  @observes('language.content_enabled', 'language.interface_enabled')
  trackUpdates() {
    if (_.isEqual(this.currentLanguage, this.language)) {
      this.updatedLanguages.removeObject(this.language);
    } else {
      this.updatedLanguages.addObject(this.language);
    }
  },
  
  @computed('language.custom')
  typeKey(custom) {
    return `multilingual.languages.${custom ? 'custom': 'base'}`;
  },
  
  @computed('language.code')
  interfaceToggleDisabled(code) {
    return code === 'en';
  },
  
  @computed('language.content_tag_conflict')
  contentDisabled(tagConflict) {
    return !this.siteSettings.multilingual_content_languages_enabled || tagConflict;
  },
  
  @computed
  interfaceDisabled() {
    return !this.siteSettings.allow_user_locale;
  },
  
  @computed('language.custom')
  actionsDisabled(custom) {
    return !custom;
  },
  
  @computed
  contentClass() {
    return this.generateControlColumnClass("content");
  },
  
  @computed
  interfaceClass() {
    return this.generateControlColumnClass("interface");
  },
  
  @computed
  actionsClass() {
    return this.generateControlColumnClass('actions');
  },
  
  generateControlColumnClass(type) {
    let columnClass = `language-control ${type}`;
    if (this.get(`${type}Disabled`)) columnClass += " disabled";
    return columnClass;
  },
  
  actions: {
    remove() {
      this.set('removing', true);
      let codes = [this.get('language.code')];
      MultilingualLanguage.remove(codes)
        .then((result) => {
          this.set('removing', false);
          this.removed(result);
        })
    }
  }
});