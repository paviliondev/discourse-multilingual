import MultilingualLanguage from "../models/multilingual-language";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model(params) {
    return MultilingualLanguage.list(params);
  },

  setupController(controller, model) {
    controller.set("languages", model);
    controller.setupObservers();
  },
});
