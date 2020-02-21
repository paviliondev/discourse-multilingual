import { registerUnbound } from "discourse-common/lib/helpers";
import { translatedCategoryName } from "../lib/multilingual-category";

export default registerUnbound("translated-category-name", function(category) {
  return new Handlebars.SafeString(translatedCategoryName(category));
});