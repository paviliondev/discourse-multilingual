import DiscourseRoute from "discourse/routes/discourse";
import MultilingualLanguage from "../models/multilingual-language";

export default DiscourseRoute.extend({
  model(params) {
    return MultilingualLanguage.list(params);
  },

  setupController(controller, model) {
    controller.set("languages", model);
    controller.setupObservers();
  },
});
