import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  beforeModel(transition) {
    if (transition.intent.url == '/admin/multilingual' ||
        transition.intent.name == 'adminMultilingual') {
      this.transitionTo("adminMultilingualLanguages");
    }
  }
});