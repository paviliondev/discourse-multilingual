import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  beforeModel(transition) {
    if (
      transition.intent.url === "/admin/multilingual" ||
      transition.intent.name === "adminMultilingual"
    ) {
      this.transitionTo("adminMultilingualLanguages");
    }
  },

  model() {
    return ajax("/admin/multilingual");
  },

  setupController(controller, model) {
    controller.setProperties({
      tagGroupId: model.content_language_tag_group_id,
      documentationUrl: "https://thepavilion.io/c/knowledge/discourse/multilingual"
    });
  },

  actions: {
    showSettings() {
      const controller = this.controllerFor("adminSiteSettings");
      this.transitionTo("adminSiteSettingsCategory", "plugins").then(() => {
        controller.set("filter", "multilingual");
        controller.set("_skipBounce", true);
        controller.filterContentNow("plugins");
      });
    },
  },
});
