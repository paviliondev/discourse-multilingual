import SelectKitRowComponent from "select-kit/components/select-kit/select-kit-row";
import { default as DiscourseURL, userPath } from "discourse/lib/url";
import {
  addParam,
  contentLanguageParam,
} from "../../discourse/lib/multilingual-route";

export default SelectKitRowComponent.extend({
  click(e) {
    if (this.rowValue === "set_content_language") {
      DiscourseURL.routeTo(
        userPath(this.currentUser.username_lower + "/preferences/interface")
      );
    } else if (this.item.icon === "times") {
      addParam(contentLanguageParam, null, { ctx: this });
    } else if (!this.currentUser) {
      addParam(contentLanguageParam, this.rowValue, { ctx: this });
    } else {
      this._super(e);
    }
  },
});
