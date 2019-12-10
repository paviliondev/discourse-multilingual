import { observes } from "discourse-common/utils/decorators";

export default Ember.Component.extend({
  tagName: 'tr',
  classNames: 'language',
  
  didInsertElement() {
    this.currentLanguage = JSON.parse(JSON.stringify(this.language));
  },
  
  @observes('language.content', 'language.locale')
  trackUpdates() {
    if (_.isEqual(this.currentLanguage, this.language)) {
      this.updatedLanguages.removeObject(this.language);
    } else {
      this.updatedLanguages.addObject(this.language);
    }
  }
});