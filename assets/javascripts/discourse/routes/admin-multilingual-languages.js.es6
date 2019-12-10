import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  queryParams: {
    order: { refreshModel: true },
    ascending: { refreshModel: true }
  },

  model() {
    return ajax('/admin/multilingual/languages')
  }
});