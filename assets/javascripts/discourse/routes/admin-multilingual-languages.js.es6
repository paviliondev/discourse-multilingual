import { ajax } from 'discourse/lib/ajax';
import MultilingualLanguage from '../models/multilingual-language';

export default Discourse.Route.extend({
  model(params) {
    return MultilingualLanguage.filter(params);
  },
  
  setupController(controller, model) {
    controller.set('languages', model);
    controller.setupObservers();
  }
});