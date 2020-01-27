import { default as computed, observes } from "discourse-common/utils/decorators";
import MultilingualTranslation from '../models/multilingual-translation';

export default Ember.Component.extend({
  tagName: 'tr',
  classNames: 'language',
  
  actions: {
    remove() {
      this.set('removing', true);
      
      MultilingualTranslation.remove(
        this.get('translation.code'),
        this.get('translation.type')
      ).then((result) => {
        this.set('removing', false);
        this.removed(result);
      });
    },
    
    download() {
      MultilingualTranslation.download(
        this.get('translation.code'),
        this.get('translation.type')
      );
    }
  }
});