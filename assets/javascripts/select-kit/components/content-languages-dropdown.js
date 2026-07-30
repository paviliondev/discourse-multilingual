import { set } from "@ember/object";
import { classNames } from "@ember-decorators/component";
import DropdownSelectBox from "discourse/select-kit/components/dropdown-select-box";
import { selectKitOptions } from "discourse/select-kit/components/select-kit";
import {
  contentLanguageParam,
  getDiscoveryParam,
} from "../../discourse/lib/multilingual-route";

@classNames("content-languages-dropdown")
@selectKitOptions({
  icon: "translate",
  showFullTitle: false,
  autoFilterable: false,
  headerComponent: "content-languages-header",
  hasLanguages: false,
})
export default class ContentLanguagesDropdown extends DropdownSelectBox {
  valueProperty = "locale";
  nameProperty = "name";

  didInsertElement() {
    super.didInsertElement(...arguments);

    if (!this.currentUser) {
      this.selectKit.options.set("filterable", true);
    }
  }

  modifyComponentForRow() {
    return "content-languages-row";
  }

  modifyContent(content) {
    if (!this.currentUser) {
      const param = getDiscoveryParam(this, contentLanguageParam);
      let activeIndex;

      content.forEach((l, i) => {
        if (l.locale === param) {
          set(l, "classNames", `${l.classNames} active`);
          set(l, "icon", "xmark");
          activeIndex = i;
        } else if (l.icon === "xmark") {
          set(l, "classNames", "guest-content-language");
          set(l, "icon", null);
        }
      });

      content.sort((a, b) => a.locale.localeCompare(b.locale));
      content.splice(0, 0, content.splice(activeIndex, 1)[0]);
    }

    return content;
  }
}
