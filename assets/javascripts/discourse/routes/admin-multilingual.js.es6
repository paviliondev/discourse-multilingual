import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  redirect: function() {
    this.transitionTo("adminMultilingualLanguages");
  }
});