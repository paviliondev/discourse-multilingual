import SelectKitRowComponent from "select-kit/components/select-kit/select-kit-row";
import { default as DiscourseURL, userPath } from "discourse/lib/url";

export default SelectKitRowComponent.extend({
  click(e) {
    if (this.rowValue === 'set_content_language') {
      DiscourseURL.routeTo(
        userPath(this.currentUser.username_lower + "/preferences/interface")
      );
    } else {
      this._super();
    }
  }
});
