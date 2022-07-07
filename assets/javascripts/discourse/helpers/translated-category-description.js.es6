import { registerUnbound } from "discourse-common/lib/helpers";
import { translatedCategoryDescription } from "../lib/multilingual-category";
import { htmlSafe } from "@ember/template";

export default registerUnbound("translated-category-description", function (category) {
  return htmlSafe(translatedCategoryDescription(category));
});
