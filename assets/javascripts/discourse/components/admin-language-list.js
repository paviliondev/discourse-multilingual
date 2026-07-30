/* eslint-disable ember/no-classic-components, ember/require-tagless-components */

import Component from "@ember/component";
import { set } from "@ember/object";
import { classNames } from "@ember-decorators/component";
import { observes } from "discourse/lib/decorators";

@classNames("admin-language-list")
export default class AdminLanguageList extends Component {
  controlColumnClassNames = ["language-control"];
  allContentEnabled = false;
  allInterfaceEnabled = false;

  @observes("allContentEnabled")
  updateAllContent() {
    this.languages.forEach((l) => {
      set(l, "content_enabled", this.allContentEnabled);
    });
  }

  @observes("allInterfaceEnabled")
  updateAllInterface() {
    this.languages.forEach((l) => {
      if (l.locale !== "en") {
        set(l, "interface_enabled", this.allInterfaceEnabled);
      }
    });
  }
}
