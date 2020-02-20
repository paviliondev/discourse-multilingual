import Controller from "@ember/controller";
import MultilingualTranslation from '../models/multilingual-translation';

export default Controller.extend({
  refreshing: false,
  
  _refresh() {
    this.set("refreshing", true);
    
    MultilingualTranslation.list().then(result => {
      this.set('translations', result);
    }).finally(() => {
      this.set("refreshing", false);
    });
  },
  
  actions: {
    refresh() {
      this._refresh();
    }
  }
});
