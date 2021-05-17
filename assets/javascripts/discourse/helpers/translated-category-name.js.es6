import { registerUnbound } from "discourse-common/lib/helpers";
import { translatedCategoryName } from "../lib/multilingual-category";
import { htmlSafe } from "@ember/template";

export default registerUnbound("translated-category-name", function (category) {
  return htmlSafe(translatedCategoryName(category));
});
