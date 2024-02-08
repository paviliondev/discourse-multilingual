import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";

export default class AdminMultilingualRoute extends Route {
  @service router;

  beforeModel(transition) {
    if (
      transition.intent.url === "/admin/multilingual" ||
      transition.intent.name === "adminMultilingual"
    ) {
      this.router.transitionTo("adminMultilingualLanguages");
    }
  }

  setupController(controller, model) {
    controller.setProperties({
      tagGroupId: model.content_language_tag_group_id,
      documentationUrl:
        "https://thepavilion.io/c/knowledge/discourse/multilingual",
    });
  }

  @action
  showSettings() {
    const controller = this.controllerFor("adminSiteSettings");
    this.router
      .transitionTo("adminSiteSettingsCategory", "plugins")
      .then(() => {
        controller.set("filter", "multilingual");
        controller.set("_skipBounce", true);
        controller.filterContentNow("plugins");
      });
  }

  model() {
    return ajax("/admin/multilingual");
  }
}
