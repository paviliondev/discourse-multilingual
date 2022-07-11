import DropdownSelectBox from "select-kit/components/dropdown-select-box";
import {
  contentLanguageParam,
  getDiscoveryParam,
} from "../../discourse/lib/multilingual-route";
import { set } from "@ember/object";

export default DropdownSelectBox.extend({
  classNames: "content-languages-dropdown",
  valueProperty: "locale",
  nameProperty: "name",

  selectKitOptions: {
    icon: "translate",
    showFullTitle: false,
    autoFilterable: false,
    headerComponent: "content-languages-header",
    hasLanguages: false,
  },

  didInsertElement() {
    if (!this.currentUser) {
      this.selectKit.options.set("filterable", true);
    }
  },

  modifyComponentForRow() {
    return "content-languages-row";
  },

  modifyContent(content) {
    if (!this.currentUser) {
      const param = getDiscoveryParam(this, contentLanguageParam);
      let activeIndex;

      content.forEach((l, i) => {
        if (l.locale === param) {
          set(l, "classNames", `${l.classNames} active`);
          set(l, "icon", "times");
          activeIndex = i;
        } else if (l.icon === "times") {
          set(l, "classNames", "guest-content-language");
          set(l, "icon", null);
        }
      });

      content.sort((a, b) => a.locale.localeCompare(b.locale));
      content.splice(0, 0, content.splice(activeIndex, 1)[0]);
    }

    return content;
  },
});
