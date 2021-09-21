import MultilingualTranslation from "../models/multilingual-translation";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  beforeModel() {
    if (!this.siteSettings.multilingual_enable_custom_translations) {
      this.transitionTo("adminMultilingualLanguages");
    }
  },

  model(params) {
    return MultilingualTranslation.list(params);
  },

  setupController(controller, model) {
    controller.set("translations", model);
  },
});
