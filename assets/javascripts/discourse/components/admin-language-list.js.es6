import { set } from "@ember/object";
// import { observes } from "discourse-common/utils/decorators";
//import Component from "@ember/component";
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class AdminLanguageList extends Component {
  @tracked allContentEnabled = false;
  @tracked allInterfaceEnabled = false;
  @tracked controlColumnClassNames =  ["language-control"];

  // @observes("allContentEnabled")
  // updateAllContent() {
  //   debugger;
  //   this.languages.forEach((l) => {
  //     set(l, "content_enabled", this.allContentEnabled);
  //   });
  // },

  // @observes("allInterfaceEnabled")
  // updateAllInterface() {
  //   debugger;
  //   this.languages.forEach((l) => {
  //     if (l.locale !== "en") {
  //       set(l, "interface_enabled", this.allInterfaceEnabled);
  //     }
  //   });
  // }

  @action
  selectAllContentEnabled() {
    this.languages.forEach((l) => {
      if (l.locale !== "en") {
        set(l, "interface_enabled", this.allInterfaceEnabled);
      }
    });
  }

  @action
  selectAllInterfaceEnabled() {
    this.languages.forEach((l) => {
      if (l.locale !== "en") {
        set(l, "interface_enabled", this.allInterfaceEnabled);
      }
    });
  }
};
