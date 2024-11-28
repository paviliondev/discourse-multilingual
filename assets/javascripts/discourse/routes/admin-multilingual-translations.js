import DiscourseRoute from "discourse/routes/discourse";
import MultilingualTranslation from "../models/multilingual-translation";

export default DiscourseRoute.extend({
  model(params) {
    return MultilingualTranslation.list(params);
  },

  setupController(controller, model) {
    controller.set("translations", model);
  },
});
