import { default as computed, observes } from "discourse-common/utils/decorators";
import MultilingualLanguage from '../models/multilingual-language';

export default Ember.Component.extend({
  tagName: 'tr',
  classNames: 'language',
  
  didInsertElement() {
    this.currentLanguage = JSON.parse(JSON.stringify(this.language));
  },
  
  @observes('language.content_enabled', 'language.locale_enabled')
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