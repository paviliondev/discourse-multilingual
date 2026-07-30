/* eslint-disable ember/no-classic-components, ember/require-tagless-components */

import Component from "@ember/component";
import EmberObject, { action, computed } from "@ember/object";
import { bind } from "@ember/runloop";
import { classNames } from "@ember-decorators/component";
import { on } from "discourse/lib/decorators";
import I18n from "discourse-i18n";
import { addParam, localeParam } from "../lib/multilingual-route";

@classNames("language-switcher-bar")
export default class LanguageSwitcherBar extends Component {
  showHidden = false;

  @computed("hiddenLanguages.[]")
  get showHiddenToggle() {
    return this.hiddenLanguages?.length > 0;
  }

  @on("init")
  setup() {
    const availableLanguages = this.availableLanguages();
    const currentLanguage = I18n.currentLocale();
    let visibleList =
      this.siteSettings.multilingual_guest_language_switcher_footer_visible.split(
        "|"
      );

    availableLanguages.forEach((l) => {
      if (l.locale === currentLanguage) {
        l.set("class", `${l.class} current`);

        if (visibleList.indexOf(l.locale) === -1) {
          visibleList.pop();
          visibleList.unshift(l.locale);
        }
      }
    });

    const visibleLimit = this.site.mobileView ? 3 : 10;
    let visibleLanguages = [];
    let hiddenLanguages = [];
    availableLanguages.forEach((l) => {
      if (
        visibleList.indexOf(l.locale) > -1 &&
        visibleLanguages.length < visibleLimit
      ) {
        visibleLanguages.push(l);
      } else {
        hiddenLanguages.push(l);
      }
    });

    this.setProperties({ visibleLanguages, hiddenLanguages });
  }

  availableLanguages() {
    return this.site.interface_languages.map((l) => {
      return EmberObject.create(Object.assign({}, l, { class: "language" }));
    });
  }

  didInsertElement() {
    super.didInsertElement(...arguments);
    this.set("clickOutsideHandler", bind(this, this.clickOutside));
    document.addEventListener("click", this.clickOutsideHandler);
  }

  willDestroyElement() {
    super.willDestroyElement(...arguments);
    document.removeEventListener("click", this.clickOutsideHandler);
  }

  clickOutside(e) {
    const hidden = document.querySelector(
      ".language-switcher-bar .hidden-languages"
    );

    if (!hidden?.contains(e.target)) {
      this.set("showHidden", false);
    }
  }

  @action
  change(locale) {
    this.set("showHidden", false);
    addParam(localeParam, locale, { add_cookie: true, ctx: this });
  }

  @action
  toggleHidden() {
    this.toggleProperty("showHidden");
  }
}
