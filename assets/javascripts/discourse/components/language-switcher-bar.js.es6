import { on } from "discourse-common/utils/decorators";
import EmberObject from "@ember/object";
import { addParam, localeParam } from "../lib/multilingual-route";
import { notEmpty } from "@ember/object/computed";
import Component from "@ember/component";
import { bind } from "@ember/runloop";
import I18n from "I18n";

export default Component.extend({
  classNames: "language-switcher-bar",
  showHidden: false,
  showHiddenToggle: notEmpty("hiddenLanguages"),

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
  },

  availableLanguages() {
    return this.site.interface_languages.map((l) => {
      return EmberObject.create(Object.assign({}, l, { class: "language" }));
    });
  },

  didInsertElement() {
    this.set("clickOutsideHandler", bind(this, this.clickOutside));
    $(document).on("click", this.clickOutsideHandler);
  },

  willDestroyElement() {
    $(document).off("click", this.clickOutsideHandler);
  },

  clickOutside(e) {
    const $hidden = $(".language-switcher-bar .hidden-languages");
    const $target = $(e.target);

    if (!$target.closest($hidden).length) {
      this.set("showHidden", false);
    }
  },

  actions: {
    change(locale) {
      this.set("showHidden", false);
      addParam(localeParam, locale, { add_cookie: true, ctx: this });
    },

    toggleHidden() {
      this.toggleProperty("showHidden");
    },
  },
});
