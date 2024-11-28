import Component from "@ember/component";
import { set } from "@ember/object";
import { observes } from "discourse-common/utils/decorators";

export default Component.extend({
  classNames: "admin-language-list",
  controlColumnClassNames: ["language-control"],
  allContentEnabled: false,
  allInterfaceEnabled: false,

  @observes("allContentEnabled")
  updateAllContent() {
    this.languages.forEach((l) => {
      set(l, "content_enabled", this.allContentEnabled);
    });
  },

  @observes("allInterfaceEnabled")
  updateAllInterface() {
    this.languages.forEach((l) => {
      if (l.locale !== "en") {
        set(l, "interface_enabled", this.allInterfaceEnabled);
      }
    });
  },
});
