import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  beforeModel(transition) {
    if (transition.intent.url === '/admin/multilingual' ||
        transition.intent.name === 'adminMultilingual') {
      this.transitionTo("adminMultilingualLanguages");
    }
  },
  
  model() {
    return ajax('/admin/multilingual');
  },
  
  setupController(controller, model) {
    controller.set('tagGroupId', model.content_language_tag_group_id);
  },
  
  actions: {
    showSettings(plugin) {
      const controller = this.controllerFor("adminSiteSettings");
      this.transitionTo("adminSiteSettingsCategory", "plugins").then(() => {
        controller.set("filter", "multilingual");
        controller.set("_skipBounce", true);
        controller.filterContentNow("plugins");
      });
    }
  }
});