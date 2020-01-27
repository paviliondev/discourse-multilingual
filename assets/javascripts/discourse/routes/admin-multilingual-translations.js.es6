import { ajax } from 'discourse/lib/ajax';
import MultilingualTranslation from '../models/multilingual-translation';

export default Discourse.Route.extend({
  model(params) {
    return MultilingualTranslation.all(params);
  },
  
  setupController(controller, model) {
    controller.set('translations', model);
  }
});